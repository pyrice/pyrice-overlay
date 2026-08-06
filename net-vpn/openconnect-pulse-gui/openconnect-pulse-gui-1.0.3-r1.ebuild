# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..14} )
DISTUTILS_USE_PEP517=setuptools
inherit distutils-r1 git-r3

DESCRIPTION="Web-browser based authentication for openconnect Ivanti/Pulse Secure VPN services"
HOMEPAGE="https://github.com/markus-meier74/openconnect-pulse-gui"

EGIT_BRANCH="master"
EGIT_REPO_URI="https://github.com/markus-meier74/openconnect-pulse-gui.git"
EGIT_COMMIT="v${PV}"

LICENSE="GPL-3"

SLOT="0"
KEYWORDS="~amd64"
#IUSE=""

RDEPEND="
	$(python_gen_cond_dep '
		dev-python/pygobject[${PYTHON_USEDEP}]
	')
	net-libs/webkit-gtk:4.1
	net-vpn/openconnect
"
DEPEND="
	${RDEPEND}
"

DOCS=( "AUTHORS" "LICENSE" "README.md" )

# Upstream needs WEBKIT_DISABLE_DMABUF_RENDERER for its own WebKitGTK view and
# installs it through doenvd, which exports it from /etc/profile.env into every
# session. That disables hardware rendering for every WebKitGTK application on
# the machine — measurably so: it made x11-terms/terax lag by seconds per
# keystroke on Wayland with an Intel Arc GPU. The patch moves the same setting
# into this process, before the WebKit2 import, and the envd file is dropped.
PATCHES=( "${FILESDIR}/${P}-scope-webkit-dmabuf-workaround.patch" )

python_install_all() {
	distutils-r1_python_install_all

	msg="Sorry, installation of ${PN} failed for some reason... ;_;"

	mkdir "sudoers.d/" || die "${msg}"
	echo '%users ALL=(root:root) NOEXEC, NOPASSWD: /usr/bin/openconnect' > "sudoers.d/openconnect" || die "${msg}"

	insinto "/usr/share/doc/${PF}/"
	insopts "-m440"
	doins -r "sudoers.d/"
}

pkg_postinst() {
	einfo "${PN} will call sudo to run openconnect."
	einfo "A template sudo configuration file is provided in"
	einfo "'/usr/share/doc/${PF}/sudoers.d/openconnect'."
	einfo "It grants passwordless access to '/usr/bin/openconnect' to all users in group 'users'."
	einfo "Edit it to suit your needs and copy it to '/etc/sudoers.d/openconnect'."
	einfo "sudo requires that this file be owned by root:root"
	einfo "and its permissions be set to 440 (-r--r-----)."

	if [[ -n ${REPLACING_VERSIONS} ]]; then
		elog ""
		elog "This revision no longer installs /etc/env.d/99${PN}, which set"
		elog "WEBKIT_DISABLE_DMABUF_RENDERER=1 for every session and thereby"
		elog "disabled hardware rendering in all WebKitGTK applications."
		elog "${PN} now sets it for itself only."
		elog ""
		elog "Run 'env-update' and start a new session; until you log in again"
		elog "the old value is still exported from /etc/profile.env."
	fi
}
