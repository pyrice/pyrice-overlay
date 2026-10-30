# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="LLM inference in C/C++ with system GGML backends"
HOMEPAGE="https://github.com/ggml-org/llama.cpp"
SRC_URI="https://github.com/ggml-org/llama.cpp/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/llama.cpp-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="cuda examples openmp rocm server vulkan"
RESTRICT="test"

# Match the release's GGML API. Backends belong to the system GGML package,
# not this build. Advertise only backends supported by the compatible provider.
RDEPEND="
	>=sci-ml/ggml-0.27.0:=[cuda?,openmp?,rocm?,vulkan?]
	server? ( dev-libs/openssl:= )
"
DEPEND="${RDEPEND}"

src_configure() {
	local mycmakeargs=(
		-DLLAMA_USE_SYSTEM_GGML=ON
		-DLLAMA_BUILD_IS_DEV=OFF
		-DBUILD_SHARED_LIBS=ON
		-DLLAMA_BUILD_TESTS=OFF
		-DLLAMA_BUILD_TOOLS=ON
		-DLLAMA_BUILD_COMMON=ON
		-DLLAMA_BUILD_EXAMPLES="$(usex examples)"
		-DLLAMA_BUILD_APP=OFF
		# Upstream's CLI also lives behind LLAMA_BUILD_SERVER.
		-DLLAMA_BUILD_SERVER=ON
		-DLLAMA_OPENSSL="$(usex server)"
		# Never download or build untracked UI assets during the package build.
		-DLLAMA_BUILD_UI=OFF
		-DLLAMA_USE_PREBUILT_UI=OFF
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install
	use server || rm -f "${ED}/usr/bin/llama-server" || die
	dodoc README.md
}
