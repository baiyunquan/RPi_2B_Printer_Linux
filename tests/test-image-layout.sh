#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
exec "$root/scripts/inspect-image.sh" "${1:-$root/output/image/sdcard.img.gz}"
