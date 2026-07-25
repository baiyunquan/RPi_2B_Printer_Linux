#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

need_command git

destination=${1:-"$PROJECT_ROOT/work/sources"}
mkdir -p "$destination"

clone_commit() {
	name=$1
	url=$2
	commit=$3
	target="$destination/$name"

	if [ ! -d "$target/.git" ]; then
		rm -rf "$target"
		git init -q "$target"
		git -C "$target" remote add origin "$url"
	fi
	if ! git -C "$target" cat-file -e "$commit^{commit}" 2>/dev/null; then
		git -C "$target" fetch --depth 1 origin "$commit"
	fi
	git -C "$target" checkout -q --detach "$commit"
	actual=$(git -C "$target" rev-parse HEAD)
	[ "$actual" = "$commit" ] || {
		echo "$name checkout mismatch: $actual" >&2
		exit 1
	}
	printf '%s %s\n' "$name" "$actual"
}

clone_commit builder "$BUILDER_REPOSITORY" "$BUILDER_COMMIT"
clone_commit foo2zjs "$FOO2ZJS_REPOSITORY" "$FOO2ZJS_COMMIT"
