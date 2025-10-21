# ATproto Ecosystem Expansion Design

## Overview

This design document outlines the architecture and implementation approach for expanding the ATproto Nix User Repository (NUR) ecosystem to support comprehensive packaging of 20+ ATproto applications and services. The design builds upon existing patterns while introducing new organizational structures and packaging methodologies to handle the complexity of a multi-language, multi-service ecosystem.

### Source Code Management

**Important**: The `code-references/` directory serves only as a reference for understanding application structure and dependencies. All packages must fetch source code from their official repositories using `fetchFromGitHub`, `fetchgit`, or appropriate fetchers:

- **GitHub repositories**: Use `pkgs.fetchFromGitHub` with owner, repo, rev, and sha256
- **Tangled repositories**: Use `pkgs.fetchgit` with URL, rev, and sha256  
- **Other Git repositories**: Use appropriate Nix fetchers for the hosting platform

This ensures packages track upstream changes, maintain proper attribution, and provide reproducible builds with cryptographic verification.

## Architecture

### Organizational Framework

The expanded ecosystem will use a hierarchical organizational structure that groups packages by their origin and purpose:

```
atproto-nur/
├── pkgs/
│   ├── atproto/           # Official AT Protocol implementations
│   │   ├── frontpage/     # Official Bluesky implementation
│   │   ├── indigo/        # Official Go implementation
│   │   └── lexicons/      # Core lexicon tools
│   ├── individual/        # Individual developer projects
│   │   ├── allegedly/     # PLC tools (individual)
│   │   ├── quickdid/      # DID utilities (individual)
│   │   └── pds-gatekeeper/ # PDS registration (individual)
│   ├── hyperlink-academy/ # Hyperlink Academy projects
│   │   └── leaflet/       # Collaborative writing platform
│   ├── slices-network/    # Slices Network projects
│   │   └── slices/        # Custom AppView platform
│   ├── smokesignal-events/ # Smokesignal Events projects
│   │   └── quickdid/      # DID resolution service
│   ├── tangled-dev/       # Tangled development tools
│   │   ├── knot/          # Git hosting service
│   │   ├── spindle/       # CI/CD service
│   │   └── appview/       # Web interface
│   └── stream-place/      # Streamplace projects
│       └── streamplace/   # Video infrastructure
├── modules/
│   ├── atproto/           # Official service modules
│   ├── individual/        # Individual project modules
│   ├── hyperlink-academy/ # Academy service modules
│   ├── slices-network/    # Slices service modules
│   ├── smokesignal-events/ # Smokesignal service modules
│   ├── tangled-dev/       # Tangled service modules
│   └── stream-place/      # Streamplace service modules
└── lib/
    ├── atproto-core.nix   # Core ATproto library functions
    ├── packaging.nix      # Multi-language packaging utilities
    └── service-common.nix # Common service configuration patterns
```

### Package Classification System

Packages are classified into tiers based on complexity, community value, and maintenance requirements:

#### Tier 1: Foundation Infrastructure
- **Allegedly** (PLC tools) - Critical identity infrastructure
- **Tangled** (Git forge) - Already implemented, needs improvements
- **Microcosm-rs** (ATproto services) - Core service collection
- **Frontpage/Bluesky** (Official implementation) - Reference implementation

#### Tier 2: Ecosystem Services
- **Indigo** (Official Go implementation) - Core Go libraries and services
- **rsky** (Community Rust implementation) - Alternative Rust ecosystem
- **Leaflet** (Collaborative writing) - Popular application platform
- **Slices** (Custom AppViews) - Developer platform

#### Tier 3: Specialized Applications
- **Utility tools** (quickdid, pds-dash, pds-gatekeeper, atbackup)
- **Development tools** (lexicon generators, debugging utilities)
- **Specialized services** (Streamplace, Teal, Parakeet)

## Components and Interfaces

### Core Library System

#### ATproto Core Libraries (`lib/atproto-core.nix`)

Provides shared functions for ATproto-specific packaging needs:

```nix
{
  # Lexicon validation and code generation
  buildLexiconPackage = { src, lexicons, outputLang, ... }: ...;
  
  # ATproto service configuration helpers
  mkAtprotoService = { name, package, config, ... }: ...;
  
  # DID and identity management utilities
  mkDidResolver = { endpoints, caching, ... }: ...;
  
  # Database integration for ATproto services
  mkAtprotoDatabase = { type, migrations, ... }: ...;
}
```

