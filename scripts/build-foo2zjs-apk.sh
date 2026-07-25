#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

need_command docker
"$SCRIPT_DIR/clone-sources.sh" >/dev/null

output=${1:-"$PROJECT_ROOT/output/apk"}
rm -rf "$output"
mkdir -p "$output"

docker run --rm --privileged --platform linux/arm/v7 \
	-v "$PROJECT_ROOT:/src:ro" \
	-v "$output:/out" \
	-e "ALPINE_BRANCH=$ALPINE_BRANCH" \
	"alpine:${ALPINE_BRANCH#v}" /bin/sh -euxc '
		apk add --no-cache alpine-sdk cups-dev gzip sudo
		adduser -D build
		addgroup build abuild
		echo "build ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/abuild
		install -d -o build -g build /home/build/pkg /home/build/.abuild
		cp -a /src/packages/foo2zjs/. /home/build/pkg/
		cp -a /home/build/pkg/files/. /home/build/pkg/
		chown -R build:build /home/build
		su build -c "cd /home/build/pkg && abuild-keygen -a -n && abuild checksum && abuild -r"
		repo_index=$(find /home/build/packages -name APKINDEX.tar.gz -type f | head -n 1)
		test -n "$repo_index"
		cp -a "$(dirname "$repo_index")" /out/repository
		cp /home/build/.abuild/*.rsa.pub /out/repository/
	'

test -s "$output/repository/APKINDEX.tar.gz"
apk_count=$(find "$output/repository" -maxdepth 1 -name '*.apk' -type f | wc -l | tr -d ' ')
[ "$apk_count" -ge 3 ] || {
	echo "expected at least three APK files, found $apk_count" >&2
	exit 1
}
printf 'built %s APK files in %s\n' "$apk_count" "$output/repository"
