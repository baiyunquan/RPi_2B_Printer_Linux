#!/bin/sh

chroot_exec apk cache clean
rm -rf "$ROOTFS_PATH/var/cache/apk/"*
find "$ROOTFS_PATH" -type f -name '*.apk-new' -delete

cmdline="$BOOTFS_PATH/cmdline.txt"
[ -s "$cmdline" ] || {
	echo "missing kernel command line: $cmdline" >&2
	exit 1
}
sed -i 's/\(^\|[[:space:]]\)ro\([[:space:]]\|$\)/\1rw\2/g' "$cmdline"
grep -Eq '(^|[[:space:]])rw([[:space:]]|$)' "$cmdline"
if grep -Eq '(^|[[:space:]])ro([[:space:]]|$)' "$cmdline"; then
	echo "kernel command line still requests a read-only root filesystem" >&2
	exit 1
fi

cat >"$ROOTFS_PATH/etc/hp1020-image-release" <<EOF
IMAGE_VERSION=${IMAGE_VERSION:-dev}
ALPINE_BRANCH=${ALPINE_BRANCH}
ARCH=${ARCH}
BUILDER_COMMIT=${BUILDER_COMMIT:-unknown}
FOO2ZJS_COMMIT=${FOO2ZJS_COMMIT:-unknown}
EOF
