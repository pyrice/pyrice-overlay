# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8

CRATES="
	aead@0.5.2
	aes-gcm@0.10.3
	aes@0.8.4
	allocator-api2@0.2.21
	android_system_properties@0.1.5
	anstream@1.0.0
	anstyle-parse@1.0.0
	anstyle-query@1.1.5
	anstyle-wincon@3.0.11
	anstyle@1.0.14
	anyhow@1.0.102
	atoi@2.0.0
	autocfg@1.5.0
	base64@0.21.7
	base64@0.22.1
	base64ct@1.8.3
	bitflags@1.3.2
	bitflags@2.11.0
	block-buffer@0.10.4
	bumpalo@3.20.2
	byteorder@1.5.0
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
	concurrent-queue@2.5.0
	const-oid@0.9.6
	core-foundation-sys@0.8.7
	core-foundation@0.10.1
	core-foundation@0.9.4
	cpufeatures@0.2.17
	crc-catalog@2.4.0
	crc@3.4.0
	crossbeam-queue@0.3.12
	crossbeam-utils@0.8.21
	crypto-common@0.1.7
	ctr@0.9.2
	der@0.7.10
	digest@0.10.7
	displaydoc@0.2.5
	dotenvy@0.15.7
	either@1.15.0
	encoding_rs@0.8.35
	equivalent@1.0.2
	errno@0.3.14
	etcetera@0.8.0
	event-listener@5.4.1
	fastrand@2.3.0
	find-msvc-tools@0.1.9
	flume@0.11.1
	fnv@1.0.7
	foldhash@0.1.5
	foreign-types-shared@0.1.1
	foreign-types@0.3.2
	form_urlencoded@1.2.2
	futures-channel@0.3.32
	futures-core@0.3.32
	futures-executor@0.3.32
	futures-intrusive@0.5.0
	futures-io@0.3.32
	futures-sink@0.3.32
	futures-task@0.3.32
	futures-util@0.3.32
	generic-array@0.14.7
	getrandom@0.2.17
	getrandom@0.4.2
	ghash@0.5.1
	h2@0.3.27
	hashbrown@0.15.5
	hashbrown@0.16.1
	hashlink@0.10.0
	heck@0.5.0
	hex@0.4.3
	hkdf@0.12.4
	hmac@0.12.1
	home@0.5.12
	http-body@0.4.6
	http@0.2.12
	httparse@1.10.1
	httpdate@1.0.3
	hyper-tls@0.5.0
	hyper@0.14.32
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
	is_terminal_polyfill@1.70.2
	itoa@1.0.18
	js-sys@0.3.91
	lazy_static@1.5.0
	leb128fmt@0.1.0
	libc@0.2.183
	libm@0.2.16
	libredox@0.1.14
	libsqlite3-sys@0.30.1
	linux-raw-sys@0.12.1
	litemap@0.8.1
	lock_api@0.4.14
	log@0.4.29
	md-5@0.10.6
	memchr@2.8.0
	mime@0.3.17
	mio@1.1.1
	native-tls@0.2.18
	num-bigint-dig@0.8.6
	num-integer@0.1.46
	num-iter@0.1.45
	num-traits@0.2.19
	once_cell@1.21.4
	once_cell_polyfill@1.70.2
	opaque-debug@0.3.1
	openssl-macros@0.1.1
	openssl-probe@0.2.1
	openssl-sys@0.9.112
	openssl@0.10.76
	parking@2.2.1
	parking_lot@0.12.5
	parking_lot_core@0.9.12
	pem-rfc7468@0.7.0
	percent-encoding@2.3.2
	pin-project-lite@0.2.17
	pkcs1@0.7.5
	pkcs8@0.10.2
	pkg-config@0.3.32
	plain@0.2.3
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
	redox_syscall@0.5.18
	redox_syscall@0.7.3
	reqwest@0.11.27
	ring@0.17.14
	rsa@0.9.10
	rustix@1.1.4
	rustls-pemfile@1.0.4
	rustls-pki-types@1.14.0
	rustls-webpki@0.103.10
	rustls@0.23.37
	rustversion@1.0.22
	ryu@1.0.23
	schannel@0.1.29
	scopeguard@1.2.0
	security-framework-sys@2.17.0
	security-framework@3.7.0
	semver@1.0.27
	serde-xml-rs@0.6.0
	serde@1.0.228
	serde_core@1.0.228
	serde_derive@1.0.228
	serde_json@1.0.149
	serde_spanned@0.6.9
	serde_urlencoded@0.7.1
	sha1@0.10.6
	sha2@0.10.9
	shlex@1.3.0
	signal-hook-registry@1.4.8
	signature@2.2.0
	slab@0.4.12
	smallvec@1.15.1
	socket2@0.5.10
	socket2@0.6.3
	spin@0.9.8
	spki@0.7.3
	sqlx-core@0.8.6
	sqlx-macros-core@0.8.6
	sqlx-macros@0.8.6
	sqlx-mysql@0.8.6
	sqlx-postgres@0.8.6
	sqlx-sqlite@0.8.6
	sqlx@0.8.6
	stable_deref_trait@1.2.1
	stringprep@0.1.5
	strsim@0.11.1
	subtle@2.6.1
	syn@2.0.117
	sync_wrapper@0.1.2
	synstructure@0.13.2
	system-configuration-sys@0.5.0
	system-configuration@0.5.1
	tempfile@3.27.0
	thiserror-impl@1.0.69
	thiserror-impl@2.0.18
	thiserror@1.0.69
	thiserror@2.0.18
	tinystr@0.8.2
	tinyvec@1.11.0
	tinyvec_macros@0.1.1
	tokio-macros@2.6.1
	tokio-native-tls@0.3.1
	tokio-stream@0.1.18
	tokio-util@0.7.18
	tokio@1.50.0
	toml@0.8.23
	toml_datetime@0.6.11
	toml_edit@0.22.27
	toml_write@0.1.2
	tower-service@0.3.3
	tracing-attributes@0.1.31
	tracing-core@0.1.36
	tracing@0.1.44
	try-lock@0.2.5
	typenum@1.19.0
	unicode-bidi@0.3.18
	unicode-ident@1.0.24
	unicode-normalization@0.1.25
	unicode-properties@0.1.4
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
	wasite@0.1.0
	wasm-bindgen-futures@0.4.64
	wasm-bindgen-macro-support@0.2.114
	wasm-bindgen-macro@0.2.114
	wasm-bindgen-shared@0.2.114
	wasm-bindgen@0.2.114
	wasm-encoder@0.244.0
	wasm-metadata@0.244.0
	wasmparser@0.244.0
	web-sys@0.3.91
	webpki-roots@0.26.11
	webpki-roots@1.0.6
	whoami@1.6.1
	windows-core@0.62.2
	windows-implement@0.60.2
	windows-interface@0.59.3
	windows-link@0.2.1
	windows-result@0.4.1
	windows-strings@0.5.1
	windows-sys@0.48.0
	windows-sys@0.52.0
	windows-sys@0.61.2
	windows-targets@0.48.5
	windows-targets@0.52.6
	windows_aarch64_gnullvm@0.48.5
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_msvc@0.48.5
	windows_aarch64_msvc@0.52.6
	windows_i686_gnu@0.48.5
	windows_i686_gnu@0.52.6
	windows_i686_gnullvm@0.52.6
	windows_i686_msvc@0.48.5
	windows_i686_msvc@0.52.6
	windows_x86_64_gnu@0.48.5
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnullvm@0.48.5
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_msvc@0.48.5
	windows_x86_64_msvc@0.52.6
	winnow@0.7.15
	winreg@0.50.0
	wit-bindgen-core@0.51.0
	wit-bindgen-rust-macro@0.51.0
	wit-bindgen-rust@0.51.0
	wit-bindgen@0.51.0
	wit-component@0.244.0
	wit-parser@0.244.0
	writeable@0.6.2
	xml-rs@0.8.28
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

