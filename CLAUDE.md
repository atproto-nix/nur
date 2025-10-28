# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## MCP-NixOS Integration

This repository uses [MCP-NixOS](https://mcp-nixos.io/) for accurate, real-time NixOS package and configuration information.

**Setup for Claude Code:**

If not already configured, create `~/.claude-code/mcp.json`:
```json
{
  "mcpServers": {
    "mcp-nixos": {
      "command": "nix",
      "args": ["run", "github:utensils/mcp-nixos"]
    }
  }
}
```

**What this provides:**
- 130K+ NixOS packages information
- 22K+ configuration options
- 4K+ Home Manager options
- Prevents hallucinations about package availability
- Real-time version tracking across nixpkgs channels

**Useful queries:**
- "What NixOS packages exist for ATProto?"
- "Show me systemd service options"
- "What version of Rust is in nixpkgs-unstable?"
- "Are there any Go packages for building web servers?"

## Project Overview

The ATProto NUR (Nix User Repository) provides Nix packages and NixOS modules for the AT Protocol and Bluesky ecosystem. It contains 48+ packages organized by maintainer/organization, serving both package distribution (via binary cache) and declarative server deployment (via NixOS modules).

**Key principle**: This repository was recently simplified. Maintain simplicity - avoid over-engineering, complex abstractions, or extensive documentation systems.

## Repository Structure

```
nur/
├── flake.nix              # Main flake (multi-platform: x86_64/aarch64 Linux/Darwin)
├── default.nix            # Package aggregation and exports
├── pkgs/                  # Package definitions organized by organization
│   ├── microcosm/         # Rust services (constellation, slingshot, etc.)
│   ├── blacksky/          # Community ATProto tools (PDS, relay, etc.)
│   ├── bluesky-social/    # Official Bluesky packages (indigo, grain)
│   ├── atproto/           # Core TypeScript libraries
│   ├── tangled-dev/       # Tangled infrastructure (appview, knot, spindle)
│   └── [other orgs]/      # Third-party apps (leaflet, teal, yoten, etc.)
├── modules/               # NixOS service modules (mirror pkgs/ structure)
├── lib/                   # Build utilities and packaging helpers
│   ├── atproto.nix        # Main packaging utilities (Rust, Node, Go helpers)
│   └── fetch-tangled.nix  # Tangled.org repository fetcher
└── tests/                 # Package build tests
```

## Common Commands

### Building and Testing
```bash
# Build a specific package
nix build .#microcosm-constellation

# Build with verbose output
nix build .#blacksky-pds -L

# List all available packages
nix flake show

# Check all packages evaluate correctly
nix flake check

# Enter development shell (includes deadnix, nixpkgs-fmt)
nix develop

# Format nix files
nixpkgs-fmt *.nix
```

### Package Discovery
```bash
# List all packages (48+)
nix flake show 2>&1 | grep "package '"

# Count packages
nix eval .#packages.x86_64-linux --apply builtins.length
```

### Running and Testing Services
```bash
# Run a package temporarily
nix run .#microcosm-constellation -- --help

# Enter shell with package available
nix shell .#smokesignal-events-quickdid

# Test a NixOS module (requires NixOS or VM)
nixos-rebuild test --flake .#test-config
```

### Updating Dependencies
```bash
# Update all flake inputs (nixpkgs, crane, rust-overlay)
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs
```

### Calculating Hashes (for fixing PINNING_NEEDED.md issues)
```bash
# Method 1: Attempt build and extract correct hash from error
nix build .#PACKAGE-NAME 2>&1 | grep "got:"

# Method 2: Use nix-prefetch for source hash
nix-prefetch-url --unpack https://github.com/OWNER/REPO/archive/COMMIT.tar.gz

# Method 3: For Go modules (vendorHash)
nix build .#tangled-dev-spindle 2>&1 | grep "got:"
```

### Recent NixOS Build Fix (October 2025)

A recent debugging session resolved a series of cascading build failures when using this NUR in a NixOS configuration. The root cause was a combination of incorrect module paths, package names, and outdated hashes.

Here is a summary of the fixes applied, which should serve as a guide for similar issues:

1.  **Corrected Module Path in `flake.nix`**:
    *   **Problem**: The build failed with `attribute 'microcosm' missing` because the module path in the user's `flake.nix` was `nur.nixosModules.microcosm`.
    *   **Analysis**: This NUR uses `flake-utils`, which structures all outputs by system. The `nix flake show` command confirmed this.
    *   **Fix**: The path was corrected to be system-specific: `nur.nixosModules.x86_64-linux.microcosm`.

2.  **Removed Redundant Module Import**:
    *   **Problem**: The `microcosm` module was being imported in both `flake.nix` and `configuration.nix`.
    *   **Fix**: The redundant import in `configuration.nix` was removed to avoid evaluation conflicts. Modules should be listed once in the top-level `flake.nix`.

3.  **Corrected Package Names in `configuration.nix`**:
    *   **Problem**: The build failed with `attribute 'spacedust' missing` and a similar error for `constellation`.
    *   **Analysis**: The package names in this NUR are flattened with an organizational prefix (e.g., `microcosm-spacedust`).
    *   **Fix**: The package references in `configuration.nix` were updated from `nur.packages.x86_64-linux.spacedust` to `nur.packages.x86_64-linux.microcosm-spacedust` (and similarly for `constellation`).

4.  **Updated Caddy Plugin Hash**:
    *   **Problem**: The build failed with a `hash mismatch` error for a Caddy plugin.
    *   **Fix**: The specified hash in `configuration.nix` was updated to the new hash provided in the build error log.

**Key Takeaway**: When debugging build failures with this NUR, always:
- Use `nix flake show` to verify the exact output paths for modules and packages.
- Remember that all outputs are nested under the system architecture (e.g., `x86_64-linux`).
- Check for flattened package names that include the organization prefix.

## Architecture and Key Concepts

### Package Naming Convention
Format: `{organization}-{package-name}`

Examples:
- `microcosm-constellation`
- `blacksky-pds`
- `tangled-dev-spindle`
- `hyperlink-academy-leaflet`
- `atproto-atproto-api`

### Package Organization Flow
1. **Organization directories** (`pkgs/ORGANIZATION/`) contain individual `.nix` files
2. **Organization default.nix** (`pkgs/ORGANIZATION/default.nix`) exports packages as attrset
3. **Global pkgs/default.nix** imports all organizations and flattens with prefixes
4. **Flake** filters derivations and exposes as `packages.SYSTEM.PACKAGE-NAME`

### NixOS Module Architecture
- Each service package has a corresponding module in `modules/ORGANIZATION/`
- Modules use shared libraries (`lib/microcosm.nix`, etc.) for common patterns
- Service configuration follows declarative NixOS style with validation
- **Exception**: `atbackup` (desktop app) has no module - only package

### Build System Patterns

#### Rust Packages (via Crane)
- Use `craneLib` from flake inputs
- Shared dependency caching via `buildDepsOnly` for workspace packages
- Common environment in `lib/atproto.nix:defaultRustEnv`
- Helper function: `mkRustAtprotoService` handles standard setup

Example workflow (microcosm):
1. Build shared `cargoArtifacts` once for entire workspace
2. Build individual packages with `cargoExtraArgs = "--package NAME"`
3. Reuses artifacts, speeds up multi-package builds

#### Node.js/TypeScript Packages
- Use `buildNpmPackage`
- Require pinned `npmDepsHash`
- Helper function: `mkNodeAtprotoApp`

#### Go Packages
- Use `buildGoModule`
- Require pinned `vendorHash`
- Helper function: `mkGoAtprotoApp`

#### Complex Build Processes
Some packages require multi-stage builds with frontend tooling:

**Example: yoten (Go + templ + Tailwind CSS v4)**
- Generate code from templ templates using `templ generate`
- Fetch and minify frontend libraries (htmx, lucide, alpinejs)
- Build Tailwind CSS v4 using standalone binary (nixpkgs has v3)
- Use `autoPatchelfHook` to fix standalone binaries for NixOS
- Create static files before Go embed directive evaluation

See `pkgs/yoten-app/yoten.nix` for reference implementation.

#### JavaScript and Deno with External Builders
When Deno projects call out to JavaScript bundlers (Vite, esbuild) or npm packages, special care is needed to ensure deterministic builds:

**Problem**: Vite, esbuild, and other JS bundlers generate non-deterministic output (chunk hashes, timestamps, etc.)

**Solution**: Use Fixed-Output Derivation (FOD) to cache dependencies offline before the non-deterministic builder runs

**Examples**:
- `pkgs/witchcraft-systems/pds-dash.nix` - Deno + Vite pattern
- `pkgs/slices-network/slices.nix` - Deno + multiple builders

**See `docs/JAVASCRIPT_DENO_BUILDS.md` for detailed patterns and troubleshooting.**

### Tangled.org Integration
Custom fetcher `fetchFromTangled` (in `lib/fetch-tangled.nix`) for Tangled repositories:
```nix
fetchFromTangled {
  owner = "microcosm.blue";
  repo = "allegedly";
  rev = "abc123...";
  hash = "sha256-...";
}
```

Primary development is on Tangled; GitHub is a mirror.

## Adding New Packages

1. **Create package file**: `pkgs/ORGANIZATION/package-name.nix`
2. **Add to organization**: Update `pkgs/ORGANIZATION/default.nix`
3. **Pin versions**: NO `rev = "main"` or `lib.fakeHash` (see PINNING_NEEDED.md)
4. **Create NixOS module** (if service): `modules/ORGANIZATION/package-name.nix`
5. **Test build**: `nix build .#ORGANIZATION-package-name`
6. **Update README.md**: Add to appropriate category

### Critical Requirements
- ✅ Pin all versions with specific commit hashes
- ✅ Calculate real hashes (no `lib.fakeHash`)
- ✅ Test on your platform before committing
- ✅ Follow organizational structure
- ❌ No `rev = "main"` or `rev = "master"`
- ❌ No over-engineering or complex abstractions
- ❌ No backward compatibility layers

## Important Files

### `lib/packaging.nix`
Comprehensive multi-language build utilities (944 lines):
- Language builders: Rust (workspace), Node.js (pnpm), Go (services), Deno
- Standard environments and build inputs for ATProto ecosystem
- Multi-language coordination framework
- **Note**: See `docs/LIB_PACKAGING_IMPROVEMENTS.md` for planned enhancements
  - FOD helpers for deterministic JavaScript/Deno builds
  - Determinism controls for bundlers (Vite, esbuild)
  - Better hash validation and error handling

### `lib/atproto.nix`
Legacy packaging utilities (kept for compatibility):
- `defaultRustEnv`: Standard environment for Rust builds (OpenSSL, zstd, etc.)
- `mkRustAtprotoService`: Helper for building Rust services with ATProto metadata
- `mkNodeAtprotoApp`: Helper for Node.js applications
- `mkGoAtprotoApp`: Helper for Go applications
- `mkRustWorkspace`: Build multiple packages from single Rust workspace

### `lib/fetch-tangled.nix`
Fetcher for Tangled.org repositories (fork of `fetchFromGitHub`):
- Supports both `rev` and `tag` parameters (must specify one)
- Uses fetchgit for submodules, fetchzip otherwise
- Automatically generates homepage metadata

### Package Categories (48 total)
- **Microcosm services** (8): Rust infrastructure (constellation, spacedust, slingshot, ufos, pocket, quasar, reflector, who-am-i)
- **Blacksky/Rsky** (13): Community PDS, relay, feedgen, firehose, labeler, satnav + libraries
- **ATProto core** (8): TypeScript libraries (api, did, identity, lexicon, repo, syntax, xrpc)
- **Bluesky official** (2): indigo (Go), grain (TypeScript) - placeholders
- **Third-party apps** (10+): leaflet, parakeet, teal, yoten, red-dwarf, slices, streamplace, - `witchcraft-systems-pds-dash` - PDS monitoring dashboard (Deno), quickdid, atbackup
- **Tangled infrastructure** (5): appview, knot, spindle, genjwks, lexgen
- **Microcosm** (1): allegedly (PLC tools)

### Known Issues (October 2025 Review)

**Critical - Unpinned Versions:**
- `pkgs/witchcraft-systems/pds-dash.nix:7` - Uses `rev = "main"` (needs specific commit)
- `pkgs/blacksky/rsky/default.nix:196-222` - Commented code with unpinned version

**Critical - Missing Hashes:**
- `pkgs/likeandscribe/frontpage.nix:34` - `npmDepsHash = lib.fakeHash` (complex pnpm monorepo)
  - This is a large monorepo with 6 Node.js packages + 3 Rust packages
  - Requires special handling for pnpm workspaces

**Code Quality:**
- `pkgs/yoten-app/yoten.nix:37` - Hardcoded error for aarch64-linux hash placeholder
- `pkgs/blacksky/rsky/default.nix:189-222` - Large commented section should be removed or documented

**Nondeterminism in JavaScript/Deno Builds:**
- `pkgs/witchcraft-systems/pds-dash.nix` - Vite non-deterministic output (see `docs/JAVASCRIPT_DENO_BUILDS.md`)
- `pkgs/slices-network/slices.nix` - Multiple builders without FOD caching
- `pkgs/likeandscribe/frontpage.nix` - pnpm monorepo with bundler (see `docs/JAVASCRIPT_DENO_BUILDS.md`)

**Recently Fixed:**
- ✅ yoten-app/yoten - Complex multi-stage build now working
- ✅ hyperlink-academy/leaflet - Hash calculated
- ✅ slices-network/slices - Hash calculated
- ✅ parakeet-social/parakeet - Hash calculated

**Package Review Status (October 2025):**
- Total packages: ~45 across 18 organizations
- Code quality: A- (excellent structure, minor fixes needed)
- Compliance with guidelines: 95%
- Lines of code: ~5,135 lines

## Development Workflow

1. Make changes to package or module files
2. Test locally: `nix build .#PACKAGE-NAME`
3. Run flake check: `nix flake check` (evaluates all packages)
4. Format: `nixpkgs-fmt file.nix`
5. Update README.md if adding/removing packages
6. Commit with clear message

## Module Development Pattern

Example structure (see `modules/microcosm/constellation.nix`):
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
    # User/group creation
    # Directory management (systemd-tmpfiles)
    # systemd service configuration
    # Firewall rules (if openFirewall = true)
  };
}
```

Modules are grouped by organization in `modules/ORGANIZATION/default.nix` and imported in `modules/default.nix`.

## Flake Inputs and Outputs

### Inputs
- `nixpkgs`: nixpkgs-unstable
- `flake-utils`: Multi-system helpers
- `crane`: Rust builder (for efficient cargo builds)
- `rust-overlay`: Latest stable Rust

### Outputs (per system)
- `packages.SYSTEM.*`: All 48+ packages
- `nixosModules.*`: Service modules (default + per-organization)
- `devShells.default`: Development shell (deadnix, nixpkgs-fmt)
- `lib`: ATProto packaging utilities

## Best Practices

### DO
- ✅ Keep implementation simple and maintainable
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

## Testing and Validation

Run these before committing:
```bash
# Ensure flake evaluates
nix flake check

