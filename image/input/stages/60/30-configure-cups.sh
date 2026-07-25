#!/bin/sh

chown root:lp "$ROOTFS_PATH/etc/cups/cupsd.conf"
chmod 640 "$ROOTFS_PATH/etc/cups/cupsd.conf"
chroot_exec addgroup root lpadmin
chroot_exec cupsd -t

ppd="$ROOTFS_PATH/usr/share/cups/model/HP-LaserJet_1020.ppd.gz"
[ -s "$ppd" ] || {
	echo "HP LaserJet 1020 PPD was not installed" >&2
	exit 1
}
