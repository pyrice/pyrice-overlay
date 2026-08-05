# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )
RUST_MIN_VER="1.85.0"

# Override the vendored PyO3 with 0.29.0 for RUSTSEC-2026-0176 and
# RUSTSEC-2026-0177.
CRATES="
	aho-corasick@1.1.4
	bit-set@0.8.0
	bit-vec@0.8.0
	bstr@1.12.3
	fancy-regex@0.17.0
	heck@0.5.0
	libc@0.2.186
	memchr@2.8.3
	once_cell@1.21.4
	portable-atomic@1.13.1
	proc-macro2@1.0.106
	pyo3-build-config@0.29.0
	pyo3-ffi@0.29.0
	pyo3-macros-backend@0.29.0
	pyo3-macros@0.29.0
	pyo3@0.29.0
	quote@1.0.46
	regex-automata@0.4.14
	regex-syntax@0.8.11
	regex@1.12.4
	rustc-hash@2.1.3
	serde_core@1.0.228
	serde_derive@1.0.228
	syn@2.0.118
	target-lexicon@0.13.5
	unicode-ident@1.0.24
"

inherit cargo distutils-r1 pypi

DESCRIPTION="Fast BPE tokeniser for OpenAI models"
HOMEPAGE="https://github.com/openai/tiktoken https://pypi.org/project/tiktoken/"
SRC_URI+="
	${CARGO_CRATE_URIS}
"

LICENSE="MIT Apache-2.0-with-LLVM-exceptions Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="dev-python/regex[${PYTHON_USEDEP}] dev-python/requests[${PYTHON_USEDEP}]"
BDEPEND="
	>=dev-python/setuptools-rust-1.5.2[${PYTHON_USEDEP}]
	test? ( ${RDEPEND} )
"

QA_FLAGS_IGNORED="usr/lib.*/py.*/site-packages/tiktoken/_tiktoken.*\.so"

src_prepare() {
	distutils-r1_src_prepare
	sed '/^pyo3 =/s/version = "0\.28\.3"/version = "0.29.0"/' -i Cargo.toml || die
}

python_test() {
	cd "${T}" || die
	"${EPYTHON}" - <<-'PY' || die
		import tiktoken
		encoding = tiktoken.Encoding(
			name="test",
			pat_str=r"\s+|\w+|[^\w\s]+",
			mergeable_ranks={b"hello": 0},
			special_tokens={"<end>": 1},
		)
		assert encoding.decode(encoding.encode("hello")) == "hello"
	PY
}
