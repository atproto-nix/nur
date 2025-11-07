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
│   ├── tangled/           # Tangled infrastructure (appview, knot, spindle, etc.)
│   ├── plcbundle/         # PLC Bundle - DID operation archiving and distribution
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

# Or update specific input
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

### Recent Module System Fixes (October 2025)

**Major refactor resolved critical module import issues that prevented NixOS configurations from building.**

#### Issues Fixed

1.  **Module System Architecture Problems**
    - **Problem**: `modules/default.nix` used `pkgs` parameter causing infinite recursion
    - **Root Cause**: NixOS modules shouldn't require `pkgs` at import-time in the aggregator
    - **Fix**: Changed to use `lib` only, simplified to return module paths instead of evaluating them
    - **Impact**: Eliminated infinite recursion errors during `nixos-rebuild`

2.  **Missing Module Files**
    - **Problem**: `red-dwarf-client/default.nix` imported non-existent `red-dwarf.nix`
    - **Fix**: Created complete NixOS module for Red Dwarf (Bluesky web client with nginx integration)
    - **Features**: SSL support, proper caching headers, static site serving

3.  **Module List Mismatch**
    - **Problem**: `modules/default.nix` listed `atbackup-pages-dev` which doesn't exist, missing `atproto`
    - **Fix**: Updated module list to match actual directory structure
    - **Modules removed**: `atbackup-pages-dev`
    - **Modules added**: `atproto`

4.  **Module Export Structure**
    - **Problem**: Modules were being imported as functions instead of paths
    - **Fix**: `importModule` function now returns paths for NixOS to import, not evaluated modules
    - **Result**: Proper lazy evaluation, no premature function calls

#### Usage in NixOS Configurations

To use NUR modules in your NixOS configuration:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:atproto-nix/nur/big-refactor";
  };

  outputs = { nixpkgs, nur, ... }: {
    nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # IMPORTANT: Must import NUR modules
        nur.nixosModules.default

        # Your configuration
        ./configuration.nix
      ];
    };
  };
}
```

**Key Takeaway**: The `nur.nixosModules.default` import is REQUIRED for service options like `services.microcosm-constellation` to be available. Without it, you'll get "option does not exist" errors.

## Architecture and Key Concepts

### Package Naming Convention
Format: `{organization}-{package-name}`

Examples:
- `microcosm-constellation`
- `blacksky-pds`
- `tangled-spindle`
- `plcbundle-plcbundle`
- `hyperlink-academy-leaflet`
- `atproto-atproto-api`

### Package Organization Flow
1.  **Organization directories** (`pkgs/ORGANIZATION/`) contain individual `.nix` files
2.  **Organization default.nix** (`pkgs/ORGANIZATION/default.nix`) exports packages as attrset
3.  **Global pkgs/default.nix** imports all organizations and flattens with prefixes
4.  **Flake** filters derivations and exposes as `packages.SYSTEM.PACKAGE-NAME`

### NixOS Module Architecture
- Each service package has a corresponding module in `modules/ORGANIZATION/`
- Modules use shared libraries (`lib/microcosm.nix`, etc.) for common patterns
- Service configuration follows declarative NixOS style with validation
- **Exception**: `atbackup` (desktop app) has no module - only package

#### Common Utility Modules

The `common` module collection (`modules/common/`) provides reusable utilities for NixOS deployments:

**static-site-deploy** - Deploy static websites from Nix packages to web directories
- Declarative configuration for multiple static sites
- Automatic rsync deployment with proper ownership
- Service reload/restart hooks after deployment
- Systemd integration with proper ordering (before/after)

Usage example:
```nix
services.static-site-deploy.sites.my-app = {
  enable = true;
  package = pkgs.my-static-site;
  sourceDir = "share/my-app";          # Path within package
  targetDir = "/var/www/example.com";  # Deployment destination
  user = "caddy";
  group = "caddy";
  before = [ "caddy.service" ];        # Deploy before Caddy starts
  reloadServices = [ "caddy.service" ]; # Reload Caddy after deployment
};
```

This creates a systemd service `deploy-my-app.service` that:
1.  Syncs files from Nix store to web root using rsync
2.  Sets correct ownership and permissions
3.  Runs before specified services (e.g., web server)
4.  Reloads/restarts services after deployment

Real-world example: `whey-party-red-dwarf` deployment
```nix
services.static-site-deploy.sites.red-dwarf = {
  enable = true;
  package = pkgs.whey-party-red-dwarf;
  sourceDir = "share/red-dwarf";
  targetDir = "/var/www/snek.cc/red-dwarf";
  user = "caddy";
  group = "caddy";
  before = [ "caddy.service" ];
  reloadServices = [ "caddy.service" ];
};
```

See `modules/common/README.md` for full documentation.

### Build System Patterns

#### Rust Packages (via Crane)
- Use `craneLib` from flake inputs
- Shared dependency caching via `buildDepsOnly` for workspace packages
- Common environment in `lib/atproto.nix:defaultRustEnv`
- Helper function: `mkRustAtprotoService` handles standard setup

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

#### Deno Packages (TypeScript/JavaScript Runtime)
Deno packages provide a simpler pattern than Node.js when dependencies can be vendored offline:

**Pattern**: Cache dependencies with `deno cache`, bundle static assets (Tailwind, etc.), create wrapper scripts

**Examples**:
- `pkgs/grain-social/appview.nix` - Multi-stage Deno build with Tailwind CSS (3 KB)
- `pkgs/grain-social/labeler.nix` - Simple Deno package with caching (2.7 KB)
- `pkgs/grain-social/notifications.nix` - Deno service with offline dependencies (3.1 KB)
- `pkgs/witchcraft-systems/pds-dash.nix` - Deno + Vite pattern (requires FOD)
- `pkgs/slices-network/slices.nix` - Deno + multiple builders (requires FOD)

**Key Issue - Wrapper Script Variable Interpolation** (October 2025):
When creating bash wrapper scripts in Nix, use unquoted heredocs for variable interpolation:
```nix
# ✅ CORRECT: Unquoted heredoc allows ${deno} and \$out interpolation
cat > $out/bin/myapp <<WRAPPER_EOF
#!/bin/sh
exec ${deno}/bin/deno run \
  --allow-all \
  \$out/lib/myapp/main.ts "\$@"
