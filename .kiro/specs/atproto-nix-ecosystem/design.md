# ATProto Nix Ecosystem Design Document

## Overview

The ATProto Nix Ecosystem will provide a comprehensive, production-ready repository for packaging and deploying AT Protocol applications on NixOS. Building upon the existing foundation with blacksky and microcosm modules, this design creates a standardized, extensible framework that supports the full ATProto application lifecycle from development to production deployment.

The system follows Nix's declarative philosophy, providing reproducible builds, atomic updates, and rollback capabilities while maintaining security best practices and operational excellence.

## Architecture

### High-Level Structure

Following the established NUR (Nix User Repository) pattern, the repository is organized as:

```
atproto-nur/
├── flake.nix              # Main flake definition and outputs
├── default.nix            # Legacy Nix entry point
├── overlay.nix            # Nixpkgs overlay for integration
├── pkgs/                  # Package definitions
│   ├── microcosm/         # Microcosm-rs service collection
│   ├── blacksky/          # Blacksky community tools
│   ├── bluesky/           # Official Bluesky packages
│   └── atproto/           # Core ATProto libraries and tools
├── modules/               # NixOS service modules
│   ├── microcosm/         # Microcosm service modules
│   ├── blacksky/          # Blacksky service modules
│   └── atproto/           # Core ATProto service modules
├── tests/                 # Integration tests and validation
├── code-references/       # Reference implementations for packaging
└── .tangled/              # CI/CD workflow definitions
```

**Design Rationale**: This structure aligns with the existing project organization and follows NUR conventions, enabling seamless integration with nixpkgs while maintaining clear separation between different ATProto service collections.

### Package Organization

The package hierarchy follows a logical structure that separates concerns:

- **Core Libraries**: Fundamental ATProto libraries (lexicon, crypto, etc.)
- **Applications**: Complete ATProto services (PDS, relay, feed generators)
- **Tools**: Development, debugging, and operational utilities
- **Language-Specific**: Organized by implementation language (Node.js, Rust, Go)

### Module Architecture

NixOS modules provide declarative configuration with three layers:

1. **Base Modules**: Core ATProto functionality and shared configuration
2. **Application Modules**: Service-specific configuration and deployment
3. **Profile Modules**: Pre-configured combinations for common use cases

## Components and Interfaces

### Package Management System

#### Core Package Structure

The package system supports multiple build patterns based on the technology stack:

**Rust Applications (Primary Pattern)**:
```nix
{ lib, craneLib, fetchFromGitHub, pkg-config, openssl, zstd, ... }:

craneLib.buildPackage {
  pname = "atproto-rust-service";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "service-owner";
    repo = "service-repo";
    rev = "v${version}";
    hash = "sha256-...";
  };
  
  # Standard Rust environment for ATProto services
  env = {
    OPENSSL_NO_VENDOR = "1";
    ZSTD_SYS_USE_PKG_CONFIG = "1";
  };
  
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl zstd ];
  
  # ATProto-specific metadata
  passthru = {
    atproto = {
      type = "application";
      services = [ "constellation" ];
      protocols = [ "com.atproto" ];
    };
  };
  
  meta = with lib; {
    description = "AT Protocol Rust service";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
```

**Node.js Applications**:
```nix
{ lib, buildNpmPackage, fetchFromGitHub, ... }:

buildNpmPackage rec {
  pname = "atproto-node-service";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-...";
  };
  
  npmDepsHash = "sha256-...";
  
  # Requirement 3.4: Handle web frontend asset building and bundling
  buildPhase = ''
    runHook preBuild
    
    # Build frontend assets if present
    if [ -f "package.json" ] && grep -q "build" package.json; then
      npm run build
    fi
    
    runHook postBuild
  '';
  
  # Include built assets in output
  installPhase = ''
    runHook preInstall
    
    # Install Node.js application
    mkdir -p $out/lib/node_modules/${pname}
    cp -r . $out/lib/node_modules/${pname}
    
    # Install built frontend assets
    if [ -d "dist" ] || [ -d "build" ] || [ -d "public" ]; then
      mkdir -p $out/share/${pname}
      [ -d "dist" ] && cp -r dist $out/share/${pname}/
      [ -d "build" ] && cp -r build $out/share/${pname}/
      [ -d "public" ] && cp -r public $out/share/${pname}/
    fi
    
    runHook postInstall
  '';
  
  # ATProto-specific metadata
  passthru.atproto = {
    type = "application";
    services = [ "pds" ];
    protocols = [ "com.atproto" ];
    hasWebFrontend = true;  # Indicates web assets are included
  };
}
```

