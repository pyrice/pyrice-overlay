# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	aead@0.5.2
	aes-gcm@0.10.3
	aes@0.8.4
	android_system_properties@0.1.5
	anstream@1.0.0
	anstyle-parse@1.0.0
	anstyle-query@1.1.5
	anstyle-wincon@3.0.11
	anstyle@1.0.14
	anyhow@1.0.102
	atomic-waker@1.1.2
	autocfg@1.5.0
	base64@0.22.1
	bitflags@2.11.0
	bumpalo@3.20.2
	bytes@1.11.1
	cc@1.2.57
	cfg-if@1.0.4
	chrono@0.4.44
	cipher@0.4.4
	clap@4.6.0
	clap_builder@4.6.0
	clap_derive@4.6.0
	clap_lex@1.1.0
	colorchoice@1.0.5
	core-foundation-sys@0.8.7
	core-foundation@0.10.1
	core-foundation@0.9.4
	cpufeatures@0.2.17
	crypto-common@0.1.7
	ctr@0.9.2
	displaydoc@0.2.5
	encoding_rs@0.8.35
	equivalent@1.0.2
	errno@0.3.14
	fastrand@2.3.0
	find-msvc-tools@0.1.9
	fnv@1.0.7
	foldhash@0.1.5
	foreign-types-shared@0.1.1
	foreign-types@0.3.2
	form_urlencoded@1.2.2
	futures-channel@0.3.32
	futures-core@0.3.32
	futures-io@0.3.32
	futures-sink@0.3.32
	futures-task@0.3.32
	futures-util@0.3.32
	generic-array@0.14.7
	getrandom@0.2.17
	getrandom@0.4.2
	ghash@0.5.1
	h2@0.4.13
	hashbrown@0.15.5
	hashbrown@0.16.1
	heck@0.5.0
	hex@0.4.3
	http-body-util@0.1.3
	http-body@1.0.1
	http@1.4.0
	httparse@1.10.1
	hyper-rustls@0.27.7
	hyper-tls@0.6.0
	hyper-util@0.1.20
	hyper@1.8.1
	iana-time-zone-haiku@0.1.2
	iana-time-zone@0.1.65
	icu_collections@2.1.1
	icu_locale_core@2.1.1
	icu_normalizer@2.1.1
	icu_normalizer_data@2.1.1
	icu_properties@2.1.2
	icu_properties_data@2.1.2
	icu_provider@2.1.1
	id-arena@2.3.0
	idna@1.1.0
	idna_adapter@1.2.1
	indexmap@2.13.0
	inout@0.1.4
	ipnet@2.12.0
	iri-string@0.7.10
	is_terminal_polyfill@1.70.2
	itoa@1.0.18
	js-sys@0.3.91
	leb128fmt@0.1.0
	libc@0.2.183
	linux-raw-sys@0.12.1
	litemap@0.8.1
	log@0.4.29
	memchr@2.8.0
	mime@0.3.17
	mio@1.1.1
	native-tls@0.2.18
	num-traits@0.2.19
	once_cell@1.21.4
	once_cell_polyfill@1.70.2
	opaque-debug@0.3.1
	openssl-macros@0.1.1
	openssl-probe@0.2.1
	openssl-sys@0.9.112
	openssl@0.10.76
	percent-encoding@2.3.2
	pin-project-lite@0.2.17
	pin-utils@0.1.0
	pkg-config@0.3.32
	polyval@0.6.2
	potential_utf@0.1.4
	ppv-lite86@0.2.21
	prettyplease@0.2.37
	proc-macro2@1.0.106
	quote@1.0.45
	r-efi@6.0.0
	rand@0.8.5
	rand_chacha@0.3.1
	rand_core@0.6.4
	reqwest@0.12.28
	ring@0.17.14
	rustix@1.1.4
	rustls-pki-types@1.14.0
	rustls-webpki@0.103.10
	rustls@0.23.37
	rustversion@1.0.22
	ryu@1.0.23
	schannel@0.1.29
	security-framework-sys@2.17.0
	security-framework@3.7.0
	semver@1.0.27
	serde@1.0.228
	serde_core@1.0.228
	serde_derive@1.0.228
	serde_json@1.0.149
	serde_spanned@0.6.9
	serde_urlencoded@0.7.1
	shlex@1.3.0
	slab@0.4.12
	smallvec@1.15.1
	socket2@0.6.3
	stable_deref_trait@1.2.1
	strsim@0.11.1
	subtle@2.6.1
	syn@2.0.117
	sync_wrapper@1.0.2
	synstructure@0.13.2
	system-configuration-sys@0.6.0
	system-configuration@0.7.0
	tempfile@3.27.0
	tinystr@0.8.2
	tokio-native-tls@0.3.1
	tokio-rustls@0.26.4
	tokio-util@0.7.18
	tokio@1.50.0
	toml@0.8.23
	toml_datetime@0.6.11
	toml_edit@0.22.27
	toml_write@0.1.2
	tower-http@0.6.8
	tower-layer@0.3.3
	tower-service@0.3.3
	tower@0.5.3
	tracing-core@0.1.36
	tracing@0.1.44
	try-lock@0.2.5
	typenum@1.19.0
	unicode-ident@1.0.24
	unicode-xid@0.2.6
	universal-hash@0.5.1
	untrusted@0.9.0
	url@2.5.8
	utf8_iter@1.0.4
	utf8parse@0.2.2
	vcpkg@0.2.15
	version_check@0.9.5
	want@0.3.1
	wasi@0.11.1+wasi-snapshot-preview1
	wasip2@1.0.2+wasi-0.2.9
	wasip3@0.4.0+wasi-0.3.0-rc-2026-01-06
	wasm-bindgen-futures@0.4.64
	wasm-bindgen-macro-support@0.2.114
	wasm-bindgen-macro@0.2.114
	wasm-bindgen-shared@0.2.114
	wasm-bindgen@0.2.114
	wasm-encoder@0.244.0
	wasm-metadata@0.244.0
	wasmparser@0.244.0
	web-sys@0.3.91
	windows-core@0.62.2
	windows-implement@0.60.2
	windows-interface@0.59.3
	windows-link@0.2.1
	windows-registry@0.6.1
	windows-result@0.4.1
	windows-strings@0.5.1
	windows-sys@0.52.0
	windows-sys@0.61.2
	windows-targets@0.52.6
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_msvc@0.52.6
	windows_i686_gnu@0.52.6
	windows_i686_gnullvm@0.52.6
	windows_i686_msvc@0.52.6
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_msvc@0.52.6
	winnow@0.7.15
	wit-bindgen-core@0.51.0
	wit-bindgen-rust-macro@0.51.0
	wit-bindgen-rust@0.51.0
	wit-bindgen@0.51.0
	wit-component@0.244.0
	wit-parser@0.244.0
	writeable@0.6.2
	yoke-derive@0.8.1
	yoke@0.8.1
	zerocopy-derive@0.8.47
	zerocopy@0.8.47
	zerofrom-derive@0.1.6
	zerofrom@0.1.6
	zeroize@1.8.2
	zerotrie@0.2.3
	zerovec-derive@0.11.2
	zerovec@0.11.5
	zmij@1.0.21
