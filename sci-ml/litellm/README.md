# LiteLLM Gentoo Service Guide

## Encrypted Database Credentials

To configure PostgreSQL database authentication for `litellm.service` using systemd encrypted credentials:

```bash
mkdir -p /etc/credstore.encrypted
echo -n "your_postgres_password" | systemd-creds encrypt --name=litellm.database-password - /etc/credstore.encrypted/litellm.database-password
chmod 0600 /etc/credstore.encrypted/litellm.database-password
```

## Prisma Database Setup

When using PostgreSQL with LiteLLM, generate the Prisma Python client once as root after package installation:

```bash
prisma generate --schema /usr/lib/python3.14/site-packages/litellm/proxy/schema.prisma
```

## Service Management

### Build validation prerequisite (owner root shell)

The 1.105.1 bump needs maturin 1.15.0, Hugging Face Hub, HTTPX2, SoundFile and
OpenTelemetry API. The following prerequisite block accepts only exact versions
and installs **central Gentoo dependencies**, not the untested LiteLLM bump or
its new MCP overlay dependencies. MCP 2.3.0, mcp-types 2.3.0 and sse-starlette
3.4.4 are keyworded here but only built into sandbox images by the normal-user
gate. They are not installed live before validation. After this completes, run
`scripts/test_litellm.sh` again as the ordinary owner account, without
`SKIP_DEP_GATES`. It is safe to repeat this block; existing pins are preserved.

```bash
(
    set -euo pipefail
    source /home/kent/workspace/ebuilds/scripts/lib_litellm_prerequisites.sh
    litellm_prepare_keywords /etc/portage/package.accept_keywords/litellm
    emerge --noreplace --oneshot "${LITELLM_BUILD_PREREQUISITES[@]}"
)
```

### Default database and local override repair (after the full gate passes)

The default service connects to PostgreSQL on `127.0.0.1:5432` and requires
`postgresql-18.service`. The ebuild therefore has a runtime dependency on
`dev-db/postgresql:18[server,systemd?]`; the standard profile `systemd` USE flag
requires PostgreSQL's unit on systemd hosts without breaking OpenRC profiles.
PostgreSQL is not a build tool or a linked
library of LiteLLM. Installing the dependency does not initialize a cluster,
migrate data from older PostgreSQL majors, or create the LiteLLM database/role.
Prepare those separately before starting the proxy.

When upgrading from older packaging, remove obsolete `After=postgresql-17.service`
and `Requires=postgresql-17.service` lines from
`/etc/systemd/system/litellm.service.d/10-local.conf` after installing the new
revision. Relationships in drop-ins are additive: the new packaged unit cannot
cancel those old requirements. Preserve the Prisma engine and environment-file
settings, then run `systemctl daemon-reload` before restarting LiteLLM. The root
preparation script now inherits database relationships from the packaged unit
rather than maintaining a second PostgreSQL version.

On the already initialized ICEBEARGentoo host, after the package gate and review
pass, run this block in the owner's root shell. It saves and checks a private
database backup before upgrading, backs up the existing local override, removes
only the two obsolete PostgreSQL 17 directives, and keeps engine/key settings.
Do not rerun the broad first-time root preparation just for this repair. The
readiness probe allows up to 30 minutes for migrations; follow startup from
another terminal with `journalctl -u litellm.service -f`.

