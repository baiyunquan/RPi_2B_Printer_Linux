#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

need_command docker
need_command git

apk_repository=${APK_REPOSITORY:-"$PROJECT_ROOT/output/apk/repository"}
firmware=${HP1020_FIRMWARE_PATH:-"$PROJECT_ROOT/output/firmware/sihp1020.dl"}
output=${IMAGE_OUTPUT_DIR:-"$PROJECT_ROOT/output/image"}
cache=${BUILDER_CACHE_DIR:-"$PROJECT_ROOT/cache/builder"}
prepared="$PROJECT_ROOT/work/image-input"
rtl8811cu_source="$PROJECT_ROOT/$RTL8811CU_SUBMODULE"

[ -s "$apk_repository/armv7/APKINDEX.tar.gz" ] || {
	echo "APK repository missing; run scripts/build-foo2zjs-apk.sh" >&2
	exit 1
}
[ -s "$firmware" ] || {
	echo "firmware missing; run scripts/fetch-hp1020-firmware.sh" >&2
	exit 1
}
[ -s "$rtl8811cu_source/Makefile" ] || {
	echo "RTL8811CU source missing; run scripts/clone-sources.sh" >&2
	exit 1
}
rtl8811cu_commit=$(git -C "$rtl8811cu_source" rev-parse HEAD)
# shellcheck disable=SC2153
[ "$rtl8811cu_commit" = "$RTL8811CU_COMMIT" ] || {
	echo "RTL8811CU submodule mismatch: expected $RTL8811CU_COMMIT, found $rtl8811cu_commit" >&2
	exit 1
}

rm -rf "$prepared"
mkdir -p \
	"$prepared/rootfs" \
	"$prepared/repository" \
	"$prepared/firmware" \
	"$prepared/rtl8811cu-driver" \
	"$output" \
	"$cache"
cp -a "$PROJECT_ROOT/image/input/." "$prepared/"
cp -a "$PROJECT_ROOT/image/rootfs/." "$prepared/rootfs/"
cp -a "$apk_repository/." "$prepared/repository/"
cp "$firmware" "$prepared/firmware/sihp1020.dl"
cp -a "$rtl8811cu_source/." "$prepared/rtl8811cu-driver/"
rm -f "$prepared/rtl8811cu-driver/.git"

builder_tag=$("$SCRIPT_DIR/build-builder-container.sh" | tail -n 1)

docker run --rm --privileged \
	--env-file "$PROJECT_ROOT/config/build.env" \
	-e "RPI_FIRMWARE_BRANCH=$RPI_FIRMWARE_BRANCH" \
	-e "LINUX_RPI_VERSION=$LINUX_RPI_VERSION" \
	-e "LINUX_FIRMWARE_RTW88_VERSION=$LINUX_FIRMWARE_RTW88_VERSION" \
	-e "RPI_BOOTLOADER_VERSION=$RPI_BOOTLOADER_VERSION" \
	-e "BUILDER_COMMIT=$BUILDER_COMMIT" \
	-e "FOO2ZJS_COMMIT=$FOO2ZJS_COMMIT" \
	-e "ENABLE_AVAHI=${ENABLE_AVAHI:-true}" \
	-e "ENABLE_SSH=${ENABLE_SSH:-true}" \
	-e "SSH_AUTHORIZED_KEYS=${SSH_AUTHORIZED_KEYS:-}" \
	-v "$prepared:/input:ro" \
	-v "$output:/output" \
	-v "$cache:/cache" \
	-e CACHE_PATH=/cache \
	"$builder_tag"

"$SCRIPT_DIR/create-manifest.sh" "$output"
