# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

ATProto NUR (Nix User Repository) provides 49+ packages and NixOS modules for the AT Protocol and Bluesky ecosystem. Packages are organized by maintainer/organization and support Linux (x86_64/aarch64) and macOS (x86_64/aarch64).

**Core Principle:** This repository was recently simplified to avoid over-engineering. Maintain simplicity and follow established patterns.

## Common Commands

### Building and Testing
```bash
# Build specific package
nix build .#microcosm-constellation
nix build .#blacksky-pds -L  # with verbose output

# List all packages
nix flake show

# Check all packages evaluate
nix flake check

# Run package temporarily
nix run .#microcosm-constellation -- --help

# Enter development shell (includes deadnix, nixpkgs-fmt)
nix develop

# Format nix files
nixpkgs-fmt *.nix
nixpkgs-fmt .  # format all files

# Check for unused code
deadnix .
```

### Hash Calculation (for pinning versions)
```bash
# Method 1: Extract hash from build error
nix build .#PACKAGE-NAME 2>&1 | grep "got:"

# Method 2: For source archives
nix-prefetch-url --unpack https://github.com/OWNER/REPO/archive/COMMIT.tar.gz

# Method 3: For Go vendorHash
nix build .#tangled-spindle 2>&1 | grep "got:"
```

### Testing Single Test/Module
```bash
# Test specific NixOS module
nix build .#checks.x86_64-linux.MODULE-NAME

# Examples
nix build .#checks.x86_64-linux.mackuba-lycan
nix build .#checks.x86_64-linux.microcosm-constellation
```

### Updating Dependencies
```bash
# Update all flake inputs (nixpkgs, crane, rust-overlay)
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs
```

## Repository Architecture

### Directory Structure
```
nur/
├── flake.nix              # Multi-platform flake (uses flake-utils)
├── default.nix            # Package aggregation with organizational flattening
├── pkgs/                  # Package definitions by organization
│   ├── microcosm/         # Rust services (8 packages)
│   ├── blacksky/          # Community ATProto tools (13 packages)
│   ├── tangled/           # Git forge infrastructure (5 packages)
│   ├── grain-social/      # Photo-sharing platform
│   ├── likeandscribe/     # Community platform (frontpage, drainpipe)
│   ├── mackuba/           # Ruby feed generators
│   └── [20+ other orgs]/  # Third-party apps and tools
├── modules/               # NixOS modules (mirrors pkgs/ structure)
├── lib/                   # Build utilities and packaging helpers
│   ├── atproto.nix        # Main helpers: mkRustAtprotoService, etc.
│   └── fetch-tangled.nix  # Tangled.org repository fetcher
└── tests/                 # Package build tests
```

### Package Naming Convention

Format: `{organization}-{package-name}`

Examples:
- `microcosm-constellation`
- `blacksky-pds`
- `tangled-spindle`
- `hyperlink-academy-leaflet`
- `mackuba-lycan`

**Critical:** All outputs are system-specific due to `flake-utils`. Access as:
- Packages: `nur.packages.x86_64-linux.PACKAGE-NAME`
- Modules: `nur.nixosModules.x86_64-linux.ORGANIZATION`

Use `nix flake show` to verify exact paths.

### Package Organization Flow

1. Organization directories (`pkgs/ORGANIZATION/`) contain `.nix` files
2. Organization `default.nix` exports packages as attribute set
3. Global `pkgs/default.nix` imports all organizations and flattens with prefixes
4. `flake.nix` filters derivations and exposes as `packages.SYSTEM.PACKAGE-NAME`

### Build System Patterns

#### Rust Packages (via Crane)
- Use `craneLib` from flake inputs
- Shared dependency caching via `buildDepsOnly` for workspace packages
- Helper: `mkRustAtprotoService` in `lib/atproto.nix` handles standard setup
- Standard environment: `defaultRustEnv` includes OpenSSL, zstd, RocksDB, etc.

Microcosm workspace example:
```nix
# 1. Build shared cargoArtifacts once
cargoArtifacts = craneLib.buildDepsOnly { ... };

# 2. Build individual packages with cargo workspace
craneLib.buildPackage {
  inherit src cargoArtifacts;
  cargoExtraArgs = "--package constellation";
}
```

#### Node.js/TypeScript Packages
- Use `buildNpmPackage`
- Require pinned `npmDepsHash`
- Helper: `mkNodeAtprotoApp` in `lib/atproto.nix`

#### Go Packages
- Use `buildGoModule`
- Require pinned `vendorHash`
- Helper: `mkGoAtprotoApp` in `lib/atproto.nix`

#### Ruby Packages
- Use `bundlerEnv` for gem dependencies
- Example: `mackuba/lycan` (Sinatra feed generator)

#### Complex Multi-Stage Builds

Some packages need frontend tooling before main build. See `pkgs/yoten-app/yoten.nix`:
- Generate code from templates (`templ generate`)
- Fetch and minify frontend libraries (htmx, lucide, alpinejs)
- Build Tailwind CSS v4 using standalone binary (nixpkgs has v3)
- Use `autoPatchelfHook` to fix standalone binaries
- Prepare static files before Go embed directive evaluation

### NixOS Module Patterns

All services have NixOS modules in `modules/ORGANIZATION/`. Exception: `atbackup` (desktop app).