"

inherit cargo systemd git-r3

DESCRIPTION="Query Brewfather API v2 endpoints"
HOMEPAGE="https://github.com/pyrice/brewfather-api-query"
SRC_URI="${CARGO_CRATE_URIS}"

EGIT_REPO_URI="git@github.com:pyrice/brewfather-api-query.git"
EGIT_COMMIT="v${PV}"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+=" Apache-2.0 BSD ISC MIT Unicode-3.0 ZLIB"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="systemd"

DEPEND="
	acct-group/brewfather
	acct-user/brewfather
"
RDEPEND="${DEPEND}"

QA_FLAGS_IGNORED="usr/bin/brewfather-api-query"

src_unpack() {
	git-r3_src_unpack
	cargo_src_unpack
}

src_install() {
	cargo_src_install

	# Install systemd service and timer
	if use systemd; then
		systemd_dounit "${FILESDIR}"/brewfather-api-query.service
		systemd_dounit "${FILESDIR}"/brewfather-api-query.timer
	fi

	# Install system config template to /etc/brewfather-api-query/
	insinto /etc/brewfather-api-query
	newins "${FILESDIR}"/brewfather-api-query.toml.example config.toml.example

	# Create system config directory
	keepdir /etc/brewfather-api-query
	fperms 0755 /etc/brewfather-api-query
}

pkg_postinst() {
	elog "Brewfather API Query v${PV} has been installed."
	elog ""
	elog "Configuration follows XDG Base Directory specification:"
	elog "  1. Current directory: ./brewfather-api-query.toml (highest priority)"
	elog "  2. User config: ~/.config/brewfather-api-query/config.toml"
	elog "  3. System config: /etc/brewfather-api-query/config.toml (lowest priority)"
	elog ""
	elog "For user configuration:"
	elog "  mkdir -p ~/.config/brewfather-api-query"
	elog "  cp /etc/brewfather-api-query/config.toml.example \\"
	elog "     ~/.config/brewfather-api-query/config.toml"
	elog ""
	elog "Encrypt your credentials (key stored in ~/.config/brewfather-api-query/):"
	elog "  brewfather-api-query --encrypt-user-id YOUR_USER_ID"
	elog "  brewfather-api-query --encrypt-api-key YOUR_API_KEY"
	elog ""
	elog "Add the encrypted values to your config.toml file"
	elog ""
	if use systemd; then
		elog "For system-wide service (using /etc/brewfather-api-query/config.toml):"
		elog "  1. Create service user: useradd -r -s /bin/false brewfather"
		elog "  2. Create config directory: mkdir -p /var/lib/brewfather-api-query"
		elog "  3. Set ownership: chown brewfather:brewfather /var/lib/brewfather-api-query"
		elog "  4. Copy and configure /etc/brewfather-api-query/config.toml"
		elog "  5. Encrypt credentials as brewfather user"
		elog "  6. Enable timer: systemctl enable --now brewfather-api-query.timer"
		elog ""
		elog "Systemd timer runs daily at 3:00 AM"
	fi
}
