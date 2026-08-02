# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ROCM_VERSION=7.2
inherit cuda cmake rocm toolchain-funcs

DESCRIPTION="Tensor library for machine learning"
HOMEPAGE="https://ggml.ai/"
SRC_URI="https://github.com/ggml-org/${PN}/archive/refs/tags/v${PV}.tar.gz
	-> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
# ~amd64 only: this overlay copy exists for the sycl backend, whose toolchain
# (intel-oneapi-dpcpp, mkl[sycl], level-zero, intel-compute-runtime) is amd64
# glibc only. arm64 has no reason to prefer this over ::gentoo's ggml, which
# keeps ~arm64 and is selected there automatically.
KEYWORDS="~amd64"

X86_CPU_FLAGS=(
	avx
	avx_vnni
	avx2
	avx512bw
	avx512f
	avx512vbmi
	avx512_vnni
	bmi2
	fma3
	f16c
	sse4_2
)
CPU_FLAGS=( "${X86_CPU_FLAGS[@]/#/cpu_flags_x86_}" )
# sycl is the overlay's addition over ::gentoo: it builds libggml-sycl.so for
# Intel Arc dGPUs. ::gentoo's ggml has no sycl flag, and because llama-cpp builds
# with LLAMA_USE_SYSTEM_GGML=ON, its own USE=sycl cannot produce the backend --
# only this package can. Same capability-parity lesson as sci-libs/mkl.
IUSE="${CPU_FLAGS[*]} cuda openmp rocm sycl test vulkan"

REQUIRED_USE="
	rocm? ( ${ROCM_REQUIRED_USE} )
	sycl? ( !cuda !rocm elibc_glibc )
"

RESTRICT="!test? ( test )"

# Should be >=sci-libs/hipBLAS-${ROCM_VERSION}[${ROCM_USEDEP}]
# But pkgcheck can't elaborate that
RDEPEND="
	cuda? (
		dev-util/nvidia-cuda-toolkit:=
	)
	vulkan? ( media-libs/vulkan-loader )
	rocm? (
		>=dev-util/hip-${ROCM_VERSION}
		>=sci-libs/hipBLAS-${ROCM_VERSION}
	)
	sycl? (
		elibc_glibc? (
			dev-libs/level-zero:=
			sci-libs/mkl[sycl(-)]
			dev-libs/intel-compute-runtime[l0]
		)
	)
"
DEPEND="${RDEPEND}
	vulkan? ( dev-util/vulkan-headers )
"
BDEPEND="
	vulkan? ( media-libs/shaderc )
	sycl? ( elibc_glibc? ( dev-lang/intel-oneapi-dpcpp ) )
"

pkg_pretend() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

pkg_setup() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

src_prepare() {
	cmake_src_prepare

	if use cuda; then
		cuda_src_prepare
	fi
}

src_configure() {
	local mycmakeargs=(
		-DGGML_BACKEND_DL=OFF
		-DGGML_BUILD_EXAMPLES=OFF
		-DGGML_NATIVE=OFF
		-DGGML_HIP_MMQ_MFMA=OFF

		# CPU Flags
		-DGGML_AVX=$(usex cpu_flags_x86_avx)
		-DGGML_AVX_VNNI=$(usex cpu_flags_x86_avx_vnni)
		-DGGML_AVX2=$(usex cpu_flags_x86_avx2)
		-DGGML_AVX512_VBMI=$(usex cpu_flags_x86_avx512vbmi)
		-DGGML_AVX512_VNNI=$(usex cpu_flags_x86_avx512_vnni)
		-DGGML_BMI2=$(usex cpu_flags_x86_bmi2)
		-DGGML_FMA=$(usex cpu_flags_x86_fma3)
		-DGGML_F16C=$(usex cpu_flags_x86_f16c)
		-DGGML_SSE42=$(usex cpu_flags_x86_sse4_2)

		-DGGML_CUDA=$(usex cuda)
		-DGGML_OPENMP=$(usex openmp)
		-DGGML_HIP=$(usex rocm)
		-DGGML_VULKAN=$(usex vulkan)

		-DGGML_BUILD_TESTS=$(usex test)
	)

	# Enable AVX512 if ANY of the avx512 flags are present
	if use cpu_flags_x86_avx512f || use cpu_flags_x86_avx512bw; then
		mycmakeargs+=( -DGGML_AVX512=ON )
	else
		mycmakeargs+=( -DGGML_AVX512=OFF )
	fi

	if use cuda; then
		cuda_add_sandbox -w
		addpredict "/dev/char/"
		cuda_sanitize
		mycmakeargs+=(
			-DCMAKE_CUDA_FLAGS="${NVCCFLAGS}"
		)
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
		local gcc_install_dir icpx_include icpx_wrapper hdr
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
			-DGGML_SYCL=ON
			-DGGML_SYCL_F16=ON
			-DGGML_SYCL_TARGET=INTEL
			# oneDNN is not packaged here; find_package(DNNL) would silently
			# fall back anyway, so disable it explicitly for a reproducible build.
			-DGGML_SYCL_DNN=OFF
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
