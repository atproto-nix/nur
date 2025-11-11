# NUR Codebase Review & Best Practices Documentation

## Overview

This document provides a comprehensive review of the ATProto NUR repository codebase, highlighting architectural decisions, best practices implemented, and patterns to follow when contributing.

**Date**: November 4, 2025
**Scope**: Analysis of flake.nix, default.nix, lib/atproto.nix, and related files
**Status**: Complete with comprehensive comments added to source files

---

## Architecture Summary

### System Design

The NUR repository follows a **layered, modular architecture** designed for:
- **Multi-language support**: Rust, Go, Node.js, Deno
- **Organizational isolation**: 20+ organizations in separate directories
- **Shared utilities**: Common build logic in lib/ directory
- **Reproducibility**: Hash-based dependency pinning
- **Discoverability**: ATProto metadata for ecosystem integration

### Key Layers

```
Layer 1 (Input Management)
├── nixpkgs (base packages, unstable)
├── crane (Rust builds)
├── rust-overlay (Rust toolchain)
└── deno (JavaScript runtime)
           ▼
Layer 2 (Package Definition)
├── flake.nix (multi-system output logic)
├── default.nix (package aggregation)
├── pkgs/*/default.nix (organization-specific packages)
└── pkgs/*/**.nix (individual package definitions)
           ▼
Layer 3 (Build Utilities)
├── lib/atproto.nix (shared build helpers)
├── lib/organizational-framework.nix (package mapping)
└── lib/packaging/* (language-specific utilities)
           ▼
Layer 4 (Output Generation)
├── packages (flake outputs)
├── modules (NixOS service configs)
└── overlay (nixpkgs integration)
```

---

## Best Practices Implemented

### 1. Multi-System Support

**Location**: `flake.nix` lines 23-84

**Pattern**:
```nix
forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
packages = forAllSystems (system: (preparePackages system).packages);
```

**Benefits**:
- ✅ Single definition for all systems (x86_64-linux, aarch64-linux, etc.)
- ✅ Automatic platform detection
- ✅ No duplication or manual system listing
- ✅ Scales as nixpkgs adds new systems

**When to use**: Always use `forAllSystems` when exposing packages, modules, or other outputs.

---

### 2. Input Pinning via `.follows`

**Location**: `flake.nix` lines 41-59

**Pattern**:
```nix
crane = {
  url = "github:ipetkov/crane/master";
  inputs.nixpkgs.follows = "nixpkgs";  # Pin to same nixpkgs
};
```

**Benefits**:
- ✅ Prevents version conflicts between dependencies
- ✅ Reduces closure size (fewer nixpkgs copies)
- ✅ Ensures consistent environment across all tools
- ✅ Makes `flake.lock` smaller and more maintainable

**When to use**: Every transitive dependency should follow the main nixpkgs input.

---

### 3. Overlay Ordering

**Location**: `flake.nix` lines 104-116

**Pattern**:
```nix
overlays = [
  rust-overlay.overlays.default,    # Language tooling first
  deno.overlays.default,             # More language tooling
  (final: prev: {
    fetchFromTangled = final.callPackage ./lib/fetch-tangled.nix { };
  })                                  # Custom utilities last
];
```

**Benefits**:
- ✅ Later overlays can build on earlier ones
- ✅ Custom overlays can use language-specific features
- ✅ Clear dependency graph between overlays
- ✅ Prevents "undefined variable" errors

**When to use**: Order overlays from most fundamental to most specific.

---

### 4. Package Filtering & Selection

**Location**: `default.nix` lines 68-80, `ci.nix` lines 18-22

**Pattern**:
```nix
isValidPackage = pkg:
  (pkg.type or "" == "derivation") ||
  (builtins.isAttrs pkg && pkg ? outPath) ||
  (builtins.isAttrs pkg && pkg ? drvPath) ||
  (builtins.isAttrs pkg && (
    builtins.hasAttr "pname" pkg ||
    builtins.hasAttr "name" pkg ||
    builtins.hasAttr "version" pkg ||
    builtins.hasAttr "meta" pkg
  ));

isBuildable = p:
  !(p.meta.broken or false) &&
  builtins.all (lic: lic.free or true) (
    if builtins.isList p.meta.license
    then p.meta.license
    else [ p.meta.license ]
  );
```

