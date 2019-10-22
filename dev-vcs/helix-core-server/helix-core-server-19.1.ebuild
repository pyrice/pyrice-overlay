# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils

DESCRIPTION="Perforce version control system Helix Command-line Client (P4)"
HOMEPAGE="http://www.perforce.com/"
SRC_URI="amd64? (
    http://www.perforce.com/downloads/perforce/r${PV}/bin.linux26x86_64/helix-core-server.tgz \
		    -> ${PF}-amd64 )"

LICENSE="perforce"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE=""
RESTRICT="mirror strip"

DEPEND=""
RDEPEND="${DEPEND}"

S=${WORKDIR}

src_unpack() {
	# we have to copy all of the files from $DISTDIR, otherwise we get
	# sandbox violations when trying to install

	cp ${DISTDIR}/${A} "p4"
}

src_install() {
	dodir /usr/bin/helix-core-server-client-${PV}
	cp -R "${S}/" "${D}/usr/bin/" || die "Install failed!"
}
