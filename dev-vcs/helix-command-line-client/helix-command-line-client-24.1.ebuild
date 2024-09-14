# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Perforce version control system Helix command line Client (P4)"
HOMEPAGE="https://www.perforce.com/"
SRC_URI="amd64? (
	https://www.perforce.com/downloads/perforce/r${PV}/bin.linux26x86_64/helix-core-server.tgz \
		    -> ${PF}-amd64.tgz )"
S=${WORKDIR}

LICENSE="perforce"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE=""
RESTRICT="mirror strip"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

INSTALL_TO="/opt/${PN}"

src_unpack() {
	# we have to copy all of the files from $DISTDIR, otherwise we get
	# sandbox violations when trying to install
	if [ ${A} != "" ]; then
		unpack ${A}
	fi
}

src_install() {
	into /opt/${PN}
	dobin p4
	insinto /opt/${PN}
	doins -r p4
	dosym bin/p4 /usr/bin/p4
	local targets=(
		"p4"
	)
	for t in "${targets[@]}"; do
		dosym "../../${INSTALL_TO#/}/bin/${t}" "/usr/bin/${t}"
	done
}

pkg_postinst() {
	ewarn "Perforce only provides the latest patch revisions. The SRC_URI may contain"
	ewarn "a tarball that no longer matches the hashes in the Manifest when installing"
	ewarn "another time!"
}