**Go Applications**:
```nix
{ lib, buildGoModule, fetchFromGitHub, ... }:

buildGoModule rec {
  pname = "atproto-go-service";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "service-owner";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-...";
  };
  
  vendorHash = "sha256-...";
  
  passthru.atproto = {
    type = "application";
    services = [ "tangled-knot" ];
    protocols = [ "com.atproto" ];
  };
}
```

**Multi-Package Workspace Handling**:
For Rust workspaces like Microcosm, the build system optimizes compilation by sharing dependencies:

```nix
let
  # Build shared dependencies once
  commonArgs = {
    src = fetchFromGitHub { /* ... */ };
    env = {
      OPENSSL_NO_VENDOR = "1";
      ZSTD_SYS_USE_PKG_CONFIG = "1";
    };
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ openssl zstd lz4 rocksdb sqlite ];
  };
  
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
  
  # Generate individual packages
  packages = lib.genAttrs [
    "constellation" "spacedust" "slingshot" "ufos" 
    "who-am-i" "quasar" "pocket" "reflector"
  ] (name: craneLib.buildPackage (commonArgs // {
    inherit cargoArtifacts;
    pname = "microcosm-${name}";
    cargoExtraArgs = "--bin ${name}";
  }));
in packages
```

**Design Rationale**: Using language-specific build functions (craneLib, buildNpmPackage, buildGoModule) ensures optimal build performance and follows Nix ecosystem best practices. The standardized metadata schema enables automated tooling and consistent package management. Multi-package workspaces share build artifacts to reduce compilation time and storage requirements.

#### Package Categories

**Existing Service Collections**:
- `microcosm-constellation`: Backlink indexer service
- `microcosm-spacedust`: ATProto service component
- `microcosm-slingshot`: ATProto service component
- `microcosm-ufos`: ATProto service component
- `microcosm-who-am-i`: Identity service
- `microcosm-quasar`: ATProto service component
- `microcosm-pocket`: ATProto service component
- `microcosm-reflector`: ATProto service component
- `blacksky-rsky`: Community ATProto tools

**Core ATProto Packages** (to be added):
- `atproto-lexicon`: Schema definition and validation
- `atproto-crypto`: Cryptographic utilities
- `atproto-common`: Shared utilities and types
- `atproto-api`: Client libraries and API definitions

**Official Bluesky Applications** (to be added):
- `bluesky-pds`: Personal Data Server
- `bluesky-relay`: ATProto relay service
- `bluesky-feedgen`: Feed generator framework
- `bluesky-labeler`: Content labeling service
- `bluesky-appview`: Application view aggregator

**Development Tools** (to be added):
- `atproto-cli`: Command-line interface for ATProto operations
- `atproto-dev-env`: Development environment setup
- `atproto-lexicon-tools`: Schema development utilities

**Design Rationale**: The package organization reflects the current state of the repository while providing a clear path for expansion. Service collections are grouped by maintainer/origin, enabling independent development and maintenance cycles.

#### Flake Integration and Overlay System

The repository provides multiple integration methods to meet different user needs:

**Flake Outputs**:
```nix
# flake.nix outputs structure
{
  packages = {
    # Individual packages
    microcosm-constellation = packages.microcosm.constellation;
    microcosm-spacedust = packages.microcosm.spacedust;
    # ... other packages
    
    # Package collections
    microcosm = packages.microcosm;
    blacksky = packages.blacksky;
    bluesky = packages.bluesky;
  };
  
  nixosModules = {
    # Individual modules
    microcosm-constellation = ./modules/microcosm/constellation.nix;
    # ... other modules
    
    # Module collections
    microcosm = ./modules/microcosm;
    blacksky = ./modules/blacksky;
    atproto = ./modules/atproto;
  };
  
  overlays.default = import ./overlay.nix;
}
```

