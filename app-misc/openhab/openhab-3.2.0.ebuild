# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit systemd
S=${WORKDIR}
OPENHAB_HOME="/opt/openhab"
DESCRIPTION="OpenHAB 3.2.0 Stable home automation, base package without bindings etc."
HOMEPAGE="https://www.openhab.org"
SRC_URI="
https://www.openhab.org/download/releases/org/openhab/distro/openhab/${PV}/${PN}-${PV}.zip"
LICENSE="EPL-2.0"
SLOT="3"
KEYWORDS="~amd64 ~x86"
IUSE=""
DEPEND="dev-java/openjdk:11
"
RDEPEND="${DEPEND}"
pkg_setup()
{
	enewgroup openhab
	enewuser openhab -1 -1 $OPENHAB_HOME "uucp,openhab"
}
src_install()
{
	dodir $OPENHAB_HOME
	insinto "${OPENHAB_HOME}"/
	doins -r * || die "doins failed"
	exeinto "${OPENHAB_HOME}"/
	doexe start.sh
	exeinto "${OPENHAB_HOME}"/runtime/bin/
	doexe runtime/bin/karaf
	fowners -R openhab:openhab ${OPENHAB_HOME}
default
	systemd_dounit "${FILESDIR}"/openhab.service
}
