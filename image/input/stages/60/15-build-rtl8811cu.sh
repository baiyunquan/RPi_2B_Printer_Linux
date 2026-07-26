#!/bin/sh

driver_input="$INPUT_PATH/rtl8811cu-driver"
driver_build="$ROOTFS_PATH/tmp/rtl8811cu-driver"

[ -s "$driver_input/Makefile" ] || {
	echo "RTL8811CU driver source is missing from the image input" >&2
	exit 1
}
[ -n "${LINUX_RPI_VERSION:-}" ] || {
	echo "LINUX_RPI_VERSION is required to build RTL8811CU" >&2
	exit 1
}

case "${RTL8811CU_BUILD_JOBS:-2}" in
	*[!0-9]* | 0 | '')
		echo "RTL8811CU_BUILD_JOBS must be a positive integer" >&2
		exit 1
		;;
esac

kernel_release=
for module_dir in "$ROOTFS_PATH"/lib/modules/*; do
	[ -d "$module_dir" ] || continue
	[ -z "$kernel_release" ] || {
		echo "expected exactly one installed Raspberry Pi kernel" >&2
		exit 1
	}
	kernel_release=${module_dir##*/}
done
[ -n "$kernel_release" ] || {
	echo "installed Raspberry Pi kernel modules were not found" >&2
	exit 1
}

chroot_exec apk add --virtual .rtl8811cu-build-deps \
	build-base bc "linux-rpi-dev=$LINUX_RPI_VERSION"

rm -rf "$driver_build"
install -d "$driver_build"
cp -a "$driver_input"/. "$driver_build"/

chroot_exec make \
	-C /tmp/rtl8811cu-driver \
	-j"${RTL8811CU_BUILD_JOBS:-2}" \
	ARCH=arm \
	KVER="$kernel_release" \
	KSRC="/lib/modules/$kernel_release/build" \
	modules

chroot_exec strip --strip-unneeded /tmp/rtl8811cu-driver/8821cu.ko
install -Dm644 \
	"$driver_build/8821cu.ko" \
	"$ROOTFS_PATH/lib/modules/$kernel_release/kernel/drivers/net/wireless/realtek/rtl8811cu/8821cu.ko"
install -Dm644 \
	"$driver_input/8821cu.conf" \
	"$ROOTFS_PATH/etc/modprobe.d/8821cu.conf"
install -Dm644 \
	"$driver_input/rtw88_8821cu.conf" \
	"$ROOTFS_PATH/etc/modprobe.d/rtw88_8821cu.conf"
printf '%s\n' 8821cu >"$ROOTFS_PATH/etc/modules-load.d/rtl8811cu.conf"

chroot_exec depmod -a "$kernel_release"
rm -rf "$driver_build"
chroot_exec apk del .rtl8811cu-build-deps
