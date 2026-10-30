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

# Since the 3.x series the tarball is no longer a single self-extracting
# AppImage: it ships a bin/ tree (launcher, bundled JRE, jars, JNI libraries).
# Install it as-is; Toolbox creates its own .desktop entry on first launch.
src_install() {
	# Prebuilt tree with many executables (launcher, helpers, bundled JRE):
	# copy it preserving modes instead of re-deriving them file by file.
	dodir /opt/${PN}
	cp -a bin/. "${ED}/opt/${PN}/" || die
	# AppleDouble ._* metadata files are tar artefacts, not payload.
	find "${ED}/opt/${PN}" -name '._*' -delete || die
}
