# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Meta package for the OpenVINO runtime stack"
# Not a github-hosted project of its own (it ships no sources), so HOMEPAGE points
# at the OpenVINO documentation rather than upstream's repo.
HOMEPAGE="https://docs.openvino.ai/"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+genai"

# Pure aggregate: worlding this one package keeps the whole OpenVINO stack from
# being --depclean'd. openvino is the runtime; genai (which itself pulls in
# openvino-tokenizers) is the optional GGUF/LLMPipeline layer. Feature flags of
# the members (intel-gpu, python, ...) stay configured on the members themselves.
RDEPEND="
	~sci-ml/openvino-${PV}
	genai? ( ~sci-ml/openvino-genai-${PV}.0 )
"