#### Multi-Language Packaging (`lib/packaging.nix`)

Standardizes packaging patterns across languages:

```nix
{
  # Rust packaging with ATproto-specific environment
  buildRustAtprotoPackage = { src, cargoToml, extraEnv ? {}, ... }: ...;
  
  # Node.js packaging with workspace support
  buildNodeAtprotoPackage = { src, packageJson, workspaces ? [], ... }: ...;
  
  # Go packaging with ATproto dependencies
  buildGoAtprotoPackage = { src, goMod, extraDeps ? [], ... }: ...;
  
  # Deno packaging for TypeScript applications
  buildDenoAtprotoPackage = { src, denoJson, ... }: ...;
}
```

#### Service Configuration (`lib/service-common.nix`)

Common patterns for NixOS service modules:

```nix
{
  # Standard ATproto service module template
  mkAtprotoServiceModule = { name, package, defaultConfig, ... }: ...;
  
  # Database integration patterns
  mkDatabaseIntegration = { dbType, migrations, ... }: ...;
  
  # Security hardening for ATproto services
  mkServiceSecurity = { networkAccess, fileSystem, ... }: ...;
}
```

### Language-Specific Build Systems

#### Rust Packaging Strategy

Building on the existing microcosm pattern with improvements:

```nix
# Enhanced Rust workspace packaging
buildRustWorkspace = { owner, repo, rev, sha256, members, commonEnv, ... }:
let
  src = pkgs.fetchFromGitHub {
    inherit owner repo rev sha256;
  };
  
  # Shared dependency artifacts for all workspace members
  cargoArtifacts = craneLib.buildDepsOnly {
    inherit src;
    pname = "${workspaceName}-deps";
    env = commonEnv // {
      OPENSSL_NO_VENDOR = "1";
      ZSTD_SYS_USE_PKG_CONFIG = "1";
      # ATproto-specific environment variables
    };
  };
  
  # Individual package builder
  buildMember = member: craneLib.buildPackage {
    inherit src cargoArtifacts;
    cargoExtraArgs = "--package ${member}";
    # ... member-specific configuration
  };
in
pkgs.lib.genAttrs members buildMember;
```

#### Node.js/TypeScript Packaging Strategy

Supporting complex monorepos like Frontpage:

```nix
# pnpm workspace packaging
buildPnpmWorkspace = { owner, repo, rev, sha256, workspaces, ... }:
let
  src = pkgs.fetchFromGitHub {
    inherit owner repo rev sha256;
  };
  
  # Handle pnpm catalog dependencies
  processedPackageJson = processCatalogDeps src;
  
  # Build individual workspace packages
  buildWorkspace = workspace: buildNpmPackage {
    inherit src;
    sourceRoot = "${src.name}/${workspace}";
    # ... workspace-specific configuration
  };
in
pkgs.lib.genAttrs workspaces buildWorkspace;
```

#### Go Packaging Strategy

For Indigo and other Go applications:

```nix
# Go module packaging with ATproto dependencies
buildGoAtprotoModule = { owner, repo, rev, sha256, services ? [], ... }:
let
  src = pkgs.fetchFromGitHub {
    inherit owner repo rev sha256;
  };
  
  # Common Go build environment for ATproto
  commonEnv = {
    CGO_ENABLED = "1";
    # ATproto-specific Go build flags
  };
  
  # Build individual services from the module
  buildService = service: buildGoModule {
    inherit src;
    subPackages = [ "cmd/${service}" ];
    # ... service-specific configuration
  };
in
if services == [] 
then buildGoModule { inherit src; } # Build all
else pkgs.lib.genAttrs services buildService;
```

#### Deno Packaging Strategy

For Slices frontend and other Deno applications:

```nix
# Deno application packaging
buildDenoApp = { src, denoJson, ... }:
stdenv.mkDerivation {
  inherit src;
  
  nativeBuildInputs = [ deno ];
  
  buildPhase = ''
    # Deno-specific build process
    deno task build
  '';
  
  # ... Deno-specific configuration
};
```

## Data Models

### Package Metadata Schema

Each package includes comprehensive metadata for discovery and management:

