# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..15} )

inherit distutils-r1 pypi

DESCRIPTION="Model Context Protocol wire types"
HOMEPAGE="https://modelcontextprotocol.io/ https://github.com/modelcontextprotocol/python-sdk"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-python/pydantic-2.12.0[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.13.0[${PYTHON_USEDEP}]
"
BDEPEND="
	dev-python/uv-dynamic-versioning[${PYTHON_USEDEP}]
	test? ( ${RDEPEND} )
"

python_compile() {
	local -x UV_DYNAMIC_VERSIONING_BYPASS=${PV}
	distutils-r1_python_compile
}

python_test() {
	# The standalone types sdist does not ship the SDK's test suite.
	"${EPYTHON}" - <<-'PY' || die
		from mcp_types import TextContent
		text = TextContent(type="text", text="packaging smoke test")
		assert TextContent.model_validate_json(text.model_dump_json()) == text
		print("PASS: MCP wire type serialization round trip")
	PY
}
