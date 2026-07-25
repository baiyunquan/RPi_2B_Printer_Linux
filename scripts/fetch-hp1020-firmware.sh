#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

need_command tar

output=${1:-"$PROJECT_ROOT/output/firmware"}
mkdir -p "$output"
target="$output/sihp1020.dl"

if [ -n "${HP1020_FIRMWARE_FILE:-}" ]; then
	[ -r "$HP1020_FIRMWARE_FILE" ] || {
		echo "HP1020_FIRMWARE_FILE is not readable" >&2
		exit 1
	}
	cp "$HP1020_FIRMWARE_FILE" "$target"
	verify_sha256 "$target" "$HP1020_FIRMWARE_DL_SHA256"
	chmod 600 "$target"
	printf '%s\n' "$target"
	exit 0
fi

need_command curl
need_command cc
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

archive="$tmp/sihp1020.tar.gz"
curl --fail --location --retry 3 --silent --show-error \
	"$HP1020_FIRMWARE_URL" --output "$archive"
verify_sha256 "$archive" "$HP1020_FIRMWARE_ARCHIVE_SHA256"
tar -xzf "$archive" -C "$tmp" sihp1020.img
verify_sha256 "$tmp/sihp1020.img" "$HP1020_FIRMWARE_IMAGE_SHA256"

foo_source="$PROJECT_ROOT/$FOO2ZJS_SUBMODULE"
if [ ! -f "$foo_source/arm2hpdl.c" ]; then
	"$SCRIPT_DIR/clone-sources.sh" >/dev/null
fi
cc -O2 -o "$tmp/arm2hpdl" "$foo_source/arm2hpdl.c"
"$tmp/arm2hpdl" "$tmp/sihp1020.img" >"$target"
verify_sha256 "$target" "$HP1020_FIRMWARE_DL_SHA256"
chmod 600 "$target"
printf '%s\n' "$target"
