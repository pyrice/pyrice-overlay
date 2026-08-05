# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{12..14} )

PYPI_PN="InquirerPy"
PYPI_NO_NORMALIZE=1

inherit distutils-r1 pypi

DESCRIPTION="Collection of interactive command-line user interfaces"
HOMEPAGE="https://github.com/kazhala/InquirerPy https://pypi.org/project/InquirerPy/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-python/pfzy-0.3.1[${PYTHON_USEDEP}]
	<dev-python/pfzy-0.4[${PYTHON_USEDEP}]
	>=dev-python/prompt-toolkit-3.0.1[${PYTHON_USEDEP}]
	<dev-python/prompt-toolkit-4[${PYTHON_USEDEP}]
"
BDEPEND="test? ( ${RDEPEND} )"

python_test() {
	"${EPYTHON}" - <<-'PY' || die
		from InquirerPy import inquirer
		assert inquirer.text and inquirer.select
	PY
}
