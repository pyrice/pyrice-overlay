# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

IUSE="cuda"

inherit acct-user

ACCT_USER_ID=495
ACCT_USER_HOME=/var/lib/ollama
ACCT_USER_GROUPS=( ollama )
ACCT_USER_SHELL=/sbin/nologin
ACCT_USER_COMMENT="Ollama service account"

acct-user_add_deps

pkg_preinst() {
	use cuda && ACCT_USER_GROUPS+=( video )
	acct-user_pkg_preinst
}
