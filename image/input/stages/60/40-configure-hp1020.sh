#!/bin/sh
set -eu

firmware="$ROOTFS_PATH/usr/share/foo2zjs/firmware/sihp1020.dl"
[ -s "$firmware" ] || {
	echo "HP LaserJet 1020 firmware is missing" >&2
	exit 1
}

chmod 755 \
	"$ROOTFS_PATH/usr/local/libexec/hp1020-firmware-loader" \
	"$ROOTFS_PATH/usr/local/libexec/hp1020-firstboot" \
	"$ROOTFS_PATH/etc/init.d/hp1020"
printf '%s\n' usblp >"$ROOTFS_PATH/etc/modules-load.d/hp1020.conf"
