#!/bin/sh

# Override the builder stage so the Raspberry Pi kernel and bootloader cannot
# silently advance within the Alpine stable branch.
[ -n "${LINUX_RPI_VERSION:-}" ] || {
	echo "LINUX_RPI_VERSION is required" >&2
	exit 1
}
[ -n "${RPI_BOOTLOADER_VERSION:-}" ] || {
	echo "RPI_BOOTLOADER_VERSION is required" >&2
	exit 1
}

chroot_exec apk add "linux-rpi=$LINUX_RPI_VERSION"

case "$RPI_FIRMWARE_BRANCH" in
	alpine)
		chroot_exec apk add \
			"raspberrypi-bootloader=$RPI_BOOTLOADER_VERSION" \
			"raspberrypi-bootloader-cutdown=$RPI_BOOTLOADER_VERSION"
		;;
	*)
		echo "unsupported firmware mode: $RPI_FIRMWARE_BRANCH" >&2
		exit 1
		;;
esac
