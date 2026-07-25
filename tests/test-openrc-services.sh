#!/bin/sh
set -eu

rootfs=${1:?mounted root filesystem path required}

for service in cupsd dbus dropbear hp1020; do
	test -L "$rootfs/etc/runlevels/default/$service" || {
		echo "OpenRC service not enabled: $service" >&2
		exit 1
	}
done

test -L "$rootfs/etc/runlevels/sysinit/udev"
test -L "$rootfs/etc/runlevels/sysinit/udev-trigger"
grep -q usblp "$rootfs/etc/modules-load.d/hp1020.conf"
