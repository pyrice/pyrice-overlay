# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{12..14} )

PYPI_PN="Expression"

inherit distutils-r1 pypi

DESCRIPTION="Practical functional programming for Python"
HOMEPAGE="https://github.com/cognitedata/Expression https://pypi.org/project/Expression/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND=">=dev-python/typing-extensions-4.6.0[${PYTHON_USEDEP}]"
BDEPEND="test? ( ${RDEPEND} )"

python_test() {
	"${EPYTHON}" - <<-'PY' || die
		from expression import Option, Some
		assert Option.of_optional(2).map(lambda value: value * 2) == Some(4)
	PY
}
