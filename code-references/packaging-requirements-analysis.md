# ATProto Applications Packaging Requirements Analysis

## Overview

This document provides detailed packaging requirements and challenges for each ATProto application in the code-references directory, organized by priority tier and implementation complexity.

## Tier 1 Applications (Immediate Priority)

### 1. Allegedly (DID/PLC Tools) - Rust

**Current Status**: No Nix configuration
**Packaging Complexity**: Medium
**Priority Score**: 7

#### Build Requirements
- **Language**: Rust (Edition 2024)
- **Build System**: Cargo
- **Target**: CLI tools and HTTP server

#### Dependencies Analysis
```toml
# Key dependencies from Cargo.toml
tokio = "1.47.1"           # Async runtime
poem = "3.1.12"            # HTTP server with ACME support
tokio-postgres = "0.7.13"  # PostgreSQL client
reqwest = "0.12.23"        # HTTP client
native-tls = "0.2.14"      # TLS support
serde_json = "1.0.143"     # JSON serialization
```

#### Nix Packaging Requirements
- **Build Function**: `craneLib.buildPackage`
- **Native Inputs**: `pkg-config`, `openssl`
- **Build Inputs**: `openssl`, `postgresql`
- **Environment Variables**: `OPENSSL_NO_VENDOR=1`

