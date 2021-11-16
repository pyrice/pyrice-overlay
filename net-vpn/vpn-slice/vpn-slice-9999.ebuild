# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..10} )

inherit distutils-r1
S="${WORKDIR}/${PN}-master"

DESCRIPTION="vpnc-script replacement for easy and secure split-tunnel VPN setup "
HOMEPAGE="https://github.com/dlenski/vpn-slice"
SRC_URI="https://github.com/dlenski/${PN}/archive/master.tar.gz -> ${PN}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="dev-python/setproctitle[${PYTHON_USEDEP}]
	dev-python/dnspython[${PYTHON_USEDEP}]
"
