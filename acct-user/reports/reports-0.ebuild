# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8

inherit acct-user

ACCT_USER_ID=490
ACCT_USER_GROUP="reports"
ACCT_USER_HOME="/var/lib/reports"
ACCT_USER_HOME_OWNER="reports:reports"
ACCT_USER_SHELL="/sbin/nologin"
ACCT_USER_GROUPS=( reports )

acct-user_add_deps
