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

mkdir "$tmp/root" "$tmp/boot"
gzip -dc "$archive" >"$tmp/sdcard.img"
loop=$(losetup --find --show --partscan "$tmp/sdcard.img")
mount -o ro "${loop}p1" "$tmp/boot"
mount -o ro "${loop}p2" "$tmp/root"

root="$tmp/root"
test -s "$root/usr/bin/foo2zjs"
test -s "$root/usr/share/cups/model/HP-LaserJet_1020.ppd.gz"
test -s "$root/usr/share/foo2zjs/firmware/sihp1020.dl"
test -s "$root/etc/udev/rules.d/70-hp1020.rules"
test -s "$root/etc/init.d/hp1020"
test -s "$root/etc/modules-load.d/hp1020.conf"
grep -q usblp "$root/etc/modules-load.d/hp1020.conf"
test -e "$root/etc/runlevels/default/cupsd"
test -e "$root/etc/runlevels/default/dbus"
test -e "$root/etc/runlevels/default/hp1020"
find "$root/lib/modules" -type f -name 'usblp.ko*' | grep -q .
file "$root/usr/bin/foo2zjs" | grep -Eq 'ARM|EABI'
verify_sha256 "$root/usr/share/foo2zjs/firmware/sihp1020.dl" \
	"$HP1020_FIRMWARE_DL_SHA256"
test -s "$tmp/boot/kernel7.img"

printf '%s\n' "image inspection passed: $archive"
