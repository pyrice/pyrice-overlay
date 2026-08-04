# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="An open-source AI agent for automated software development"
HOMEPAGE="https://github.com/aaif-goose/goose"
RUSTY_V8_V="v$(ver_rs 1 '').0"
SRC_URI="https://github.com/aaif-goose/goose/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://localhost/distfiles/${P}-vendor.tar.xz
	https://github.com/denoland/rusty_v8/releases/download/${RUSTY_V8_V}/\
librusty_v8_release_x86_64-unknown-linux-gnu.a.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	sys-apps/dbus
"
BDEPEND="
	|| (
		dev-lang/rust
		dev-lang/rust-bin
	)
"

src_unpack() {
	default
	mkdir -p "${WORKDIR}/vendor" || die
	tar -xf "${DISTDIR}/${P}-vendor.tar.xz" \
		-C "${WORKDIR}/vendor" \
		--strip-components=1 \
		|| die "Failed to unpack vendor tarball"
}

src_prepare() {
	default
	mkdir -p "${WORKDIR}/vendor/v8" || die
	echo '{"files":{}}' > "${WORKDIR}/vendor/v8/.cargo-checksum.json" || die
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
}

src_install() {
	dobin target/release/goose
	DOCS=( README.md SECURITY.md )
	einstalldocs
}
