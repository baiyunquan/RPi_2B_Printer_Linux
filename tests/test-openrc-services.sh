#!/bin/sh
set -eu

rootfs=${1:?mounted root filesystem path required}

for service in cupsd dbus hp1020; do
	test -e "$rootfs/etc/runlevels/default/$service" || {
		echo "OpenRC service not enabled: $service" >&2
		exit 1
	}
done

test -e "$rootfs/etc/runlevels/sysinit/udev"
test -e "$rootfs/etc/runlevels/sysinit/udev-trigger"
grep -q usblp "$rootfs/etc/modules-load.d/hp1020.conf"