**Overlay Integration**:
```nix
# overlay.nix - for nixpkgs integration
final: prev: {
  atproto = {
    # Expose all packages under atproto namespace
    # Requirement 1.2: Enable `nix-env -iA atproto.pds` installation pattern
    inherit (final.callPackage ./pkgs/microcosm {}) 
      microcosm-constellation microcosm-spacedust;
    inherit (final.callPackage ./pkgs/blacksky {})
      blacksky-rsky-pds blacksky-rsky-relay;
    inherit (final.callPackage ./pkgs/bluesky {})
      pds relay feedgen labeler;  # Simplified names for major services
    # Future packages...
  };
}
```

This enables users to install packages via multiple methods as required:
- `nix-env -iA nixpkgs.atproto.pds` (with overlay, satisfies Requirement 1.2)
- `nix-env -iA nixpkgs.atproto.microcosm-constellation` (specific service)
- `nix profile install github:owner/atproto-nur#microcosm-constellation` (direct flake)
- Through NixOS configuration with the overlay or flake inputs

**Design Rationale**: Multiple integration methods ensure compatibility with different Nix workflows while maintaining a consistent package namespace. The overlay approach enables seamless integration with existing nixpkgs-based systems.

#### Developer Templates and Tooling

To support Requirement 3 (easy packaging for developers), the repository provides standardized templates:

**Flake Templates**:
```nix
# templates/rust-atproto/flake.nix
{
  description = "ATProto Rust application template";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    crane.url = "github:ipetkov/crane";
    atproto-nur.url = "github:owner/atproto-nur";
  };
  
  outputs = { self, nixpkgs, crane, atproto-nur }: {
    packages = nixpkgs.lib.genAttrs [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        craneLib = crane.lib.${system};
      in {
        default = craneLib.buildPackage {
          src = ./.;
          # Standard ATProto Rust environment
          env = {
            OPENSSL_NO_VENDOR = "1";
            ZSTD_SYS_USE_PKG_CONFIG = "1";
          };
          nativeBuildInputs = with pkgs; [ pkg-config ];
          buildInputs = with pkgs; [ openssl zstd ];
        };
      });
  };
}
```

**Package Helper Functions**:
```nix
# lib/atproto.nix - shared utilities
{ lib, ... }: {
  # Helper for creating ATProto package metadata
  mkAtprotoPackage = { type, services ? [], protocols ? ["com.atproto"], ... }@args:
    args // {
      passthru = (args.passthru or {}) // {
        atproto = { inherit type services protocols; };
      };
    };
  
  # Helper for Rust ATProto services
  mkRustAtprotoService = craneLib: args:
    craneLib.buildPackage (mkAtprotoPackage ({
      type = "application";
      env = {
        OPENSSL_NO_VENDOR = "1";
        ZSTD_SYS_USE_PKG_CONFIG = "1";
      };
    } // args));
}
```

**Documentation and Examples**: Requirement 3.5 compliance through comprehensive contributor resources
```nix
# docs/PACKAGING.md - Packaging guidelines
# docs/CONTRIBUTING.md - Contribution workflow
# docs/EXAMPLES.md - Real-world packaging examples
# templates/ - Ready-to-use project templates
# code-references/ - Reference implementations for analysis
```

The repository includes:
- **Packaging Guidelines**: Step-by-step instructions for packaging different types of ATProto applications
- **API Documentation**: Complete documentation of helper functions and utilities
- **Example Packages**: Real-world examples demonstrating best practices
- **Troubleshooting Guides**: Common issues and solutions for package contributors
- **Security Guidelines**: Security best practices for ATProto service packaging

**Design Rationale**: Templates and helper functions reduce the barrier to entry for new contributors while ensuring consistency across packages. The templates encode best practices and handle common configuration patterns automatically. Comprehensive documentation ensures contributors can successfully package new ATProto applications following established patterns.

### Service Module System

#### Base Module Interface

