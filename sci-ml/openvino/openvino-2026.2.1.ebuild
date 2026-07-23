# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

inherit cmake python-single-r1 unpacker

DESCRIPTION="Toolkit for high-performance deep learning inference"
HOMEPAGE="https://github.com/openvinotoolkit/openvino"
SRC_URI="https://localhost/distfiles/${P}-full.tar.zst"

LICENSE="Apache-2.0 BSD MIT ZLIB"
SLOT="0/${PV}"
KEYWORDS="~amd64"
IUSE="intel-gpu +python jax onnx paddle pytorch samples tensorflow test tflite"

REQUIRED_USE="
	intel-gpu? ( elibc_glibc )
	python? ( ${PYTHON_REQUIRED_USE} )
"
RESTRICT="mirror !test? ( test )"

RDEPEND="
	dev-cpp/tbb:=
	dev-libs/pugixml:=
	intel-gpu? (
		elibc_glibc? ( >=dev-libs/intel-compute-runtime-26.14.37833.4 )
	)
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '<dev-python/numpy-2.5[${PYTHON_USEDEP}]')
	)
	onnx? ( dev-libs/protobuf:= )
	paddle? ( dev-libs/protobuf:= )
	tensorflow? ( dev-libs/protobuf:= )
	tflite? ( dev-libs/flatbuffers:= )
"
DEPEND="
	dev-cpp/tbb:=
	dev-libs/pugixml:=
	intel-gpu? (
		dev-cpp/clhpp
		dev-util/opencl-headers
		virtual/opencl
	)
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '<dev-python/numpy-2.5[${PYTHON_USEDEP}]')
	)
	onnx? ( dev-libs/protobuf:= )
	paddle? ( dev-libs/protobuf:= )
	tensorflow? ( dev-libs/protobuf:= )
	tflite? ( dev-libs/flatbuffers:= )
"
BDEPEND="
	virtual/pkgconfig
	python? ( $(python_gen_cond_dep 'dev-python/pybind11[${PYTHON_USEDEP}]') )
"

PATCHES=(
	"${FILESDIR}/${P}-respect-werror-option.patch"
	"${FILESDIR}/${P}-onednn-gpu-libdir.patch"
)

DOCS=(
	README.md
	SECURITY.md
	licensing/third-party-programs.txt
	licensing/runtime-third-party-programs.txt
	licensing/onednn_third-party-programs.txt
	licensing/onetbb_third-party-programs.txt
	"${FILESDIR}/SOURCES.lock"
	"${FILESDIR}/LICENSES.audit"
)

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_DISABLE_FIND_PACKAGE_Git=ON
		-DCMAKE_COMPILE_WARNING_AS_ERROR=OFF
		# Use conda-forge layout: OV_CPACK_*DIR maps to standard FHS paths
		# (lib64/, include/, lib/python*/site-packages/) instead of the
		# archive default of runtime/lib/intel64/ and python/.
		-DCPACK_GENERATOR=CONDA-FORGE
		-DFETCHCONTENT_FULLY_DISCONNECTED=ON
		-DTHREADING=TBB
		-DENABLE_SYSTEM_TBB=ON
		-DENABLE_TBBBIND_2_5=OFF
		-DENABLE_SYSTEM_PUGIXML=ON
		-DENABLE_SYSTEM_OPENCL=$(usex intel-gpu)
		-DGPU_RT_TYPE=OCL
		-DENABLE_INTEL_CPU=ON
		-DENABLE_INTEL_GPU=$(usex intel-gpu)
		-DENABLE_ONEDNN_FOR_GPU=$(usex intel-gpu)
		-DENABLE_INTEL_NPU=OFF
		-DENABLE_INTEL_NPU_INTERNAL=OFF
		-DENABLE_PYTHON=$(usex python)
		-DENABLE_JS=OFF
		-DENABLE_SAMPLES=$(usex samples)
		-DENABLE_TESTS=$(usex test)
		-DENABLE_TEMPLATE=OFF
		-DENABLE_NCC_STYLE=OFF
		-DENABLE_PROFILING_ITT=OFF
		-DENABLE_OV_IR_FRONTEND=ON
		-DENABLE_OV_ONNX_FRONTEND=$(usex onnx)
		-DENABLE_OV_PADDLE_FRONTEND=$(usex paddle)
		-DENABLE_OV_PYTORCH_FRONTEND=$(usex pytorch)
		-DENABLE_OV_JAX_FRONTEND=$(usex jax)
		-DENABLE_OV_TF_FRONTEND=$(usex tensorflow)
		-DENABLE_OV_TF_LITE_FRONTEND=$(usex tflite)
		-DENABLE_SYSTEM_PROTOBUF=$(usex onnx ON $(usex paddle ON $(usex tensorflow)))
		-DENABLE_SYSTEM_FLATBUFFERS=$(usex tflite)
		-DENABLE_SNAPPY_COMPRESSION=OFF
		-DENABLE_WHEEL=OFF
		-DPython3_EXECUTABLE=$(usex python "${PYTHON}" "")
	)

	cmake_src_configure
}

src_install() {
	cmake_src_install

	if use python; then
		# EPYTHON is e.g. "python3.14"; strip prefix to get "3.14" for
		# the cmake component name pyopenvino_python3.14.
		# python_get_version does not exist in portage's eclass.
		local component="pyopenvino_python${EPYTHON#python}"
		DESTDIR="${D}" cmake --install "${BUILD_DIR}" \
			--prefix "${EPREFIX}/usr" \
			--component "${component}" || die
		python_optimize
	fi
}
