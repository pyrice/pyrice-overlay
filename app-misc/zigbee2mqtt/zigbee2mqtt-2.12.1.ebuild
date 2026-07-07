# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="Zigbee to MQTT bridge, get rid of your proprietary Zigbee bridges"
HOMEPAGE="
	https://www.zigbee2mqtt.io/
	https://github.com/Koenkk/zigbee2mqtt
"
# The application is a TypeScript/Node.js project managed with pnpm. Portage may
# not access the network during src_compile, so the npm dependency tree is
# vendored into a separate distfile generated offline with
# `pnpm install --frozen-lockfile` (node-linker=hoisted). The build then compiles
# TypeScript and prunes devDependencies without any network access.
# See scripts/test_zigbee2mqtt.sh in this overlay for how the bundle is produced.
SRC_URI="
	https://github.com/Koenkk/zigbee2mqtt/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/Koenkk/zigbee2mqtt/releases/download/${PV}/${P}-node_modules.tar.xz
"

S="${WORKDIR}/${P}"

LICENSE="GPL-3"
# The vendored node_modules bundle contains many third-party packages under
# permissive licenses (MIT, ISC, Apache-2.0, BSD).
LICENSE+=" MIT ISC Apache-2.0 BSD BSD-2 BSD-4 0BSD CC0-1.0 Unlicense"
SLOT="0"
KEYWORDS="~amd64"

# Native modules (e.g. winston-syslog's unix-dgram) are shipped prebuilt in the
# vendored bundle; mark them as prebuilt so QA does not flag the binaries.
QA_PREBUILT="usr/lib/${PN}/node_modules/.*"

BDEPEND=">=net-libs/nodejs-20.15.0[npm]"
RDEPEND="
	>=net-libs/nodejs-20.15.0:=
	acct-user/zigbee2mqtt
	acct-group/zigbee2mqtt
"

src_unpack() {
	default
	# Merge the vendored dependency tree into the source checkout.
	mv "${WORKDIR}/node_modules" "${S}/" || die "could not place vendored node_modules"
}

src_compile() {
	# Drop any stale incremental build state so tsc performs a full build.
	rm -f tsconfig.tsbuildinfo || die

	# Compile TypeScript sources into dist/.
	./node_modules/.bin/tsc || die "TypeScript compilation failed"

	# Write dist/.hash. Without it the runtime would try to rebuild on every
	# start via `pnpm run prepack`, which is unavailable on the target system.
	node index.js writehash || die "failed to write dist/.hash"

	# Remove devDependencies from the bundle. Fully offline: no network access.
	npm prune --omit=dev --offline --no-audit --no-fund \
		|| die "failed to prune devDependencies"
}

src_install() {
	local instdir="/usr/lib/${PN}"

	dodir "${instdir}"
	# cp -a preserves the symlinks and executable bits inside node_modules/.bin
	# and the permissions of prebuilt native (.node) modules.
	cp -a dist node_modules index.js cli.js package.json \
		"${ED}${instdir}/" || die "install failed"

	# Command-line launcher.
	dobin "${FILESDIR}/${PN}"

	# Service integration.
	newinitd "${FILESDIR}/${PN}.initd" "${PN}"
	newconfd "${FILESDIR}/${PN}.confd" "${PN}"
	systemd_dounit "${FILESDIR}/${PN}.service"

	# Data and log directories owned by the service account.
	keepdir /var/lib/${PN}
	fowners ${PN}:${PN} /var/lib/${PN}
	fperms 0750 /var/lib/${PN}

	keepdir /var/log/${PN}
	fowners ${PN}:${PN} /var/log/${PN}
	fperms 0750 /var/log/${PN}

	dodoc README.md
}

pkg_postinst() {
	elog "Zigbee2MQTT is installed to /usr/lib/${PN}."
	elog "Configuration and state live in /var/lib/${PN} (ZIGBEE2MQTT_DATA)."
	elog
	elog "Start it with one of:"
	elog "    rc-service ${PN} start          # OpenRC"
	elog "    systemctl start ${PN}.service   # systemd"
	elog
	elog "On first start the web onboarding wizard is reachable on port 8080."
	elog "The ${PN} user is a member of the dialout group for serial adapter"
	elog "access; ensure your Zigbee coordinator (e.g. /dev/ttyUSB0) is present."
}