Following the established pattern from existing modules, each service gets its own dedicated module:

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-constellation;
in {
  options.services.microcosm-constellation = {
    enable = mkEnableOption "Microcosm Constellation backlink indexer";
    
    package = mkOption {
      type = types.package;
      default = pkgs.nur.repos.atproto.microcosm-constellation;
      description = "Constellation package to use";
    };
    
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/microcosm-constellation";
      description = "Data directory for Constellation service";
    };
    
    user = mkOption {
      type = types.str;
      default = "microcosm-constellation";
      description = "User account for Constellation service";
    };
    
    group = mkOption {
      type = types.str;
      default = "microcosm-constellation";
      description = "Group for Constellation service";
    };
    
    settings = mkOption {
      type = types.submodule {
        options = {
          # Service-specific configuration options
          port = mkOption {
            type = types.port;
            default = 8080;
            description = "Service listening port";
          };
          
          logLevel = mkOption {
            type = types.enum [ "trace" "debug" "info" "warn" "error" ];
            default = "info";
            description = "Logging level";
          };
        };
      };
      default = {};
      description = "Constellation service configuration";
    };
  };
  
  config = mkIf cfg.enable {
    # User and group management
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
    };
    
    users.groups.${cfg.group} = {};
    
    # Directory management using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ];
    
    # systemd service with security hardening
    systemd.services.microcosm-constellation = {
      description = "Microcosm Constellation backlink indexer";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      
      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/constellation --port ${toString cfg.settings.port}";
        
        # Security hardening
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
        ReadWritePaths = [ cfg.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };
    };
  };
}
```

**Design Rationale**: Each service gets a dedicated user, group, and configuration namespace to ensure proper isolation and security. The module pattern follows NixOS conventions and includes comprehensive systemd security hardening by default.

#### Application-Specific Modules

Each ATProto application gets a dedicated module with service-specific configuration:

```nix
# services.atproto.pds module
{
  options.services.atproto.pds = {
    enable = mkEnableOption "AT Protocol Personal Data Server";
    
    settings = mkOption {
      type = types.submodule {
        options = {
          hostname = mkOption {
            type = types.str;
            description = "PDS hostname";
          };
          
          port = mkOption {
            type = types.port;
            default = 3000;
            description = "PDS listening port";
          };
          
          database = {
            type = mkOption {
              type = types.enum [ "sqlite" "postgres" ];
              default = "sqlite";
              description = "Database backend";
            };
            
            connectionString = mkOption {
              type = types.str;
              description = "Database connection string";
            };
          };
          
          blobstore = {
            type = mkOption {
              type = types.enum [ "disk" "s3" ];
              default = "disk";
              description = "Blob storage backend";
            };
          };
        };
      };
    };
  };
}
```

### Configuration Management

#### Declarative Configuration

The system provides type-safe, validated configuration through individual service modules:

```nix
# Example configuration for multiple ATProto services
services = {
  # Existing Microcosm services
  microcosm-constellation = {
    enable = true;
    settings = {
      port = 8080;
      logLevel = "info";
    };
  };
  
  microcosm-spacedust = {
    enable = true;
    settings = {
      port = 8081;
      upstreamUrl = "https://bsky.network";
    };
  };
  
  # Future Bluesky services
  bluesky-pds = {
    enable = true;
    settings = {
      hostname = "pds.example.com";
      port = 3000;
      database = {
        type = "postgres";
        connectionString = "postgresql://atproto:password@localhost/atproto";
      };
    };
  };
  
  bluesky-relay = {
    enable = true;
    settings = {
      hostname = "relay.example.com";
      upstreamRelays = [ "bsky.network" ];
    };
  };
};
```

**Design Rationale**: Individual service modules provide better isolation, clearer configuration boundaries, and easier maintenance. This approach aligns with NixOS conventions where each service has its own configuration namespace.

#### Environment-Specific Profiles

Pre-configured profiles for common deployment scenarios:

```nix
# profiles/development.nix - Local development setup
{ config, ... }: {
  services = {
    microcosm-constellation.enable = true;
    microcosm-spacedust.enable = true;
    
    # Future development services
    bluesky-pds = {
      enable = true;
      settings = {
        hostname = "localhost";
        database.type = "sqlite";
        blobstore.type = "disk";
      };
    };
  };
}

