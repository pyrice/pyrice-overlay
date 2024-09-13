# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit xdg

DESCRIPTION="JetBrains IDE manager"
HOMEPAGE="https://www.jetbrains.com/toolbox-app/"
SRC_URI="https://download.jetbrains.com/toolbox/jetbrains-toolbox-${PV}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip"

RDEPEND="app-arch/tar
	media-libs/fontconfig
	sys-fs/fuse:0
	x11-apps/mesa-progs
	x11-libs/gtk+
	x11-libs/libXi
	x11-libs/libXrender
	x11-libs/libXtst"

QA_PREBUILT="opt/${PN}/*"

src_compile() {
	./"${PN}" --appimage-extract
}

src_install() {
	keepdir /opt/jetbrains-toolbox
	insinto /opt/jetbrains-toolbox
	doins jetbrains-toolbox

	fperms +x /opt/jetbrains-toolbox/jetbrains-toolbox
}