```bash
(
    set -euo pipefail
    umask 077
    systemctl is-active postgresql-18.service
    install -d -m 0700 /root/litellm-backups
    backup=$(mktemp /root/litellm-backups/pre-1.105.1-XXXXXX.dump)
    runuser -u postgres -- pg_dump --host=/run/postgresql --port=5432 --format=custom \
        --no-password --dbname=litellm > "${backup}"
    pg_restore --list "${backup}" >/dev/null
    printf 'PASS: database backup verified: %s\n' "${backup}"
    # Generated Python client files must remain readable by DynamicUser.
    umask 022
    emerge --oneshot =sci-ml/litellm-1.105.1
    prisma generate --schema /usr/lib/python3.14/site-packages/litellm/proxy/schema.prisma
    python3.14 -m compileall -q /usr/lib/python3.14/site-packages/prisma
    dropin=/etc/systemd/system/litellm.service.d/10-local.conf
    if [[ -f ${dropin} ]]; then
        cp -a -- "${dropin}" "${dropin}.before-pg18.$(date +%Y%m%dT%H%M%S%N)"
        sed -i -e '/^After=postgresql-17\.service$/d' \
            -e '/^Requires=postgresql-17\.service$/d' "${dropin}"
    fi
    systemctl daemon-reload
    relationships=$(systemctl show litellm.service -p After -p Requires)
    printf '%s\n' "${relationships}"
    if [[ ${relationships} == *postgresql-17.service* ]]; then
        printf 'ERROR: another local override still requires PostgreSQL 17.\n' >&2
        exit 1
    fi
    systemctl is-active postgresql-18.service
    systemctl reset-failed litellm.service
    systemctl restart litellm.service
    systemctl --no-pager --full status litellm.service
    readiness=$(curl --fail --silent --show-error --max-time 10 \
        --retry 180 --retry-delay 10 --retry-max-time 1800 \
        --retry-connrefused --retry-all-errors \
        http://127.0.0.1:4000/health/readiness)
    printf '%s\n' "${readiness}"
    python3.14 -c 'import json,sys; result=json.load(sys.stdin); sys.exit(0 if result.get("status") == "healthy" and result.get("db") == "connected" else 1)' <<< "${readiness}"
    unfinished=$(runuser -u postgres -- psql --host=/run/postgresql --port=5432 \
        --no-password --dbname=litellm --no-psqlrc --set=ON_ERROR_STOP=1 --tuples-only --no-align \
        --command='SELECT count(*) FROM "_prisma_migrations" WHERE finished_at IS NULL AND rolled_back_at IS NULL;')
    [[ ${unfinished} == 0 ]]
    printf 'PASS: proxy ready, database connected, no unfinished migrations\n'
)
```

A successful `systemctl restart` for this `Type=simple` unit does not prove
application or database readiness. The block therefore also requires the public
readiness response to report `db=connected` and checks for unfinished migrations.
If the backup cannot authenticate over the local PostgreSQL socket, the block
stops before any upgrade; resolve database access rather than skipping the backup.

The systemd unit uses `DynamicUser=yes`, `LogsDirectory=litellm`, and `ConfigurationDirectory=litellm`.

1. Edit configuration in `/etc/litellm/config.yaml`.
2. Enable and start the service:

```bash
systemctl enable --now litellm.service
```

## Prisma CLI for database migrations

`prisma migrate deploy` runs the Prisma CLI, which normally npm-installs itself
below `$HOME` on first use. The service runs with `DynamicUser=yes`, which
leaves `$HOME` at `/` — unwritable under `ProtectSystem=strict`. Pointing the
cache at a `CacheDirectory=` does not help either: the resolved path sits below
`/var/cache/private`, which the dynamic user cannot traverse, so spawning the
schema engine fails with `EACCES` and every migration aborts. The proxy reports
this only as `Database migration failed but continuing startup`.

The unit therefore sets `PRISMA_BINARY_CACHE_DIR=/usr/libexec/prisma/cli`.
Prisma performs no writes once that directory, its `package.json` and its
entrypoint all exist, so a root-owned read-only copy works. Populate it once as
root:

```bash
install -d -m 0755 /usr/libexec/prisma/cli
HOME=/root PRISMA_BINARY_CACHE_DIR=/usr/libexec/prisma/cli prisma --version
```

Verify afterwards that no migration errors remain:

```bash
psql -U litellm -d litellm -c 'select count(*) from "_prisma_migrations";'
```

## First start against a pre-existing database

If the database already has litellm's tables but no `_prisma_migrations` table
— the state left by an earlier `prisma db push` — `prisma migrate deploy` fails
with `P3005` and litellm baselines the database instead. Baselining marks the
shipped migrations as applied without running them, which is correct only when
the existing schema really was created from the same `schema.prisma`.

That first start resolves every migration in turn, each spawning its own Node
process, so it takes roughly 30 minutes for ~140 migrations and the proxy does
not listen until it finishes. Do not interrupt it. Subsequent starts find the
history recorded and complete in seconds.
