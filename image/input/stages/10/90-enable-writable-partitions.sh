#!/bin/sh

fstab="$ROOTFS_PATH/etc/fstab"
[ -s "$fstab" ] || {
	echo "target fstab is missing: $fstab" >&2
	exit 1
}

sed -i 's/defaults,ro/defaults,rw/g' "$fstab"

grep -Eq '^/dev/root[[:space:]]+/[[:space:]]+ext4[[:space:]]+defaults,rw' "$fstab"
grep -Eq '^LABEL=BOOT[[:space:]]+/(uboot|boot)[[:space:]]+vfat[[:space:]]+defaults,rw' "$fstab"
if grep -q 'defaults,ro' "$fstab"; then
	echo "read-only filesystem entry remains in $fstab" >&2
	exit 1
fi
