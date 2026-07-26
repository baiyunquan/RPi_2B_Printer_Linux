#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

required_files='
config/build.env
config/sources.lock
packages/foo2zjs/APKBUILD
packages/foo2zjs/files/hp1020-firmware-loader
image/input/image.sh
image/input/stages/10/90-enable-writable-partitions.sh
image/input/stages/60/15-build-rtl8811cu.sh
image/input/stages/60/20-install-print-stack.sh
image/rootfs/etc/cups/cupsd.conf
image/rootfs/etc/avahi/services/hp1020.service
image/rootfs/etc/udev/rules.d/80-wifi-hotplug.rules
image/rootfs/usr/libexec/wifi-hotplug
image/rootfs/usr/libexec/wifi-hotplug-worker
scripts/build-foo2zjs-apk.sh
scripts/fetch-hp1020-firmware.sh
scripts/build-image.sh
.github/workflows/build-image.yml
'

for file in $required_files; do
	test -s "$file" || {
		echo "missing required file: $file" >&2
		exit 1
	}
done

grep -q '^ARCH=armv7$' config/build.env
grep -q '^DEV=eudev$' config/build.env
grep -q '^iw$' config/packages.txt
grep -q '^wpa_supplicant$' config/packages.txt
grep -q \
	'^ADDITIONAL_KERNEL_MODULES="usblp rtw88_8822cu 8821cu"$' \
	config/build.env
(
	# shellcheck disable=SC1091
	. ./config/build.env
	[ "$ADDITIONAL_KERNEL_MODULES" = \
		"usblp rtw88_8822cu 8821cu" ]
)
grep -q '^RTL8811CU_BUILD_JOBS=2$' config/build.env
grep -q '^LINUX_FIRMWARE_RTW88_VERSION=20251125-r1$' config/sources.lock
grep -q '^RTL8811CU_SUBMODULE=RTL8811CU_Driver$' config/sources.lock
grep -q '^RTL8811CU_COMMIT=d28dd4b5949c4be59a8bacb67c68dd1dbd511bb5$' \
	config/sources.lock
grep -q "linux-firmware-rtw88=\$LINUX_FIRMWARE_RTW88_VERSION" \
	image/input/stages/00/50-arch-specific-rpi.sh
grep -Fq "\"linux-rpi-dev=\$LINUX_RPI_VERSION\"" \
	image/input/stages/60/15-build-rtl8811cu.sh
grep -q '/rtl8811cu/8821cu.ko' \
	image/input/stages/60/15-build-rtl8811cu.sh
grep -q '^blacklist rtw88_8821cu$' RTL8811CU_Driver/rtw88_8821cu.conf
grep -q '0xC811' RTL8811CU_Driver/os_dep/linux/usb_intf.c
grep -q '^DEFAULT_DROPBEAR_ENABLED=true$' config/build.env
grep -q '^DEFAULT_ROOT_PASSWORD=1234$' config/build.env
grep -q '^ENABLE_SSH=true$' config/build.env
grep -q '^OVERLAY=true$' config/build.env
grep -q '^SIZE_BOOT=32M$' config/build.env
grep -q '^SIZE_ROOT_PART=256M$' config/build.env
grep -q '^SIZE_DATA=64M$' config/build.env
grep -q 'DROPBEAR_OPTS="-p 22"' image/input/stages/60/60-configure-security.sh
grep -q 'ATTR{idVendor}=="03f0"' packages/foo2zjs/files/hp1020-udev.rules
grep -q 'ATTR{idProduct}=="2b17"' packages/foo2zjs/files/hp1020-udev.rules
grep -q 'SUBSYSTEM=="net"' image/rootfs/etc/udev/rules.d/80-wifi-hotplug.rules
grep -q 'KERNEL=="wlan\*"' image/rootfs/etc/udev/rules.d/80-wifi-hotplug.rules
grep -q 'RUN+="/usr/libexec/wifi-hotplug %k"' \
	image/rootfs/etc/udev/rules.d/80-wifi-hotplug.rules
grep -q 'chroot_exec apk add iw wpa_supplicant' \
	image/input/stages/60/50-configure-network.sh
grep -q '^iface wlan0 inet dhcp$' image/input/stages/60/50-configure-network.sh
grep -q 'rc-service wpa_supplicant start' \
	image/rootfs/usr/libexec/wifi-hotplug-worker
grep -Fq "ifup \"\$iface\"" image/rootfs/usr/libexec/wifi-hotplug-worker
grep -q 'Port 631' image/rootfs/etc/cups/cupsd.conf
test "$(grep -c 'Allow @LOCAL' image/rootfs/etc/cups/cupsd.conf)" -eq 3
grep -q 'chroot_exec addgroup root lpadmin' \
	image/input/stages/60/30-configure-cups.sh
grep -q 'chroot_exec cupsd -t' image/input/stages/60/30-configure-cups.sh
grep -q 's/defaults,ro/defaults,rw/g' \
	image/input/stages/10/90-enable-writable-partitions.sh
grep -q "sed -i .*ro.*rw" image/input/stages/60/90-finalize.sh
grep -q 'rp=printers/hp1020' image/rootfs/etc/avahi/services/hp1020.service
test -f .gitmodules
grep -q 'path = vendor/builder' .gitmodules
grep -q 'path = vendor/foo2zjs' .gitmodules
grep -q 'path = RTL8811CU_Driver' .gitmodules

if [ -e vendor/builder/.git ] && [ -e vendor/foo2zjs/.git ] &&
	[ -e RTL8811CU_Driver/.git ]; then
	builder_commit=$(git -C vendor/builder rev-parse HEAD)
	foo2zjs_commit=$(git -C vendor/foo2zjs rev-parse HEAD)
	rtl8811cu_commit=$(git -C RTL8811CU_Driver rev-parse HEAD)
	grep -q "^BUILDER_COMMIT=$builder_commit$" config/sources.lock
	grep -q "^FOO2ZJS_COMMIT=$foo2zjs_commit$" config/sources.lock
	grep -q "^RTL8811CU_COMMIT=$rtl8811cu_commit$" config/sources.lock
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	if git ls-files '*.dl' '*.img' '*.img.gz' | grep -q .; then
		echo "firmware or image binary is tracked by Git" >&2
		exit 1
	fi
fi

for key in BUILDER_COMMIT FOO2ZJS_COMMIT RTL8811CU_COMMIT ACTION_CHECKOUT_SHA \
	ACTION_SETUP_QEMU_SHA ACTION_UPLOAD_ARTIFACT_SHA; do
	value=$(sed -n "s/^$key=//p" config/sources.lock)
	printf '%s' "$value" | grep -Eq '^[0-9a-f]{40}$' || {
		echo "$key is not a full commit SHA" >&2
		exit 1
	}
done

echo "static checks passed"
