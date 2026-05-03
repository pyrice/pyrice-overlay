# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

inherit python-single-r1 systemd

DESCRIPTION="Web-based GUI backend for CamillaDSP"
HOMEPAGE="https://github.com/HEnquist/camillagui-backend"
SRC_URI="
	https://github.com/HEnquist/camillagui-backend/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/HEnquist/camillagui/archive/refs/tags/v${PV}.tar.gz -> camillagui-${PV}.tar.gz
"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/aiohttp[${PYTHON_USEDEP}]
		dev-python/jsonschema[${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
		dev-python/pycamilladsp[${PYTHON_USEDEP}]
		dev-python/pycamilladsp-plot[plot,${PYTHON_USEDEP}]
	')
"
DEPEND="${RDEPEND}"
BDEPEND="net-libs/nodejs"

src_compile() {
	cd "${WORKDIR}/camillagui-${PV}" || die
	npm install || die
	npm run build || die
}

src_install() {
	insinto /usr/share/${PN}
	doins -r backend main.py
	doins -r "${WORKDIR}/camillagui-${PV}/build"

	insinto /etc/camillagui
	doins config/camillagui.yml
	doins config/gui-config.yml

	dosym -r /etc/camillagui /usr/share/${PN}/config

	sed "s|@PYTHON@|${PYTHON}|g" \
		"${FILESDIR}/${PN}.service.in" > "${T}/${PN}.service" || die
	systemd_dounit "${T}/${PN}.service"
}
