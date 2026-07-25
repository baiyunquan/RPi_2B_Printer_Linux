#!/bin/sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
repository=${1:-"$root/output/apk/repository"}
test -s "$repository/armv7/APKINDEX.tar.gz"

docker run --rm --privileged --platform linux/arm/v7 \
	-v "$repository:/repo:ro" \
	-v "$root/tests/assets:/tests:ro" \
	"alpine:3.23" /bin/sh -euxc '
		cp /repo/*.rsa.pub /etc/apk/keys/
		apk add --no-cache --repository /repo \
			foo2zjs foo2zjs-cups cups-filters ghostscript
		gzip -dc /usr/share/cups/model/HP-LaserJet_1020.ppd.gz >/tmp/hp1020.ppd
		export PPD=/tmp/hp1020.ppd
		cupsfilter -p "$PPD" -m application/vnd.cups-postscript \
			/tests/test-page.ps >/tmp/cupsfilter.ps
		test -s /tmp/cupsfilter.ps
		foomatic-rip 1 ci hp1020-test 1 "" /tmp/cupsfilter.ps \
			>/tmp/test-page.zjs
		test -s /tmp/test-page.zjs
		test "$(wc -c </tmp/test-page.zjs)" -gt 100
	'
