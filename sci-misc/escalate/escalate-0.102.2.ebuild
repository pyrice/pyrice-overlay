# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Lifting gas calculator for stratospheric balloons (CLI + TUI)"
HOMEPAGE="https://github.com/pyrice/escalate"
# Upstream is a private repository reachable only over SSH, so no fetcher
# Portage has can reach it: every archive is generated locally into
# ${DISTDIR} from the vX.Y.Z tag. See scripts/make_escalate_distfiles.sh.
#
# ${P}-web.tar.xz holds the browser front end already built to wasm. It is
# shipped prebuilt because it cannot be built inside the Portage sandbox on
# this system: dev-lang/rust-bin-1.97.1 carries no wasm32 target (its IUSE
# has no rust_targets), no wasm-bindgen-cli is packaged in any configured
# repository, wasm-opt is absent, and trunk downloads and manages both
# itself over the network. Every other archive here is locally generated for
# the same private-upstream reason, so this adds no new trust assumption.
SRC_URI="https://localhost/distfiles/${P}.tar.xz
	https://localhost/distfiles/${P}-vendor.tar.xz
	webui? ( https://localhost/distfiles/${P}-web.tar.xz )"

# No LICENSE file and no license field in any of the workspace manifests;
# the repository is private.
LICENSE="all-rights-reserved"
# Dependent crate licenses. Derived from the license field of all 456
# crates in ${P}-vendor.tar.xz, not from memory. The external crate set is
# byte-identical to 0.65.0's (verified against both tags' Cargo.lock: the
# only entries that differ are the workspace's own escalate/escalate-core/
# escalate-view/escalate-plan packages), so the license list carries over
# unchanged. Two crates declare license-file instead: aga8 ships NIST's
# public-domain notice, cfg_block ships Apache-2.0. Where a crate offers a
# choice, the atom kept is one already in this list, so LGPL-2.1-or-later
# (r-efi, also MIT/Apache-2.0) and zlib-acknowledgement (fastdivide, also
# MIT) are deliberately absent.
LICENSE+=" Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2 Boost-1.0
	ISC MIT MPL-2.0 Unicode-3.0 Unicode-DFS-2016 Unlicense WTFPL-2 ZLIB
	public-domain"
SLOT="0"
KEYWORDS="~amd64"
IUSE="webui"
RESTRICT="bindist mirror"

# 1.90.0 is the highest rust-version declared by any vendored dependency
# (roaring). Neither escalate nor escalate-core nor escalate-view nor the
# new escalate-plan declares one; all four are edition 2021. Unchanged from
# 0.65.0: the vendored crate set is identical (see the LICENSE comment).
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
	# aga8 is now pulled in transitively through escalate-core only (0.92.0
	# dropped the root package's own direct dependency on it); the vendored
	# crate and this patch are unaffected.
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
	# Builds the root workspace only: escalate plus its members
	# escalate-core, escalate-plan and escalate-view. escalate-web is
	# excluded from that workspace upstream (it builds for wasm32 alone and
	# forces release profile settings the TUI must not inherit) and is not
	# built here; see the SRC_URI comment and USE=webui.
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
	elog "The history database is migrated the first time it is opened for"
	elog "writing. On a machine where nobody opens the TUI — a host that only"
	elog "runs 'escalate serve' — ask for it explicitly, with the TUI closed:"
	elog "  escalate migrate"
	elog ""
	elog "Upgrading from a version older than 0.102.0: rows written before"
	elog "that release have no recorded_at_offset (the writer's local UTC"
	elog "offset, stored beside the existing UTC timestamp since 0.102.0)."
	elog "'escalate migrate' adds the column; backfilling it on old rows is a"
	elog "separate, owner-run step documented in CHANGELOG.md's 0.102.1 and"
	elog "0.102.2 entries (tools/normalize_recorded_at.py in the source tree)."
	elog ""
	elog "'escalate serve' exposes the stored containers, missions and history"
	elog "as read-only JSON on 127.0.0.1:8080. It has no authentication; keep"
	elog "it on a trusted network."
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
