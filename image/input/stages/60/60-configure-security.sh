#!/bin/sh

# The builder creates a password hash before Stage 60. Lock it unconditionally.
chroot_exec passwd -l root
chroot_exec rc-update del dropbear default 2>/dev/null || true

if [ "${ENABLE_SSH:-false}" = true ]; then
	[ -n "${SSH_AUTHORIZED_KEYS:-}" ] || {
		echo "ENABLE_SSH=true requires SSH_AUTHORIZED_KEYS" >&2
		exit 1
	}
	install -d -m700 "$DATAFS_PATH/root/.ssh"
	printf '%s\n' "$SSH_AUTHORIZED_KEYS" \
		>"$DATAFS_PATH/root/.ssh/authorized_keys"
	chmod 600 "$DATAFS_PATH/root/.ssh/authorized_keys"
	chroot_exec rc-update add dropbear default
	install -d "$DATAFS_PATH/etc/dropbear"
	printf '%s\n' 'DROPBEAR_OPTS="-s -g -w"' \
		>"$DATAFS_PATH/etc/dropbear/dropbear.conf"
fi