# profiles/production.nix - Production deployment
{ config, ... }: {
  services = {
    microcosm-constellation = {
      enable = true;
      settings.logLevel = "warn";
    };
    
    bluesky-pds = {
      enable = true;
      settings = {
        database.type = "postgres";
        blobstore.type = "s3";
      };
    };
  };
  
  # Production hardening is built into each service module
  # Additional production-specific configuration can be added here
}

# profiles/relay-node.nix - ATProto relay deployment
{ config, ... }: {
  services = {
    bluesky-relay = {
      enable = true;
      settings = {
        upstreamRelays = [ "bsky.network" ];
        maxConnections = 1000;
      };
    };
    
    microcosm-constellation.enable = true;  # For backlink indexing
  };
}
```

**Design Rationale**: Profiles provide opinionated configurations for common use cases while maintaining the flexibility to customize individual services. Each profile can be imported and extended as needed.

## Data Models

### Package Metadata Schema

```nix
{
  atproto = {
    # Package classification
    type = "application" | "library" | "tool";
    
    # Services provided by this package
    services = [ "pds" "relay" "feedgen" ];
    
    # ATProto protocols supported
    protocols = [ "com.atproto" "app.bsky" ];
    
    # Configuration schema version
    schemaVersion = "1.0";
    
    # Dependencies on other ATProto packages
    atprotoDependencies = {
      "atproto-lexicon" = "^0.4.0";
      "atproto-crypto" = "^0.3.0";
    };
    
    # Service configuration requirements
    configuration = {
      required = [ "hostname" ];
      optional = [ "port" "database" ];
    };
    
    # Requirement 5.3: Security metadata and vulnerability information
    security = {
      # Known vulnerabilities (updated through CI/CD)
      vulnerabilities = [ ];
      
      # Security assessment metadata
      assessment = {
        lastReviewed = "2024-01-15";
        riskLevel = "low" | "medium" | "high";
        dataHandling = [ "user-data" "credentials" "public-data" ];
      };
      
      # Required security constraints
      constraints = {
        requiresNetwork = true;
        requiresFileSystem = [ "/var/lib/service" ];
        requiresPrivileges = [ ];
        bindsPorts = [ 3000 ];
      };
      
      # Security recommendations
      recommendations = {
        isolateNetwork = false;
        dedicatedUser = true;
        systemdHardening = true;
      };
    };
    
    # Web frontend assets (Requirement 3.4)
    hasWebFrontend = false;
    webAssets = {
      buildCommand = "npm run build";
      outputDir = "dist";
      staticFiles = [ "public" ];
    };
  };
}
```

### Service Configuration Schema

```nix
{
  # Service identity
  service = {
    name = "pds";
    version = "1.0.0";
    description = "Personal Data Server";
  };
  
  # Runtime configuration
  runtime = {
    user = "atproto-pds";
    group = "atproto";
    workingDirectory = "/var/lib/atproto-pds";
    environment = {
      NODE_ENV = "production";
      LOG_LEVEL = "info";
    };
  };
  
  # Network configuration
  network = {
    ports = [ 3000 ];
    protocols = [ "http" "https" ];
    dependencies = [ "network.target" ];
  };
  
  # Security configuration
  security = {
    capabilities = [ ];
    readOnlyPaths = [ "/nix/store" ];
    readWritePaths = [ "/var/lib/atproto-pds" ];
  };
}
```

## Error Handling

### Package Build Failures

The system provides comprehensive error handling for package builds:

1. **Dependency Resolution**: Clear error messages for missing or incompatible dependencies
2. **Build Environment**: Validation of required build tools and environment variables
3. **Test Failures**: Integration with package test suites and failure reporting
4. **Security Validation**: Automated security scanning and vulnerability reporting

### Service Configuration Errors

Service modules include extensive validation with clear error messages:

```nix
# Configuration validation example
config = mkIf cfg.enable {
  assertions = [
    {
      assertion = cfg.settings.port > 0 && cfg.settings.port < 65536;
      message = "services.microcosm-constellation.settings.port must be a valid port number (1-65535)";
    }
    {
      assertion = cfg.settings.database.type == "postgres" -> 
                  cfg.settings.database.connectionString != "";
      message = "PostgreSQL connection string required when using postgres database type";
    }
    {
      assertion = cfg.settings.blobstore.type == "s3" ->
                  (cfg.settings.blobstore.bucket != "" && cfg.settings.blobstore.region != "");
      message = "S3 bucket and region must be specified when using S3 blobstore";
    }
  ];
  
  warnings = lib.optional (cfg.settings.logLevel == "trace") 
    "Trace logging enabled for ${cfg.user} - this may impact performance in production";
};
```

**Design Rationale**: Comprehensive validation prevents common configuration errors and provides actionable error messages. Warnings alert users to potentially problematic configurations without blocking deployment.

### Runtime Error Recovery

Services include automatic recovery mechanisms through systemd:

- **Health Checks**: systemd watchdog and restart policies for automatic recovery
- **Graceful Degradation**: Service dependencies and ordering prevent cascading failures
- **Atomic Updates**: Nix's atomic activation ensures consistent system state
- **Rollback Support**: NixOS generations enable instant rollback to previous configurations

```nix
# Example systemd service configuration with recovery
systemd.services.microcosm-constellation = {
  serviceConfig = {
    Restart = "on-failure";
    RestartSec = "5s";
    StartLimitBurst = 3;
    StartLimitIntervalSec = "60s";
    
    # Watchdog for health monitoring
    WatchdogSec = "30s";
    NotifyAccess = "main";
  };
  
  # Graceful shutdown
  preStop = "${pkgs.coreutils}/bin/sleep 5";
};
```

**Design Rationale**: Leveraging systemd's built-in recovery mechanisms provides robust error handling without requiring custom monitoring infrastructure. NixOS's atomic updates and generations provide system-level rollback capabilities.

## Testing Strategy

### Package Testing

**Build Verification**: Each package includes comprehensive build testing
- Multi-platform build verification (x86_64-linux, aarch64-linux)
- Dependency resolution and compatibility testing
- Reproducible build validation across different Nix versions

**Security Validation**: Requirement 5.3 compliance through automated security testing
- Vulnerability scanning of package dependencies using tools like `vulnix`
- Security metadata validation and consistency checking
- License compliance verification and security audit trail
- Automated security constraint verification for systemd hardening

**Integration Tests**: Cross-package compatibility testing using NixOS VM tests
```nix
# tests/constellation-shell.nix - example integration test
import <nixpkgs/nixos/tests/make-test-python.nix> ({ pkgs, ... }: {
  name = "constellation-integration";
  
  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/microcosm ];
    services.microcosm-constellation.enable = true;
  };
  
  testScript = ''
    machine.start()
    machine.wait_for_unit("microcosm-constellation.service")
    machine.wait_for_open_port(8080)
    machine.succeed("curl -f http://localhost:8080/health")
  '';
})
```

### Module Testing

**Configuration Validation**: Automated testing of module configurations
- NixOS assertion testing for invalid configurations
- Type checking and option validation
- Service dependency verification

**Service Integration**: End-to-end service testing using NixOS VM tests
- Service startup and shutdown procedures
- Inter-service communication validation
- Resource usage and security constraint verification

### Continuous Integration

**Tangled Workflows**: Using the existing `.tangled/workflows/build.yml` system
```yaml
# .tangled/workflows/build.yml
name: Build and Test
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v20
      - name: Build packages
        run: nix build .#microcosm-constellation .#microcosm-spacedust
      - name: Run tests
        run: nix build .#tests
      - name: Check flake
        run: nix flake check
