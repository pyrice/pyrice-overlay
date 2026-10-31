# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..15} )

inherit cmake fortran-2 python-any-r1

MY_P="${P}-Source"

DESCRIPTION="A set of encoding/decoding APIs and tools for WMO GRIB, BUFR, and GTS messages"
HOMEPAGE="https://confluence.ecmwf.int/display/ECC"
SRC_URI="https://confluence.ecmwf.int/download/attachments/45757960/${MY_P}.tar.gz"
S="${WORKDIR}/${MY_P}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

IUSE="aec +defs examples fortran jpeg2k memfs netcdf openmp png test threads"

REQUIRED_USE="
	openmp? ( !threads )
	test? ( defs !memfs )"

# The source tarball carries its own copy of the ecbuild macros (cmake/), so no
# separate ecbuild package is needed. Data-driven "extra" tests download their
# input from ECMWF at build time and are not run.
RESTRICT="!test? ( test )"

RDEPEND="
	aec? ( >=sci-libs/libaec-1.1.4 )
	jpeg2k? ( >=media-libs/openjpeg-2:2 )
	netcdf? ( >=sci-libs/netcdf-4.2[hdf5] )
	png? ( media-libs/libpng:= )"
DEPEND="${RDEPEND}"
BDEPEND="
	${PYTHON_DEPS}
	virtual/pkgconfig"

pkg_setup() {
	use fortran && fortran-2_pkg_setup
	python-any-r1_pkg_setup
}

src_configure() {
	local mycmakeargs=(
		-DINSTALL_LIB_DIR="$(get_libdir)"
		-DCMAKE_SKIP_INSTALL_RPATH=TRUE
		-DBUILD_SHARED_LIBS=ON
		-DENABLE_AEC=$(usex aec)
		-DENABLE_BUILD_TOOLS=ON
		-DENABLE_ECCODES_OMP_THREADS=$(usex openmp)
		-DENABLE_ECCODES_THREADS=$(usex threads)
		-DENABLE_EXAMPLES=OFF  # built from source tree only if wanted at install time
		-DENABLE_EXTRA_TESTS=OFF
		-DENABLE_FORTRAN=$(usex fortran)
		-DENABLE_INSTALL_ECCODES_DEFINITIONS=$(usex defs)
		-DENABLE_INSTALL_ECCODES_SAMPLES=$(usex defs)
		-DENABLE_JPG=$(usex jpeg2k)
		-DENABLE_JPG_LIBJASPER=OFF
		-DENABLE_JPG_LIBOPENJPEG=$(usex jpeg2k)
		-DENABLE_MEMFS=$(usex memfs)
		-DENABLE_NETCDF=$(usex netcdf)
		-DENABLE_PNG=$(usex png)
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install

	if use examples; then
		insinto "/usr/share/${PN}/examples"
		doins -r examples/C
		use fortran && doins -r examples/F90
	fi
}
