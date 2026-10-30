# llama.cpp 0.7.0 packaging

## Current status

**Full non-root package gate passed on 2026-10-17, exit 0.** Both owner-added
exact keyword pins were verified before the run. Independent Ren review is the
remaining pre-upgrade handoff; the parent session must arrange it. No live
packages or services changed, and no commit/push is authorized.

GitHub's latest non-prerelease release is `v0.7.0`, published 2026-10-15,
verified on 2026-10-17. Tag commit:
`757cad021b357f417065ddbc41a6e8f87c1f8136`.

- Release: <https://github.com/ggml-org/llama.cpp/releases/tag/v0.7.0>
- Release metadata: <https://api.github.com/repos/ggml-org/llama.cpp/releases/latest>
- Gentoo packaging API: `/var/db/repos/gentoo/eclass/cmake.eclass`

Upstream now publishes semantic-version stable releases instead of only numbered
`bNNNNN` snapshots. Its CMake project reports 0.7.0 and its bundled GGML reports
0.27.0. Use the compatible system library rather than installing colliding GGML
libraries/headers from llama.cpp.

## Compatibility and deliberate differences

Installed on this host: llama-cpp `0_pre10034-r2` and GGML `0.18.0`, both from
pyrice-overlay, with `openmp vulkan`; llama-cpp also has `server` enabled.
Gentoo already provides GGML `0.27.0`, including the host's OpenMP/Vulkan backends.
The new ebuild forwards `cuda`, `rocm`, `openmp`, and `vulkan` to that provider.

**The new release does not advertise the old custom GGML provider's `sycl`,
`rpc`, BLAS-provider, or `opencl` flags.** The compatible central provider does
not implement them; advertising these flags would produce unsatisfiable USE
dependencies or silently omit the backend. Hosts requiring those features must
retain the old ebuild/provider until a compatible provider is packaged. The old
version is retained; no multi-host package retirement is implied.

All GPU compilation belongs to GGML. The new llama-cpp ebuild therefore has no
fake SYCL compiler wrappers or redundant GPU toolchain dependencies. The CLI
shares upstream's server build switch, so server internals are built for the CLI
and the server executable is removed when `USE=-server`. HTTPS follows `server`
as in the previous package. Embedded Web UI build and prebuilt downloads are
disabled explicitly: the HTTP API/CLI remain available, but no Web UI is shipped.

## Completed owner keyword prerequisite

Both pins below are already present on this host. This idempotent block remains
as a reference for another host; there is no need to rerun it here. It only
appends missing exact keyword pins, without installing packages or altering
existing entries.

```bash
set -e
for spec in 'sci-ml/llama-cpp 0.7.0' 'sci-ml/ggml 0.27.0'; do
    read -r package version <<< "${spec}"
    file="/etc/portage/package.accept_keywords/${package#*/}"
    pin="=${package}-${version} ~amd64"
    if ! grep -Fqx -- "${pin}" "${file}" 2>/dev/null; then
        printf '\n%s\n' "${pin}" >> "${file}"
    fi
done
```

Do not install GGML separately as a prerequisite: its changed subslot conflicts
with installed llama-cpp's recorded dependency. Do not use flags that bypass
that protection. The test script builds the central GGML ebuild into its normal
non-root sandbox image and points llama-cpp's CMake and runtime loader at that
image. Gentoo's source ebuild and Manifest are read-only. The final resolver plan
upgrades both packages together, without a live merge during testing.

To repeat the package gate, run as the ordinary owner account, not root:

```bash
set -o pipefail
bash /home/kent/workspace/ebuilds/scripts/test_llama-cpp.sh \
    2>&1 | tee /tmp/opencode/llama-cpp-full-gate.log
```

Do not run this concurrently with another package build. The script prints its
per-phase log directory at startup. It first checks both keyword pins, manifests
and checks llama-cpp, resolves the entire upgrade, and verifies all other build
prerequisites are installed. Only then does it build GGML followed by llama-cpp.
It verifies staged library version, CLI/bench/header/shared-library payload,
absence of bundled GGML, server flag behavior, CLI version/device enumeration,
and final dependency resolution. No model inference or service restart is part
of this package gate.

## Validation evidence

- Four release/harness contract tests failed before implementation. A fifth
  test failed before adding explicit unsupported-backend rejection. All five
  now pass. Red logs: `/tmp/opencode/llama-cpp-contract-red.log` and
  `/tmp/opencode/llama-cpp-use-validation-red.log`.
