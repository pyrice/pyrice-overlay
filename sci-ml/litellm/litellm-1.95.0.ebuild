# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=maturin
DISTUTILS_SINGLE_IMPL=1
PYTHON_COMPAT=( python3_{12..14} )
RUST_MIN_VER="1.88.0"

CRATES="
	arc-swap@1.9.2
	async-trait@0.1.91
	atomic-waker@1.1.2
	autocfg@1.5.1
	aws-config@1.9.0
	aws-credential-types@1.3.0
	aws-lc-rs@1.17.3
	aws-lc-sys@0.43.0
	aws-runtime@1.8.1
	aws-sdk-sts@1.108.0
	aws-sigv4@1.5.1
	aws-smithy-async@1.3.0
	aws-smithy-http-client@1.2.0
	aws-smithy-http@0.64.0
	aws-smithy-json@0.63.0
	aws-smithy-observability@0.3.0
	aws-smithy-query@0.61.1
	aws-smithy-runtime-api-macros@1.1.0
	aws-smithy-runtime-api@1.13.0
	aws-smithy-runtime@1.12.0
	aws-smithy-schema@0.2.0
	aws-smithy-types@1.6.1
	aws-smithy-xml@0.61.1
	aws-types@1.4.0
	axum-core@0.4.5
	axum@0.7.9
	base64-simd@0.8.0
	base64@0.22.1
	bitflags@2.13.1
	block-buffer@0.10.4
	block-buffer@0.12.1
	bumpalo@3.20.3
	byteorder@1.5.0
	bytes-utils@0.1.4
	bytes@1.12.1
	cc@1.3.0
	cfg-if@1.0.4
	cfg_aliases@0.2.2
	chacha20@0.10.1
	cmake@0.1.58
	cmov@0.5.4
	const-oid@0.10.2
	core-foundation-sys@0.8.7
	core-foundation@0.10.1
	cpufeatures@0.2.17
	cpufeatures@0.3.0
	crypto-common@0.1.7
	crypto-common@0.2.2
	ctutils@0.4.2
	data-encoding@2.11.0
	deranged@0.5.8
	digest@0.10.7
	digest@0.11.3
	displaydoc@0.2.6
	dunce@1.0.5
	either@1.16.0
	equivalent@1.0.2
	fastrand@2.5.0
	find-msvc-tools@0.1.9
	fnv@1.0.7
	form_urlencoded@1.2.2
	fs_extra@1.3.0
	futures-channel@0.3.33
	futures-core@0.3.33
	futures-io@0.3.33
	futures-macro@0.3.33
	futures-sink@0.3.33
	futures-task@0.3.33
	futures-util@0.3.33
	generic-array@0.14.7
	getrandom@0.2.17
	getrandom@0.4.3
	h2@0.3.27
	h2@0.4.15
	hashbrown@0.17.1
	heck@0.5.0
	hex@0.4.3
	hmac@0.13.0
	http-body-util@0.1.4
	http-body@0.4.6
	http-body@1.1.0
	http@0.2.12
	http@1.4.2
	httparse@1.10.1
	httpdate@1.0.3
	hybrid-array@0.4.13
	hyper-rustls@0.24.2
	hyper-rustls@0.27.9
	hyper-util@0.1.20
	hyper@0.14.32
	hyper@1.10.1
	icu_collections@2.2.0
	icu_locale_core@2.2.0
	icu_normalizer@2.2.0
	icu_normalizer_data@2.2.0
	icu_properties@2.2.0
	icu_properties_data@2.2.0
	icu_provider@2.2.0
	idna@1.1.0
	idna_adapter@1.2.2
	indexmap@2.14.0
	ipnet@2.12.0
	itoa@1.0.18
	jobserver@0.1.35
	js-sys@0.3.103
	libc@0.2.186
	litemap@0.8.2
	log@0.4.33
	lru-slab@0.1.2
	matchit@0.7.3
	memchr@2.8.3
	mime@0.3.17
	mio@1.2.2
	num-conv@0.2.2
	num-integer@0.1.46
	num-traits@0.2.19
	once_cell@1.21.4
	openssl-probe@0.2.1
	outref@0.5.2
	percent-encoding@2.3.2
	pin-project-lite@0.2.17
	pin-utils@0.1.0
	pkg-config@0.3.33
	portable-atomic@1.14.0
	potential_utf@0.1.5
	powerfmt@0.2.0
	ppv-lite86@0.2.21
	proc-macro2@1.0.107
	pyo3-async-runtimes@0.29.0
	pyo3-build-config@0.29.0
	pyo3-ffi@0.29.0
	pyo3-macros-backend@0.29.0
	pyo3-macros@0.29.0
	pyo3@0.29.0
	quinn-proto@0.11.16
	quinn-udp@0.5.15
	quinn@0.11.11
	quote@1.0.47
	r-efi@6.0.0
	rand@0.10.2
	rand@0.8.7
	rand_chacha@0.3.1
	rand_core@0.10.1
	rand_core@0.6.4
	rand_pcg@0.10.2
	regex-lite@0.1.9
	reqwest@0.12.28
	ring@0.17.14
	rustc-hash@2.1.3
	rustc_version@0.4.1
	rustls-native-certs@0.8.4
	rustls-pki-types@1.15.0
	rustls-webpki@0.101.7
	rustls-webpki@0.103.13
	rustls@0.21.12
	rustls@0.23.42
	rustversion@1.0.23
	ryu@1.0.23
	schannel@0.1.29
	sct@0.7.1
	security-framework-sys@2.17.0
	security-framework@3.7.0
	semver@1.0.28
	serde@1.0.229
	serde_core@1.0.229
	serde_derive@1.0.229
	serde_json@1.0.150
	serde_path_to_error@0.1.20
	serde_urlencoded@0.7.1
	sha1@0.10.7
	sha2@0.10.9
	sha2@0.11.0
	shlex@2.0.1
	slab@0.4.12
	smallvec@1.15.2
	socket2@0.5.10
	socket2@0.6.5
	stable_deref_trait@1.2.1
	subtle@2.6.1
	syn@2.0.119
	syn@3.0.0
	sync_wrapper@1.0.2
	synstructure@0.13.2
	target-lexicon@0.13.5
	thiserror-impl@1.0.69
	thiserror-impl@2.0.19
	thiserror@1.0.69
	thiserror@2.0.19
	time-core@0.1.9
	time-macros@0.2.31
	time@0.3.53
	tinystr@0.8.3
	tinyvec@1.12.0
	tinyvec_macros@0.1.1
	tokio-macros@2.7.1
	tokio-rustls@0.24.1
	tokio-rustls@0.26.4
	tokio-tungstenite@0.24.0
	tokio-util@0.7.18
	tokio@1.53.0
	tower-http@0.6.11
	tower-layer@0.3.3
	tower-service@0.3.3
	tower@0.5.3
	tracing-attributes@0.1.31
	tracing-core@0.1.36
	tracing@0.1.44
	try-lock@0.2.5
	tungstenite@0.24.0
	typenum@1.20.1
	unicode-ident@1.0.24
	untrusted@0.9.0
	url@2.5.8
	urlencoding@2.1.3
	utf-8@0.7.6
	utf8_iter@1.0.4
	uuid@1.24.0
	version_check@0.9.5
	vsimd@0.8.0
	want@0.3.1
	wasi@0.11.1+wasi-snapshot-preview1
	wasm-bindgen-futures@0.4.76
	wasm-bindgen-macro-support@0.2.126
	wasm-bindgen-macro@0.2.126
	wasm-bindgen-shared@0.2.126
	wasm-bindgen@0.2.126
	wasm-streams@0.4.2
	web-sys@0.3.103
	web-time@1.1.0
	webpki-roots@1.0.9
	windows-link@0.2.1
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
	writeable@0.6.3
	xmlparser@0.13.6
	yoke-derive@0.8.2
	yoke@0.8.3
	zerocopy-derive@0.8.54
	zerocopy@0.8.54
	zerofrom-derive@0.1.7
	zerofrom@0.1.8
	zeroize@1.9.0
	zerotrie@0.2.4
	zerovec-derive@0.11.3
	zerovec@0.11.6
	zmij@1.0.23
