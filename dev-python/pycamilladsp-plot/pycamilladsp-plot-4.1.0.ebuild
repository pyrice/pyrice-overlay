# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

DESCRIPTION="Library for validating and plotting CamillaDSP configs"
HOMEPAGE="https://github.com/HEnquist/pycamilladsp-plot"
SRC_URI="https://github.com/HEnquist/pycamilladsp-plot/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="plot"

RDEPEND="
	>=dev-python/jsonschema-4.10[${PYTHON_USEDEP}]
	>=dev-python/pyyaml-6.0[${PYTHON_USEDEP}]
	dev-python/pycamilladsp[${PYTHON_USEDEP}]
	plot? (
		dev-python/matplotlib[${PYTHON_USEDEP}]
		dev-python/numpy[${PYTHON_USEDEP}]
	)
"
