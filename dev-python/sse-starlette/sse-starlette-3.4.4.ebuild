# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..15} )

inherit distutils-r1 pypi

DESCRIPTION="Server-Sent Events for Starlette and FastAPI"
HOMEPAGE="https://github.com/sysid/sse-starlette/ https://pypi.org/project/sse-starlette/"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-python/anyio-4.7.0[${PYTHON_USEDEP}]
	>=dev-python/starlette-0.49.1[${PYTHON_USEDEP}]
"
BDEPEND="test? ( ${RDEPEND} )"

python_test() {
	# Offline ASGI response contract; no listening socket or remote services.
	"${EPYTHON}" - <<-'PY' || die
		import asyncio
		from sse_starlette.sse import EventSourceResponse
		from sse_starlette.event import ServerSentEvent

		async def check():
		    async def events():
		        yield {"data": "packaging smoke test"}
		    response = EventSourceResponse(events())
		    assert response.headers["content-type"].startswith("text/event-stream")
		    assert [event async for event in response.body_iterator] == [
		        {"data": "packaging smoke test"}
		    ]
		    assert ServerSentEvent(data="hello", event="test").encode() == (
		        b"event: test\r\ndata: hello\r\n\r\n"
		    )
		asyncio.run(check())
		print("PASS: SSE asynchronous response and event framing")
	PY
}
