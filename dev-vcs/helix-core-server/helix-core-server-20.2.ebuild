# Copyright 1999-2021 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils

DESCRIPTION="Perforce version control system Helix Command-line Client (P4)"
HOMEPAGE="http://www.perforce.com/"
SRC_URI="http://www.perforce.com/downloads/perforce/r${PV}/bin.linux26x86_64/helix-core-server.tgz"

LICENSE="perforce"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE=""
RESTRICT="mirror strip"

DEPEND=""
RDEPEND="${DEPEND}"

S=${WORKDIR}

src_install() {
	dobin p4d || die "Install failed!"
}
