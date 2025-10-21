# ATProto Applications Analysis

## Available Applications for Packaging

Based on analysis of the code-references directory, we have several diverse ATProto applications that represent different categories and technology stacks:

### 1. **Tangled** (Git Forge) - Go
- **Purpose**: Git forge for ATProto with knot (git hosting), spindle (CI/CD), and appview (web interface)
- **Technology**: Go with CGO, SQLite, Docker, SSH integration
- **Nix Status**: ✅ **Complete flake.nix with modules** - Production ready
- **Complexity**: High - Multi-service architecture with complex dependencies
- **Category**: Development tools, Git hosting, CI/CD

### 2. **Allegedly** (PLC Tools) - Rust
- **Purpose**: Public Ledger Consortium (PLC) tools and services for DID management
- **Technology**: Rust, PostgreSQL, TLS/ACME, HTTP reverse proxy
- **Nix Status**: ❌ **No Nix configuration** - Needs packaging
- **Complexity**: Medium - CLI tools with server components
- **Category**: Identity infrastructure, DID management

### 3. **Leaflet** (Collaborative Writing) - TypeScript/Node.js
- **Purpose**: Shared writing and social publishing platform built on Bluesky
- **Technology**: Next.js, React, Supabase, Replicache, TailwindCSS
- **Nix Status**: ❌ **No Nix configuration** - Needs packaging
- **Complexity**: High - Full-stack web application with real-time sync
- **Category**: Content creation, collaborative editing

### 4. **Slices** (Custom AppViews) - Rust + Deno
- **Purpose**: Platform for building custom AT Protocol AppViews with custom schemas
- **Technology**: Rust API backend, Deno frontend, PostgreSQL, Redis, Docker
- **Nix Status**: ❌ **No Nix configuration** - Needs packaging
- **Complexity**: High - Multi-language platform with code generation
- **Category**: Developer platform, AppView framework

### 5. **Streamplace** (Video Infrastructure) - Go + Rust + JavaScript
- **Purpose**: Video streaming infrastructure for ATProto
- **Technology**: Go, Rust, JavaScript, GStreamer, WebRTC, multiple databases
- **Nix Status**: ❌ **No Nix configuration** - Needs packaging
- **Complexity**: Very High - Complex multimedia processing pipeline
- **Category**: Media infrastructure, video streaming

### 6. **Microcosm-rs** (ATProto Services) - Rust
- **Purpose**: Collection of ATProto services (Constellation, Spacedust, Slingshot, UFOs)
- **Technology**: Rust, various databases, WebSocket APIs
- **Nix Status**: ❌ **No Nix configuration** - Needs packaging
- **Complexity**: Medium-High - Multiple independent services
- **Category**: ATProto infrastructure, data indexing

## Technology Stack Distribution

### Languages
- **Go**: Tangled, Streamplace (partial)
- **Rust**: Allegedly, Slices (API), Streamplace (partial), Microcosm-rs
- **TypeScript/Node.js**: Leaflet, Streamplace (partial)
- **Deno**: Slices (frontend)

### Databases
- **PostgreSQL**: Allegedly, Slices, Streamplace
- **SQLite**: Tangled, Leaflet (via Supabase)
- **Redis**: Slices, Streamplace
- **Various**: Microcosm-rs (RocksDB, etc.)

### Key Dependencies
- **ATProto Libraries**: All applications use various ATProto client libraries
- **Docker**: Tangled (spindle), Slices, Streamplace
- **WebSocket/Real-time**: Leaflet (Replicache), Slices (Jetstream), Microcosm-rs
- **Multimedia**: Streamplace (GStreamer, WebRTC)

## Packaging Priority Recommendations

### Tier 1: High Priority (Foundation)
1. **Tangled** - Already has excellent Nix support, perfect reference implementation
2. **Allegedly** - Critical identity infrastructure, relatively straightforward Rust packaging
3. **Microcosm-rs** - Core ATProto services, good Rust packaging example

### Tier 2: Medium Priority (Applications)
4. **Leaflet** - Popular user-facing application, good Node.js packaging example
5. **Slices** - Developer platform, demonstrates multi-language packaging

### Tier 3: Lower Priority (Complex)
6. **Streamplace** - Very complex multimedia dependencies, specialized use case

## Packaging Challenges by Application

### Tangled ✅
- **Challenges**: Hardcoded endpoints (already documented)
- **Solutions**: Configuration templating, environment overrides

### Allegedly
- **Challenges**: TLS/ACME integration, PostgreSQL setup, reverse proxy config
- **Solutions**: NixOS modules for certificate management, database integration

### Leaflet
- **Challenges**: Supabase dependency, Next.js build complexity, real-time sync
- **Solutions**: Self-hosted Supabase alternative, proper Node.js packaging

### Slices
- **Challenges**: Multi-language (Rust + Deno), code generation, OAuth integration
- **Solutions**: Coordinated build process, proper Deno packaging patterns

### Streamplace
- **Challenges**: GStreamer, WebRTC, complex multimedia pipeline, multiple languages
- **Solutions**: Multimedia-focused Nix packaging, extensive native dependencies

### Microcosm-rs
- **Challenges**: Multiple independent services, various database backends
- **Solutions**: Modular packaging approach, service discovery patterns

## Implementation Strategy

1. **Start with Tangled** - Use as reference and improve configuration handling
2. **Package Allegedly** - Establish Rust packaging patterns for ATProto
3. **Add Microcosm-rs** - Expand Rust patterns, demonstrate service modularity
4. **Package Leaflet** - Establish Node.js/TypeScript patterns
5. **Add Slices** - Demonstrate multi-language coordination
6. **Consider Streamplace** - Advanced multimedia packaging (optional)

This analysis provides a solid foundation for expanding our ATProto Nix ecosystem beyond the current blacksky/microcosm packages.