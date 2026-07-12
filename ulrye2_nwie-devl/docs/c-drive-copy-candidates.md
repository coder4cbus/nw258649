# C Drive Copy Candidates For New-Laptop Setup

This file lists high-value assets discovered and copied for migration.

## Scoop (offline-friendly)

Detected custom Scoop layout:

- C:\apps
- C:\buckets
- C:\cache
- C:\shims

Copied into repo:

- migration-assets/scoop/core/current
- migration-assets/scoop/buckets
- migration-assets/scoop/cache
- migration-assets/scoop/shims
- migration-assets/install-scoop-offline.ps1

Why this matters:

- You can restore Scoop without fetching installer scripts from the public internet.
- Buckets and cache give you local manifests and many local package payloads.

## Certificates

Public certs exported from Windows stores:

- Cert:\CurrentUser\Root
- Cert:\CurrentUser\CA
- Cert:\CurrentUser\My (public cert only)
- Cert:\LocalMachine\Root
- Cert:\LocalMachine\CA

Also copied:

- migration-assets/certs/nw-truststores-cer
- migration-assets/certs/nationwide-truststore.pem

## Safe config subset copied

- migration-assets/configs/ssh-public
  - config
  - known_hosts
  - authorized_keys
  - *.pub

## What not to commit by default

- Private keys (.pfx, .p12, .key)
- Full .ssh private key material
- Secrets/tokens in app config files

Note:

- .gitignore already blocks common private key patterns in migration-assets.

## Commands used

Collect assets:

powershell -ExecutionPolicy Bypass -File scripts/collect-c-drive-bootstrap-assets.ps1 -IncludeScoopCache

Optional private-key capture (not recommended for Git):

powershell -ExecutionPolicy Bypass -File scripts/collect-c-drive-bootstrap-assets.ps1 -IncludeScoopCache -IncludePrivateKeys

Restore Scoop from copied assets:

powershell -ExecutionPolicy Bypass -File migration-assets/install-scoop-offline.ps1

Generate cert selection list and import selected certs into CurrentUser Root/CA:

powershell -ExecutionPolicy Bypass -File migration-assets/install-certs-currentuser.ps1 -GenerateSelectionFile
powershell -ExecutionPolicy Bypass -File migration-assets/install-certs-currentuser.ps1

Verify imported cert presence and produce pass/fail report:

powershell -ExecutionPolicy Bypass -File migration-assets/verify-certs-currentuser.ps1 -UseDefaultSelection
