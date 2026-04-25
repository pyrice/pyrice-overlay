# Brewfather API Query - Gentoo Ebuild

## Installation

1. Copy this entire directory to your overlay:
   ```bash
   sudo cp -r /tmp/brewfather-ebuild/* /var/db/repos/pyrice-overlay/app-misc/brewfather-api-query/
   ```

2. Generate the Manifest file:
   ```bash
   cd /var/db/repos/pyrice-overlay/app-misc/brewfather-api-query
   ebuild brewfather-api-query-0.2.0.ebuild manifest
   ```

3. Install the package:
   ```bash
   emerge -av app-misc/brewfather-api-query
   ```

## Updating CRATES Variable

The ebuild includes a simplified CRATES list. For a complete and accurate list, use one of these methods:

### Method 1: Using pycargoebuild (Recommended)
```bash
emerge -av app-portage/pycargoebuild
cd /path/to/brewfather-api-query/source
pycargoebuild brewfather-api-query 0.2.0
```

### Method 2: Manual generation
```bash
cd /path/to/brewfather-api-query/source
cargo fetch
cargo metadata --format-version 1 | jq -r '.packages[] | select(.source != null) | "\(.name)-\(.version)"' | sort
```

Then update the CRATES variable in the ebuild file.

## Configuration

1. Copy the example config:
   ```bash
   sudo cp /etc/brewfather-api-query.toml.example /etc/brewfather-api-query.toml
   ```

2. Encrypt your credentials:
   ```bash
   brewfather-api-query --key-file /var/lib/brewfather-api-query/.brewfather_key --encrypt-user-id YOUR_USER_ID
   brewfather-api-query --key-file /var/lib/brewfather-api-query/.brewfather_key --encrypt-api-key YOUR_API_KEY
   ```

3. Add the encrypted values to `/etc/brewfather-api-query.toml`

4. Enable the systemd timer (optional):
   ```bash
   systemctl enable --now brewfather-api-query.timer
   ```

## Files

- `brewfather-api-query-0.2.0.ebuild` - Main ebuild file
- `metadata.xml` - Package metadata
- `files/brewfather-api-query.service` - Systemd service unit
- `files/brewfather-api-query.timer` - Systemd timer unit
- `files/brewfather-api-query.toml.example` - Example configuration file
- `generate-crates.sh` - Helper script for generating CRATES list

## User and Group

The service runs as the `brewfather` user and group. These will be created automatically by the ebuild if they don't exist.
