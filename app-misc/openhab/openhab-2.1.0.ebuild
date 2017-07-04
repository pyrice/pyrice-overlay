# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
EAPI=6
inherit user systemd
S=${WORKDIR}
OPENHAB_HOME="/opt/openhab2"
DESCRIPTION="OpenHAB home automation, base package without bindings etc."
HOMEPAGE="http://www.openhab.org"
SRC_URI="https://bintray.com/openhab/mvn/download_file?file_path=org/${PN}/distro/${PN}/${PV}/${PN}-${PV}.tar.gz"
LICENSE="EPL"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
DEPEND="virtual/jdk:1.8
        app-arch/unzip
        virtual/jre:1.8"
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
#	fperms +x start.sh
#	fperms +x runtime/bin/karaf
#	ls -la
default
	systemd_dounit "${FILESDIR}"/openhab2.service
}
