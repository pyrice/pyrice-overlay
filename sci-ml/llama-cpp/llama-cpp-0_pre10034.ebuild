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
		sci-libs/mkl[sycl(-)]
	)
	vulkan? ( media-libs/vulkan-loader )
"

DEPEND="
	${COMMON_DEPEND}
	server? ( dev-libs/openssl:= )
"

BDEPEND="
	sycl? ( dev-lang/intel-oneapi-dpcpp )
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
		# dev-lang/intel-oneapi-dpcpp installs to a fixed prefix; use it directly.
		local oneapi_root="${EPREFIX}/opt/intel/oneapi"
		local icpx_bin="${oneapi_root}/compiler/latest/bin/icpx"
		export ONEAPI_ROOT="${oneapi_root}"

		# icpx ships no C/C++ headers. On Gentoo, stddef.h and friends live
		# only in GCC's internal include dir — not in /usr/include (unlike
		# Ubuntu/Debian where glibc provides them). We cannot add the full
		# GCC include dir via -isystem because it also contains hundreds of
		# *intrin.h files that use __builtin_ia32_* in ways incompatible with
		# icpx/clang. Symlink only the safe C-standard headers into a minimal
		# directory. Adding -isystem to CXXFLAGS would break g++ which is used
		# for cmake's initial compiler test; use a wrapper instead.
		local gcc_install_dir icpx_include icpx_wrapper
		gcc_install_dir=$(dirname "$($(tc-getCXX) -print-libgcc-file-name)")
		icpx_include="${T}/icpx-include"
		mkdir -p "${icpx_include}" || die
		for hdr in "${gcc_install_dir}"/include/std*.h \
		            "${gcc_install_dir}"/include/float.h \
		            "${gcc_install_dir}"/include/iso646.h; do
			[[ -f "${hdr}" ]] || continue
			ln -sf "${hdr}" "${icpx_include}/${hdr##*/}" || die
		done

		# DPC++ 2026.0 ships no sycl-post-link or file-table-tform binaries; their
		# functionality is built into clang-linker-wrapper via
		# --no-use-sycl-post-link-tool.  spirv-to-ir-wrapper is still called as an
		# external process — it converts SPIR-V-flavoured LLVM IR to a form
		# suitable for linking; the input is already in that form, so a passthrough
		# script is sufficient.
		cat > "${T}/spirv-to-ir-wrapper" <<-'_STUB_' || die
			#!/bin/bash
			input="" output=""
			i=0; args=("$@")
			while [[ $i -lt ${#args[@]} ]]; do
				case "${args[$i]}" in
					-o) i=$((i+1)); output="${args[$i]}" ;;
					--*) ;;
					*) input="${args[$i]}" ;;
				esac
				i=$((i+1))
			done
			[[ -n ${input} && -n ${output} && -f ${input} ]] && cp "${input}" "${output}"
		_STUB_
		chmod +x "${T}/spirv-to-ir-wrapper" || die

		# icpx wrapper: compile steps (-c/-E/-S) pass through with the GCC
		# headers shim and --offload-new-driver enabled.  Link steps run the
		# clang-linker-wrapper pipeline via icpx -### so we can inject
		# --no-use-sycl-post-link-tool (no icpx-level flag exposes this).
		# ${T} is prepended to PATH so spirv-to-ir-wrapper is found at runtime.
		icpx_wrapper="${T}/icpx"
		cat > "${icpx_wrapper}" <<-_WRAP_ || die "failed to write icpx wrapper"
			#!/bin/bash
			for arg; do
				case "\${arg}" in
					-c|-E|-S) exec "${icpx_bin}" -isystem "${icpx_include}" --offload-new-driver "\$@" ;;
				esac
			done
			export PATH="${T}:\${PATH}"
			tmplog=\$(mktemp) || exit 1
			"${icpx_bin}" -### --offload-new-driver "\$@" 2>"\${tmplog}" || {
				cat "\${tmplog}" >&2; rm -f "\${tmplog}"; exit 1
			}
			rc=0
			while read -r cmd; do
				[[ "\${cmd:0:1}" == '"' ]] || continue
				if [[ "\${cmd}" == *"clang-linker-wrapper"* ]]; then
					cmd="\${cmd/\" \"--/\" \"--no-use-sycl-post-link-tool\" \"--}"
				fi
				eval "\${cmd}" || { rc=\$?; break; }
			done < "\${tmplog}"
			rm -f "\${tmplog}"
			exit \${rc}
		_WRAP_
		chmod +x "${icpx_wrapper}" || die

		# Export CXX so that cmake_src_configure's tc-getCXX picks up our wrapper
		# and the generated gentoo_toolchain.cmake sets CMAKE_CXX_COMPILER to it.
		# Setting -DCMAKE_CXX_COMPILER alone is insufficient: the toolchain file
		# is the authority cmake uses for compiler detection.
		local -x CXX="${icpx_wrapper}"

		mycmakeargs+=(
			-DGGML_SYCL=yes
			-DGGML_SYCL_F16=yes
			-DCMAKE_PREFIX_PATH="${oneapi_root}/compiler/latest;${oneapi_root}/mkl/latest;${ESYSROOT}/usr"
			-DCMAKE_CXX_COMPILER="${icpx_wrapper}"
			# MKLConfig.cmake derives MKL_ROOT from its cmake file location; via
			# the /usr/lib64/cmake/mkl/ symlink it gets /usr, then fails to find
			# the SYCL libs. Set MKL_ROOT explicitly to the oneAPI installation.
			-DMKL_ROOT="${oneapi_root}/mkl/latest"
			# MKLConfig.cmake only creates MKL::MKL_SYCL::BLAS when SYCL_COMPILER=ON;
			# it auto-detects this by checking if CMAKE_CXX_COMPILER name == "icpx",
			# but our wrapper is named differently. Force it explicitly.
			-DENABLE_SYCL_COMPILER=ON
			# sci-libs/mkl removes intel_thread and gnu_thread unless those USE
			# flags are set; sequential is always present.
			-DMKL_THREADING=sequential
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
