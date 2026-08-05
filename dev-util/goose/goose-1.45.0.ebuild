# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop

DESCRIPTION="An open-source AI agent for automated software development"
HOMEPAGE="https://github.com/aaif-goose/goose"
RUSTY_V8_V="v$(ver_rs 1 '').0"
ELECTRON_V="41.0.0"

SRC_URI="https://github.com/aaif-goose/goose/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://localhost/distfiles/${P}-vendor.tar.xz
	https://github.com/denoland/rusty_v8/releases/download/${RUSTY_V8_V}/\
librusty_v8_release_x86_64-unknown-linux-gnu.a.gz
	gui? (
		https://localhost/distfiles/${P}-pnpm-vendor.tar.xz
		https://github.com/electron/electron/releases/download/v${ELECTRON_V}/electron-v${ELECTRON_V}-linux-x64.zip
	)"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="gui"

RDEPEND="
	sys-apps/dbus
	gui? (
		app-accessibility/at-spi2-core
		dev-libs/glib:2
		dev-libs/nspr
		dev-libs/nss
		media-libs/alsa-lib
		media-libs/fontconfig
		media-libs/mesa
		net-print/cups
		x11-libs/cairo
		x11-libs/gtk+:3
		x11-libs/libpciaccess
		x11-libs/libX11
		x11-libs/libXcomposite
		x11-libs/libXdamage
		x11-libs/libXext
		x11-libs/libXfixes
		x11-libs/libXi
		x11-libs/libxkbcommon
		x11-libs/libXrandr
		x11-libs/libXrender
		x11-libs/libxshmfence
		x11-libs/pango
	)
"
BDEPEND="
	|| (
		dev-lang/rust
		dev-lang/rust-bin
	)
	gui? (
		app-arch/unzip
		net-libs/nodejs
	)
"

src_unpack() {
	unpack "${P}.tar.gz"
	mkdir -p "${WORKDIR}/vendor" || die
	tar -xf "${DISTDIR}/${P}-vendor.tar.xz" \
		-C "${WORKDIR}/vendor" \
		--strip-components=1 \
		|| die "Failed to unpack vendor tarball"

	if use gui; then
		tar -xf "${DISTDIR}/${P}-pnpm-vendor.tar.xz" \
			-C "${S}" \
			|| die "Failed to unpack pnpm vendor tarball"
	fi
}

src_prepare() {
	default
	mkdir -p "${WORKDIR}/vendor/v8" || die
	echo '{"files":{}}' > "${WORKDIR}/vendor/v8/.cargo-checksum.json" || die

	if use gui; then
		sed -i 's/let cfg = {/let cfg = {\n  electronZipDir: process.env.ELECTRON_CACHE_DIR,/' \
			ui/desktop/forge.config.ts || die "Failed to patch forge.config.ts for electronZipDir"
	fi
}

src_compile() {
	export CARGO_HOME="${S}/.cargo"
	export RUSTY_V8_ARCHIVE="${DISTDIR}/librusty_v8_release_x86_64-unknown-linux-gnu.a.gz"
	mkdir -p "${CARGO_HOME}" || die
	cat > "${CARGO_HOME}/config.toml" <<-EOF || die "Failed to write cargo config"
		[source.crates-io]
		replace-with = "vendored-sources"

		[source."git+https://github.com/jbg/cudaforge?rev=e7c1967340e40673db98dc9e17da0f04834a456f"]
		git = "https://github.com/jbg/cudaforge"
		rev = "e7c1967340e40673db98dc9e17da0f04834a456f"
		replace-with = "vendored-sources"

		[source.vendored-sources]
		directory = "${WORKDIR}/vendor"
	EOF

	cargo build --release --offline -p goose-cli --bin goose || die "Cargo build failed"

	if use gui; then
		mkdir -p "${S}/ui/desktop/src/bin" || die
		cp -p target/release/goose "${S}/ui/desktop/src/bin/goose" || die "Failed to copy goose binary for GUI"

		mkdir -p "${WORKDIR}/electron_cache" || die
		cp "${DISTDIR}/electron-v${ELECTRON_V}-linux-x64.zip" "${WORKDIR}/electron_cache/" || die

		cd "${S}/ui/desktop" || die
		ELECTRON_CACHE_DIR="${WORKDIR}/electron_cache" npx electron-forge package || die "Electron package build failed"
		cd "${S}" || die
	fi
}

src_install() {
	dobin target/release/goose

	if use gui; then
		insinto /opt/Goose
		doins -r ui/desktop/out/Goose-linux-x64/*
		fperms 0755 /opt/Goose/Goose
		fperms 0755 /opt/Goose/chrome-sandbox
		fperms 0755 /opt/Goose/chrome_crashpad_handler

		dosym ../../opt/Goose/Goose /usr/bin/goose-gui

		newicon -s 512 ui/desktop/src/images/icon-512.png goose.png
		make_desktop_entry --eapi9 goose-gui -d goose-gui -n "Goose" -i goose -c "Development;Utility;"
	fi

	DOCS=( README.md SECURITY.md )
	einstalldocs
}
