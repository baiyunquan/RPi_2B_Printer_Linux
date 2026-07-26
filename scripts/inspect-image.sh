#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

need_command losetup
need_command mount
need_command umount
need_command gzip

archive=${1:-"$PROJECT_ROOT/output/image/sdcard.img.gz"}
[ -s "$archive" ] || {
	echo "image not found: $archive" >&2
	exit 1
}

tmp=$(mktemp -d)
loop=
cleanup() {
	if mountpoint -q "$tmp/data"; then
		umount "$tmp/data" || true
	fi
	if mountpoint -q "$tmp/root"; then
		umount "$tmp/root" || true
	fi
	if mountpoint -q "$tmp/boot"; then
		umount "$tmp/boot" || true
	fi
	if [ -n "$loop" ]; then
		losetup -d "$loop" || true
	fi
	rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

mkdir "$tmp/root" "$tmp/boot" "$tmp/data"
gzip -dc "$archive" >"$tmp/sdcard.img"
loop=$(losetup --find --show --partscan "$tmp/sdcard.img")
mount -o ro "${loop}p1" "$tmp/boot"
mount -o ro "${loop}p2" "$tmp/root"
mount -o ro "${loop}p4" "$tmp/data"

root="$tmp/root"
data="$tmp/data"
require_file() {
	[ -s "$1" ] || {
		echo "required image file is missing or empty: $1" >&2
		exit 1
	}
}

require_link() {
	[ -L "$1" ] || {
		echo "required image symlink is missing: $1" >&2
		exit 1
	}
}

require_file "$root/usr/bin/foo2zjs"
require_file "$root/usr/share/cups/model/HP-LaserJet_1020.ppd.gz"
require_file "$root/usr/share/foo2zjs/firmware/sihp1020.dl"
require_file "$root/etc/udev/rules.d/70-hp1020.rules"
require_file "$root/etc/udev/rules.d/80-wifi-hotplug.rules"
require_file "$root/etc/init.d/hp1020"
require_file "$root/etc/modules-load.d/hp1020.conf"
require_file "$root/etc/modules-load.d/rtl8811cu.conf"
require_file "$root/etc/modprobe.d/8821cu.conf"
require_file "$root/etc/modprobe.d/rtw88_8821cu.conf"
require_file "$root/usr/libexec/wifi-hotplug"
require_file "$root/usr/libexec/wifi-hotplug-worker"
require_file "$root/etc/fstab"
grep -q 'RUN+="/usr/libexec/wifi-hotplug %k"' \
	"$root/etc/udev/rules.d/80-wifi-hotplug.rules"
grep -q '^iface wlan0 inet dhcp$' "$root/etc/network/interfaces"
grep -q usblp "$root/etc/modules-load.d/hp1020.conf"
grep -q '^8821cu$' "$root/etc/modules-load.d/rtl8811cu.conf"
grep -q '^blacklist rtw88_8821cu$' \
	"$root/etc/modprobe.d/rtw88_8821cu.conf"
grep -Eq '^/dev/root[[:space:]]+/[[:space:]]+ext4[[:space:]]+defaults,rw' \
	"$root/etc/fstab"
grep -Eq '^LABEL=BOOT[[:space:]]+/(uboot|boot)[[:space:]]+vfat[[:space:]]+defaults,rw' \
	"$root/etc/fstab"
if grep -Eq 'defaults,ro' "$root/etc/fstab"; then
	echo "image contains a read-only filesystem entry" >&2
	exit 1
fi
grep -Eq '^[[:space:]]*overlay[[:space:]]+/etc[[:space:]]' "$root/etc/fstab"
require_link "$root/etc/runlevels/default/cupsd"
require_link "$root/etc/runlevels/default/dbus"
require_link "$root/etc/runlevels/default/dropbear"
require_link "$root/etc/runlevels/default/hp1020"
require_file "$data/etc/dropbear/dropbear.conf"
grep -q '^DROPBEAR_OPTS="-p 22"$' "$data/etc/dropbear/dropbear.conf"
require_file "$data/etc/shadow"
root_password=$(awk -F: '$1 == "root" { print $2 }' "$data/etc/shadow")
case "$root_password" in
	'' | '!'* | '*')
		echo "root password is missing or locked in the data partition" >&2
		exit 1
		;;
esac
find "$root/lib/modules" -type f -name 'usblp.ko*' | grep -q .
find "$root/lib/modules" -type f -name 'rtw88_8822cu.ko*' | grep -q .
rtl8811cu_module=$(
	find "$root/lib/modules" -type f -path '*/rtl8811cu/8821cu.ko*' \
		-print -quit
)
[ -n "$rtl8811cu_module" ]
file "$rtl8811cu_module" | grep -Eq 'ARM|EABI'
find "$root/lib/firmware/rtw88" -maxdepth 1 -type f \
	-name 'rtw8822c_fw.bin*' | grep -q .
file "$root/usr/bin/foo2zjs" | grep -Eq 'ARM|EABI'
verify_sha256 "$root/usr/share/foo2zjs/firmware/sihp1020.dl" \
	"$HP1020_FIRMWARE_DL_SHA256"
require_file "$root/boot/vmlinuz-rpi"
require_file "$tmp/boot/u-boot_rpi2.bin"
require_file "$tmp/boot/boot.scr"
require_file "$tmp/boot/cmdline.txt"
grep -q '^kernel=u-boot_rpi2.bin$' "$tmp/boot/config.txt"
grep -Eq '(^|[[:space:]])rw([[:space:]]|$)' "$tmp/boot/cmdline.txt"
if grep -Eq '(^|[[:space:]])ro([[:space:]]|$)' "$tmp/boot/cmdline.txt"; then
	echo "kernel command line requests a read-only root filesystem" >&2
	exit 1
fi

printf '%s\n' "image inspection passed: $archive"
