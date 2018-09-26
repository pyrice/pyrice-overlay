# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$
EAPI=7

inherit versionator eutils

REL=$(get_version_component_range 1-2)
SHORTREL=${REL/#20/}

DESCRIPTION="Perforce version control system Helix Visual Client (P4V)"
HOMEPAGE="http://www.perforce.com/"
SRC_URI="amd64? (
		http://www.perforce.com/downloads/perforce/r${SHORTREL}/bin.linux26x86_64/p4v.tgz \
		    -> ${PF}-amd64 )"

LICENSE="perforce"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE=""
RESTRICT="mirror strip"

S=${WORKDIR}

src_unpack() {
	# we have to copy all of the files from $DISTDIR, otherwise we get
	# sandbox violations when trying to install

	cp ${DISTDIR}/${A} p4
}

src_install() {
	dobin p4 || die
}