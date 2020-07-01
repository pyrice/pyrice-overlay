# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
 
EAPI=7
 
inherit toolchain-funcs git-r3

DESCRIPTION="OpenHantek DSO software"
HOMEPAGE="https://github.com/OpenHantek/openhantek"
EGIT_REPO_URI="git@github.com:OpenHantek/openhantek.git"
 
LICENSE="GPL-3.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
 
DEPEND=">=dev-util/cmake-3.5
        >=sci-libs/fftw:3
        =dev-libs/libusb:1
        >=dev-qt/qtcore:5.4
        sys-devel/binutils
        "
RDEPEND="${DEPEND}"
BDEPEND=""

src_unpack() {
   git-r3_fetch ${EGIT_REPO_URI} ${REFS} ${TAG}
   git-r3_checkout ${EGIT_REPO_URI} ${WORKDIR}/${P} ${TAG}
}

src_prepare() {
   eautoreconf
   default
}

src_install() {
    dobin "${PN}"
    doman "${PN}.1"
    dodoc ANNOUNCE-* HISTORY README SCRIPTS

    local i
    for i in {1..4}; do
        docinto "script${i}"
        dodoc -r "script${i}"/.
    done
}
