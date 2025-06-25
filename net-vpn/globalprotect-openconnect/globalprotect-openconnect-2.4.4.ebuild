# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit xdg-utils desktop systemd

DESCRIPTION="GlobalProtect VPN GUI based on OpenConnect with SAML auth mode support"
HOMEPAGE="https://github.com/yuezk/GlobalProtect-openconnect"
SRC_URI="https://github.com/yuezk/GlobalProtect-openconnect/releases/download/v${PV}/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+gnome kde"

DEPEND="
	virtual/rust
	dev-lang/perl
	sys-auth/polkit
	net-vpn/openconnect
	net-libs/webkit-gtk:4
	net-libs/libsoup:2.4
	dev-libs/libayatana-appindicator
	net-misc/curl
	net-misc/wget
	gnome? ( gnome-base/gnome-keyring )
	kde? ( kde-plasma/kwallet-pam )
"

RDEPEND="${DEPEND}"

src_compile() {
	emake build BUILD_FE=0
}

src_install() {
	emake DESTDIR="${D}" install

	domenu "${FILESDIR}/gpclient.desktop"
	systemd_newuserunit "${FILESDIR}/gpservice.service" gpservice.service
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
	systemctl --user daemon-reexec &>/dev/null || true
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
