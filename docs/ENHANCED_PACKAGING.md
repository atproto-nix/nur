# Enhanced Multi-Language Build Coordination

This document describes the enhanced multi-language build coordination features implemented in the ATproto NUR packaging library.

## Overview

The enhanced packaging library (`lib/packaging.nix`) provides improved build functions for coordinating complex multi-language ATproto projects. These functions offer better shared artifact management, enhanced error handling, and comprehensive cross-language integration support.

## Enhanced Build Functions

### buildRustWorkspace

Enhanced Rust workspace packaging with improved shared artifacts:

```nix
buildRustWorkspace {
  owner = "example";
  repo = "rust-workspace";
  rev = "v1.0.0";
  sha256 = "...";
  members = [ "service-a" "service-b" "cli-tool" ];
  memberConfigs = {
    "service-a" = {
      description = "API service";
      doCheck = true;
      env = { CUSTOM_VAR = "value"; };
    };
    "service-b" = {
      description = "Worker service";
      doCheck = false;
    };
  };
}
```

**Key Features:**
- Shared dependency artifacts with enhanced caching
- Per-member configuration support
- Automatic workspace member validation
- Improved build performance through artifact reuse

### buildPnpmWorkspace

Enhanced pnpm workspace packaging for complex Node.js monorepos:

```nix
buildPnpmWorkspace {
  owner = "example";
  repo = "node-monorepo";
  rev = "v1.0.0";
  sha256 = "...";
  workspaces = [ "frontend" "backend" "shared" ];
  workspaceConfigs = {
    "frontend" = {
      description = "React frontend";
      buildPhase = "pnpm build:prod";
    };
    "backend" = {
      description = "Express API";
      buildInputs = [ pkgs.postgresql ];
    };
  };
}
```

**Key Features:**
- Automatic pnpm catalog dependency processing
- Shared node_modules management
- Per-workspace configuration support
- Enhanced build artifact detection

### buildGoAtprotoModule

Enhanced Go module packaging with ATproto-specific environment:

```nix
buildGoAtprotoModule {
  owner = "example";
  repo = "go-services";
  rev = "v1.0.0";
  sha256 = "...";
  services = [ "api" "worker" "cli" ];
  serviceConfigs = {
    "api" = {
      description = "HTTP API server";
      path = "cmd/api";
      ldflags = [ "-X main.version=1.0.0" ];
    };
    "worker" = {
      description = "Background worker";
      path = "cmd/worker";
      env = { WORKER_THREADS = "4"; };
    };
  };
}
```

**Key Features:**
- Enhanced CGO support for ATproto dependencies
- Per-service configuration and build flags
- Automatic service validation
- Improved dependency management

### buildDenoApp

Enhanced Deno application packaging for TypeScript ATproto applications:

```nix
buildDenoApp {
  owner = "example";
  repo = "deno-app";
  rev = "v1.0.0";
  sha256 = "...";
  pname = "atproto-deno-service";
}
```

**Key Features:**
- Automatic Deno configuration detection
- Enhanced build artifact detection
- Proper SSL certificate handling for HTTPS imports
- Comprehensive error handling and fallbacks

## Multi-Language Coordination

### buildMultiLanguageProject

Coordinate builds across multiple languages in a single project:

```nix
buildMultiLanguageProject {
  buildRustFn = packaging.buildRustAtprotoPackage;
  buildNodeFn = packaging.buildNodeAtprotoPackage;
  buildGoFn = packaging.buildGoAtprotoModule;
  buildDenoFn = packaging.buildDenoApp;
} {
  src = fetchFromGitHub { ... };
  components = {
    "rust-backend" = {
      language = "rust";
      sourceRoot = "backend";
      autoStart = true;
    };
    "node-frontend" = {
      language = "nodejs";
      sourceRoot = "frontend";
    };
    "go-worker" = {
      language = "go";
      sourceRoot = "worker";
      services = [ "worker" ];
    };
  };
  coordinationStrategy = "orchestrated";
}
```

### Cross-Language Interface Validation

Validate interfaces between components:

```nix
validateCrossLanguageInterfaces {
  components = {
    rust-service = rustPackage;
    node-service = nodePackage;
  };
  interfaceSpecs = {
    "api" = { version = "v1"; };
  };
}
```

### Shared Dependency Management

Create shared dependencies for better build performance:

```nix
# Rust shared dependencies
rustDeps = createSharedDependencies {
  language = "rust";
  src = projectSrc;
  pname = "project-rust-deps";
};

# Node.js shared dependencies
nodeDeps = createSharedDependencies {
  language = "nodejs";
  src = projectSrc;
  pname = "project-node-deps";
  npmDepsHash = "sha256-...";
};
```

## Build Coordination Utilities

### coordinateBuildOrder

Automatically determine optimal build order based on dependencies:

```nix
buildOrder = coordinateBuildOrder {
  components = {
    "shared-lib" = { dependencies = []; };
    "api-service" = { dependencies = [ "shared-lib" ]; };
    "frontend" = { dependencies = [ "api-service" ]; };
  };
};
# Result: [ "shared-lib" "api-service" "frontend" ]
```

### monitorBuildPerformance

Monitor build performance for optimization:

```nix
perfReport = monitorBuildPerformance {
  component = myPackage;
};
```

## Usage Examples

### Complex ATproto Application

```nix
# Build a complex ATproto application with multiple languages
let
  atprotoApp = packaging.buildMultiLanguageProject {
    buildRustFn = packaging.buildRustAtprotoPackage;
    buildNodeFn = packaging.buildPnpmWorkspace;
    buildGoFn = packaging.buildGoAtprotoModule;
  } {
    src = fetchFromGitHub {
      owner = "atproto-org";
      repo = "complex-app";
      rev = "v2.0.0";
      sha256 = "sha256-...";
    };
    
    components = {
      "pds-server" = {
        language = "rust";
        sourceRoot = "pds";
        description = "Personal Data Server";
      };
      "web-interface" = {
        language = "nodejs";
        sourceRoot = "web";
        workspaces = [ "frontend" "admin" ];
      };
      "relay-service" = {
        language = "go";
        sourceRoot = "relay";
        services = [ "relay" "indexer" ];
      };
    };
    
    coordinationStrategy = "orchestrated";
  };
in
atprotoApp
```

### Workspace with Shared Dependencies

```nix
# Build Rust workspace with optimized shared dependencies
let
  sharedDeps = packaging.createSharedDependencies {
    language = "rust";
    src = workspaceSrc;
    pname = "atproto-workspace-deps";
  };
  
  workspace = packaging.buildRustWorkspace {
    owner = "atproto-org";
    repo = "rust-workspace";
    rev = "v1.5.0";
    sha256 = "sha256-...";
    
    members = [ "pds" "relay" "cli" "shared" ];
    
    memberConfigs = {
      "pds" = {
        description = "Personal Data Server";
        doCheck = true;
        env = { PDS_VERSION = "1.5.0"; };
      };
      "relay" = {
        description = "ATproto Relay";
        buildInputs = [ pkgs.rocksdb ];
      };
      "cli" = {
        description = "ATproto CLI tools";
        mainProgram = "atproto";
      };
    };
  };
in
workspace
```

## Testing

The enhanced packaging functions include comprehensive tests in `tests/enhanced-packaging.nix`. Run tests with:

```bash
nix-build tests/enhanced-packaging.nix -A runAllTests
```

## Migration from Basic Functions

The enhanced functions are backward-compatible with existing usage patterns. To migrate:

1. Replace `buildRustAtprotoPackage` calls with `buildRustWorkspace` for multi-package Rust projects
2. Use `buildPnpmWorkspace` instead of `buildNodeAtprotoPackage` for complex monorepos
3. Leverage `buildMultiLanguageProject` for projects spanning multiple languages
4. Add shared dependency management for improved build performance

## Performance Considerations

- **Shared Dependencies**: Use `createSharedDependencies` to avoid rebuilding common dependencies
- **Build Coordination**: Use `coordinateBuildOrder` to optimize build parallelization
- **Artifact Reuse**: Enhanced functions automatically reuse build artifacts where possible
- **Caching**: Improved caching strategies reduce rebuild times significantly

## Security Features

All enhanced functions maintain the security standards of the base packaging library:

- Source integrity verification with cryptographic hashes
- Isolated build environments
- Minimal dependency sets
- Proper permission management
- Network isolation where appropriate

## Future Enhancements

Planned improvements include:

- Advanced dependency graph analysis
- Automatic performance optimization suggestions
- Enhanced cross-language type checking
- Integrated security scanning
- Build artifact signing and verification