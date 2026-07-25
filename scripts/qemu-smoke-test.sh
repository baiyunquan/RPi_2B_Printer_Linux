#!/bin/sh
set -eu

if [ "${RUN_QEMU_SMOKE_TEST:-false}" != true ]; then
	echo "QEMU smoke test disabled (set RUN_QEMU_SMOKE_TEST=true)"
	exit 0
fi

command -v qemu-system-arm >/dev/null 2>&1 || {
	echo "qemu-system-arm is required" >&2
	exit 127
}

echo "The raspi2b machine does not emulate the HP USB device."
echo "Run scripts/inspect-image.sh first; QEMU boot validation is opt-in."
set +e
timeout 45 qemu-system-arm \
	-M raspi2b -m 1024 -nographic -no-reboot \
	-drive "file=${1:?uncompressed SD image required},format=raw,if=sd" \
	>"${2:-qemu-smoke.log}" 2>&1
status=$?
set -e
cat "${2:-qemu-smoke.log}"

[ "$status" -eq 124 ] || exit "$status"
grep -Eq 'Linux version|OpenRC' "${2:-qemu-smoke.log}"
