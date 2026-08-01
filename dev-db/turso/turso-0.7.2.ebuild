# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="In-process SQL database written in Rust, compatible with SQLite"
HOMEPAGE="https://github.com/tursodatabase/turso"
# Source + a locally generated cargo vendor bundle (the whole workspace's crate
# deps, incl. the git pin of syntect). Regenerate both on every version bump; see
# ebuilds/CLAUDE.md "Vendored Cargo Packages".
SRC_URI="https://localhost/distfiles/${P}.tar.xz
	https://localhost/distfiles/${P}-vendor.tar.xz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror"

BDEPEND="
	|| (
		dev-lang/rust
		dev-lang/rust-bin
	)
"

# default src_unpack handles both archives: the source to ${WORKDIR}/${P} (= S)
# and the vendor bundle to ${WORKDIR}/vendor.

src_compile() {
	export CARGO_HOME="${S}/.cargo"
	mkdir -p "${CARGO_HOME}" || die
	cat > "${CARGO_HOME}/config.toml" <<-EOF || die "Failed to write cargo config"
		[source.crates-io]
		replace-with = "vendored-sources"

		[source."git+https://github.com/trishume/syntect.git?rev=64644ffe064457265cbcee12a0c1baf9485ba6ee"]
		git = "https://github.com/trishume/syntect.git"
		rev = "64644ffe064457265cbcee12a0c1baf9485ba6ee"
		replace-with = "vendored-sources"

		[source.vendored-sources]
		directory = "${WORKDIR}/vendor"
	EOF

	# turso_core embeds a build timestamp (core/build.rs); pin it to the tag's
	# commit time for a reproducible build instead of the wall clock.
	export SOURCE_DATE_EPOCH=1785418626

	# Build only the CLI (binary: tursodb). The workspace also carries language
	# bindings, perf harnesses and test crates we do not ship. --frozen because
	# the vendored Cargo.lock is exactly the tag's committed lock.
	cargo build --release --frozen --package turso_cli || die "cargo build failed"
}

src_install() {
	dobin target/release/tursodb
	dodoc README.md CHANGELOG.md
}