Standard module structure:
```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.services.PACKAGE-NAME;
in {
  options.services.PACKAGE-NAME = {
    enable = lib.mkEnableOption "SERVICE";
    package = lib.mkOption { ... };
    # Service-specific options
  };

  config = lib.mkIf cfg.enable {
    # User/group via systemd-tmpfiles
    # systemd service with security hardening
    # Firewall rules (if openFirewall = true)
  };
}
```

### Tangled.org Integration

Custom fetcher `fetchFromTangled` in `lib/fetch-tangled.nix`:
```nix
fetchFromTangled {
  owner = "microcosm-blue.org";
  repo = "allegedly";
  rev = "abc123...";  # Must pin specific commit
  hash = "sha256-...";  # Must calculate real hash
}
```

Primary development on Tangled; GitHub is mirror.

## Key Files

### `lib/atproto.nix`
Main packaging utilities:
- `defaultRustEnv` - Standard Rust build environment
- `mkRustAtprotoService` - Helper for Rust services
- `mkNodeAtprotoApp` - Helper for Node.js apps
- `mkGoAtprotoApp` - Helper for Go apps
- `mkRustWorkspace` - Build multiple packages from Rust workspace

### `pkgs/default.nix`
- Imports all organizational packages
- Flattens with `ORGANIZATION-PACKAGE` naming
- Filters out non-derivations
- Exports organizational metadata

### `flake.nix`
- Multi-platform support via `flake-utils`
- Exposes packages, modules, devShells, checks, lib
- Modules grouped by organization (microcosm, tangled, etc.)

## Adding New Packages

1. **Create package file:** `pkgs/ORGANIZATION/package-name.nix`
2. **Add to organization:** Update `pkgs/ORGANIZATION/default.nix`
3. **Pin versions:** NO `rev = "main"` or `lib.fakeHash` - calculate real hashes
4. **Create NixOS module** (if service): `modules/ORGANIZATION/package-name.nix`
5. **Test build:** `nix build .#ORGANIZATION-package-name`
6. **Update README.md:** Add to appropriate category

### Critical Requirements
- ✅ Pin all versions with specific commit hashes
- ✅ Calculate real hashes (no `lib.fakeHash`)
- ✅ Test on your platform before committing
- ✅ Follow organizational structure
- ❌ NO `rev = "main"` or `rev = "master"`
- ❌ NO over-engineering or complex abstractions
- ❌ NO backward compatibility layers

## Known Issues and Gotchas

### flake-utils System Nesting
All outputs are nested under system architecture. Use `nix flake show` to verify paths.

**Correct:**
- `nur.nixosModules.x86_64-linux.microcosm`
- `nur.packages.x86_64-linux.microcosm-constellation`

**Incorrect:**
- `nur.nixosModules.microcosm` (missing system)
- `nur.packages.constellation` (missing org prefix and system)

### Module Imports
Import modules once in top-level `flake.nix`, not in both `flake.nix` and `configuration.nix`.

### Package Flattening
Package names include organizational prefix. Use full name:
- ✅ `nur.packages.x86_64-linux.microcosm-spacedust`
- ❌ `nur.packages.x86_64-linux.spacedust`

## Development Workflow

1. Make changes to package or module files
2. Test locally: `nix build .#PACKAGE-NAME`
3. Run flake check: `nix flake check`
4. Format: `nixpkgs-fmt file.nix`
5. Check unused code: `deadnix .`
6. Update README.md if adding/removing packages
7. Commit with clear message

## Testing Before Commit

```bash
# Ensure flake evaluates
nix flake check

# Test specific package builds
nix build .#microcosm-constellation
nix build .#blacksky-pds
nix build .#mackuba-lycan

# Format and clean
nixpkgs-fmt .
deadnix .
```

## Binary Cache (Cachix)

Pre-built binaries available via Cachix:
```bash
# Setup using cachix CLI (recommended)
nix-env -iA cachix -f https://cachix.org/api/v1/install
cachix use atproto

# Or manually in configuration.nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org"
    "https://atproto.cachix.org"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "atproto.cachix.org-1:mgH0q9dt3ZI9puHEfIGDnkRBfT80I3vfEh4Wda2B0rk="
  ];
};
```

Caches Rust (Crane), Go (vendorHash), Node.js (npmDepsHash), and Ruby (bundlerEnv) dependencies.

## Flake Inputs

- `nixpkgs` - nixpkgs-unstable
- `flake-utils` - Multi-system helpers
- `crane` - Efficient Rust builder with incremental caching
- `rust-overlay` - Latest stable Rust toolchain

## Best Practices

### DO
- ✅ Keep implementation simple
- ✅ Pin all versions with specific commits and real hashes
- ✅ Follow existing organizational patterns
- ✅ Test builds before committing
- ✅ Use helpers from `lib/atproto.nix`
- ✅ Create NixOS modules for services

### DON'T
- ❌ Add complex organizational frameworks
- ❌ Create over-engineered abstractions
- ❌ Use `rev = "main"` or `lib.fakeHash`
- ❌ Add backward compatibility layers
- ❌ Create extensive documentation hierarchies
- ❌ Guess at hashes - always calculate them

## Resources

- [AT Protocol Docs](https://atproto.com) - Protocol specifications
- [Bluesky Social](https://bsky.social) - Main platform
- [Tangled](https://tangled.org) - Primary development platform
- [NUR Guidelines](https://github.com/nix-community/NUR) - Repository standards
- [Crane Documentation](https://github.com/ipetkov/crane) - Rust builder