#### Runtime Requirements
- PostgreSQL database (configurable)
- TLS certificate management (ACME/Let's Encrypt)
- HTTP reverse proxy support
- Network access for DID resolution

#### NixOS Module Requirements
```nix
services.allegedly = {
  enable = mkEnableOption "Allegedly PLC server";
  database = {
    host = mkOption { type = types.str; };
    port = mkOption { type = types.port; default = 5432; };
    name = mkOption { type = types.str; default = "allegedly"; };
    user = mkOption { type = types.str; default = "allegedly"; };
    passwordFile = mkOption { type = types.path; };
  };
  tls = {
    enable = mkOption { type = types.bool; default = true; };
    acme = {
      enable = mkOption { type = types.bool; default = false; };
      email = mkOption { type = types.str; };
    };
    certificateFile = mkOption { type = types.nullOr types.path; };
    keyFile = mkOption { type = types.nullOr types.path; };
  };
  reverseProxy = {
    enable = mkOption { type = types.bool; default = false; };
    host = mkOption { type = types.str; default = "localhost"; };
    port = mkOption { type = types.port; default = 8080; };
  };
};
```

#### Packaging Challenges
1. **PostgreSQL Integration**: Requires database setup and migration handling
2. **TLS/ACME**: Complex certificate management and renewal
3. **Reverse Proxy**: Integration with nginx or other reverse proxies
4. **DID Resolution**: Network dependencies and external service integration

#### Implementation Strategy
1. Create basic Rust package with PostgreSQL support
2. Add NixOS module with database integration
3. Implement TLS and ACME certificate management
4. Add reverse proxy configuration options
5. Create deployment examples and documentation

---

### 2. Tangled (Git Forge) - Go

**Current Status**: Complete flake.nix with modules ✅
**Packaging Complexity**: High (but already implemented)
**Priority Score**: 5

#### Current Implementation Status
- ✅ Complete flake.nix with proper Go packaging
- ✅ NixOS modules for knot (git hosting) and spindle (CI/CD)
- ✅ Docker integration and SSH key management
- ⚠️ Hardcoded endpoints need configuration

#### Remaining Work
1. **Configuration Templating**: Make hardcoded tangled.org/tangled.sh references configurable
2. **Endpoint Configuration**: Allow custom appview, jetstream, and nixery endpoints
3. **Documentation**: Create deployment guides and examples
4. **Testing**: Add integration tests for multi-service deployment

#### Configuration Improvements Needed
```nix
services.tangled = {
  knot = {
    endpoints = {
      appview = mkOption { 
        type = types.str; 
        default = "https://tangled.org"; 
        description = "AppView endpoint URL";
      };
      jetstream = mkOption { 
        type = types.str; 
        default = "wss://jetstream.tangled.sh"; 
        description = "Jetstream WebSocket URL";
      };
      nixery = mkOption { 
        type = types.str; 
        default = "nixery.tangled.sh"; 
        description = "Nixery container registry";
      };
    };
  };
};
```

---

### 3. Microcosm-rs (ATProto Services) - Rust

**Current Status**: Partial packaging in repository
**Packaging Complexity**: Medium-High
**Priority Score**: 4

#### Current Implementation
- ✅ Basic package structure exists in `pkgs/microcosm/`
- ✅ NixOS modules exist in `modules/microcosm/`
- ⚠️ Needs integration with code-references version
- ⚠️ Missing some services and proper dependency management

#### Services to Package
```rust
// From workspace members
"constellation"  // Backlink indexer
"spacedust"     // ATProto service component  
"slingshot"     // ATProto service component
"ufos"          // ATProto service component
"who-am-i"      // Identity service
"quasar"        // ATProto service component
"pocket"        // ATProto service component
"reflector"     // ATProto service component
"jetstream"     // Event streaming
"links"         // Shared utilities
```

#### Dependencies Analysis
```toml
# Key shared dependencies
tokio = "1.44"              # Async runtime
axum = "0.8.1"             # HTTP server
rocksdb = "0.23.0"         # Database (optional)
serde_json = "1.0.139"     # JSON serialization
tungstenite = "0.26.1"     # WebSocket support
zstd = "0.13.2"            # Compression
```

#### Packaging Requirements
- **Workspace Build**: Use `craneLib.buildDepsOnly` for shared dependencies
- **Individual Services**: Generate packages with `lib.genAttrs`
- **Feature Flags**: Handle optional features like RocksDB
- **Native Dependencies**: OpenSSL, zstd, RocksDB (optional)

#### Implementation Strategy
1. Update existing packages to use code-references source
2. Add missing services (jetstream, links)
3. Improve dependency sharing and build optimization
4. Update NixOS modules for new services
5. Add comprehensive testing and integration

---

### 4. Frontpage/Bluesky (Official Implementation) - TypeScript

**Current Status**: No Nix configuration
**Packaging Complexity**: High
**Priority Score**: 4

#### Project Structure
```
packages/
├── atproto-browser/        # Browser-based ATProto client
├── frontpage/             # Main application
├── frontpage-atproto-client/ # ATProto client library
├── frontpage-oauth/       # OAuth implementation
├── unravel/              # Additional component
└── typescript-config/     # Shared TypeScript config
```

#### Dependencies Analysis
```json
// Key dependencies across packages
"@atproto/api": "^0.14.22"
"@atproto/lexicon": "^0.4.12"
"@atproto/identity": "^0.4.8"
"next": "catalog:"
"react": "catalog:"
"swr": "^2.3.4"
"zod": "^3.25.76"
```

#### Packaging Requirements
- **Build System**: pnpm workspace with turbo
- **Package Manager**: `buildNpmPackage` with pnpm support
- **Monorepo Handling**: Workspace dependency resolution
- **Asset Building**: Next.js build with Turbopack

#### NixOS Module Requirements
```nix
services.bluesky = {
  frontpage = {
    enable = mkEnableOption "Bluesky Frontpage application";
    port = mkOption { type = types.port; default = 3000; };
    hostname = mkOption { type = types.str; };
    database = {
      type = mkOption { 
        type = types.enum [ "sqlite" "postgres" ]; 
        default = "sqlite"; 
      };
      connectionString = mkOption { type = types.str; };
    };
    oauth = {
      clientId = mkOption { type = types.str; };
      clientSecret = mkOption { type = types.str; };
      redirectUri = mkOption { type = types.str; };
    };
  };
};
```

#### Packaging Challenges
1. **Monorepo Complexity**: Multiple interdependent packages
2. **pnpm Workspaces**: Proper workspace dependency resolution
3. **Catalog Dependencies**: Handling pnpm catalog references
4. **Asset Building**: Next.js and Turbopack integration
5. **OAuth Configuration**: Secure credential management

#### Implementation Strategy
1. Create individual packages for each workspace component
2. Establish pnpm workspace packaging patterns
3. Handle catalog dependencies and version resolution
4. Create NixOS module with OAuth and database integration
5. Add deployment examples for production use

## Tier 2 Applications (High Priority)

### 5. Indigo (Official Go Implementation)

**Packaging Complexity**: High
**Key Challenges**: 
- Large codebase with many services
- Complex IPFS/IPLD dependencies
- Multiple database backends
- Extensive Go module dependencies

**Implementation Approach**:
- Start with core libraries (atproto/, api/, lex/)
- Package individual services incrementally
- Create shared Go packaging utilities
- Handle CGO dependencies properly

### 6. rsky (Community Rust Implementation)

**Packaging Complexity**: Medium-High
**Key Challenges**:
- Workspace with multiple services
- Cryptographic dependencies
- IPLD and CBOR handling
- Cross-service communication

**Implementation Approach**:
- Use existing blacksky/rsky as foundation
- Fix placeholder hashes and source references
- Add proper build environment setup
- Create comprehensive service modules

### 7. PDS Ecosystem (pds-dash, pds-gatekeeper)

**Packaging Complexity**: Medium
**Key Challenges**:
- Svelte packaging (pds-dash)
- Rust packaging (pds-gatekeeper)
- PDS integration and coordination
- Database and email configuration

**Implementation Approach**:
- Package each component separately
- Create unified PDS deployment profiles
- Handle inter-service communication
- Add comprehensive configuration options

## Tier 3 Applications (Future Consideration)

### 8. Slices (Custom AppViews Platform)

**Packaging Complexity**: Very High
**Key Challenges**:
- Multi-language (Rust API + Deno frontend)
- Code generation from schemas
- Complex OAuth and authentication
- Redis and PostgreSQL integration

### 9. Streamplace (Video Infrastructure)

**Packaging Complexity**: Extremely High
**Key Challenges**:
- GStreamer and WebRTC dependencies
- Multi-language codebase
- Complex multimedia pipeline
- Specialized hardware requirements

### 10. Leaflet (Collaborative Writing)

**Packaging Complexity**: High
**Key Challenges**:
- Next.js with complex frontend
- Supabase dependency
- Real-time synchronization (Replicache)
- Authentication and session management

## Common Packaging Patterns

### Rust Applications
```nix
craneLib.buildPackage {
  pname = "atproto-rust-app";
  src = fetchFromGitHub { /* ... */ };
  
  env = {
    OPENSSL_NO_VENDOR = "1";
    ZSTD_SYS_USE_PKG_CONFIG = "1";
  };
  
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl zstd ];
  
  # ATProto-specific metadata
  passthru.atproto = {
    type = "application";
    services = [ "service-name" ];
    protocols = [ "com.atproto" ];
  };
}
```

### Node.js Applications
```nix
buildNpmPackage {
  pname = "atproto-node-app";
  src = fetchFromGitHub { /* ... */ };
  
  npmDepsHash = "sha256-...";
  
  # Handle workspace dependencies
  npmWorkspace = "packages/app-name";
  
  passthru.atproto = {
    type = "application";
    services = [ "service-name" ];
  };
}
```

### Go Applications
```nix
buildGoModule {
  pname = "atproto-go-app";
  src = fetchFromGitHub { /* ... */ };
  
  vendorHash = "sha256-...";
  
  # Handle CGO dependencies
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ sqlite ];
  
  passthru.atproto = {
    type = "application";
    services = [ "service-name" ];
  };
}
```

## Conclusion

This analysis provides a comprehensive roadmap for packaging ATProto applications, with detailed requirements and implementation strategies for each tier. The focus on Tier 1 applications ensures rapid progress on high-value, manageable complexity packages, while the detailed analysis of higher-tier applications provides a clear path for future expansion.

The common packaging patterns and standardized metadata schema ensure consistency across the ecosystem while accommodating the diverse technology stacks used in ATProto applications.