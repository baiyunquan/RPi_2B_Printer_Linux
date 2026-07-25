#!/bin/sh

printf '%s\n' hp1020 >"$ROOTFS_PATH/etc/hostname"
if [ "${ENABLE_AVAHI:-true}" = true ]; then
	chmod 644 "$ROOTFS_PATH/etc/avahi/services/hp1020.service"
else
	rm -f "$ROOTFS_PATH/etc/avahi/services/hp1020.service"
fi

chroot_exec apk add iw wpa_supplicant

chmod 644 "$ROOTFS_PATH/etc/udev/rules.d/80-wifi-hotplug.rules"
chmod 755 \
	"$ROOTFS_PATH/usr/libexec/wifi-hotplug" \
	"$ROOTFS_PATH/usr/libexec/wifi-hotplug-worker"

interfaces="$ROOTFS_PATH/etc/network/interfaces"
if ! grep -Eq '^[[:space:]]*iface[[:space:]]+wlan0[[:space:]]' \
	"$interfaces"; then
	cat >>"$interfaces" <<'EOF'

iface wlan0 inet dhcp
EOF
fi
