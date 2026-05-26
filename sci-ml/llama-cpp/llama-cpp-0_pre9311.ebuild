# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION="6.1"
inherit cmake cuda rocm toolchain-funcs

MY_B="${PV#0_pre}"
MY_P="llama.cpp-b${MY_B}"

DESCRIPTION="LLM inference in C/C++ — CPU, Vulkan, SYCL/Level Zero, CUDA, ROCm"
HOMEPAGE="https://github.com/ggml-org/llama.cpp"

SRC_URI="https://github.com/ggml-org/llama.cpp/archive/refs/tags/b${MY_B}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/${MY_P}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

IUSE="blas blis cuda examples flexiblas mkl opencl openblas openmp rocm rpc server sycl vulkan"

REQUIRED_USE="
	blas? ( ^^ ( blis flexiblas mkl openblas ) )
	sycl? ( !cuda !rocm )
"

COMMON_DEPEND="
	blas? (
		blis? ( sci-libs/blis:= )
		flexiblas? ( sci-libs/flexiblas[blis?,mkl?,openblas?] )
		mkl? ( sci-libs/mkl[llvm-openmp] )
		openblas? ( sci-libs/openblas )
	)
	cuda? ( dev-util/nvidia-cuda-toolkit:= )
	opencl? ( virtual/opencl )
	rocm? (
		>=dev-util/hip-${ROCM_VERSION}:=
		>=sci-libs/hipBLAS-${ROCM_VERSION}:=
		>=sci-libs/rocBLAS-${ROCM_VERSION}:=
	)
	sycl? (
		dev-libs/level-zero:=
		sci-libs/mkl
	)
	vulkan? ( media-libs/vulkan-loader )
"

DEPEND="
	${COMMON_DEPEND}
	server? ( dev-libs/openssl:= )
"

BDEPEND="
	vulkan? (
		dev-util/vulkan-headers
		media-libs/shaderc
	)
"

RDEPEND="
	${COMMON_DEPEND}
	server? ( dev-libs/openssl:= )
	sycl? ( dev-libs/intel-compute-runtime[l0] )
"

RESTRICT="mirror test"

src_prepare() {
	cmake_src_prepare

	# cuda_src_prepare from the cuda eclass must only run when CUDA is actually
	# enabled; the eclass exports src_prepare unconditionally otherwise.
	if use cuda; then
		cuda_src_prepare
	fi
}

pkg_pretend() {
	if use sycl; then
		local oneapi_root="${ONEAPI_ROOT:-/opt/intel/oneapi}"
		local icpx_candidate
		if type -P icpx &>/dev/null; then
			icpx_candidate=$(type -P icpx)
		else
			icpx_candidate="${oneapi_root}/compiler/latest/bin/icpx"
		fi
		if [[ ! -x ${icpx_candidate} ]]; then
			eerror "USE=sycl requires Intel's DPC++/C++ compiler (icpx)."
			eerror "Download and install the Intel oneAPI DPC++/C++ Compiler Standalone from:"
			eerror "  https://www.intel.com/content/www/us/en/developer/articles/tool/oneapi-standalone-components.html"
			eerror "After installation source the environment before emerging:"
			eerror "  source /opt/intel/oneapi/setvars.sh"
			eerror "  emerge =sci-ml/llama-cpp-${PV}"
			die "icpx not found — Intel oneAPI DPC++ compiler required for USE=sycl"
		fi
	fi
}

