#!/bin/sh

# This file is sourced by raspi-alpine/builder; do not change the caller's
# shell options.

rootfs_overlay="$INPUT_PATH/rootfs"
[ -d "$rootfs_overlay" ] || {
	echo "missing rootfs overlay: $rootfs_overlay" >&2
	exit 1
}

cp -a "$rootfs_overlay"/. "$ROOTFS_PATH"/

firmware="$INPUT_PATH/firmware/sihp1020.dl"
if [ -r "$firmware" ]; then
	install -Dm644 "$firmware" \
		"$ROOTFS_PATH/usr/share/foo2zjs/firmware/sihp1020.dl"
else
	echo "missing $firmware; run scripts/fetch-hp1020-firmware.sh" >&2
	exit 1
fi
