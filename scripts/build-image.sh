#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

need_command docker

apk_repository=${APK_REPOSITORY:-"$PROJECT_ROOT/output/apk/repository"}
firmware=${HP1020_FIRMWARE_PATH:-"$PROJECT_ROOT/output/firmware/sihp1020.dl"}
output=${IMAGE_OUTPUT_DIR:-"$PROJECT_ROOT/output/image"}
cache=${BUILDER_CACHE_DIR:-"$PROJECT_ROOT/cache/builder"}
prepared="$PROJECT_ROOT/work/image-input"

[ -s "$apk_repository/APKINDEX.tar.gz" ] || {
	echo "APK repository missing; run scripts/build-foo2zjs-apk.sh" >&2
	exit 1
}
[ -s "$firmware" ] || {
	echo "firmware missing; run scripts/fetch-hp1020-firmware.sh" >&2
	exit 1
}

rm -rf "$prepared"
mkdir -p "$prepared/rootfs" "$prepared/repository" "$prepared/firmware" "$output" "$cache"
cp -a "$PROJECT_ROOT/image/input/." "$prepared/"
cp -a "$PROJECT_ROOT/image/rootfs/." "$prepared/rootfs/"
cp -a "$apk_repository/." "$prepared/repository/"
cp "$firmware" "$prepared/firmware/sihp1020.dl"

builder_tag=$("$SCRIPT_DIR/build-builder-container.sh" | tail -n 1)

docker run --rm --privileged \
	--env-file "$PROJECT_ROOT/config/build.env" \
	-e "RPI_FIRMWARE_BRANCH=$RPI_FIRMWARE_BRANCH" \
	-e "LINUX_RPI_VERSION=$LINUX_RPI_VERSION" \
	-e "RPI_BOOTLOADER_VERSION=$RPI_BOOTLOADER_VERSION" \
	-e "BUILDER_COMMIT=$BUILDER_COMMIT" \
	-e "FOO2ZJS_COMMIT=$FOO2ZJS_COMMIT" \
	-e "ENABLE_AVAHI=${ENABLE_AVAHI:-true}" \
	-e "ENABLE_SSH=${ENABLE_SSH:-false}" \
	-e "SSH_AUTHORIZED_KEYS=${SSH_AUTHORIZED_KEYS:-}" \
	-v "$prepared:/input:ro" \
	-v "$output:/output" \
	-v "$cache:/cache" \
	-e CACHE_PATH=/cache \
	"$builder_tag"

"$SCRIPT_DIR/create-manifest.sh" "$output"
