#!/usr/bin/env bash
set -euo pipefail

cred_file=""
if [[ -n "${CREDENTIALS_DIRECTORY:-}" ]]; then
	if [[ -f "${CREDENTIALS_DIRECTORY}/litellm.database-password" ]]; then
		cred_file="${CREDENTIALS_DIRECTORY}/litellm.database-password"
	elif [[ -f "${CREDENTIALS_DIRECTORY}/db_password" ]]; then
		cred_file="${CREDENTIALS_DIRECTORY}/db_password"
	fi
fi

if [[ -n "${cred_file}" ]]; then
	DATABASE_PASSWORD="$(cat "${cred_file}")"
	export DATABASE_PASSWORD
	if [[ -n "${DATABASE_HOST:-}" && -n "${DATABASE_USERNAME:-}" && -n "${DATABASE_NAME:-}" ]]; then
		export DATABASE_URL="postgresql://${DATABASE_USERNAME}:${DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT:-5432}/${DATABASE_NAME}"
	fi
fi

config_dir="${CONFIGURATION_DIRECTORY:-/etc/litellm}"
config_path="${LITELLM_CONFIG_PATH:-${config_dir}/config.yaml}"
port="${LITELLM_PORT:-4000}"

exec litellm --config "${config_path}" --port "${port}"
