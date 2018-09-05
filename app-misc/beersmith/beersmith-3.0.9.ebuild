# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
EAPI=6
inherit
S=${WORKDIR}
BEERSMITH_HOME="/opt/beersmith3"
DESCRIPTION="Beersmith 3 Home Brewing Software"
HOMEPAGE="http://www.beersmith.com"
SRC_URI="https://s3.amazonaws.com/beersmith-3/BeerSmith-3.0.9_amd64.deb"
LICENSE="GPL-2"
SLOT="3"
KEYWORDS="~amd64 ~x86"
IUSE=""
DEPEND="x11-libs/cairo
      media-libs/fontconfig
      dev-libs/glib
      x11-libs/gdk-pixbuf:2
      sys-libs/glibc
      x11-libs/gtk+:3
      media-libs/libpng
      x11-libs/libSM
      x11-libs/libX11
      x11-libs/libXxf86vm
      dev-libs/openssl
      x11-libs/pango
      net-libs/webkit-gtk
      sys-libs/zlib"
RDEPEND="${DEPEND}"
src_install() 
{
        dodir $BEERSMITH_HOME
        insinto "${BEERSMITH_HOME}"/
        doins -r * || die "doins failed"
}