"

inherit cargo distutils-r1 pypi systemd

DESCRIPTION="Library to interface with multiple LLM API providers"
HOMEPAGE="https://github.com/BerriAI/litellm https://pypi.org/project/litellm/"
SRC_URI+=" ${CARGO_CRATE_URIS}"

LICENSE="MIT Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD CDLA-Permissive-2.0 ISC Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

PATCHES=( "${FILESDIR}/${P}-optional-sso.patch" )

# Gentoo compatibility waivers tested by python_test(): cryptography-49.0.0
# (upstream <49), importlib-metadata-9.0.0 (<9), rich-15.0.0 (<14), and
# websockets-16.0 (<16). Portage retains upstream floors without overpinning.
RDEPEND="
	$(python_gen_cond_dep '
		>=dev-python/aiohttp-3.10.0[${PYTHON_USEDEP}]
		<dev-python/aiohttp-4[${PYTHON_USEDEP}]
		>=dev-python/click-8.0.0[${PYTHON_USEDEP}]
		<dev-python/click-9[${PYTHON_USEDEP}]
		>=dev-python/fastuuid-0.14.0[${PYTHON_USEDEP}]
		<dev-python/fastuuid-1[${PYTHON_USEDEP}]
		dev-python/httpx[${PYTHON_USEDEP}]
		>=dev-python/importlib-metadata-8.0.0[${PYTHON_USEDEP}]
		>=dev-python/jinja2-3.1.6[${PYTHON_USEDEP}]
		<dev-python/jinja2-4[${PYTHON_USEDEP}]
		>=dev-python/jsonschema-4.0.0[${PYTHON_USEDEP}]
		<dev-python/jsonschema-5[${PYTHON_USEDEP}]
		>=dev-python/openai-2.20.0[${PYTHON_USEDEP}]
		<dev-python/openai-3[${PYTHON_USEDEP}]
		>=dev-python/pydantic-2.10.0[${PYTHON_USEDEP}]
		<dev-python/pydantic-3[${PYTHON_USEDEP}]
		>=dev-python/python-dotenv-1.0.0[${PYTHON_USEDEP}]
		<dev-python/python-dotenv-2[${PYTHON_USEDEP}]
		>=dev-python/tiktoken-0.8.0[${PYTHON_USEDEP}]
		<dev-python/tiktoken-1[${PYTHON_USEDEP}]
		>=dev-python/apscheduler-3.11.2[${PYTHON_USEDEP}]
		<dev-python/apscheduler-4[${PYTHON_USEDEP}]
		>=dev-python/backoff-2.2.1[${PYTHON_USEDEP}]
		<dev-python/backoff-3[${PYTHON_USEDEP}]
		>=dev-python/boto3-1.43.1[${PYTHON_USEDEP}]
		<dev-python/boto3-2[${PYTHON_USEDEP}]
		>=dev-python/cryptography-48.0.1[${PYTHON_USEDEP}]
		~dev-python/fastapi-0.136.3[${PYTHON_USEDEP}]
		>=dev-python/inquirerpy-0.3.4[${PYTHON_USEDEP}]
		<dev-python/inquirerpy-1[${PYTHON_USEDEP}]
		dev-python/orjson[${PYTHON_USEDEP}]
		>=dev-python/pydantic-settings-2.14.1[${PYTHON_USEDEP}]
		<dev-python/pydantic-settings-3[${PYTHON_USEDEP}]
		>=dev-python/pyjwt-2.13.0[${PYTHON_USEDEP}]
		<dev-python/pyjwt-3[${PYTHON_USEDEP}]
		>=dev-python/python-multipart-0.0.27[${PYTHON_USEDEP}]
		<dev-python/python-multipart-1[${PYTHON_USEDEP}]
		>=dev-python/pyyaml-6.0.3[${PYTHON_USEDEP}]
		<dev-python/pyyaml-7[${PYTHON_USEDEP}]
		>=dev-python/email-validator-2.0.0[${PYTHON_USEDEP}]
		>=dev-python/expression-5.6.0[${PYTHON_USEDEP}]
		<dev-python/expression-6[${PYTHON_USEDEP}]
		>=dev-python/redis-7.4.1[${PYTHON_USEDEP}]
		>=dev-python/requests-2.32.0[${PYTHON_USEDEP}]
		<dev-python/requests-3[${PYTHON_USEDEP}]
		>=dev-python/rich-13.9.4[${PYTHON_USEDEP}]
		>=dev-python/starlette-1.0.1[${PYTHON_USEDEP}]
		<dev-python/starlette-2[${PYTHON_USEDEP}]
		>=dev-python/uvicorn-0.33.0[${PYTHON_USEDEP}]
		<dev-python/uvicorn-1[${PYTHON_USEDEP}]
		>=dev-python/uvloop-0.21.0[${PYTHON_USEDEP}]
		<dev-python/uvloop-1[${PYTHON_USEDEP}]
		>=dev-python/websockets-15.0.1[${PYTHON_USEDEP}]
	')
	>=sci-ml/tokenizers-0.21.0[${PYTHON_SINGLE_USEDEP}]
	<sci-ml/tokenizers-1[${PYTHON_SINGLE_USEDEP}]
"
BDEPEND="
	$(python_gen_cond_dep '=dev-util/maturin-1.9.4-r0[${PYTHON_USEDEP}]')
	test? ( ${RDEPEND} )
"

QA_FLAGS_IGNORED="usr/lib.*/py.*/site-packages/litellm/rust_bridge/_native.*\.so"

src_unpack() {
	cargo_src_unpack
}

pkg_setup() {
	python-single-r1_pkg_setup
	rust_pkg_setup
}

src_configure() {
	cargo_src_configure
	distutils-r1_src_configure
}

python_test() {
	cd "${T}" || die
	local -x LITELLM_LOCAL_MODEL_COST_MAP=True
	local -x LITELLM_TELEMETRY=False
	local -x PATH="${BUILD_DIR}/install/usr/bin:${PATH}"
	local command
	for command in litellm lite litellm-proxy; do
		"${command}" --help >/dev/null || die "${command} --help failed"
	done

	"${EPYTHON}" - <<-'PY' || die
		import importlib.metadata
		import os
		import socket
		import subprocess
		import time
		import urllib.request

		import litellm
		from litellm.rust_bridge import _native

		assert importlib.metadata.version("litellm") == "1.95.0"
		compat_versions = {
		    "cryptography": "49.0.0",
		    "importlib-metadata": "9.0.0",
		    "rich": "15.0.0",
		    "websockets": "16.0",
		}
		for package, expected in compat_versions.items():
		    actual = importlib.metadata.version(package)
		    assert actual == expected, f"{package}: expected {expected}, got {actual}"
		print(f"PASS: Gentoo compatibility versions {compat_versions}")
		assert litellm.__file__ and _native.__file__
		router = litellm.Router(
		    model_list=[{
		        "model_name": "local-test",
		        "litellm_params": {
		            "model": "openai/gpt-4o-mini",
		            "api_key": "not-used",
		        },
		    }]
		)
		assert router.get_model_list()[0]["model_name"] == "local-test"

		with socket.socket() as sock:
		    sock.bind(("127.0.0.1", 0))
		    port = sock.getsockname()[1]
		env = os.environ.copy()
		env.update({
		    "LITELLM_LOCAL_MODEL_COST_MAP": "True",
		    "LITELLM_TELEMETRY": "False",
		})
		process = subprocess.Popen(
		    [
		        "litellm", "--host", "127.0.0.1", "--port", str(port),
		        "--telemetry", "False",
		    ],
		    stdout=subprocess.PIPE,
		    stderr=subprocess.STDOUT,
		    text=True,
		    env=env,
		)
		try:
		    deadline = time.monotonic() + 30
		    while time.monotonic() < deadline:
		        if process.poll() is not None:
		            break
		        try:
		            with urllib.request.urlopen(
		                f"http://127.0.0.1:{port}/health/liveliness", timeout=1
		            ) as response:
		                assert response.status == 200
		                assert b"alive" in response.read()
		                break
		        except OSError:
		            time.sleep(0.25)
		    else:
		        raise AssertionError("proxy did not become healthy")
		    if process.poll() is not None:
		        raise AssertionError(process.stdout.read())
		finally:
		    process.terminate()
		    try:
		        output, _ = process.communicate(timeout=15)
		    except subprocess.TimeoutExpired:
		        process.kill()
		        output, _ = process.communicate()
		assert "Application startup complete" in output
		print("PASS: core, routing, entrypoints, proxy health, clean shutdown")
	PY
}

python_install_all() {
	distutils-r1_python_install_all

	exeinto /usr/libexec
	newexe "${FILESDIR}"/litellm-start.sh litellm-start

	systemd_dounit "${FILESDIR}"/litellm.service

	insinto /etc/litellm
	newins "${FILESDIR}"/config.yaml.example config.yaml
}
