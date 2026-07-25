#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

output=${1:-"$PROJECT_ROOT/output/image"}
mkdir -p "$output"

build_time=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
project_commit=$(
	git -C "$PROJECT_ROOT" rev-parse --verify HEAD 2>/dev/null ||
		printf unknown
)

cat >"$output/build-manifest.json" <<EOF
{
  "image_version": "$IMAGE_VERSION",
  "built_at": "$build_time",
  "project_commit": "$project_commit",
  "architecture": "$ARCH",
  "alpine_branch": "$ALPINE_BRANCH",
  "builder_base_image": "$BUILDER_BASE_IMAGE@$BUILDER_BASE_IMAGE_DIGEST",
  "builder": {
    "repository": "$BUILDER_REPOSITORY",
    "commit": "$BUILDER_COMMIT",
    "submodule": "$BUILDER_SUBMODULE"
  },
  "foo2zjs": {
    "repository": "$FOO2ZJS_REPOSITORY",
    "commit": "$FOO2ZJS_COMMIT",
    "submodule": "$FOO2ZJS_SUBMODULE"
  },
  "raspberry_pi_firmware": {
    "branch": "$RPI_FIRMWARE_BRANCH",
    "commit": "$RPI_FIRMWARE_COMMIT",
    "package": "$RPI_FIRMWARE_PACKAGE"
  },
  "hp1020_firmware_sha256": "$HP1020_FIRMWARE_DL_SHA256"
}
EOF

cp "$PROJECT_ROOT/config/packages.txt" "$output/packages-manifest.txt"

for image in "$output"/sdcard*.img.gz; do
	[ -f "$image" ] || continue
	sha256_file "$image" >"$image.sha256.tmp"
	printf '%s  %s\n' "$(cat "$image.sha256.tmp")" "$(basename "$image")" \
		>"$image.sha256"
	rm "$image.sha256.tmp"
done