```

**Quality Gates**:
- All packages must build successfully on supported platforms
- NixOS VM tests must pass for all service modules
- Flake check must pass (includes basic validation)
- No security vulnerabilities in direct dependencies

### Testing Infrastructure

**NixOS VM Tests**: Leveraging NixOS's built-in testing framework
- Isolated test execution in QEMU VMs
- Reproducible test environments
- Parallel test execution for faster feedback

**Test Organization**: Following the established `tests/` directory structure
- Individual service tests (e.g., `constellation-shell.nix`)
- Integration tests for service combinations
- Performance and load testing scenarios

**Design Rationale**: Using NixOS's built-in testing infrastructure ensures tests run in realistic environments while maintaining reproducibility. The VM-based approach provides true isolation and enables testing of system-level interactions.

## Monitoring and Operational Features

### Logging Integration

All services integrate with systemd journaling for centralized log management:

```nix
# Service configuration with structured logging
systemd.services.microcosm-constellation = {
  serviceConfig = {
    StandardOutput = "journal";
    StandardError = "journal";
    SyslogIdentifier = "constellation";
  };
  
  environment = {
    RUST_LOG = cfg.settings.logLevel;
    LOG_FORMAT = "json";  # Structured logging for better parsing
  };
};
```

**Log Management Features**:
- Structured JSON logging for machine parsing
- Configurable log levels per service
- Automatic log rotation through systemd
- Integration with external log aggregation systems

### Metrics and Monitoring

Services expose metrics endpoints where supported by the application:

```nix
# Prometheus metrics configuration
services.microcosm-constellation.settings = {
  metrics = {
    enable = true;
    port = 9090;
    path = "/metrics";
  };
};