DESCRIPTION="Fetches electricity prices and currency rates to PostgreSQL database"
HOMEPAGE="https://github.com/pyrice/reports"
EGIT_REPO_URI="git@github.com:pyrice/reports.git"
EGIT_COMMIT="v${PV/_/-}"

SRC_URI="${CARGO_CRATE_URIS}"

LICENSE="|| ( MIT Apache-2.0 )"
# Dependent crate licenses
LICENSE+=" Apache-2.0 BSD CDLA-Permissive-2.0 ISC MIT Unicode-3.0 ZLIB"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systemd"

DEPEND="dev-db/postgresql:*
	acct-group/reports
	acct-user/reports"
RDEPEND="${DEPEND}"

QA_FLAGS_IGNORED="usr/bin/reports"

src_unpack() {
	git-r3_src_unpack
	cargo_src_unpack
}

pkg_preinst() {
	enewgroup reports
	enewuser reports -1 -1 /var/lib/reports reports
}

src_install() {
	cargo_src_install
	keepdir /var/lib/reports
	fowners reports:reports /var/lib/reports
	keepdir /etc/reports
	fowners reports:reports /etc/reports
	insinto /etc/reports
	doins "${FILESDIR}/config.example.toml"
	if use systemd; then
		systemd_dounit "${FILESDIR}/reports.service"
		systemd_dounit "${FILESDIR}/reports.timer"
	fi
}

pkg_postinst() {
	if use systemd; then
		elog "To enable the daily reports service, run:"
		elog "  systemctl enable --now reports.timer"
	fi
	elog ""
	elog "Before starting the service, copy and edit the config file:"
	elog "  cp /etc/reports/config.example.toml /etc/reports/config.toml"
	elog "  nano /etc/reports/config.toml"
	elog "encrypt-password 'your_database_password'"
        elog "This will:- Generate a `.encryption_key` file (if it doesn't exist)"
        elog "Place your encrypted keyfile at /etc/reports/keyfile"
	elog "and ensure correct permissions:"
	elog "  chown root:reports /etc/reports/keyfile"
	elog "  chmod 640 /etc/reports/keyfile"
}