WRAPPER_EOF

# ❌ WRONG: Single-quoted heredoc prevents ALL interpolation
cat > $out/bin/myapp <<'WRAPPER_EOF'
#!/bin/sh
exec ${deno}/bin/deno run \
  --allow-all \
  "$UNDEFINED_VAR"/main.ts "\$@"  # \$UNDEFINED_VAR not set!
WRAPPER_EOF
```

**Important Notes**:
- Use `\$out` to pass bash `$out` (escaped from Nix)
- Use `${deno}` for Nix variable interpolation (deno package path)
- Single-quoted heredocs (`<<'EOF'`) prevent ALL variable expansion
- For complex shell variables use `\''${VAR:-default}` (Nix-escaped dash syntax)

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

1.  **Create package file**: `pkgs/ORGANIZATION/package-name.nix`
2.  **Add to organization**: Update `pkgs/ORGANIZATION/default.nix`
3.  **Pin versions**: NO `rev = "main"` or `lib.fakeHash` (see PINNING_NEEDED.md)
4.  **Create NixOS module** (if service): `modules/ORGANIZATION/package-name.nix`
5.  **Test build**: `nix build .#ORGANIZATION-package-name`
6.  **Update README.md**: Add to appropriate category

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

### Package Categories (50+ total)
- **Microcosm services** (8): Rust infrastructure (constellation, spacedust, slingshot, ufos, pocket, quasar, reflector, who-am-i)
- **Blacksky/Rsky** (13): Community PDS, relay, feedgen, firehose, labeler, satnav + libraries
- **ATProto core** (8): TypeScript libraries (api, did, identity, lexicon, repo, syntax, xrpc)
- **Bluesky official** (2): indigo (Go) - placeholder, grain (parent package - placeholder)
- **Grain Social** (6): appview (Deno web app), darkroom (Rust image processing), cli (Rust CLI), labeler (Deno moderation), notifications (Deno service), grain (metapackage)
- **Third-party apps** (10+): leaflet, parakeet, teal, yoten, red-dwarf, slices, streamplace, witchcraft-systems-pds-dash (Deno), quickdid, atbackup
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

**Recently Fixed (November 2025):**
- ✅ grain-social/appview - Deno + Tailwind CSS multi-stage build with wrapper script fix
- ✅ grain-social/labeler - Deno content moderation service with dependency caching
- ✅ grain-social/notifications - Deno notification service with offline dependencies
- ✅ Fixed wrapper script variable interpolation pattern in all 3 grain-social Deno packages
  - Issue: Single-quoted heredocs prevented Nix `${...}` and bash `\$...` interpolation
  - Solution: Changed to unquoted heredocs with proper escaping (`\$out`, `${deno}`)