# Automatic Prometheus scrape configuration
services.prometheus.scrapeConfigs = lib.mkIf config.services.microcosm-constellation.enable [{
  job_name = "constellation";
  static_configs = [{
    targets = [ "localhost:9090" ];
  }];
}];
```

### Health Checks and Diagnostics

Services include comprehensive health checking and diagnostic capabilities:

```nix
# Health check endpoint configuration
systemd.services.microcosm-constellation = {
  serviceConfig = {
    ExecStartPost = "${pkgs.curl}/bin/curl -f http://localhost:8080/health";
    ExecReload = "${pkgs.curl}/bin/curl -f http://localhost:8080/health";
  };
};

# Diagnostic information collection
environment.systemPackages = with pkgs; [
  (writeShellScriptBin "atproto-diagnostics" ''
    echo "=== ATProto Service Status ==="
    systemctl status microcosm-constellation
    echo "=== Service Logs (last 50 lines) ==="
    journalctl -u microcosm-constellation -n 50
    echo "=== Health Check ==="
    curl -s http://localhost:8080/health | ${pkgs.jq}/bin/jq .
  '')
];
```

**Design Rationale**: Leveraging systemd's logging and monitoring capabilities provides consistent operational interfaces across all services. Health checks and diagnostic tools enable rapid troubleshooting and maintenance.

## Security Architecture

### Service Isolation and Hardening

All services run with comprehensive systemd security constraints by default:

```nix
# Standard security hardening applied to all services
systemd.services.microcosm-constellation.serviceConfig = {
  # User and privilege management
  User = cfg.user;
  Group = cfg.group;
  DynamicUser = false;  # Use dedicated system users
  
  # Security restrictions
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
  
  # File system access control
  ReadWritePaths = [ cfg.dataDir ];
  ReadOnlyPaths = [ "/nix/store" ];
  PrivateDevices = true;
  ProtectKernelLogs = true;
  ProtectClock = true;
  
  # Network isolation (configurable per service)
  PrivateNetwork = lib.mkDefault false;
  RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
};
```

### Network Security

Services support network isolation options for enhanced security:

```nix
# Network isolation configuration
services.microcosm-constellation = {
  settings.network = {
    # Bind only to localhost for internal services
    bindAddress = "127.0.0.1";
    
    # Enable network isolation for services that don't need external access
    isolateNetwork = false;  # Set to true for internal-only services
    
    # Firewall integration
    openFirewall = false;  # Explicit firewall control
  };
};

# Automatic firewall configuration when enabled
networking.firewall.allowedTCPPorts = lib.mkIf 
  (cfg.enable && cfg.settings.network.openFirewall) 
  [ cfg.settings.port ];