**Benefits**:
- ✅ Handles multiple derivation formats
- ✅ CI only builds what's actually buildable
- ✅ Prevents "broken" packages from delaying CI
- ✅ Saves resources by skipping non-free software
- ✅ Robust against edge cases

**When to use**: Use these predicates to filter package sets before building.

---

### 5. Organization Pattern

**Location**: `pkgs/ORGANIZATION/default.nix` (all organizations)

**Pattern**:
```nix
{ pkgs, lib, buildGoModule, ... }:

let
  organizationMeta = {
    name = "organization-name";
    displayName = "Display Name";
    website = "https://...";
    description = "...";
    atprotoFocus = [ "category" ];
  };

  packages = {
    package1 = pkgs.callPackage ./package1.nix { inherit buildGoModule; };
    package2 = pkgs.callPackage ./package2.nix { inherit buildGoModule; };
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

**Benefits**:
- ✅ Encapsulates organization-specific logic
- ✅ Automatic metadata attachment to all packages
- ✅ Clear responsibility and ownership
- ✅ Easy to add new packages to organization
- ✅ Metadata available without evaluating all packages

**When to use**: All packages must be in organizational directories following this pattern.

---

### 6. Metadata Validation

**Location**: `lib/atproto.nix` lines 51-68

**Pattern**:
```nix
validateAtprotoMetadata = metadata:
  let
    requiredFields = [ "type" "services" "protocols" ];
    validTypes = [ "application" "library" "tool" ];
    hasRequiredFields = builtins.all (field: builtins.hasAttr field metadata) requiredFields;
    validType = builtins.elem metadata.type validTypes;
  in
  if !hasRequiredFields then
    throw "ATProto metadata missing required fields: ..."
  else if !validType then
    throw "ATProto metadata type must be one of: ..."
  else
    true;
```

**Benefits**:
- ✅ Catches configuration errors at definition time
- ✅ Clear, actionable error messages
- ✅ Prevents invalid packages from building
- ✅ Enables tooling that relies on metadata

**When to use**: Always validate complex metadata structures.

---

### 7. Language-Specific Helpers

**Location**: `lib/atproto.nix` lines 110-207

**Helpers**:
- `mkRustAtprotoService`: Rust with standard environment
- `mkGoAtprotoApp`: Go with standard configuration
- `mkNodeAtprotoApp`: Node.js with standard build
- `mkAtprotoPackage`: Generic metadata injection

**Benefits**:
- ✅ Reduces boilerplate in package definitions
- ✅ Ensures consistent build environments
- ✅ Automatic ATProto metadata injection
- ✅ Single source of truth for environment variables
- ✅ Easy to update build configuration globally

**Example - Rust**:
```nix
mkRustAtprotoService {
  pname = "my-service";
  version = "1.0.0";
  src = fetchFromTangled { ... };
  type = "application";
  services = [ "my-service" ];
  # Standard Rust env, dependencies, and flags automatically applied
}
```

**When to use**: Use language-specific helpers for all new packages.

---

### 8. Workspace Build Optimization

**Location**: `lib/atproto.nix` lines 259-299

**Pattern**:
```nix
mkRustWorkspace = args:
  let
    # Build shared dependencies once
    cargoArtifacts = craneLib.buildDepsOnly { ... };

    # Build individual members using shared cache
    buildMember = member: craneLib.buildPackage {
      inherit src cargoArtifacts;
      cargoExtraArgs = "--package ${member}";
    };
  in
  lib.genAttrs members buildMember;
