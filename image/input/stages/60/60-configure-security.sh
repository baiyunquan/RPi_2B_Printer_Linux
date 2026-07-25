#!/bin/sh

if [ "${ENABLE_SSH:-true}" = true ]; then
	chroot_exec rc-update add dropbear default
	install -d "$DATAFS_PATH/etc/dropbear"
	printf '%s\n' 'DROPBEAR_OPTS="-p 22"' \
		>"$DATAFS_PATH/etc/dropbear/dropbear.conf"

	if [ -n "${SSH_AUTHORIZED_KEYS:-}" ]; then
		install -d -m700 "$DATAFS_PATH/root/.ssh"
		printf '%s\n' "$SSH_AUTHORIZED_KEYS" \
			>"$DATAFS_PATH/root/.ssh/authorized_keys"
		chmod 600 "$DATAFS_PATH/root/.ssh/authorized_keys"
	fi
else
	chroot_exec rc-update del dropbear default 2>/dev/null || true
fi
