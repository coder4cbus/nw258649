# Laptop Migration Process

This repo can be your source of truth for rebuilding a new Windows laptop with a close-to-identical setup.

## 1) Capture a snapshot from current laptop

Run from repo root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/collect-laptop-inventory.ps1
```

Optional: include raw values for environment variables (use cautiously):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/collect-laptop-inventory.ps1 -IncludeSensitiveValues
```

The script writes to:

- inventory/snapshots/<timestamp>/manifest.json
- inventory/snapshots/<timestamp>/env/
- inventory/snapshots/<timestamp>/software/
- inventory/snapshots/<timestamp>/packages/
- inventory/snapshots/<timestamp>/cli/
- inventory/snapshots/<timestamp>/ide/
- inventory/snapshots/<timestamp>/configs/

Additional capture coverage now includes:

- Conda environments and packages
- Rustup toolchains and cargo installs
- WSL status and distro inventory
- Docker contexts/version/info and Docker Desktop settings (if present)
- JetBrains product directory inventory (if present)

## 2) Review and commit

Recommended review order:

1. env/*.json for anything sensitive
2. configs/ssh-config and configs/.gitconfig
3. software/nonstandard-install-locations.csv
4. packages/*.txt and packages/winget-export.json

Commit only what you are comfortable storing in Git.

## 3) Generate a bootstrap script for a new laptop

Pick a snapshot folder, then run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/new-bootstrap-from-inventory.ps1 -SnapshotPath inventory/snapshots/<timestamp>
```

This creates scripts/bootstrap-new-laptop.ps1 using discovered package manager inventories:

- winget import
- choco install list
- scoop install list
- VS Code extensions install list

## 4) Rebuild on new laptop

Suggested sequence:

1. Install Git and clone this repo
2. Install package managers (winget built-in, then chocolatey/scoop if desired)
3. Run generated bootstrap script
4. Restore selected config files manually:
   - VS Code settings/keybindings/snippets
   - .gitconfig
   - ssh config
5. Re-run collect script on the new laptop and compare snapshots

## 5) Compare old vs new snapshot

Generate a structured drift report:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/compare-laptop-snapshots.ps1 -BaselineSnapshot inventory/snapshots/<old> -CandidateSnapshot inventory/snapshots/<new>
```

Optional output file and auto-open:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/compare-laptop-snapshots.ps1 -BaselineSnapshot inventory/snapshots/<old> -CandidateSnapshot inventory/snapshots/<new> -OutputPath inventory/snapshots/<new>/comparison-report.md -OpenReport
```

The report includes differences for:

- Installed software
- winget/choco/scoop package inventories
- CLI tool versions
- VS Code extensions
- Environment variables (Machine + User)

## Notes

- InstallLocation in registry can be empty or inconsistent for some programs.
- Some tools report version with different flags; unknown values are expected for a few commands.
- Driver and service exports are included for deep troubleshooting, not always needed for app migration.
