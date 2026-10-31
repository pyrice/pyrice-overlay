# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake xdg

# Upstream tags the "new engine" alpha releases as A<N> (e.g. A75); the
# internal version string is "NE alpha 75". Map that to a sortable Gentoo
# version of <N>_alpha and reconstruct the tag for SRC_URI / S.
MY_PV="A${PV%_alpha}"

DESCRIPTION="UEFI firmware image viewer and editor (UEFITool NE) plus UEFIExtract/UEFIFind"
HOMEPAGE="https://github.com/LongSoft/UEFITool"
SRC_URI="https://github.com/LongSoft/UEFITool/archive/refs/tags/${MY_PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/UEFITool-${MY_PV}"

# Main sources and the Tiano/digest code are BSD-2; bstrlib is 3-clause BSD;
# QHexView, bundled brotli and the kaitai runtime are MIT; bundled zlib is
# ZLIB; the bundled LZMA SDK is public domain. All are compiled in statically.
LICENSE="BSD-2 BSD MIT ZLIB public-domain"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+gui"

# The GUI target requires Qt6 Widgets; the CLI tools have no external runtime
# deps (all third-party libraries are vendored under common/ and built in).
RDEPEND="gui? ( dev-qt/qtbase:6[gui,widgets] )"
DEPEND="${RDEPEND}"

# The patch applies unchanged to A76; sharing the 75_alpha file avoids a
# byte-identical duplicate in files/. Rename it when 75_alpha is pruned.
PATCHES=( "${FILESDIR}/${PN}-75_alpha-optional-gui.patch" )

src_configure() {
	local mycmakeargs=(
		-DBUILD_UEFITOOL_GUI=$(usex gui ON OFF)
	)
	cmake_src_configure
}
