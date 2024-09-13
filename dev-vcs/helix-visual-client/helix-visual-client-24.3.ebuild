# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop

DESCRIPTION="Perforce version control system Helix Visual Client (P4V)"
HOMEPAGE="http://www.perforce.com/"
SRC_URI="amd64? (
	http://www.perforce.com/downloads/perforce/r${PV}/bin.linux26x86_64/p4v.tgz \
		    -> ${PF}-amd64.tgz )"

LICENSE="perforce"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE=""
RESTRICT="mirror strip"

DEPEND=""
RDEPEND="x11-libs/libxcb x11-libs/xcb-util-cursor ${DEPEND}"
BDEPEND=""

INSTALL_TO="/opt/${PN}"
S=${WORKDIR}

src_unpack() {
	# we have to copy all of the files from $DISTDIR, otherwise we get
	# sandbox violations when trying to install
	if [ ${A} != "" ]; then
		unpack ${A}
	fi
}

src_install() {
	into /opt/${PN}
	dobin p4v-*/bin/*
	insinto /opt/${PN}
	doins -r p4v-*/lib
	dosym bin/p4v /usr/bin/p4v
	local targets=(
		"p4admin"
		"p4merge"
		"p4v"
		"p4vc"
	)
	for t in "${targets[@]}"; do
		dosym "../../${INSTALL_TO#/}/bin/${t}" "/usr/bin/${t}"
	done
	doicon p4v-*/lib/P4VResources/icons/p4v.svg
	make_desktop_entry p4v p4v /usr/share/pixmaps/p4v.svg
}

pkg_postinst() {
	ewarn "Perforce only provides the latest patch revisions. The SRC_URI may contain"
	ewarn "a tarball that no longer matches the hashes in the Manifest when installing"
	ewarn "another time!"
}
