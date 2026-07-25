#!/bin/sh

set -eu

PROJECT_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/.." && pwd)

# shellcheck disable=SC1091
. "$PROJECT_ROOT/config/build.env"
# shellcheck disable=SC1091
. "$PROJECT_ROOT/config/sources.lock"

export PROJECT_ROOT ARCH ALPINE_BRANCH IMAGE_VERSION

need_command() {
	command -v "$1" >/dev/null 2>&1 || {
		echo "required command not found: $1" >&2
		exit 127
	}
}

sha256_file() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$1" | awk '{print $1}'
	else
		shasum -a 256 "$1" | awk '{print $1}'
	fi
}

verify_sha256() {
	actual=$(sha256_file "$1")
	expected=$(printf '%s' "$2" | tr 'A-F' 'a-f')
	[ "$actual" = "$expected" ] || {
		echo "SHA-256 mismatch for $1" >&2
		echo "expected: $expected" >&2
		echo "actual:   $actual" >&2
		exit 1
	}
}
