# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

inherit cmake python-single-r1

MY_PN="openvino.genai"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Generative AI pipelines for OpenVINO"
HOMEPAGE="https://github.com/openvinotoolkit/openvino.genai"
SRC_URI="
	https://github.com/openvinotoolkit/openvino.genai/archive/refs/tags/${PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/google/minja/archive/3e4c61c616eda133cfb1e440fc7a14bf1729bbee.tar.gz
		-> ${P}-minja-3e4c61c.tar.gz
	https://github.com/hsnyder/safetensors.h/archive/974a85d7dfd6e010558353226638bb26d6b9d756.tar.gz
		-> ${P}-safetensors-h-974a85d.tar.gz
	https://github.com/Lourdle/gguf-tools/archive/bac796ada809ac293e685db59b075971181cb008.tar.gz
		-> ${P}-gguf-tools-bac796a.tar.gz
"
S="${WORKDIR}/${MY_P}"

LICENSE="Apache-2.0 MIT Unlicense"
SLOT="0/2026.2.1"
KEYWORDS="~amd64"
IUSE="+python"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

RDEPEND="
	~sci-ml/openvino-2026.2.1:0/2026.2.1[intel-gpu]
	~sci-ml/openvino-tokenizers-2026.2.1.0:0/2026.2.1
	python? (
		${PYTHON_DEPS}
		~sci-ml/openvino-2026.2.1:0/2026.2.1[python,${PYTHON_SINGLE_USEDEP}]
		~sci-ml/openvino-tokenizers-2026.2.1.0:0/2026.2.1[${PYTHON_SINGLE_USEDEP}]
	)
"
DEPEND="${RDEPEND}
	dev-cpp/nlohmann_json
"
BDEPEND="
	python? ( $(python_gen_cond_dep 'dev-python/pybind11[${PYTHON_USEDEP}]') )
"

PATCHES=(
	"${FILESDIR}/${P}-gentoo-layout.patch"
	"${FILESDIR}/${P}-pybind11-3-keep-alive.patch"
	"${FILESDIR}/${P}-gguf-format-template-linkage.patch"
)
DOCS=(
	README.md
	SECURITY.md
	third-party-programs.txt
	"${FILESDIR}/LICENSES.audit"
	"${FILESDIR}/SOURCES.lock"
)

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	cmake_src_prepare

	# Prefer Gentoo's nlohmann-json and pybind11 over FetchContent copies.
	sed -i \
		-e '/# Dependencies/a find_package(nlohmann_json 3.11 CONFIG REQUIRED)' \
		-e 's/if(NOT TARGET nlohmann_json)/if(NOT TARGET nlohmann_json::nlohmann_json)/' \
		src/cpp/CMakeLists.txt || die
	sed -i \
		-e '/include(FetchContent)/a find_package(pybind11 3.0.1 CONFIG REQUIRED)' \
		src/python/CMakeLists.txt || die
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_DISABLE_FIND_PACKAGE_Git=ON
		-DFETCHCONTENT_FULLY_DISCONNECTED=ON
		-DFETCHCONTENT_SOURCE_DIR_MINJA="${WORKDIR}/minja-3e4c61c616eda133cfb1e440fc7a14bf1729bbee"
		-DFETCHCONTENT_SOURCE_DIR_SAFETENSORS.H="${WORKDIR}/safetensors.h-974a85d7dfd6e010558353226638bb26d6b9d756"
		-DFETCHCONTENT_SOURCE_DIR_GGUFLIB="${WORKDIR}/gguf-tools-bac796ada809ac293e685db59b075971181cb008"
		-DBUILD_TOKENIZERS=OFF
		# gguf_tokenizer.cpp (and continuous_batching) unconditionally include
		# gguf.hpp -> gguflib.h, so ENABLE_GGUF=OFF fails to compile: the flag
		# only drops four of the five gguf sources. Build GGUF support instead.
		-DENABLE_GGUF=ON
		-DENABLE_XGRAMMAR=OFF
		-DENABLE_JS=OFF
		-DENABLE_LTO=OFF
		-DENABLE_PYTHON=$(usex python)
		-DENABLE_SAMPLES=OFF
		-DENABLE_TESTS=OFF
		-DENABLE_TOOLS=OFF
		-DENABLE_SYSTEM_OPENCL=OFF
		-DPYBIND11_FINDPYTHON=ON
	)
	if use python; then
		mycmakeargs+=(
			-DOPENVINO_GENAI_PYTHON_INSTALL_DIR=$(python_get_sitedir)
			-DPython3_EXECUTABLE="${PYTHON}"
		)
	fi

	cmake_src_configure
}

src_install() {
	cmake_src_install
	use python && python_optimize
}
