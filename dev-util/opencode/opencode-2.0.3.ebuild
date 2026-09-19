# Copyright 2021-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion

DESCRIPTION="The open source coding agent"
HOMEPAGE="https://opencode.ai"
SRC_URI="
	https://github.com/anomalyco/opencode/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/opencode-${PV}/opencode-${PV}-deps.tar.xz
	https://github.com/0x6d6e647a/mndz-overlay-assets/releases/download/opencode-${PV}/opencode-${PV}-models.json
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="bash-completion test +webui zsh-completion"
# Bun --compile embeds the app in ELF sections that strip destroys; after
# strip the binary reports host Bun (e.g. 1.4.2) instead of OPENCODE_VERSION.
RESTRICT="strip !test? ( test )"

# Upstream's packages/script/src/index.ts enforces bun@^$(packageManager in
# root package.json) at build time; 2.0.x monorepo pins packageManager to
# bun@1.4.2, up from 1.3.14 for the 1.18.x line.
BDEPEND=">=dev-lang/bun-bin-1.4.2"
RDEPEND="sys-apps/ripgrep"

# InstallTree deps: unpack source + overlay node_modules onto ${S}.
# Models JSON stays in DISTDIR (MODELS_DEV_API_JSON); do not unpack it.
# Avoid default_src_unpack so deps are not also expanded under ${WORKDIR}.
src_unpack() {
	unpack ${P}.tar.gz
	cd "${S}" || die
	unpack ${P}-deps.tar.xz
}

src_compile() {
	export MODELS_DEV_API_JSON="${DISTDIR}/${PN}-${PV}-models.json"
	export OPENCODE_DISABLE_MODELS_FETCH=1
	export OPENCODE_VERSION="${PV}"
	export OPENCODE_CHANNEL=stable
	# Deps already installed under ${S} via InstallTree deps tarball.
	# CLI package moved from packages/opencode (1.x) to packages/cli (2.x
	# monorepo restructure); --skip-embed-web-ui was renamed --skip-web-ui.
	cd packages/cli || die
	if use webui; then
		bun --bun ./script/build.ts --single --skip-install || die
	else
		bun --bun ./script/build.ts --single --skip-install --skip-web-ui || die
	fi
}

src_install() {
	local bin
	bin="$(find packages/cli/dist -type f -name opencode -executable | head -n1)" || die
	[[ -n ${bin} ]] || die "opencode binary not found under packages/cli/dist"
	dobin "${bin}"

	# Running the binary for shell completions can open ftrace's trace_marker
	# (sandbox ACCESS DENIED open_wr without this).
	addwrite /sys/kernel/debug/tracing

	# The 1.x "opencode completion" subcommand was replaced by a global
	# "--completions <shell>" flag in the 2.x CLI.
	if use bash-completion; then
		SHELL=/bin/bash "${ED}/usr/bin/opencode" --completions bash > opencode.bash || die
		newbashcomp opencode.bash opencode
	fi
	if use zsh-completion; then
		SHELL=/bin/zsh "${ED}/usr/bin/opencode" --completions zsh > opencode.zsh || die
		newzshcomp opencode.zsh _opencode
	fi
}

src_test() {
	# Upstream package suite; InstallTree deps already unpacked under ${S}.
	cd packages/cli || die
	bun test --timeout 30000 --only-failures || die
}
