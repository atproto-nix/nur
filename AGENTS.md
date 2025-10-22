# Agent Guide for ATProto NUR

This document provides guidance for AI agents working with the ATProto NUR repository.

## Project Overview

The ATProto NUR is a Nix User Repository providing packages and NixOS modules for the AT Protocol and Bluesky ecosystem. It contains 48+ packages organized by maintainer/organization.

## Repository Structure

```
nur/
├── flake.nix              # Flake configuration (simplified)
├── default.nix            # Package exports
├── pkgs/                  # Package definitions (organized by org)
│   ├── microcosm/         # Microcosm Rust services
│   ├── blacksky/          # Community ATProto tools
│   ├── bluesky-social/    # Official Bluesky packages
│   ├── atproto/           # Core libraries
│   ├── tangled-dev/       # Tangled infrastructure
│   └── [other orgs]/      # Third-party apps
├── modules/               # NixOS service modules
├── lib/                   # Build utilities and helpers
└── tests/                 # Package tests
```

## Key Principles

1. **Simplicity**: This repo was recently simplified. Keep it simple - no over-engineering.
2. **Organizational Structure**: Packages are grouped by their maintainer/organization for clarity.
3. **Reproducibility**: All packages should have pinned versions (no `rev = "main"` or `lib.fakeHash`).
4. **NixOS Integration**: Each package should have a corresponding NixOS module.

## Common Tasks

### Building Packages

```bash
# Build specific package
nix build .#microcosm-constellation

# Evaluate flake
nix flake show

# Check all packages
nix flake check

# Enter dev shell
nix develop
```

### Adding New Packages

1. Create `.nix` file in appropriate `pkgs/ORGANIZATION/` directory
2. Add to `pkgs/ORGANIZATION/default.nix`
3. Pin all versions (no `rev = "main"`, no `lib.fakeHash`)
4. Create NixOS module in `modules/ORGANIZATION/`
5. Test build

### Package Naming Convention

- Format: `{organization}-{package-name}`
- Examples:
  - `microcosm-constellation`
  - `blacksky-pds`
  - `tangled-dev-spindle`
  - `hyperlink-academy-leaflet`

## Important Files

### `flake.nix`
- Main flake configuration
- Multi-platform support (x86_64/aarch64 for Linux/Darwin)
- Exports packages, lib, and nixosModules
- **Keep it simple** - no backward compatibility layers

### `default.nix`
- Package aggregation from `pkgs/`
- Exports lib and modules
- Filter to only include derivations

### `pkgs/default.nix`
- Imports all organizational package collections
- Flattens into single namespace with org prefixes
- Each organization has its own subdirectory

### `lib/atproto.nix`
- Main packaging utilities
- Rust build helpers (uses crane)
- ATProto-specific helpers

## Package Categories

### Working Packages (48 total)
- Microcosm services (8): constellation, spacedust, slingshot, ufos, etc.
- Blacksky/Rsky (19): PDS, relay, feedgen, libraries, etc.
- ATProto core libraries (8): TypeScript packages
- Third-party apps (10+): leaflet, parakeet, teal, yoten, etc.
- Tangled infrastructure (5): appview, knot, spindle, etc.

### Packages Needing Work
See `PINNING_NEEDED.md` for packages that need version pinning:
- tangled-dev/* (3 packages)
- witchcraft-systems/pds-dash
- hyperlink-academy/leaflet
- atproto/frontpage
- And others

## Build System

### Rust Packages
- Use `craneLib` for building
- Multi-package workspaces (like microcosm) share build artifacts
- See `lib/atproto.nix` for helpers

### Go Packages
- Use `buildGoModule`
- Need `vendorHash` pinned

### Node.js/TypeScript Packages
- Use `buildNpmPackage`
- Need `npmDepsHash` pinned

## NixOS Modules

Each service has a module in `modules/ORGANIZATION/SERVICE.nix`:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.services.PACKAGE-NAME;
in {
  options.services.PACKAGE-NAME = {
    enable = lib.mkEnableOption "SERVICE";
    settings = { ... };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.PACKAGE-NAME = { ... };
  };
}
```

Modules are grouped by organization in `modules/ORGANIZATION/default.nix`.

## Development Workflow

1. **Make changes** to packages or modules
2. **Test locally**: `nix build .#PACKAGE`
3. **Check flake**: `nix flake check`
4. **Update README** if adding/removing packages
5. **Commit** with clear message

## What NOT to Do

❌ Don't add complex organizational frameworks
❌ Don't create over-engineered abstractions
❌ Don't use `rev = "main"` or `lib.fakeHash`
❌ Don't add backward compatibility layers
❌ Don't create extensive documentation systems

✅ DO keep it simple
✅ DO pin all versions
✅ DO test builds
✅ DO follow existing patterns

## Current Status

- ✅ 48 packages available and evaluating
- ✅ Flake simplified and clean
- ✅ Multi-platform support
- ✅ NixOS modules for all services
- ⚠️ ~8 packages need version pinning (see PINNING_NEEDED.md)

## Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [NUR Guidelines](https://github.com/nix-community/NUR)
- [AT Protocol Docs](https://atproto.com)
- [Crane (Rust builder)](https://github.com/ipetkov/crane)

## Notes for Agents

- This repo serves both **packaging** (for binary cache) and **server deployment** (via NixOS modules)
- The organizational structure is intentional - it helps users find packages by maintainer
- Recently simplified from an over-complex structure - maintain simplicity
- Some packages have `fakeHash` and won't build until hashes are calculated
- Primary development is on Tangled, GitHub is a mirror

## Quick Reference

```bash
# List all packages
nix flake show 2>&1 | grep "package '"

# Build a package
nix build .#PACKAGE-NAME

# Test a module
nixos-rebuild test --flake .#test-config

# Update inputs
nix flake update

# Format nix files
nixpkgs-fmt *.nix
```
