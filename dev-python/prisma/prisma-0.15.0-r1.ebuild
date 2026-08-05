# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Prisma Client Python is an auto-generated and fully type-safe database client"
HOMEPAGE="https://github.com/RobertCraigie/prisma-client-py https://pypi.org/project/prisma/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

# Upstream archived the project on 2025-04-15, so this is carried locally.
# The generated types module is one TypedDict per field combination — ~71k
# classes for a 68-model schema. CPython 3.14 evaluates its forward references
# eagerly, taking ~220s to import where 3.13 takes ~11s. The template already
# supports the `annotations` flag that client.py.jinja and actions.py.jinja
# set; turning it on for types.py.jinja emits `from __future__ import
# annotations` and restores ~16s. Nothing in prisma introspects these
# annotations at runtime.
PATCHES=( "${FILESDIR}/${P}-py314-stringify-generated-types.patch" )

RDEPEND="
	>=dev-python/click-7.1.2[${PYTHON_USEDEP}]
	dev-python/httpx[${PYTHON_USEDEP}]
	>=dev-python/jinja2-2.11.2[${PYTHON_USEDEP}]
	dev-python/nodeenv[${PYTHON_USEDEP}]
	>=dev-python/pydantic-1.10.0[${PYTHON_USEDEP}]
	>=dev-python/python-dotenv-0.12.0[${PYTHON_USEDEP}]
	dev-python/tomlkit[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.5.0[${PYTHON_USEDEP}]
"
BDEPEND="
	test? ( ${RDEPEND} )
"

python_test() {
	cd "${T}" || die
	"${EPYTHON}" - <<-'PY' || die
		import importlib.metadata
		import pathlib

		import prisma

		assert importlib.metadata.version("prisma") == "0.15.0"
		assert prisma.__file__

		# `prisma generate` renders types.py from this template. The directive
		# must be the first statement of the output, so assert it precedes the
		# imports the shared header emits; a misplaced one is a SyntaxError at
		# generate time, which no build-time check would otherwise catch.
		templates = pathlib.Path(prisma.__file__).parent / "generator" / "templates"
		template = (templates / "types.py.jinja").read_text()
		assert template.startswith("{% set annotations = true %}\n"), template[:80]

		header = (templates / "_header.py.jinja").read_text().splitlines()
		emitted = [
		    line for line in header
		    if line.strip() and not line.lstrip().startswith(("#", "{%"))
		]
		assert emitted[0] == "from __future__ import annotations", emitted[:3]
		print("PASS: generated types.py stringifies its annotations")
	PY
}
