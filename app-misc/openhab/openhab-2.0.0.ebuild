# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
EAPI=6
MY_PN=openhab
DESCRIPTION="OpenHAB home automation, base package without bindings etc."
HOMEPAGE="http://www.openhab.org"
SRC_URI="https://bintray.com/openhab/mvn/download_file?file_path=org/${MY_PN}/distro/${MY_PN}/${PV}/${MY_PN}-${PV}.tar.gz"
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
  enewuser openhab -1 -1 -1 "uucp,openhab"
  return
}
src_install() 
{
  into /opt
}
  

