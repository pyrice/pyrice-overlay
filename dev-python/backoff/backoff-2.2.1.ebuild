# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Function decoration for backoff and retry"
HOMEPAGE="https://github.com/litl/backoff https://pypi.org/project/backoff/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

python_test() {
	"${EPYTHON}" - <<-'PY' || die
		import backoff
		calls = 0
		@backoff.on_exception(backoff.constant, ValueError, max_tries=2, interval=0)
		def eventually():
		    global calls
		    calls += 1
		    if calls == 1:
		        raise ValueError
		    return "ok"
		assert eventually() == "ok" and calls == 2
	PY
}
