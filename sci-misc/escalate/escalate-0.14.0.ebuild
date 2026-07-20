# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Lifting gas calculator for stratospheric balloons (CLI + TUI)"
HOMEPAGE="https://github.com/pyrice/escalate"
SRC_URI="https://localhost/distfiles/${P}.tar.xz
	https://localhost/distfiles/${P}-vendor.tar.xz"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror"

BDEPEND="
	|| (
	dev-lang/rust
	dev-lang/rust-bin
	)
"

src_unpack() {
	default
	# vendor/ must stay outside ${S}: aga8's build.rs runs `cargo metadata`,
	# and if vendor/aga8 sits under ${S} it gets pulled into ${S}'s own
	# [workspace] as an unlisted member, which cargo refuses.
	mkdir -p "${WORKDIR}/vendor" || die
	tar -xf "${DISTDIR}/${P}-vendor.tar.xz" -C "${WORKDIR}/vendor" --strip-components=1 || die "Failed to unpack vendor"
}

src_prepare() {
	default

	# aga8's build.rs unconditionally shells out to cbindgen to emit a C
	# header (aga8.h) for FFI/C consumers. Internally that calls
	# `cargo metadata`, which resolves aga8's own dev-dependencies
	# (assert_float_eq, criterion, rand 0.9) — unused by escalate (a
	# pure-Rust consumer) and not vendored. Skip the header generation.
	sed -i '/cbindgen::generate_with_config/,+2d' "${WORKDIR}/vendor/aga8/build.rs" \
		|| die "Failed to patch aga8 build.rs"
	sed -i 's/"files":{[^}]*}/"files":{}/' "${WORKDIR}/vendor/aga8/.cargo-checksum.json" \
		|| die "Failed to clear aga8 vendor checksum"
}

src_compile() {
	export CARGO_HOME="${S}/.cargo"
	mkdir -p "${CARGO_HOME}" || die
	cat > "${CARGO_HOME}/config.toml" <<-EOF || die "Failed to write cargo config"
		[source.crates-io]
		replace-with = "vendored-sources"

		[source.vendored-sources]
		directory = "${WORKDIR}/vendor"
	EOF

	cargo build --release --offline || die "Rust build failed"
}

src_install() {
	dobin target/release/escalate

	dodoc README.md CHANGELOG.md
}
