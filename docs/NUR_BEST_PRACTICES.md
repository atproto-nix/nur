# ATProto NUR - Architecture & Best Practices Guide

This guide documents the architectural patterns, best practices, and design decisions in the Tangled ATProto NUR repository. It serves as a reference for contributors and maintainers.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Flake Design](#flake-design)
3. [Package Organization](#package-organization)
4. [Build System Integration](#build-system-integration)
5. [Metadata and Discovery](#metadata-and-discovery)
6. [Common Patterns](#common-patterns)
7. [Testing and CI/CD](#testing-and-cicd)
8. [Adding New Packages](#adding-new-packages)
9. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### High-Level Structure

```
┌─────────────────────────────────────────────────────────┐
│         Flake (flake.nix)                               │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Inputs: nixpkgs, crane, rust-overlay, deno        │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌────────────────────────────────────────────────┐    │
│  │ Outputs (per-system):                          │    │
│  │  - packages: All buildable derivations         │    │
│  │  - legacyPackages: Non-flake access            │    │
│  │  - nixosModules: Service configurations         │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         ▼                ▼                ▼
    default.nix    pkgs/default.nix   lib/atproto.nix
        │               │                  │
        │      ┌────────┴──────────┐       │
        │      ▼                   ▼       │
        │  ┌─────────────────────────┐    │
        │  │ Organization packages   │    │
        │  │ (microcosm/, etc.)      │    │
        │  └─────────────────────────┘    │
        │                                 │
        └────────────┬────────────────────┘
                     ▼
         ┌──────────────────────────┐
         │  Overlay (overlay.nix)   │
         │  - For non-flake usage   │
         │  - Integrates with nixpkgs │
         └──────────────────────────┘
```

### Key Concepts

**Inputs**: External flake dependencies
- `nixpkgs`: Base package set (unstable)
- `crane`: Rust build system
- `rust-overlay`: Rust toolchain management
- `deno`: JavaScript runtime

**Outputs**: What the flake exposes
- `packages`: Buildable derivations per system
- `legacyPackages`: For non-flake tools
- `nixosModules`: NixOS service configurations

**Overlays**: Functions that modify or extend packages
- Applied in order (language tools first, custom tools last)
- Enable adding custom packages to nixpkgs

---

## Flake Design

### Best Practices

#### 1. **Multi-System Support**

```nix
# GOOD: Support all exposed systems
forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

packages = forAllSystems (system: (preparePackages system).packages);

# BAD: Hard-coding specific systems
packages.x86_64-linux = ...;
packages.aarch64-linux = ...;
# (Maintenance nightmare when adding new systems)
```

**Why**: Scales naturally as nixpkgs adds new systems. Single definition for all platforms.

#### 2. **Input Pinning**

```nix
# GOOD: Follow transitive dependencies
crane = {
  url = "github:ipetkov/crane/master";
  inputs.nixpkgs.follows = "nixpkgs";  # Pin to same version
};

# BAD: Allow version drift
crane = {
  url = "github:ipetkov/crane/master";
  # (crane uses different nixpkgs than flake)
};
```

**Why**: Prevents dependency version conflicts, reduces closure size, ensures consistency.

#### 3. **Overlay Ordering**

```nix
# GOOD: Language runtimes before custom tools
overlays = [
  rust-overlay.overlays.default,   # Provides rust-bin
  deno.overlays.default,            # Provides deno
  (final: prev: {
    fetchFromTangled = final.callPackage ./lib/fetch-tangled.nix { };
  })
];

# BAD: Mixing order
overlays = [
  custom-overlay,      # Uses rust-bin before rust-overlay applied
  rust-overlay.overlays.default,
];
```

**Why**: Each overlay can build on previous ones. Prevents "undefined variable" errors.

#### 4. **Context Passing**

```nix
# GOOD: Pass all needed context to package set
selectedPackages = import ./pkgs/default.nix {
  inherit pkgs craneLib;
  lib = pkgs.lib;
  fetchgit = pkgs.fetchgit;
  buildGoModule = pkgs.buildGoModule;
  buildNpmPackage = pkgs.buildNpmPackage;
  atprotoLib = pkgs.callPackage ./lib/atproto.nix { };
};

# BAD: Make packages import what they need
selectedPackages = import ./pkgs/default.nix { inherit pkgs; };
# (Each package then does: import nixpkgs, fetch buildGoModule, etc.)
```

**Why**: Single source of truth for versions. Packages focus on specifics, not infrastructure.

#### 5. **Default Package**

```nix
# GOOD: Provide default for convenience
packages = selectedPackages // {
  default = pkgs.symlinkJoin {
    name = "atproto-nur-all";
    paths = builtins.attrValues selectedPackages;
  };
};

# Users can: nix build (without package name)

# BAD: No default package
# Users must: nix build .#microcosm-constellation
```

**Why**: Better user experience, useful for CI testing.

---

## Package Organization

### Directory Structure

```
pkgs/
├── default.nix           # Main aggregator - imports all organizations
├── ORGANIZATION/
│   ├── default.nix       # Organization's package set
│   ├── package1.nix
│   ├── package2.nix
│   └── subdir/
│       └── default.nix
└── ...more organizations
```

### Organization Pattern

```nix
# GOOD: Organization encapsulation
# pkgs/tangled/default.nix
{ pkgs, lib, buildGoModule, ... }:

let
  organizationMeta = {
    name = "tangled";
    displayName = "Tangled";
    website = "https://tangled.org";
    # ... metadata
  };

  packages = {
    spindle = pkgs.callPackage ./spindle.nix { inherit buildGoModule; };
    appview = pkgs.callPackage ./appview.nix { inherit buildGoModule; };
    # ... more packages
  };

  enhancedPackages = lib.mapAttrs (name: pkg:
    pkg.overrideAttrs (oldAttrs: {
      passthru = (oldAttrs.passthru or {}) // {
        organization = organizationMeta;
      };
    })
  ) packages;

in
enhancedPackages // {
  all = pkgs.symlinkJoin { ... };
  _organizationMeta = organizationMeta;
}
```

**Why**:
- Self-contained organization logic
- Clear responsibility boundaries
- Easy to add new organizations
- Metadata automatically attached

### Naming Convention

```
Pattern: {organization}-{package-name}

Examples:
- tangled-spindle
- blacksky-pds
- plcbundle-plcbundle
- microcosm-constellation

Benefits:
- No naming conflicts across organizations
- Clear ownership/responsibility
- Natural grouping in package browsers
```

---

## Build System Integration

### Language Support

#### Rust (Using Crane)

```nix
# Efficient incremental Rust builds with caching
buildRustPackage = (pkgs: craneLib: {
  src = fetchFromTangled { ... };
  cargoExtraArgs = "--release";
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl sqlite rocksdb ];
}).mkDerivation { };
```

**Best Practices**:
- Use `crane` for efficient builds and caching
- Pin Rust toolchain (stable by default)
- Declare all native and build dependencies
- Use `cargoExtraArgs` for build optimization

#### Go (Using buildGoModule)

```nix
buildGoModule rec {
  pname = "package-name";
  version = "1.0.0";
  src = fetchFromTangled { ... };
  vendorHash = "sha256-...";  # Computed from go.sum
  subPackages = [ "cmd/binary" ];  # Build specific binaries
  ldflags = [ "-s" "-w" "-X main.version=${version}" ];
}.
```

**Best Practices**:
- Always specify `vendorHash` for reproducibility
- Use `subPackages` to build only needed binaries
- Add `ldflags` for version injection
- Include `-s -w` to strip binaries

#### Node.js (Using buildNpmPackage)

```nix
buildNpmPackage rec {
  pname = "package-name";
  version = "1.0.0";
  src = fetchFromTangled { ... };
  npmDepsHash = "sha256-...";  # Computed from package-lock.json
  npm script install;
  npm script build;
}
```

**Best Practices**:
- Specify `npmDepsHash` for reproducibility
- Use `npm script` for custom build steps
- Include lock files in commits
- Test locally before committing

#### Deno (Using custom helpers)

```nix
denoBuild = {
  src = fetchFromTangled { ... };
  mainScript = "src/main.ts";
  permissions = [ "--allow-net" "--allow-read" ];
}
```

**Best Practices**:
- Lock deno.lock for reproducibility
- Specify minimal permissions
- Test with deno.lock included

---

## Metadata and Discovery

### ATProto Metadata Schema

All packages should include ATProto metadata for ecosystem integration:

```nix
{
  atproto = {
    type = "application|library|tool|infrastructure";
    services = [ "service-name" "another-service" ];
    protocols = [ "com.atproto" "com.atproto.service.x" ];
    schemaVersion = "1.0";

    # Optional: Service-specific configuration
    configuration = {
      required = [ "ENV_VAR_1" ];
      optional = [ "ENV_VAR_2" ];
    };

    # Optional: Endpoints this service can connect to
    endpoints = {
      configurable = [ "plc-directory" "atproto-pds" ];
      defaults = {
        plc-directory = "https://plc.directory";
      };
    };
  };

  organization = {
    name = "organization-name";
    displayName = "Display Name";
    website = "https://...";
    description = "What this organization does";
    atprotoFocus = [ "category1" "category2" ];
  };
}
```

### Metadata Benefits

1. **Service Discovery**: Tools can find packages by type/protocol
2. **Configuration Hints**: Auto-documentation of environment variables
3. **Endpoint Management**: Automatic endpoint discovery
4. **Organizational Context**: Clear ownership and responsibility

---

## Common Patterns

### Pattern 1: Shared Library Helper

```nix
# lib/atproto.nix
{
  mkAtprotoPackage = { type, services, ... }@args:
    args // {
      passthru = (args.passthru or {}) // {
        atproto = { inherit type services; };
      };
    };

  mkRustEnv = { };
  mkGoPackage = { };
}

# Usage in packages
buildRustPackage (mkAtprotoPackage {
  type = "application";
  services = [ "my-service" ];
  # ... rest of config
})
```

**Why**: Reduces duplication, enforces consistent metadata.

### Pattern 2: Organization Metadata

```nix
let
  organizationMeta = {
    name = "org-name";
    packageCount = builtins.length (builtins.attrNames packages);
  };
in
{
  _organizationMeta = organizationMeta;
}
```

**Why**: Metadata available for tooling without evaluating all packages.

### Pattern 3: Safe Module Import

```nix
importModule = name:
  let
    modulePath = ./modules + "/${name}";
  in
  if builtins.pathExists modulePath
  then import modulePath
  else { imports = []; };
```

**Why**: Gracefully handles missing modules, doesn't break entire build.

### Pattern 4: Package Filtering

```nix
# Filter packages by buildability
isBuildable = p:
  !(p.meta.broken or false) &&
  builtins.all (lic: lic.free or true) (
    if builtins.isList p.meta.license
    then p.meta.license
    else [ p.meta.license ]
  );

buildPkgs = filter isBuildable (attrValues packages);
```

**Why**: CI only builds what's actually buildable, saves time and failures.

---

## Testing and CI/CD

### CI Strategy

1. **Evaluate Flake**
   ```bash
   nix flake check
   # Ensures no Nix syntax errors
   ```

2. **Build Buildable Packages**
   ```bash
   # ci.nix identifies what can/should be built
   nix build .#buildOutputs -L
   ```

3. **Cache Results**
   ```bash
   nix build .#cacheOutputs
   # Only cache packages marked cacheable
   ```

### Build Markers

```nix
meta = {
  broken = false;         # Skip if true (broken on current nixpkgs)
  license = licenses.mit; # Free software (cacheable)
  preferLocalBuild = false;  # Build on local machine
  platforms = [ "x86_64-linux" "aarch64-linux" ];
  badPlatforms = [ ];
}
```

### Local Testing

```bash
# Evaluate without building
nix flake check

# Build specific package
nix build .#org-packagename -L

# Build and run
nix run .#org-packagename -- --help

# Enter dev environment
nix develop

# Shell with package available
nix shell .#org-packagename
```

---

## Adding New Packages

### Step-by-Step Process

#### 1. Create Organization Directory (if new)

```bash
mkdir -p pkgs/new-org
cat > pkgs/new-org/default.nix << 'EOF'
{ pkgs, lib, buildGoModule, ... }:

let
  organizationMeta = {
    name = "new-org";
    displayName = "New Organization";
    website = "https://...";
    description = "...";
  };

  packages = {
    # Will add packages here
  };

  enhancedPackages = lib.mapAttrs (name: pkg:
    pkg.overrideAttrs (oldAttrs: {
      passthru = (oldAttrs.passthru or {}) // {
        organization = organizationMeta;
      };
    })
  ) packages;

in
enhancedPackages // {
  _organizationMeta = organizationMeta;
}
EOF
```

#### 2. Create Package File

```bash
cat > pkgs/new-org/mypackage.nix << 'EOF'
{ lib, buildGoModule, fetchFromTangled, ... }:

buildGoModule rec {
  pname = "mypackage";
  version = "1.0.0";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@myorg";
    repo = "mypackage";
    rev = "...";
    hash = "sha256-...";
  };

  vendorHash = "sha256-...";
  subPackages = [ "cmd/mypackage" ];

  passthru = {
    atproto = {
      type = "tool";
      services = [ "my-service" ];
      protocols = [ "com.atproto" ];
    };
    organization = {
      name = "new-org";
      # ... etc
    };
  };

  meta = with lib; {
    description = "...";
    homepage = "https://...";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
EOF
```

#### 3. Register in Organization

```nix
# pkgs/new-org/default.nix
packages = {
  mypackage = pkgs.callPackage ./mypackage.nix { inherit buildGoModule; };
};
```

#### 4. Register in Main Package Set

```nix
# pkgs/default.nix
organizationalPackages = {
  # ... existing orgs
  new-org = pkgs.callPackage ./new-org { inherit lib buildGoModule; };
};
```

#### 5. Compute Hashes

```bash
nix build .#new-org-mypackage 2>&1 | grep "got:"
# Copy source hash into mypackage.nix

nix build .#new-org-mypackage 2>&1 | grep "got:"
# Copy vendor hash into mypackage.nix
```

#### 6. Test Build

```bash
nix build .#new-org-mypackage -L
./result/bin/mypackage --version
```

#### 7. Commit

```bash
git add pkgs/new-org/
git commit -m "Add new-org-mypackage package"
```

---

## Troubleshooting

### Issue: "Hash mismatch"

```
Error: hash mismatch in fixed-output derivation ...
  wanted: sha256-AAAA...
  got:    sha256-XXXX...
```

**Solution**:
1. Update hash value from error message
2. Or use placeholder and let Nix compute it:
   ```bash
   hash = "sha256-0000000000000000000000000000000000000000000=";
   nix build ... 2>&1 | grep "got:"
   ```

### Issue: "Cannot find module"

```
error: file not found: (source tree)
```

**Solutions**:
- Check path is relative to flake root
- Verify module exists
- Use `builtins.pathExists` for conditional imports

### Issue: "Dependency conflict"

```
error: Package conflicts: derivation uses X, overlay provides Y
```

**Solutions**:
- Check overlay ordering
- Ensure `inputs.X.follows = "nixpkgs"` for transitive deps
- Use `nix flake update` and rebuild

### Issue: "Package evaluation fails"

**Debug with**:
```bash
nix eval .#packages.x86_64-linux.org-package --show-trace
```

### Issue: "CI fails but works locally"

**Causes**:
- Different system (Linux vs macOS)
- Different nixpkgs version (ci.lock vs local)
- Different Nix version

**Solutions**:
- Test on target system if possible
- Use same nixpkgs version
- Update Nix to latest

---

## Performance Optimization

### Build Caching

1. **Source Caching**: Use `fetchFromTangled` with pinned revisions
2. **Dependency Caching**: Specify exact vendor/npm hashes
3. **Binary Caching**: Mark packages with `meta.license.free`

### Evaluation Caching

1. **Lazy Evaluation**: NUR uses lazy evaluation by default
2. **Avoid Forcing**: Don't use `builtins.deepSeq` unnecessarily
3. **Module Lazy Loading**: `safeModuleImport` loads modules on-demand

### Build Parallelization

1. **Per-System**: Builds for each system run in parallel
2. **Packages**: Independent packages build in parallel
3. **Dependencies**: Nix automatically parallelizes build graph

---

## References

- [Flakes RFC](https://github.com/NixOS/rfcs/blob/master/rfcs/0049-flakes.md)
- [NUR Documentation](https://nur.nix-community.org/)
- [nixpkgs Manual](https://nixos.org/manual/nixpkgs/)
- [Nix Manual](https://nixos.org/manual/nix/)
- [Crane Documentation](https://github.com/ipetkov/crane)
- [buildGoModule](https://nixos.org/manual/nixpkgs/unstable/#go)

---

**Last Updated**: November 4, 2025
**Maintained By**: Tangled
**License**: MIT
