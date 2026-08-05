# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=pdm-backend
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="High-performance Python web framework"
HOMEPAGE="https://fastapi.tiangolo.com/ https://github.com/fastapi/fastapi https://pypi.org/project/fastapi/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-python/annotated-doc-0.0.2[${PYTHON_USEDEP}]
	>=dev-python/pydantic-2.9.0[${PYTHON_USEDEP}]
	>=dev-python/starlette-0.46.0[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.8.0[${PYTHON_USEDEP}]
	>=dev-python/typing-inspection-0.4.2[${PYTHON_USEDEP}]
"
BDEPEND="test? ( ${RDEPEND} )"

python_prepare_all() {
	# The optional fastapi-cli package owns this command.
	sed -i '/^\[project.scripts\]/,/^$/d' pyproject.toml || die
	distutils-r1_python_prepare_all
}

python_test() {
	"${EPYTHON}" - <<-'PY' || die
		from fastapi import FastAPI
		app = FastAPI()
		app.add_api_route("/health", lambda: {"ok": True})
		assert any(route.path == "/health" for route in app.routes)
	PY
}
