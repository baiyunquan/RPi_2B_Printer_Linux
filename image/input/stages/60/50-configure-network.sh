#!/bin/sh
set -eu

printf '%s\n' hp1020 >"$ROOTFS_PATH/etc/hostname"
if [ "${ENABLE_AVAHI:-true}" = true ]; then
	chmod 644 "$ROOTFS_PATH/etc/avahi/services/hp1020.service"
else
	rm -f "$ROOTFS_PATH/etc/avahi/services/hp1020.service"
fi
