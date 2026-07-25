#!/bin/sh

chroot_exec apk update
chroot_exec apk add \
	cups cups-openrc cups-filters ghostscript \
	dbus dbus-openrc avahi avahi-openrc \
	usbutils foo2zjs foo2zjs-cups foo2zjs-hp1020

for service in dbus cupsd hp1020; do
	chroot_exec rc-update add "$service" default
done

if [ "${ENABLE_AVAHI:-true}" = true ]; then
	chroot_exec rc-update add avahi-daemon default
else
	chroot_exec rc-update del avahi-daemon default 2>/dev/null || true
fi

install -d "$ROOTFS_PATH/var/spool/cups" "$ROOTFS_PATH/var/cache/cups"
install -d "$DATAFS_PATH/var/spool/cups" "$DATAFS_PATH/var/cache/cups"
lp_gid=$(awk -F: '$1 == "lp" { print $3 }' "$ROOTFS_PATH/etc/group")
[ -n "$lp_gid" ] || {
	echo "lp group is missing from the target root filesystem" >&2
	exit 1
}
chown "0:$lp_gid" \
	"$ROOTFS_PATH/var/spool/cups" "$ROOTFS_PATH/var/cache/cups" \
	"$DATAFS_PATH/var/spool/cups" "$DATAFS_PATH/var/cache/cups"
chmod 710 "$ROOTFS_PATH/var/spool/cups" "$DATAFS_PATH/var/spool/cups"
