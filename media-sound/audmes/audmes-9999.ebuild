# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit toolchain-funcs git-r3

DESCRIPTION="AUDio MEasurement System"
HOMEPAGE="https://sourceforge.net/projects/audmes/"

LICENSE="GPL-2"
SLOT="0"

# JRG: Special version numbers to access specific branches.
case "${PV}" in
    # Head of master branch. This is a Gentoo convention.
    9999)
        EGIT_REPO_URI="https://github.com/swwa/audmes.git"
        PATCHES=( "${FILESDIR}"/${PN}-9999-fix-build-system.patch )
        ;;
esac

src_unpack() {
    case "${PV}" in
        9999)
            git-r3_fetch ${EGIT_REPO_URI} ${REFS} ${TAG}
            git-r3_checkout ${EGIT_REPO_URI} "${WORKDIR}/${P}" ${TAG}
            ;;
        *)
            default
            ;;
    esac
}

src_configure() {
    tc-export CC
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
_________________