- Shell syntax passes for the ebuild and gate script.
- Both README shell blocks parse; the keyword block preserves existing bytes
  (including an unterminated final line) and is byte-for-byte repeat-run idempotent.
- Diagnostic deployment/Manifest and pkgcheck pass as an ordinary user. Reviewed
  warnings apply only to retained `0_pre10034-r2`: `MissingUseDepDefault` for its
  obsolete `intel-compute-runtime[l0]` dependency, and `RedundantVersion`.
- Diagnostic resolver selects exactly GGML 0.27.0 and llama-cpp 0.7.0. Only their
  two exact keyword accepts are requested. An unrelated installed NTP mask is
  informational, not a dependency in this upgrade.
- Executing the gate's real Python prerequisite probe confirms all six
  DEPEND/BDEPEND/RDEPEND sets, excluding the explicitly staged GGML dependency,
  are already installed. Portage's real API requires `trees=portage.db`; the
  initial diagnostic probe exposed that and it was corrected before any build.
- The earlier full gate stopped at absent keyword pins. After the owner added
  them, the complete normal-user gate passed all phases without skips:
  GGML fetch/unpack/prepare/configure/compile/install/image/version, followed by
  llama-cpp manifest/pkgcheck/fetch/unpack/prepare/configure/compile/install/
  image/pretend. Master log: `/tmp/opencode/llama-cpp-full-gate.log`, ending with
  `GATE_EXIT_STATUS=0`. Phase logs: `/tmp/opencode/llama-cpp-test-Jv4SVh/`.
- The real CMake cache selects the staged GGML configuration. Runtime ldd
  resolves ggml, ggml-base, ggml-cpu, and ggml-vulkan to the GGML image. No
  sandbox RPATH/RUNPATH exists in the 27 installed ELF files; installed CMake/
  pkg-config metadata also has no sandbox paths.
- Image CLI and server both report `version: 0.7.0 (build 0, commit unknown)`.
  CLI enumerates `Vulkan0: Intel(R) Arc(tm) B580 Graphics (BMG G21)`.
  No compiler warnings/errors were found in either package's full logs.
  Expected upstream CMake warnings are the missing Git checkout metadata
  (release archive) and deliberately absent embedded UI assets.
- Final ordinary pretend exits zero and selects exactly GGML 0.27.0 and
  llama-cpp 0.7.0, without further keyword requests. The unrelated installed
  NTP mask is informational. Nothing was installed into the live filesystem.
- All three README shell blocks parse, and the exact provider-qualified atoms
  in the live-upgrade block resolve together (exit 0;
  `/tmp/opencode/llama-cpp-live-block-pretend.log`). The existing unchanged
  service's port 8091 health endpoint responds `{"status":"ok"}`.
- Nested Ren delegation was rejected by the runtime's subagent-depth limit;
  the parent session must arrange the independent review. No review approval
  is implied by the successful package gate.

## Owner live upgrade after independent review

The real inference service is the **kent user unit** `llama-server.service`,
not a system service. It runs `~/workspace/local-llm/serve.sh` in router mode
on port 8091. All eight service options were confirmed in the new server's
actual `--help`. The unit file is unchanged, so no daemon-reload is needed.

The owner can run the following single block in the root shell after Ren review.
It stops the router before changing its shared libraries, merges the two exact
packages together, then starts the same user service and checks HTTP health.
**If emerge fails, this block leaves the service stopped:** resolve the package
failure before restarting against potentially mixed libraries. No agent has
executed this block.

```bash
bash <<'ROOT'
set -euo pipefail
owner_uid=$(id -u kent)
owner_service() {
    runuser -u kent -- env \
        XDG_RUNTIME_DIR="/run/user/${owner_uid}" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${owner_uid}/bus" \
        systemctl --user "$@"
}
owner_service stop llama-server.service
emerge --oneshot --verbose \
    '=sci-ml/ggml-0.27.0::gentoo' \
    '=sci-ml/llama-cpp-0.7.0::pyrice-overlay'
owner_service start llama-server.service
owner_service --no-pager --full status llama-server.service
curl --fail --show-error --retry 15 --retry-connrefused \
    --retry-delay 2 --max-time 5 http://127.0.0.1:8091/health
ROOT
```

HTTP health and device enumeration are not model-inference validation. After
the merge, send a representative request through the normal local-LLM client
and check the user journal if the router or a child model server fails. Existing
presets and model configuration are not changed by this package update.
