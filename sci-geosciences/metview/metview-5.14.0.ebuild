# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
 
EAPI=8

inherit cmake

MY_P="${P}-Source"
 
DESCRIPTION="ECMWF Metview software"
HOMEPAGE="https://confluence.ecmwf.int/display/METV/Metview"
SRC_URI="https://confluence.ecmwf.int/download/attachments/3964985/${PN}-${PV}-Source.tar.gz"
 
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="-magics -mars logs"
 
DEPEND="dev-qt/qtcore:5 app-shells/bash sci-libs/netcdf net-misc/curl
sys-libs/gdbm sci-libs/eccodes"
RDEPEND="magics? ( sci-geosciences/magics ) ${DEPEND}"
BDEPEND="sys-devel/gcc
    sys-devel/make
    dev-util/cmake
    sys-devel/flex
    sys-devel/bison"

RESTRICT=""

S="${WORKDIR}/${MY_P}"

BUILD_DIR="${WORKDIR}/build"

CMAKE_BUILD_TYPE=RelWithDebInfo

src_configure() {
    local mycmakeargs=(
        -DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr"
        -DENABLE_UI=ON
        -DENABLE_PLOTTING=$(usex magics ON OFF)
        -DENABLE_MARS=$(usex mars ON OFF)
        -DENABLE_USAGE_LOGS=$(usex logs ON OFF)
        -DLOG_DIR="~/.log/metview"
        -DECCODES_PATH="/usr/share/eccodes"
        -DMAGICS_PATH="/usr/local/"
    )
    cmake_src_configure
}

src_install() {
    cmake_src_install
}

src_test() {
	cmake_src_test
}
