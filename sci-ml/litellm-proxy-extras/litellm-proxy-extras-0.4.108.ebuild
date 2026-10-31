# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=uv-build
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Prisma schema and database migrations for the LiteLLM proxy"
HOMEPAGE="https://github.com/BerriAI/litellm
	https://pypi.org/project/litellm-proxy-extras/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

# Prisma migrations still use the Python wrapper's CLI. psycopg is now required
# for migration locking and database checks. Gentoo builds its native backend
# against system libpq, replacing upstream's separate psycopg-binary wheel.
RDEPEND="
	>=dev-python/prisma-0.15.0[${PYTHON_USEDEP}]
	>=dev-python/psycopg-3.2[${PYTHON_USEDEP}]
	<dev-python/psycopg-4[${PYTHON_USEDEP}]
"
BDEPEND="test? ( ${RDEPEND} )"

python_test() {
	# Leave ${S}, otherwise sys.path[0] shadows the built copy with the source
	# tree and the migration payload below would never be verified.
	cd "${T}" || die
	local -x PYTHONPATH="${BUILD_DIR}/install$(python_get_sitedir):${PYTHONPATH}"

	"${EPYTHON}" - <<-'PY' || die
		import importlib.metadata
		import os

		import litellm_proxy_extras
		from litellm_proxy_extras.utils import ProxyExtrasDBManager, str_to_bool

		assert importlib.metadata.version("litellm-proxy-extras") == "0.4.108"

		# _get_prisma_dir() returns the installed package directory, which must
		# carry both the schema and the migration set the proxy applies.
		prisma_dir = ProxyExtrasDBManager._get_prisma_dir()
		assert os.path.isdir(prisma_dir), prisma_dir
		schema = os.path.join(prisma_dir, "schema.prisma")
		assert os.path.isfile(schema), schema
		assert "model LiteLLM_VerificationToken" in open(schema).read()

		# _get_migration_names() globs "<arg>/migrations/*/migration.sql",
		# so it takes the package directory, not the migrations directory.
		names = ProxyExtrasDBManager._get_migration_names(prisma_dir)
		assert len(names) == 213, len(names)
		assert "20250326162113_baseline" in names
		for name in names:
		    sql = os.path.join(prisma_dir, "migrations", name, "migration.sql")
		    assert os.path.isfile(sql), sql

		assert str_to_bool("yes") is True
		assert str_to_bool(None) is False
		print(f"PASS: schema.prisma and {len(names)} migrations at {prisma_dir}")
	PY
}
