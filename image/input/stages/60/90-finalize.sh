#!/bin/sh
set -eu

chroot_exec apk cache clean
rm -rf "$ROOTFS_PATH/var/cache/apk/"*
find "$ROOTFS_PATH" -type f -name '*.apk-new' -delete

cat >"$ROOTFS_PATH/etc/hp1020-image-release" <<EOF
IMAGE_VERSION=${IMAGE_VERSION:-dev}
ALPINE_BRANCH=${ALPINE_BRANCH}
ARCH=${ARCH}
BUILDER_COMMIT=${BUILDER_COMMIT:-unknown}
FOO2ZJS_COMMIT=${FOO2ZJS_COMMIT:-unknown}
EOF
