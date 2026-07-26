#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

need_command git

sync_submodule() {
	name=$1
	path=$2
	commit=$3
	target="$PROJECT_ROOT/$path"

	git -C "$PROJECT_ROOT" submodule update --init --recursive -- "$path"
	actual=$(git -C "$target" rev-parse HEAD)
	[ "$actual" = "$commit" ] || {
		echo "$name submodule mismatch: expected $commit, found $actual" >&2
		exit 1
	}
	printf '%s %s\n' "$name" "$actual"
}

git -C "$PROJECT_ROOT" submodule sync --recursive
sync_submodule builder "$BUILDER_SUBMODULE" "$BUILDER_COMMIT"
sync_submodule foo2zjs "$FOO2ZJS_SUBMODULE" "$FOO2ZJS_COMMIT"
sync_submodule rtl8811cu "$RTL8811CU_SUBMODULE" "$RTL8811CU_COMMIT"
