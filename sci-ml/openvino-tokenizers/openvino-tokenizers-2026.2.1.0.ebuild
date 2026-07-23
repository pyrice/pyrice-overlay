# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

inherit cmake flag-o-matic python-single-r1

MY_PN="openvino_tokenizers"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Tokenizer extension and conversion tools for OpenVINO"
HOMEPAGE="https://github.com/openvinotoolkit/openvino_tokenizers"
SRC_URI="
	https://github.com/openvinotoolkit/openvino_tokenizers/archive/refs/tags/${PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/google/sentencepiece/releases/download/v0.2.1/sentencepiece-0.2.1.tar.gz
		-> ${P}-sentencepiece-0.2.1.tar.gz
	https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.46/pcre2-10.46.zip
		-> ${P}-pcre2-10.46.zip
"
S="${WORKDIR}/${MY_P}"

LICENSE="Apache-2.0 BSD"
SLOT="0/2026.2.1"
KEYWORDS="~amd64"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '<dev-python/numpy-2.5[${PYTHON_USEDEP}]')
	~sci-ml/openvino-2026.2.1:0/2026.2.1[python,${PYTHON_SINGLE_USEDEP}]
"
DEPEND="${RDEPEND}"
BDEPEND="app-arch/unzip"

PATCHES=(
	"${FILESDIR}/${P}-optional-frontend-extensions.patch"
)

DOCS=(
	README.md
	SECURITY.md
	third-party-programs.txt
	"${FILESDIR}/LICENSES.audit"
	"${FILESDIR}/SOURCES.lock"
)

pkg_setup() {
	python-single-r1_pkg_setup
}

src_prepare() {
	cmake_src_prepare
	sed -i \
		-e 's|DESTINATION "docs/openvino_tokenizers"|DESTINATION "${CMAKE_INSTALL_DOCDIR}"|' \
		src/CMakeLists.txt || die
}

src_configure() {
	# Enable ONNX / TF frontend extension registration only when the matching
	# openvino frontend headers are present (they require USE=onnx / USE=tensorflow).
	[[ -f ${ESYSROOT}/usr/include/openvino/frontend/onnx/extension/conversion.hpp ]] \
		&& append-cxxflags -DOPENVINO_TOKENIZERS_ENABLE_ONNX_EXTENSIONS
	[[ -f ${ESYSROOT}/usr/include/openvino/frontend/tensorflow/extension/conversion.hpp ]] \
		&& append-cxxflags -DOPENVINO_TOKENIZERS_ENABLE_TF_EXTENSIONS

	local mycmakeargs=(
		-DCMAKE_DISABLE_FIND_PACKAGE_Git=ON
		-DFETCHCONTENT_FULLY_DISCONNECTED=ON
		-DFETCHCONTENT_SOURCE_DIR_SENTENCEPIECE="${WORKDIR}/sentencepiece-0.2.1"
		-DFETCHCONTENT_SOURCE_DIR_PCRE2="${WORKDIR}/pcre2-10.46"
		-DBUILD_CPP_EXTENSION=ON
		-DENABLE_LTO=OFF
		-DREGENERATE_PRECOMPILED_CHARSMAP=OFF
		-DOPENVINO_TOKENIZERS_INSTALL_LIBDIR=$(get_libdir)
		-DOPENVINO_TOKENIZERS_INSTALL_BINDIR=$(get_libdir)
		-DPython3_EXECUTABLE="${PYTHON}"
	)

	cmake_src_configure
}

src_install() {
	cmake_src_install
	python_domodule python/openvino_tokenizers
	python_optimize
}
