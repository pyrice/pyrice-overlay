# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils desktop

DESCRIPTION="Perforce version control system Helix Command Line Client (P4)"
HOMEPAGE="http://www.perforce.com/"
SRC_URI="amd64? (
		http://www.perforce.com/downloads/perforce/r${PV}/bin.linux26x86_64/helix-core-server.tgz \
		    -> ${PF}-amd64.tgz )"

LICENSE="perforce"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE=""
RESTRICT="mirror strip"

DEPEND=""
RDEPEND="dev-qt/qtcore:5 ${DEPEND}"

S=${WORKDIR}

src_unpack() {
	# we have to copy all of the files from $DISTDIR, otherwise we get
	# sandbox violations when trying to install
	if [ "${A}" != "" ]; then
		unpack ${A}
	fi
}

src_install() {
	into /opt/${PN}
        dobin p4
	insinto /opt/${PN}
	doins -r p4
	dosym /opt/${PN}/bin/p4 /usr/bin/p4  
}