**Previously Fixed:**
- ✅ yoten-app/yoten - Complex multi-stage build now working
- ✅ hyperlink-academy/leaflet - Hash calculated
- ✅ slices-network/slices - Hash calculated
- ✅ parakeet-social/parakeet - Hash calculated
- ✅ smokesignal-events/quickdid - File permission issue in postInstall (October 2025)

**Known Issues - Needs Fixing:**
- ❌ mackuba/lycan - Git gem dependencies (didkit) not loading in bundlerEnv
  - Error: `cannot load such file -- didkit (LoadError)`
  - Root cause: bundlerEnv doesn't properly handle git-sourced gems
  - Solution needed: Custom gemConfig for didkit or alternative packaging approach

**Package Review Status (October 2025):**
- Total packages: ~45 across 18 organizations
- Code quality: A- (excellent structure, minor fixes needed)
- Compliance with guidelines: 95%
- Lines of code: ~5,135 lines

## Development Workflow

1.  Make changes to package or module files
2.  Test locally: `nix build .#PACKAGE-NAME`
3.  Run flake check: `nix flake check` (evaluates all packages)
4.  Format: `nixpkgs-fmt *.nix`
5.  Update README.md if adding/removing packages
6.  Commit with clear message

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

## Troubleshooting

### Module Import Errors

**Error**: `The option 'services.microcosm-constellation' does not exist`

**Cause**: NUR modules not imported in NixOS configuration

**Solution**:
```nix
# flake.nix - Add to modules list
modules = [
  nur.nixosModules.default  # ← Add this
  ./configuration.nix
];
```

### Infinite Recursion During Evaluation

**Error**: `error: infinite recursion encountered`

**Common Causes**:
1.  Module `default.nix` files using `pkgs` parameter incorrectly
2.  Circular dependencies in module imports
3.  Config referenced in imports list

**Solution**: Check that module aggregators (`modules/default.nix`, `modules/ORGANIZATION/default.nix`) only use `lib` parameter and return paths, not evaluated modules.

### Module File Not Found

**Error**: `error: path '/nix/store/.../PATH/service.nix' does not exist`

**Solution**:
1.  Verify file exists in `modules/ORGANIZATION/service.nix`
2.  Check imports in `modules/ORGANIZATION/default.nix`
3.  Update `modules/default.nix` module list if directory was added/removed
4.  Run `nix flake lock --update-input nur` to refresh

### Hash Mismatch Errors

**Error**: `hash mismatch in fixed-output derivation`

**Solution**:
1.  Build the package and note the "got:" hash from error
2.  Update the hash in the package `.nix` file
3.  Rebuild to verify

### Build Failures - File Permission Issues

**Error**: `sed: couldn't open temporary file /nix/store/.../PATH/sedXXXXXX: Permission denied`

**Cause**: Files copied in `postInstall` from `$src` are read-only, but the fixup phase (which strips toolchain references) needs write access.

**Solution**: Add `chmod -R u+w $out/PATH` after copying files:
```nix
postInstall = ''
  mkdir -p $out/share/package
  cp -r $src/static $out/share/package/
  # Make files writable for fixup phase
  chmod -R u+w $out/share/package/static
'';
```

**Real-world example**: Fixed in `pkgs/smokesignal-events/quickdid.nix` (October 2025)

### Package Attribute Not Found

**Error**: `attribute 'spacedust' missing`

**Solution**: Use full flattened name: `nur.packages.x86_64-linux.microcosm-spacedust`

Remember: Package names are prefixed with organization (e.g., `microcosm-constellation`, not just `constellation`)

### Local Development with NUR

When testing local NUR changes:
```bash
# In your NixOS config flake.nix
nur.url = "path:/home/atproto/nur";

# After making changes to NUR
cd /path/to/nixos-config
nix flake lock --update-input nur
sudo nixos-rebuild switch --flake .#hostname
```

### Sinatra/Rack: "Host Not Permitted" Errors

**Error**: HTTP requests fail with "Host not permitted" or similar host validation errors in Sinatra-based services (e.g., mackuba-lycan)

**Root Cause**: Sinatra automatically includes the `rack-protection` middleware, which enables `Rack::Protection::HostAuthorization` by default. This validates the `Host` header against a whitelist of allowed hosts. If you access the service via a hostname not in the whitelist, the request is rejected.

**Affected Services**: Any Sinatra-based service (currently `mackuba-lycan` in NUR)