```

**Benefits**:
- ✅ Dependencies compiled once, reused for all members
- ✅ Significant build time savings
- ✅ Better cache utilization
- ✅ Enables efficient monorepo builds

**When to use**: Use for Rust workspaces with multiple members.

---

### 9. Default Package Provision

**Location**: `flake.nix` lines 155-165

**Pattern**:
```nix
packages = selectedPackages // {
  default = pkgs.symlinkJoin {
    name = "atproto-nur-all";
    paths = builtins.attrValues selectedPackages;
  };
};
```

**Benefits**:
- ✅ `nix build` works without specifying package
- ✅ Easy to test all packages at once
- ✅ Useful for CI to verify nothing is broken
- ✅ Better user experience

**When to use**: Always provide a default package that builds all packages.

---

### 10. Service Configuration Helpers

**Location**: `lib/atproto.nix` lines 327-396

**Pattern**:
```nix
mkServiceConfig = {
  serviceName, package, user ? serviceName, ...
}:
{
  # Service user/group configuration
  userConfig = { ${user} = { isSystemUser = true; }; };

  # Standard systemd hardening
  systemdConfig = {
    serviceConfig = {
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      # ... more hardening
    };
  };
};
```

**Benefits**:
- ✅ Consistent security hardening across all services
- ✅ Reduces boilerplate in NixOS modules
- ✅ One place to improve security for all services
- ✅ Clear service configuration structure

**When to use**: Use when creating NixOS service modules.

---

## Code Quality Observations

### Strengths

1. **Clear Separation of Concerns**
   - Build configuration separate from package definitions
   - Organizational logic isolated per organization
   - Shared utilities in dedicated lib/ directory

2. **Robust Error Handling**
   - Clear error messages for configuration mistakes
   - Metadata validation catches errors early
   - Safe module imports don't break entire build

3. **DRY (Don't Repeat Yourself)**
   - Shared helpers reduce duplication
   - Standard environment variables defined once
   - Organization pattern applied consistently

4. **Discoverability**
   - ATProto metadata enables ecosystem integration
   - Clear package naming conventions
   - Organizational metadata exported separately

5. **Reproducibility**
   - Hash-based dependency pinning
   - Build flags and environment documented
   - Workspace caching optimization

### Areas for Enhancement

1. **Documentation**
   - ✅ **ADDRESSED**: Best practices guide created (`NUR_BEST_PRACTICES.md`)
   - ✅ **ADDRESSED**: Code comments added to key files
   - Could expand examples for each package type

2. **Testing**
   - Consider integration tests for workspace builds
   - Add tests for metadata validation
   - Test package filtering predicates

3. **Performance**
   - Consider lazy evaluation for large package sets
   - Profile build times for workspace optimization
   - Evaluate caching strategy effectiveness

4. **Extensibility**
   - Document how to add new organizations
   - Create template for new package types
   - Provide migration guide for legacy packages

---

## File-by-File Analysis

### flake.nix

**Purpose**: Define inputs, outputs, and multi-system logic
**Lines**: ~220 (with new comments)
**Complexity**: Medium

**Key Sections**:
- Lines 1-60: Inputs with proper pinning
- Lines 62-173: Output generation per system
- Lines 175-210: Flake outputs and modules

**Best Practices**:
- ✅ Multi-system support via `forAllSystems`
- ✅ Proper input pinning
- ✅ Overlay ordering and application
- ✅ Complete context passing to packages

**Improvements Made**:
- Added 60+ lines of best practices comments
- Documented each input and its purpose
- Explained overlay ordering rationale
- Clarified context passing strategy

---

### default.nix

**Purpose**: Package aggregation and library initialization
**Lines**: ~115 (with new comments)
**Complexity**: Medium

**Key Sections**:
- Lines 1-80: Header comments and package detection
- Lines 82-115: Module import and export

**Best Practices**:
- ✅ Robust package detection
- ✅ Safe module imports
- ✅ Metadata context passing
- ✅ Clear error messages

**Improvements Made**:
- Added 50+ lines of best practices comments
- Documented package detection logic
- Explained metadata context usage
- Clarified module import strategy

---

### lib/atproto.nix

**Purpose**: Shared build helpers and utilities
**Lines**: ~491
**Complexity**: High

**Key Sections**:
- Lines 51-68: Metadata validation
- Lines 110-207: Language-specific helpers
- Lines 259-299: Workspace optimization
- Lines 327-396: Service configuration

**Best Practices**:
- ✅ Metadata validation with clear errors
- ✅ Language-specific build helpers
- ✅ Workspace caching optimization
- ✅ Service security hardening

**Improvements Made**:
- Added 30+ lines of best practices comments
- Documented helper functions and their use cases
- Explained validation strategy
- Highlighted workspace optimization benefits

---

### overlay.nix

**Purpose**: Provide nixpkgs overlay for non-flake usage
**Lines**: ~68
**Complexity**: Medium

**Key Sections**:
- Lines 1-19: Header and helper functions
- Lines 20-62: Package mapping and filtering
- Lines 64-68: Final overlay export

**Best Practices**:
- ✅ Platform support filtering
- ✅ Safe package collection access
- ✅ Package prefixing for namespace isolation
- ✅ Fallback error handling

---

### ci.nix

**Purpose**: Define cacheable and buildable packages for CI
**Lines**: ~58
**Complexity**: Low-Medium

**Key Sections**:
- Lines 14-23: Package classification predicates
- Lines 29-36: Package flattening logic
- Lines 49-57: Cache definition

**Best Practices**:
- ✅ Buildability predicate
- ✅ Cacheability predicate
- ✅ Proper license handling
- ✅ Output aggregation

---

## Adding Comments to Source Code

### Locations with New Comments

1. **flake.nix** (lines 1-173)
   - Header explaining best practices
   - Input organization comments
   - Output generation explanation
   - Context passing documentation

2. **default.nix** (lines 1-80)
   - Header explaining architecture
   - Package detection logic documentation
   - Metadata validation notes
   - Module import strategy

3. **lib/atproto.nix** (lines 1-51)
   - Header explaining shared library purpose
   - Metadata validation strategy
   - Language-specific helper documentation
   - Organizational framework notes

### Comment Style

All comments follow this pattern:
- **Section headers**: `# ==...===` for major sections
- **Inline comments**: Explain "why" not "what"
- **Code comments**: Explain non-obvious logic
- **Best practices**: Highlight patterns to follow