src_configure() {
	local mycmakeargs=(
		-DGGML_NATIVE=no
		-DGGML_CCACHE=no
		-DBUILD_SHARED_LIBS=yes

		-DLLAMA_BUILD_TESTS=no
		-DLLAMA_BUILD_TOOLS=yes
		-DLLAMA_BUILD_COMMON=yes
		-DLLAMA_BUILD_EXAMPLES="$(usex examples)"
		-DLLAMA_BUILD_APP=no
		-DLLAMA_BUILD_SERVER=yes
		-DLLAMA_OPENSSL="$(usex server)"

		-DGGML_BLAS="$(usex blas)"
		-DGGML_CUDA=no
		-DGGML_HIP=no
		-DGGML_OPENCL="$(usex opencl)"
		-DGGML_OPENMP="$(usex openmp)"
		-DGGML_RPC="$(usex rpc)"
		-DGGML_SYCL=no
		-DGGML_VULKAN="$(usex vulkan)"
	)

	if use blas; then
		if use flexiblas; then
			mycmakeargs+=( -DGGML_BLAS_VENDOR="FlexiBLAS" )
		elif use blis; then
			mycmakeargs+=( -DGGML_BLAS_VENDOR="FLAME" )
		elif use mkl; then
			mycmakeargs+=( -DGGML_BLAS_VENDOR="Intel10_64lp" )
		elif use openblas; then
			mycmakeargs+=( -DGGML_BLAS_VENDOR="OpenBLAS" )
		fi
	fi

	if use cuda; then
		local -x CUDAHOSTCXX CUDAHOSTLD
		CUDAHOSTCXX="$(cuda_gccdir)"
		CUDAHOSTLD="$(tc-getCXX)"
		[[ ! -v CUDAARCHS ]] && local CUDAARCHS="all-major"
		mycmakeargs+=(
			-DGGML_CUDA=yes
			-DCMAKE_CUDA_ARCHITECTURES="${CUDAARCHS}"
		)
		cuda_add_sandbox -w
		addpredict "/dev/char/"
	fi

	if use rocm; then
		mycmakeargs+=(
			-DGGML_HIP=yes
			-DCMAKE_HIP_ARCHITECTURES="$(get_amdgpu_flags)"
			-DAMDGPU_TARGETS="$(get_amdgpu_flags)"
		)
		local -x HIP_PATH="${ESYSROOT}/usr"
	fi

	if use sycl; then
		# Locate the Intel oneAPI installation root and icpx binary.
		# The user must have sourced /opt/intel/oneapi/setvars.sh before emerging,
		# or have icpx in PATH. ONEAPI_ROOT tells the SYCL CMakeLists which
		# compiler path is in use ("oneAPI Release" vs open-source LLVM).
		local oneapi_root="${ONEAPI_ROOT:-/opt/intel/oneapi}"
		local icpx_bin
		if type -P icpx &>/dev/null; then
			icpx_bin=$(type -P icpx)
			# Derive oneapi_root from the binary: <root>/compiler/<ver>/bin/icpx
			local resolved
			resolved=$(readlink -f "${icpx_bin}" 2>/dev/null || echo "${icpx_bin}")
			oneapi_root=$(dirname "$(dirname "$(dirname "$(dirname "${resolved}")")")")
		else
			icpx_bin="${oneapi_root}/compiler/latest/bin/icpx"
		fi

		export ONEAPI_ROOT="${oneapi_root}"

		mycmakeargs+=(
			-DGGML_SYCL=yes
			-DGGML_SYCL_F16=yes
			# cmake prefix for IntelSYCL and MKL CMake config files
			-DCMAKE_PREFIX_PATH="${oneapi_root}/compiler/latest;${oneapi_root}/mkl/latest;${ESYSROOT}/usr"
			-DCMAKE_CXX_COMPILER="${icpx_bin}"
		)
	fi

	cmake_src_configure
}

src_install() {
	cmake_src_install
	use server || rm -f "${ED}/usr/bin/llama-server" || die
	dodoc README.md
}

pkg_postinst() {
	if use sycl; then
		einfo "Intel Arc GPU inference via SYCL/Level Zero."
		einfo "Ensure the user running llama-server is in the 'render' group:"
		einfo "  usermod -aG render <username>"
		einfo ""
		einfo "Verify the A770 is detected:"
		einfo "  llama-cli --list-devices"
	fi

	if use vulkan; then
		einfo "Vulkan GPU inference enabled."
		einfo "Intel Arc requires media-libs/mesa with vulkan and VIDEO_CARDS=intel."
	fi

	einfo ""
	einfo "Run inference:"
	einfo "  llama-cli -m /path/to/model.gguf -p 'Hello' -n 128 -ngl 999"
	if use server; then
		einfo ""
		einfo "Start OpenAI-compatible server:"
		einfo "  llama-server -m /path/to/model.gguf --port 8080 -ngl 999"
	fi
}