**Solution**: Configure the `allowedHosts` option in the NixOS module:

```nix
services.mackuba-lycan = {
  enable = true;
  hostname = "lycan.example.com";
  allowedHosts = [
    "lycan.example.com"
    "localhost"         # for local development
    "127.0.0.1"        # optional: for IP-based access
  ];
};
```

This sets the `RACK_PROTECTION_ALLOWED_HOSTS` environment variable, which Sinatra/Rack reads at startup. The value is a comma-separated list of hostnames to allow.

**Technical Details**:
- `rack-protection` gem (included by Sinatra) provides host validation
- Environment variable: `RACK_PROTECTION_ALLOWED_HOSTS`
- Format: comma-separated list of hostnames (no spaces)
- Empty list disables the check (but not recommended)

## Resources

- [AT Protocol Docs](https://atproto.com) - Protocol specifications
- [Bluesky Social](https://bsky.social) - Main platform
- [Tangled](https://tangled.org) - Primary development platform
- [NUR Guidelines](https://github.com/nix-community/NUR) - Repository standards
- [Crane Documentation](https://github.com/ipetkov/crane) - Rust builder
- [Nix Manual](https://nixos.org/manual/nix/stable/) - Nix language reference

## Repository Status (Updated November 2025)

**Overall Grade: A**

✅ 50+ packages available and evaluating (all core implementations complete)
✅ Multi-platform support (x86_64/aarch64 Linux/Darwin)
✅ NixOS modules for all services (except atbackup desktop app)
✅ Excellent organizational structure (18 organizations)
✅ Comprehensive build helpers in `lib/atproto.nix`
✅ Custom Tangled.org fetcher working correctly
✅ Complex builds handled properly (yoten multi-stage, grain-social Deno examples)
✅ Rich metadata (ATProto passthru, organizational context)
✅ Grain Social fully implemented (appview, darkroom, cli, labeler, notifications)
✅ Wrapper script patterns documented with fix for Deno packages
⚠️ 2 packages need fixes (2 unpinned: pds-dash, likeandscribe-frontpage)

**Package Distribution:**
- Microcosm: 12 packages (largest - Rust workspace)
- Tangled: 8 packages (Go infrastructure)
- Bluesky: 8 packages (TypeScript libraries)
- Grain Social: 6 packages (fully implemented, Rust + Deno mix)
- Blacksky: 13 packages (community implementations)
- 14 other organizations: 1-2 packages each

## `workerd` Integration for Self-Hosting Serverless Functions

We have packaged and created a NixOS module for `workerd`, the open-source runtime for Cloudflare Workers. This allows us to self-host services that were originally designed as serverless functions.

- **`workerd` Package:** A Nix package for `workerd` has been added to the `nur` repository.
- **`workerd` Module:** A NixOS module for `workerd` has been created. It allows for the declarative configuration of workers, sockets, and bindings.
- **`tangled-avatar` Refactoring:** The `tangled-avatar` service has been refactored to run on our self-hosted `workerd` instance, replacing the previous standalone `systemd` service. This serves as a template for migrating other serverless functions.

This work is a major step towards our goal of self-hosting our infrastructure and reducing our reliance on external cloud services.

## Documentation Links

- **[README.md](../README.md)** - Quick start, package overview, module examples, and public-facing documentation
- **[CLAUDE.md](./CLAUDE.md)** (this file) - AI assistant guidance, technical deep dives, build patterns, and troubleshooting
- **[MCP_INTEGRATION.md](./MCP_INTEGRATION.md)** - MCP-NixOS setup for real-time package information
- **[JAVASCRIPT_DENO_BUILDS.md](./JAVASCRIPT_DENO_BUILDS.md)** - Deterministic builds for JavaScript/Deno projects with bundlers
- **[SECRETS_INTEGRATION.md](./SECRETS_INTEGRATION.md)** - Secrets management patterns and backends
- **[ROADMAP.md](./ROADMAP.md)** - Development roadmap and planned work

### Grain Social Package Implementation

See [README.md § Grain Social](../README.md#grain-social) for user-facing documentation and examples of:
- **appview.nix** - Multi-stage Deno + Tailwind CSS build
- **labeler.nix** - Content moderation service
- **notifications.nix** - Real-time notification delivery
- **darkroom.nix** - Rust image processing service
- **cli.nix** - Rust command-line tools

Implementation details and troubleshooting available in **CLAUDE.md § Deno Packages** (this file, above).