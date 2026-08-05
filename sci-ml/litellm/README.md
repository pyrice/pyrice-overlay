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

The systemd unit uses `DynamicUser=yes`, `LogsDirectory=litellm`, and `ConfigurationDirectory=litellm`.

1. Edit configuration in `/etc/litellm/config.yaml`.
2. Enable and start the service:

```bash
systemctl enable --now litellm.service
```
