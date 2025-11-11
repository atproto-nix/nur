# Packages and Modules Organization Guide

## Overview

This guide explains how the NUR organizes packages and NixOS modules, providing patterns and best practices for both contributing new packages and creating service modules.

## Table of Contents

1. [Package Organization (pkgs/)](#package-organization)
2. [Module Organization (modules/)](#module-organization)
3. [Package Creation Guide](#package-creation-guide)
4. [Module Creation Guide](#module-creation-guide)
5. [Common Patterns](#common-patterns)
6. [Best Practices](#best-practices)

---

## Package Organization

### Directory Structure

```
pkgs/
├── default.nix                    # Main aggregator - imports all organizations
├── ORGANIZATION/
│   ├── default.nix               # Organization's package collection
│   ├── package1.nix              # Individual package
│   ├── package2.nix              # Individual package
│   └── subdir/
│       └── default.nix           # Nested package organization
└── [20+ organizations]
```

### Organization-Level Structure

Each organization directory contains:

```nix
# pkgs/ORGANIZATION/default.nix

{ pkgs, lib, buildGoModule, ... }:

let
  # STEP 1: Define organization metadata
  organizationMeta = {
    name = "organization-name";
    displayName = "Display Name";
    website = "https://...";
    description = "What this organization does";
    atprotoFocus = [ "category1" "category2" ];
  };

  # STEP 2: Import individual packages (simple local names)
  packages = {
    package1 = pkgs.callPackage ./package1.nix { inherit buildGoModule; };
    package2 = pkgs.callPackage ./package2.nix { inherit lib; };
  };

  # STEP 3: Enhance packages with organization metadata
  enhancedPackages = lib.mapAttrs (name: pkg:
    pkg.overrideAttrs (oldAttrs: {
      passthru = (oldAttrs.passthru or {}) // {
        organization = organizationMeta;
      };
    })
  ) packages;

  # STEP 4: Create "all" package for testing
  allPackages = pkgs.symlinkJoin {
    name = "org-all";
    paths = lib.filter (pkg: pkg != packages.static-files) (lib.attrValues packages);
  };

in
# STEP 5: Export packages and metadata
enhancedPackages // {
  all = allPackages;
  _organizationMeta = organizationMeta;
}
```

### Main Aggregator (pkgs/default.nix)

The main aggregator:

1. **Imports all organizations** with proper context:
   ```nix
   organizationalPackages = {
     organization-name = pkgs.callPackage ./organization-name { inherit lib buildGoModule; };
   };
   ```

2. **Flattens namespace** from `org/package` to `org-package`:
   ```nix
   # Tangled organization has: { spindle, appview, knot }
   # Flattened to: { tangled-spindle, tangled-appview, tangled-knot }
   ```

3. **Exports organizational metadata** separately:
   ```nix
   _organizationalMetadata = lib.mapAttrs (org: packages:
     packages._organizationMeta or null
   ) organizationalPackages;
   ```

### Best Practices for Package Organization

#### 1. Use Simple Local Names

```nix
# GOOD: Simple name within organization
packages = {
  spindle = pkgs.callPackage ./spindle.nix { ... };
};

# BAD: Prefixed name (prefix added at aggregation layer)
packages = {
  tangled-spindle = pkgs.callPackage ./spindle.nix { ... };
};
```

**Why**: Allows flexibility within organization, prefixing happens automatically.

#### 2. Include Organization Metadata

```nix
organizationMeta = {
  name = "tangled";              # Required: unique identifier
  displayName = "Tangled";       # Required: human readable
  website = "https://...";       # Recommended: organization site
  description = "...";           # Recommended: organization purpose
  atprotoFocus = [ "tools" ];    # Recommended: ecosystem categories
};
```

**Why**: Enables discovery, documentation, and ecosystem integration.

#### 3. Enhance All Packages Consistently

```nix
# GOOD: Automatic enhancement
enhancedPackages = lib.mapAttrs (name: pkg:
  pkg.overrideAttrs (oldAttrs: {
    passthru = (oldAttrs.passthru or {}) // {
      organization = organizationMeta;
    };
  })
) packages;

# BAD: Manual enhancement for each package (error-prone)
spindle = packages.spindle // {
  passthru = (packages.spindle.passthru or {}) // {
    organization = organizationMeta;
  };
};
appview = packages.appview // { ... };  # Repetition
```

**Why**: Ensures consistency, reduces errors, scales automatically.

#### 4. Create "All" Package

```nix
allPackages = pkgs.symlinkJoin {
  name = "org-all";
  paths = lib.attrValues packages;
};

# Export
enhancedPackages // {
  all = allPackages;
}

# Usage:
# nix build .#org-all    # Build all packages in organization
# nix run .#org-all      # Run all packages (symlinks in result)
```

**Why**:
- Easy testing of entire organization
- Useful for CI verification
- Quick sanity check that nothing is broken

#### 5. Export Metadata Separately

```nix
# Export metadata without evaluating packages
_organizationMeta = organizationMeta;

# Available via:
# nix eval '.#organizations.org._organizationMeta'
# Used by tooling and documentation generators
```

**Why**: Metadata available without evaluating all packages (performance).

---

## Module Organization

### Directory Structure

```
modules/
├── default.nix                          # Main module aggregator
├── ORGANIZATION/
│   ├── default.nix                     # Organization's module collection
│   ├── service1.nix                    # Service module
│   ├── service2.nix                    # Service module
│   └── lib/
│       └── helpers.nix                 # Shared module utilities
└── [20+ organizations]
```

### Organization-Level Module Structure

```nix
# modules/ORGANIZATION/default.nix

{ ... }:

{
  imports = [
    ./service1.nix
    ./service2.nix
    ./service3.nix
  ];
}
```

### Individual Service Module Pattern

```nix
# modules/ORGANIZATION/service.nix

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.org-service;
  atprotoLib = pkgs.callPackage ../../lib/atproto.nix { };
in

{
  # STEP 1: Define options
  options.services.org-service = {
    enable = mkEnableOption "org service";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.org-service;
      description = "Package to use";
    };

    user = mkOption {
      type = types.str;
      default = "org-service";
      description = "User account name";
    };

    # ... more options
  };

  # STEP 2: Implement configuration
  config = mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
    };
    users.groups.${cfg.user} = { };

    # Create systemd service
    systemd.services.org-service = {
      description = "Organization Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.user;
        ExecStart = "${cfg.package}/bin/service-binary";

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
      };
    };

    # Create state directory
    systemd.tmpfiles.rules = [
      "d '/var/lib/org-service' 0750 ${cfg.user} ${cfg.user} - -"
    ];
  };
}
```

### Best Practices for Modules

#### 1. Use Standard Module Pattern

```nix
# GOOD: Standard NixOS module pattern
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.myservice;
in
{
  options.services.myservice = { /* ... */ };
  config = mkIf cfg.enable { /* ... */ };
}

# BAD: Unconventional structure
{ config, pkgs, ... }:
{
  # Mixes options and config without clear separation
  # Hard to understand what's optional vs. required
}
```

**Why**: Matches NixOS conventions, familiar to users.

#### 2. Organize with Helpers

```nix
# modules/ORGANIZATION/lib/helpers.nix
{ lib, pkgs, ... }:

{
  # Shared functions
  mkServiceConfig = { serviceName, package, user ? serviceName }:
    { /* ... */ };

  # Shared defaults
  defaultSecurityConfig = { /* ... */ };
}

# modules/ORGANIZATION/service.nix
{ config, lib, pkgs, ... }:

let
  helpers = import ./lib/helpers.nix { inherit lib pkgs; };
in
{
  # Use helpers
  config.systemd.services.myservice.serviceConfig =
    helpers.mkServiceConfig { /* ... */ };
}
```

**Why**: Reduces duplication across related modules.

#### 3. Include Security Hardening

```nix
systemd.services.myservice.serviceConfig = {
  # Security hardening (standard set)
  NoNewPrivileges = true;
  ProtectSystem = "strict";
  ProtectHome = true;
  PrivateTmp = true;
  ProtectKernelTunables = true;
  ProtectKernelModules = true;
  ProtectControlGroups = true;
  RestrictSUIDSGID = true;
  RestrictRealtime = true;
  RestrictNamespaces = true;
  LockPersonality = true;
  MemoryDenyWriteExecute = true;

  # File system access
  ReadWritePaths = [ "/var/lib/myservice" ];
  ReadOnlyPaths = [ "/nix/store" ];
};
```

**Why**: Provides defense-in-depth security.

#### 4. Use Environment Variables for Configuration

```nix
systemd.services.myservice.environment = {
  SERVICE_HOST = cfg.host;
  SERVICE_PORT = toString cfg.port;
  LOG_LEVEL = cfg.logLevel;
};
```

**Why**: Easy to change without modifying code.

#### 5. Document Configuration Options

```nix
options.services.myservice.port = mkOption {
  type = types.port;
  default = 8080;
  example = 9000;
  description = ''
    Port to listen on.
    Note: Requires elevation if using ports < 1024.
  '';
};
```

**Why**: Users understand what options do and when to use them.

---

## Package Creation Guide

### Step-by-Step Process

#### 1. Create Organization (if new)

```bash
mkdir -p pkgs/myorg
cat > pkgs/myorg/default.nix << 'EOF'
{ pkgs, lib, buildGoModule ? pkgs.buildGoModule, ... }:

let
  organizationMeta = {
    name = "myorg";
    displayName = "My Organization";
    website = "https://...";
    description = "...";
    atprotoFocus = [ "tools" ];
  };

  packages = {
    # Packages go here
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
cat > pkgs/myorg/mypackage.nix << 'EOF'
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

  meta = with lib; {
    description = "...";
    homepage = "https://...";
    license = licenses.mit;
    platforms = platforms.unix;
  };

  passthru = {
    atproto = {
      type = "tool";
      services = [ "myservice" ];
      protocols = [ "com.atproto" ];
    };
  };
}
EOF
```

#### 3. Register in Organization

```nix
# pkgs/myorg/default.nix
packages = {
  mypackage = pkgs.callPackage ./mypackage.nix { inherit buildGoModule; };
};
```

#### 4. Register in Main Aggregator

```nix
# pkgs/default.nix
organizationalPackages = {
  # ... existing organizations
  myorg = pkgs.callPackage ./myorg { inherit lib buildGoModule; };
};
```

#### 5. Compute Hashes

```bash
nix build .#myorg-mypackage 2>&1 | grep "got:"
# Copy hash into mypackage.nix
# Repeat for vendorHash
```

#### 6. Test Build

```bash
nix build .#myorg-mypackage -L
./result/bin/mypackage --version
```

---

## Module Creation Guide

### Step-by-Step Process

#### 1. Create Organization Module Directory

```bash
mkdir -p modules/myorg
cat > modules/myorg/default.nix << 'EOF'
{ ... }:

{
  imports = [
    ./myservice.nix
  ];
}
EOF
```

#### 2. Create Service Module

```bash
cat > modules/myorg/myservice.nix << 'EOF'
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.myorg-myservice;
in

{
  options.services.myorg-myservice = {
    enable = mkEnableOption "My Service";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.myorg-mypackage;
      description = "Package to use";
    };

    user = mkOption {
      type = types.str;
      default = "myservice";
      description = "User account name";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port to listen on";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
    };
    users.groups.${cfg.user} = { };

    systemd.services.myorg-myservice = {
      description = "My Organization Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        ExecStart = "${cfg.package}/bin/myservice";

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/myservice" ];
      };

      environment = {
        SERVICE_PORT = toString cfg.port;
      };
    };
  };
}
EOF
```

#### 3. Register in Main Module Aggregator

```nix
# modules/default.nix or in flake.nix
moduleList = [
  # ... existing modules
  "myorg"
];
```

#### 4. Test Configuration

```bash
# Create test configuration
cat > test-myorg.nix << 'EOF'
{ config, pkgs, ... }:

{
  imports = [ ./modules ];

  services.myorg-myservice = {
    enable = true;
    port = 9000;
  };
}
EOF

# Test in NixOS VM
nixos-rebuild test --flake '.#test-myorg'
```

---

## Common Patterns

### Multi-Package Organization

```nix
# pkgs/myorg/default.nix
packages = {
  cli = pkgs.callPackage ./cli.nix { inherit buildGoModule; };
  server = pkgs.callPackage ./server.nix { inherit buildGoModule; };
  library = pkgs.callPackage ./library.nix { };

  # Utilities
  utils = pkgs.callPackage ./utils { };
};

# Flattened to:
# myorg-cli, myorg-server, myorg-library, myorg-utils
```

### Rust Workspace Organization

```nix
# pkgs/myorg/workspace.nix
{ lib, buildRustPackage, src, ... }:

let
  # Build all members with shared dependencies
  workspace = lib.genAttrs [ "member1" "member2" "member3" ] (member:
    buildRustPackage rec {
      pname = member;
      version = "1.0.0";
      inherit src;
      cargoExtraArgs = "--package ${member}";
    }
  );
in
workspace
```

### Layered Service Configuration

```nix
# modules/myorg/lib/helpers.nix
{ lib, ... }:

{
  mkServiceConfig = { serviceName, package, ... }:
    let
      user = serviceName;
    in
    {
      users.users.${user} = { isSystemUser = true; group = user; };
      users.groups.${user} = { };

      systemd.services.${serviceName} = {
        inherit (config.services.${serviceName}) description wantedBy after;
        serviceConfig = { /* shared hardening */ };
      };
    };
}
```

---

## Best Practices Summary

### For Packages

✅ Use simple local names within organization
✅ Define comprehensive organization metadata
✅ Enhance all packages automatically
✅ Create "all" packages for testing
✅ Export metadata separately
✅ Follow consistent naming conventions
✅ Use language-specific helpers
✅ Include ATProto metadata

### For Modules

✅ Follow standard NixOS module pattern
✅ Use `mkIf` for conditional configuration
✅ Include security hardening
✅ Document all options
✅ Use environment variables for config
✅ Create helper libraries for shared logic
✅ Test configuration before committing
✅ Include proper user/group setup

### For Both

✅ Keep organization logic self-contained
✅ Avoid duplication across packages/modules
✅ Write clear, descriptive comments
✅ Include ATProto metadata
✅ Test with multiple systems/scenarios
✅ Maintain backward compatibility
✅ Document breaking changes
✅ Link to upstream documentation

---

## Examples

### Simple Go Package

```nix
# pkgs/myorg/myapp.nix
{ lib, buildGoModule, fetchFromTangled, ... }:

buildGoModule rec {
  pname = "myapp";
  version = "1.0.0";
  src = fetchFromTangled { /* ... */ };
  vendorHash = "sha256-...";

  meta = with lib; {
    description = "My application";
    homepage = "https://...";
    license = licenses.mit;
  };
}
```

### Simple Service Module

```nix
# modules/myorg/myservice.nix
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.myservice;
in {
  options.services.myservice = {
    enable = mkEnableOption "My Service";
  };

  config = mkIf cfg.enable {
    systemd.services.myservice = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart = "${pkgs.nur.myapp}/bin/myapp";
    };
  };
}
```

---

**Last Updated**: November 4, 2025
**Maintained By**: Tangled
**License**: MIT
