# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit xdg-utils desktop systemd

DESCRIPTION="GlobalProtect VPN GUI based on OpenConnect with SAML auth mode support"
HOMEPAGE="https://github.com/yuezk/GlobalProtect-openconnect"
SRC_URI="https://github.com/yuezk/GlobalProtect-openconnect/releases/download/v${PV}/${P}.tar.gz
	https://localhost/distfiles/${P}-vendor.tar.xz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+gnome kde"

DEPEND="
	|| (
	dev-lang/rust
	dev-lang/rust-bin
	)
	dev-lang/perl
	sys-auth/polkit
	net-vpn/openconnect
	net-libs/webkit-gtk:4.1=
	net-libs/libsoup:2.4
	dev-libs/libayatana-appindicator
	net-misc/curl
	net-misc/wget
	gnome? ( gnome-base/gnome-keyring )
	kde? ( kde-plasma/kwallet-pam )
"

RDEPEND="${DEPEND}"
BDEPEND="app-misc/jq"

src_unpack() {
	default
	mkdir -p "${S}/vendor" || die
	tar -xf "${DISTDIR}/${P}-vendor.tar.xz" -C "${S}/vendor" --strip-components=1 || die "Failed to unpack vendor"
}

src_compile() {
	# Konfigurera cargo att använda local vendor dir
	export CARGO_HOME="${S}/.cargo"
	mkdir -p "${CARGO_HOME}" || die
	cat > "${CARGO_HOME}/config.toml" <<EOF
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "${S}/vendor"
EOF
	[[ $? -ne 0 ]] && die "Failed to write cargo config"

	# Kör bygget (utan nätverk)
	cargo build --release -p gpclient -p gpservice -p gpauth || die "Rust build failed"
	cargo build --release -p gpgui-helper --features "tauri/custom-protocol" || die "GUI build failed"

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