```

### Configuration Security

Security-sensitive configuration parameters include validation and secure defaults:

```nix
# Secure configuration validation
config = mkIf cfg.enable {
  assertions = [
    {
      assertion = cfg.settings.database.passwordFile != null -> 
                  (lib.hasPrefix "/run/secrets/" cfg.settings.database.passwordFile);
      message = "Database password file should be in /run/secrets/ for proper security";
    }
    {
      assertion = cfg.settings.network.bindAddress != "0.0.0.0" || cfg.settings.network.openFirewall;
      message = "Binding to 0.0.0.0 requires explicit firewall configuration";
    }
  ];
  
  warnings = lib.optionals (cfg.settings.logLevel == "debug") [
    "Debug logging enabled - may expose sensitive information in logs"
  ];
};
```

### Secrets Management

Integration with NixOS secrets management systems:

```nix
# Example secrets integration with sops-nix
services.microcosm-constellation.settings = {
  database = {
    passwordFile = config.sops.secrets.constellation-db-password.path;
  };
  
  api = {
    keyFile = config.sops.secrets.constellation-api-key.path;
  };
};

# Automatic secrets dependency
systemd.services.microcosm-constellation = {
  after = [ "sops-nix.service" ];
  wants = [ "sops-nix.service" ];
};
```

**Design Rationale**: Security is built into the foundation of every service module rather than being an afterthought. The comprehensive systemd security features provide defense in depth, while configuration validation prevents common security misconfigurations.

## Update and Migration System

### Atomic Updates

NixOS provides atomic updates for all ATProto services through its generation system:

```nix
# Service updates are atomic - either all succeed or all fail
# No partial update states that could leave the system broken
systemd.services.microcosm-constellation = {
  # Graceful service restarts on configuration changes
  reloadIfChanged = true;
  restartIfChanged = true;
  
  # Proper service ordering during updates
  before = [ "atproto-dependent-services.target" ];
  wantedBy = [ "multi-user.target" ];
};
```

### Configuration Migration

The system provides migration helpers for breaking configuration changes:

```nix
# Migration helper example
{ config, lib, ... }:
let
  cfg = config.services.microcosm-constellation;
  
  # Detect old configuration format
  hasOldConfig = cfg.settings ? "old_option_name";
  
in {
  config = lib.mkIf cfg.enable {
    # Automatic migration warnings
    warnings = lib.optional hasOldConfig 
      "services.microcosm-constellation.settings.old_option_name is deprecated, use new_option_name instead";
    
    # Automatic migration when possible
    services.microcosm-constellation.settings.new_option_name = 
      lib.mkIf hasOldConfig (lib.mkDefault cfg.settings.old_option_name);
  };
}
```

### Data Migration

Services support data migration through pre-start scripts:

```nix
systemd.services.microcosm-constellation = {
  preStart = ''
    # Check if data migration is needed
    if [[ -f ${cfg.dataDir}/.migration_needed ]]; then
      echo "Running data migration..."
      ${cfg.package}/bin/constellation-migrate --data-dir ${cfg.dataDir}
      rm ${cfg.dataDir}/.migration_needed
    fi
    
    # Ensure proper directory permissions
    chown -R ${cfg.user}:${cfg.group} ${cfg.dataDir}
    chmod 750 ${cfg.dataDir}
  '';
  
  serviceConfig = {
    Type = "notify";  # Service signals when ready
    ExecStartPre = [
      # Backup data before starting (for rollback capability)
      "${pkgs.rsync}/bin/rsync -a ${cfg.dataDir}/ ${cfg.dataDir}.backup/"
    ];
  };
};
```

### Rollback Support

NixOS generations provide instant rollback capabilities:

```bash
# Rollback to previous generation if update fails
sudo nixos-rebuild switch --rollback

# List available generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to specific generation
sudo nix-env --switch-generation 42 --profile /nix/var/nix/profiles/system
```

### Version Compatibility

The package system maintains compatibility information:

```nix
# Package compatibility metadata
passthru = {
  atproto = {
    # Minimum compatible version for data migration
    minCompatibleVersion = "1.0.0";
    
    # Breaking changes that require migration
    breakingChanges = [
      { version = "2.0.0"; migration = "config-format-v2"; }
      { version = "3.0.0"; migration = "database-schema-v3"; }
    ];
  };
};
```

**Design Rationale**: Leveraging NixOS's atomic update and rollback capabilities provides robust update mechanisms without requiring custom tooling. Data migration is handled at the service level where domain knowledge exists, while configuration migration is handled declaratively through the module system.