```nix
{
  meta = {
    description = "Brief service description";
    longDescription = "Detailed description with ATproto context";
    homepage = "https://github.com/owner/repo";
    license = licenses.mit;
    maintainers = [ maintainers.atproto-team ];
    platforms = platforms.linux;
    
    # ATproto-specific metadata
    atproto = {
      category = "infrastructure" | "application" | "utility" | "library";
      services = [ "pds" "relay" "feedgen" "labeler" "appview" ];
      protocols = [ "xrpc" "jetstream" "firehose" ];
      dependencies = [ "postgresql" "redis" "sqlite" ];
      tier = 1 | 2 | 3;
    };
  };
}
```

### Service Configuration Schema

Standardized configuration options for NixOS modules:

```nix
{
  services.atproto.${serviceName} = {
    enable = mkEnableOption "ATproto ${serviceName} service";
    
    package = mkOption {
      type = types.package;
      default = pkgs.atproto.${serviceName};
      description = "Package to use for ${serviceName}";
    };
    
    # Common ATproto service options
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/atproto/${serviceName}";
      description = "Data directory for ${serviceName}";
    };
    
    database = {
      type = mkOption {
        type = types.enum [ "postgresql" "sqlite" "rocksdb" ];
        default = "postgresql";
      };
      
      url = mkOption {
        type = types.str;
        description = "Database connection URL";
      };
    };
    
    # Service-specific options defined per service
    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional service configuration";
    };
  };
}
```

## Error Handling

### Build Error Management

Comprehensive error handling for complex multi-language builds:

1. **Dependency Resolution Errors**
   - Clear error messages for missing ATproto dependencies
   - Automatic suggestion of required packages
   - Version compatibility checking

2. **Cross-Language Build Coordination**
   - Validation of interface compatibility between Rust/Deno components
   - Proper error propagation from sub-builds
   - Rollback mechanisms for failed multi-stage builds

3. **Service Configuration Errors**
   - Validation of ATproto-specific configuration options
   - Database connectivity testing during build
   - Network endpoint validation

### Runtime Error Handling

Service modules include comprehensive error handling:

1. **Service Startup Validation**
   - Database connectivity checks
   - Required file/directory validation
   - Network port availability verification

2. **Configuration Validation**
   - ATproto endpoint reachability
   - DID resolution functionality
   - Lexicon schema validation

3. **Graceful Degradation**
   - Fallback configurations for optional services
   - Service dependency management
   - Automatic restart policies

## Testing Strategy

### Multi-Tier Testing Approach

#### Unit Tests (Package Level)
- Individual package build verification
- Dependency resolution testing
- Basic functionality validation

#### Integration Tests (Service Level)
- Service startup and configuration testing
- Database integration validation
- ATproto protocol compliance testing

#### System Tests (Ecosystem Level)
- Multi-service deployment scenarios
- Cross-service communication validation
- Performance and resource usage testing

### Automated Testing Infrastructure

```nix
# Test framework for ATproto packages
atprotoTests = {
  # Package build tests
  packageTests = pkgs.lib.mapAttrs (name: pkg: 
    runCommand "${name}-test" {} ''
      ${pkg}/bin/${name} --version > $out
    ''
  ) atprotoPackages;
  
  # Service integration tests
  serviceTests = {
    allegedly-pds = nixosTest {
      nodes.server = {
        services.atproto.allegedly.enable = true;
        services.postgresql.enable = true;
      };
      
      testScript = ''
        server.wait_for_unit("allegedly.service")
        server.wait_for_open_port(3000)
        # ATproto-specific functionality tests
      '';
    };
  };
  
  # Cross-service compatibility tests
  ecosystemTests = {
    full-stack = nixosTest {
      # Test complete ATproto stack deployment
    };
  };
};
```

### Continuous Integration Strategy

1. **Build Matrix Testing**
   - Test all packages across supported platforms
   - Validate dependency combinations
   - Performance regression testing

2. **Security Scanning**
   - Automated vulnerability detection
   - Dependency security auditing
   - Service configuration security validation

3. **Compatibility Testing**
   - Cross-version compatibility validation
   - Protocol compliance testing
   - Interoperability with upstream services

## Implementation Phases

### Phase 1: Foundation (Months 1-2)
**Goal**: Establish core infrastructure and improve existing packages

