# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Lifting gas calculator for stratospheric balloons (CLI + TUI)"
HOMEPAGE="https://github.com/pyrice/escalate"
# Upstream is a private repository; every archive is generated locally into
# ${DISTDIR} from the vX.Y.Z tag. See scripts/make_escalate_distfiles.sh.
#
# ${P}-web.tar.xz holds the browser front end already built to wasm. It is
# shipped prebuilt because it cannot be built inside the Portage sandbox on
# this system: dev-lang/rust-bin carries no wasm32 target (IUSE has no
# rust_targets), no wasm-bindgen-cli is packaged in any configured repository,
# wasm-opt is absent, and trunk fetches its own toolchain over the network.
# Every other archive here is locally generated for the same private-upstream
# reason, so this adds no new trust assumption.
SRC_URI="https://localhost/distfiles/${P}.tar.xz
	https://localhost/distfiles/${P}-vendor.tar.xz
	webui? ( https://localhost/distfiles/${P}-web.tar.xz )"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
IUSE="webui"
RESTRICT="bindist mirror"

# 1.90.0 is the highest rust-version declared by any vendored dependency.
BDEPEND="
	|| (
		>=dev-lang/rust-1.90.0
		>=dev-lang/rust-bin-1.90.0
	)
"

src_unpack() {
	default
	# vendor/ must stay outside ${S}: aga8's build.rs runs `cargo metadata`,
	# and if vendor/aga8 sits under ${S} it gets pulled into ${S}'s own
	# [workspace] as an unlisted member, which cargo refuses.
	mkdir -p "${WORKDIR}/vendor" || die
	tar -xf "${DISTDIR}/${P}-vendor.tar.xz" -C "${WORKDIR}/vendor" --strip-components=1 \
		|| die "Failed to unpack vendor"
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

src_configure() {
	export CARGO_HOME="${S}/.cargo"
	mkdir -p "${CARGO_HOME}" || die
	cat > "${CARGO_HOME}/config.toml" <<-EOF || die "Failed to write cargo config"
		[source.crates-io]
		replace-with = "vendored-sources"

		[source.vendored-sources]
		directory = "${WORKDIR}/vendor"
	EOF
}

src_compile() {
	export CARGO_HOME="${S}/.cargo"
	cargo build --release --offline || die "Rust build failed"
}

src_test() {
	export CARGO_HOME="${S}/.cargo"
	cargo test --release --offline || die "Rust test suite failed"
}

src_install() {
	dobin target/release/escalate

	if use webui; then
		# `escalate serve --web-root` reads plain files out of this
		# directory; nothing here is executed by the package itself.
		insinto /usr/share/${PN}/web
		doins "${WORKDIR}/${P}-web/"*
	fi

	dodoc README.md CHANGELOG.md
}

pkg_postinst() {
	elog "User configuration lives in ~/.config/escalate/config.toml and is"
	elog "written back when escalate exits."
	elog ""
	elog "'escalate serve' exposes the stored containers and history as"
	elog "read-only JSON on 127.0.0.1:8080. It has no authentication; keep it"
	elog "on a trusted network."
	elog ""
	if use webui; then
		elog "The browser front end is installed. Serve it on the same"
		elog "origin as the API with:"
		elog "  escalate serve --web-root /usr/share/${PN}/web"
	else
		elog "The browser front end is not installed. Enable USE=webui, or"
		elog "build it with trunk and point the server at the result:"
		elog "  escalate serve --web-root /path/to/escalate-web/dist"
	fi
}
