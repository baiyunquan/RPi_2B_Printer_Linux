#!/bin/sh

repository="$INPUT_PATH/repository"
[ -f "$repository/armv7/APKINDEX.tar.gz" ] || {
	echo "local APKINDEX is missing; build foo2zjs first" >&2
	exit 1
}

install -d "$ROOTFS_PATH/var/cache/hp1020-apk" "$ROOTFS_PATH/etc/apk/keys"
cp -a "$repository"/. "$ROOTFS_PATH/var/cache/hp1020-apk/"

key=$(find "$repository" -maxdepth 1 -name '*.rsa.pub' -type f | head -n 1)
[ -n "$key" ] || {
	echo "local APK signing public key is missing" >&2
	exit 1
}
install -m644 "$key" "$ROOTFS_PATH/etc/apk/keys/$(basename "$key")"
printf '%s\n' 'file:///var/cache/hp1020-apk' >>"$ROOTFS_PATH/etc/apk/repositories"
