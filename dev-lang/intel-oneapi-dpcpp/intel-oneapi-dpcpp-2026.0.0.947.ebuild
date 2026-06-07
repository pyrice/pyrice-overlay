# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker

PN_VER=$(ver_cut 1-2)
MY_PV=$(ver_cut 1-3)-$(ver_cut 4)

# UMF has its own versioning; 1.1.0-340 ships libumf.so.1 needed by libur_adapter_level_zero.so
UMF_VER="1.1"
UMF_PV="1.1.0-340"

DESCRIPTION="Intel oneAPI DPC++/C++ Compiler (icpx/icx) — SYCL compiler for Intel Arc GPUs"
HOMEPAGE="https://www.intel.com/content/www/us/en/developer/tools/oneapi/dpc-compiler.html"

# Seven DEBs:
#   dpcpp-cpp           — icpx, icx, dpcpp binaries + SYCL device-lib bitcode
#   compiler-shared     — offload bundler/extractor tools, CRT objects
#   runtime             — libsycl.so, libur_adapter_level_zero.so, libur_loader.so
#   common              — sycl/sycl.hpp and all SYCL C++ headers (arch-independent)
#   openmp              — llvm-link, llvm-foreach, llvm-objcopy, llvm-spirv (needed by
#                         clang-linker-wrapper during SYCL --offload-new-driver link)
#   compiler-shared-rt  — libintlc.so, libsvml.so, libimf.so, libirng.so, libirc.so
#                         (Intel C/math runtime libs; linked into every SYCL binary)
#   umf                 — libumf.so.1 (Unified Memory Framework); required by
#                         libur_adapter_level_zero.so at runtime
SRC_URI="
	https://apt.repos.intel.com/oneapi/pool/main/intel-oneapi-dpcpp-cpp-${PN_VER}-${MY_PV}_amd64.deb
	https://apt.repos.intel.com/oneapi/pool/main/intel-oneapi-compiler-shared-${PN_VER}-${MY_PV}_amd64.deb
	https://apt.repos.intel.com/oneapi/pool/main/intel-oneapi-compiler-dpcpp-cpp-runtime-${PN_VER}-${MY_PV}_amd64.deb
	https://apt.repos.intel.com/oneapi/pool/main/intel-oneapi-compiler-dpcpp-cpp-common-${PN_VER}-${MY_PV}_all.deb
	https://apt.repos.intel.com/oneapi/pool/main/intel-oneapi-openmp-${PN_VER}-${MY_PV}_amd64.deb
	https://apt.repos.intel.com/oneapi/pool/main/intel-oneapi-compiler-shared-runtime-${PN_VER}-${MY_PV}_amd64.deb
	https://apt.repos.intel.com/oneapi/pool/main/intel-oneapi-umf-${UMF_VER}-${UMF_PV}_amd64.deb
"
S="${WORKDIR}"

LICENSE="ISSL"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="strip"

RDEPEND="
	dev-libs/level-zero
	sys-apps/hwloc:=
"
BDEPEND="
	app-arch/xz-utils[extra-filters(+)]
"

QA_PREBUILT="*"
QA_TEXTRELS="*"
QA_SONAME="*"

src_install() {
	mv "${S}/"* "${ED}" || die

	dosym "${PN_VER}" /opt/intel/oneapi/compiler/latest
	dosym "${UMF_VER}" /opt/intel/oneapi/umf/latest

	newenvd - "70intel-oneapi-dpcpp" <<-_EOF_
		ONEAPI_ROOT="${EPREFIX}/opt/intel/oneapi"
		PATH="${EPREFIX}/opt/intel/oneapi/compiler/${PN_VER}/bin"
		ROOTPATH="${EPREFIX}/opt/intel/oneapi/compiler/${PN_VER}/bin"
		LDPATH="${EPREFIX}/opt/intel/oneapi/compiler/${PN_VER}/lib:${EPREFIX}/opt/intel/oneapi/umf/${UMF_VER}/lib"
	_EOF_
}

pkg_postinst() {
	einfo "Intel DPC++/C++ Compiler ${PN_VER} installed."
	einfo "  icpx: ${EPREFIX}/opt/intel/oneapi/compiler/${PN_VER}/bin/icpx"
	einfo ""
	einfo "Reload environment before use:"
	einfo "  source /etc/profile"
	einfo "  env-update && source /etc/profile"
	einfo ""
	einfo "To verify:"
	einfo "  icpx --version"
	einfo ""
	einfo "To build llama-cpp with SYCL (Intel Arc GPU):"
	einfo "  emerge sci-ml/llama-cpp[sycl]"
}
