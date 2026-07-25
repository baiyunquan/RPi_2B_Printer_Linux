#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
repository=${1:-"$root/output/apk/repository"}
test -s "$repository/APKINDEX.tar.gz"

docker run --rm --privileged --platform linux/arm/v7 \
	-v "$repository:/repo:ro" "alpine:3.23" /bin/sh -euxc '
		cp /repo/*.rsa.pub /etc/apk/keys/
		apk add --no-cache file
		apk add --no-cache --repository /repo \
			foo2zjs foo2zjs-cups foo2zjs-hp1020
		test -x /usr/bin/foo2zjs
		test -x /usr/bin/foo2zjs-wrapper
		test -x /usr/bin/foo2zjs-pstops
		test -s /usr/share/cups/model/HP-LaserJet_1020.ppd.gz
		test -x /usr/libexec/hp1020-firmware-loader
		test -s /etc/udev/rules.d/70-hp1020.rules
		file /usr/bin/foo2zjs | grep -Eq "ARM|EABI"
	'