---

## Lessons Learned

### What Works Well

1. **Organization Separation**: Keeps packages organized and maintainable
2. **Shared Helpers**: Reduces code duplication significantly
3. **Metadata Validation**: Catches errors early
4. **Multi-System Support**: Scales naturally
5. **Clear Error Messages**: Aids debugging

### What to Improve

1. **Template Documentation**: Add starter examples for new packages
2. **Integration Tests**: Verify helper functions work correctly
3. **Performance Profiling**: Measure impact of workspace optimization
4. **Migration Guides**: Help contributors update legacy packages

---

## Recommendations for Contributors

### When Adding a New Package

1. **Choose Organization**: Add to existing org or create new one
2. **Follow Pattern**: Use appropriate language-specific helper
3. **Add Metadata**: Include type, services, protocols
4. **Test Build**: `nix build .#org-package -L`
5. **Verify Metadata**: Check ATProto metadata is correct
6. **Register**: Add to organization's default.nix

### When Modifying Build System

1. **Update Helper**: Make change in lib/atproto.nix
2. **Test All**: Verify all package types still work
3. **Document**: Add comments explaining change
4. **CI Test**: Ensure CI still builds all packages
5. **Update Guide**: Document new pattern in this file

### When Reviewing Code

1. **Check Organization**: Is package in right directory?
2. **Verify Metadata**: Does metadata match package?
3. **Test Build**: Does it build without errors?
4. **Review Helpers**: Is there code duplication?
5. **Check Security**: Are systemd hardening settings applied?

---

## Summary

The ATProto NUR repository demonstrates **excellent architecture and best practices** for a large, multi-language Nix package repository:

✅ **Clear separation of concerns**
✅ **Robust error handling**
✅ **Extensive code reuse**
✅ **Comprehensive metadata**
✅ **Performance optimization**
✅ **Well-organized structure**

The repository serves as a **model for NUR projects** and demonstrates how to effectively manage 48+ packages across 20+ organizations while maintaining consistency and discoverability.

---

## Document Status

- **Created**: November 4, 2025
- **Scope**: Comprehensive code review and best practices
- **Status**: Complete
- **Coverage**: All major files reviewed and documented
- **Comments Added**: Comprehensive annotations in source files

**Related Documents**:
- `NUR_BEST_PRACTICES.md` - Detailed best practices and patterns
- `CLAUDE.md` - Repository development guide
- Source files (flake.nix, default.nix, lib/atproto.nix) - With added comments

---

**Maintained By**: Tangled
**License**: MIT