**Deliverables**:
- Enhanced organizational framework implementation
- Allegedly PLC tools packaging with full PostgreSQL integration
- Tangled configuration improvements and endpoint customization
- Updated Microcosm-rs packages using code-references source
- Core library system (`lib/atproto-core.nix`, `lib/packaging.nix`)

**Success Criteria**:
- All Tier 1 packages build successfully
- NixOS modules provide complete service configuration
- Integration tests pass for core services
- Documentation covers basic deployment scenarios

### Phase 2: Official Implementations (Months 3-4)
**Goal**: Package official ATproto implementations

**Deliverables**:
- Frontpage/Bluesky pnpm workspace packaging
- Indigo Go services and libraries
- Core ATproto TypeScript libraries (@atproto namespace)
- Enhanced testing infrastructure

**Success Criteria**:
- Official implementations match upstream functionality
- Multi-language build coordination works reliably
- Service modules support production deployment
- Performance meets or exceeds upstream benchmarks

### Phase 3: Community Ecosystem (Months 5-6)
**Goal**: Expand community implementation support

**Deliverables**:
- Updated rsky/blacksky packages with all services
- Leaflet collaborative writing platform
- Slices custom AppView platform with Rust/Deno coordination
- Utility tools (quickdid, pds-dash, pds-gatekeeper)

**Success Criteria**:
- Community implementations provide feature parity
- Complex multi-language applications build successfully
- Service discovery and coordination works across implementations
- Developer experience matches or improves upon upstream

### Phase 4: Specialized Applications (Months 7+)
**Goal**: Support specialized and complex applications

**Deliverables**:
- Advanced applications based on community demand
- Specialized deployment profiles and configurations
- Performance optimization and resource management
- Long-term maintenance and update strategies

**Success Criteria**:
- Ecosystem supports diverse use cases
- Maintenance burden is sustainable
- Community contributions are active
- Documentation is comprehensive and up-to-date

## Security Considerations

### Service Hardening

All ATproto services implement comprehensive security hardening:

```nix
# Standard security configuration for ATproto services
atprotoServiceSecurity = {
  # systemd security restrictions
  NoNewPrivileges = true;
  ProtectSystem = "strict";
  ProtectHome = true;
  ProtectKernelTunables = true;
  ProtectKernelModules = true;
  ProtectControlGroups = true;
  
  # Network isolation
  RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
  
  # File system restrictions
  ReadWritePaths = [ "/var/lib/atproto" ];
  
  # Capability restrictions
  CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
};
```

### Dependency Security

1. **Source Verification**
   - All sources pinned to specific commit hashes
   - Cryptographic verification of source integrity
   - Regular security auditing of dependencies

2. **Build Environment Security**
   - Isolated build environments
   - Minimal build dependencies
   - Reproducible builds with content addressing

3. **Runtime Security**
   - Principle of least privilege for all services
   - Network segmentation and access controls
   - Regular security updates and patching

## Performance Considerations

### Build Performance

1. **Shared Dependency Caching**
   - Rust: Shared cargo artifacts across workspace members
   - Node.js: Shared node_modules for monorepo packages
   - Go: Shared module cache for related services

2. **Parallel Build Optimization**
   - Independent package builds run in parallel
   - Multi-stage builds for complex applications
   - Build artifact reuse across related packages

### Runtime Performance

1. **Resource Management**
   - Memory limits and monitoring for all services
   - CPU scheduling optimization for ATproto workloads
   - Disk I/O optimization for database-heavy services

2. **Network Performance**
   - Connection pooling for database connections
   - HTTP/2 and WebSocket optimization
   - CDN integration for static assets

## Maintenance Strategy

### Automated Updates

1. **Dependency Monitoring**
   - Automated tracking of upstream repository changes
   - Security vulnerability scanning and alerting
   - Compatibility testing for dependency updates

2. **Package Maintenance**
   - Automated build testing for all packages
   - Performance regression detection
   - Documentation synchronization with code changes

### Community Engagement

1. **Contribution Guidelines**
   - Clear packaging standards and templates
   - Code review processes for new packages
   - Mentorship programs for new contributors

2. **Ecosystem Coordination**
   - Regular communication with upstream projects
   - Coordination with other ATproto packaging efforts
   - Community feedback collection and integration

This design provides a comprehensive foundation for expanding the ATproto Nix ecosystem while maintaining quality, security, and maintainability standards.