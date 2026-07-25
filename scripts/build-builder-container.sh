#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

need_command docker
"$SCRIPT_DIR/clone-sources.sh"

tag=${BUILDER_IMAGE_TAG:-hp1020-alpine-builder:"${BUILDER_COMMIT%????????????????????????????????}"}
docker build \
	--build-arg "ALPINE_VER=${ALPINE_BRANCH#v}@${BUILDER_BASE_IMAGE_DIGEST}" \
	--label "org.opencontainers.image.revision=$BUILDER_COMMIT" \
	--tag "$tag" \
	"$PROJECT_ROOT/work/sources/builder"
printf '%s\n' "$tag"