# Test specific package builds
nix build .#microcosm-constellation
nix build .#blacksky-pds

# Format nix files
nixpkgs-fmt .

# Check for unused code
deadnix .
```

## Resources

- [AT Protocol Docs](https://atproto.com) - Protocol specifications
- [Bluesky Social](https://bsky.social) - Main platform
- [Tangled](https://tangled.org) - Primary development platform
- [NUR Guidelines](https://github.com/nix-community/NUR) - Repository standards
- [Crane Documentation](https://github.com/ipetkov/crane) - Rust builder
- [Nix Manual](https://nixos.org/manual/nix/stable/) - Nix language reference

## Repository Status (Updated October 2025)

**Overall Grade: A-**

✅ 48 packages available and evaluating (45 package files + 3 from monorepos)
✅ Multi-platform support (x86_64/aarch64 Linux/Darwin)
✅ NixOS modules for all services (except atbackup desktop app)
✅ Excellent organizational structure (18 organizations)
✅ Comprehensive build helpers in `lib/atproto.nix`
✅ Custom Tangled.org fetcher working correctly
✅ Complex builds handled properly (yoten multi-stage example)
✅ Rich metadata (ATProto passthru, organizational context)
⚠️ 3 packages need fixes (2 unpinned, 1 missing hash)
⚠️ Some packages are placeholders awaiting implementation

**Package Distribution:**
- Microcosm: 12 packages (largest - Rust workspace)
- Tangled: 8 packages (Go infrastructure)
- Bluesky: 8 packages (TypeScript libraries)
- Grain Social: 3 packages
- 14 other organizations: 1-2 packages each
