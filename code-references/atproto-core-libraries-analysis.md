# ATProto Core Libraries Analysis

## Executive Summary

Based on analysis of ATProto applications in the code-references directory, this document identifies core ATProto libraries, their dependencies, and packaging priorities for the Nix ecosystem. The analysis reveals a clear hierarchy of foundational libraries that should be packaged first to support the broader ATProto application ecosystem.

## Core ATProto Libraries by Language

### TypeScript/Node.js Libraries (Official)

**Primary ATProto Libraries** (from @atproto namespace):
- `@atproto/api` (v0.14.22) - Main ATProto client API
- `@atproto/lexicon` (v0.4.12) - Schema definition and validation
- `@atproto/xrpc` (v0.6.12) - XRPC protocol implementation
- `@atproto/did` (v0.1.5) - DID (Decentralized Identifier) utilities
- `@atproto/identity` (v0.4.8) - Identity resolution and management
- `@atproto/repo` (v0.7.3) - Repository management
- `@atproto/syntax` (v0.3.4) - ATProto syntax parsing and validation

**Supporting Libraries**:
- `@atproto/lex-cli` (v0.8.3) - Lexicon CLI tools for code generation
- `multiformats` (v13.3.7) - Multiformat data structures (CID, etc.)
- `zod` (v3.25.76) - Schema validation (commonly used with ATProto)

### Go Libraries (Indigo Implementation)

**Core ATProto Modules** (from github.com/bluesky-social/indigo):
- `atproto/` - Core ATProto protocol implementation
- `api/` - Generated API bindings from lexicons
- `lex/` - Lexicon schema handling
- `xrpc/` - XRPC client and server implementation
- `did/` - DID resolution and management
- `repo/` - Repository and MST (Merkle Search Tree) implementation
- `carstore/` - CAR (Content Addressable aRchive) storage
- `events/` - Event streaming and firehose implementation

**Key Dependencies**:
- IPFS/IPLD libraries for content addressing
- Cryptographic libraries (secp256k1, JWT)
- Database drivers (PostgreSQL, SQLite)
- WebSocket and HTTP libraries

### Rust Libraries (Community Implementations)

**rsky Libraries** (Rust ATProto implementation):
- `rsky-lexicon` - Lexicon schema handling
- `rsky-crypto` - Cryptographic utilities
- `rsky-identity` - Identity and DID management
- `rsky-syntax` - ATProto syntax parsing
- `rsky-common` - Shared utilities and types
- `rsky-repo` - Repository management
- `rsky-firehose` - Event streaming implementation

**Microcosm Libraries**:
- `links` - URI parsing and validation utilities (custom implementation)

**Key Dependencies**:
- `serde` ecosystem for serialization
- `tokio` for async runtime
- `secp256k1` for cryptography
- IPLD and CBOR libraries
- WebSocket and HTTP client libraries

## Dependency Analysis by Application Category

### Infrastructure Services (PDS, Relay, Feed Generators)

**Common Dependencies**:
- Database backends (PostgreSQL, SQLite, RocksDB)
- WebSocket servers for real-time communication
- HTTP/HTTPS servers with TLS support
- Cryptographic libraries for signing and verification
- IPFS/IPLD for content addressing
- Event streaming (Jetstream/Firehose)

**Language-Specific Patterns**:
- **Node.js**: Express/Fastify + official @atproto libraries
- **Go**: Echo/Gin + Indigo libraries + GORM
- **Rust**: Axum/Warp + rsky libraries + tokio ecosystem

### Development Tools

**Lexicon Tools**:
- Schema validation and code generation
- Cross-language binding generation
- API documentation generation

**CLI Tools**:
- DID management and resolution
- Repository inspection and manipulation
- Development server and testing utilities

### Applications (Leaflet, Slices, etc.)

**Frontend Dependencies**:
- React/Next.js ecosystem
- Real-time synchronization (Replicache, WebSockets)
- Authentication and session management

**Backend Dependencies**:
- Database ORMs and migration tools
- File storage and blob handling
- Background job processing

## Packaging Priority Matrix

### Tier 1: Foundation Libraries (Immediate Priority)

1. **@atproto/lexicon** - Schema foundation for all applications
2. **@atproto/api** - Primary client library
3. **@atproto/xrpc** - Protocol implementation
4. **multiformats** - Content addressing primitives
5. **rsky-lexicon** - Rust lexicon implementation
6. **rsky-crypto** - Rust cryptographic utilities

**Rationale**: These libraries are dependencies for virtually all ATProto applications and provide the foundational protocol implementation.

### Tier 2: Core Services (High Priority)

1. **@atproto/did** and **@atproto/identity** - Identity infrastructure
2. **@atproto/repo** - Repository management
3. **rsky-identity** and **rsky-repo** - Rust equivalents
4. **Indigo core modules** (atproto/, api/, lex/) - Go implementation
5. **@atproto/lex-cli** - Development tooling

**Rationale**: Required for building any ATProto service that handles identity or data storage.

### Tier 3: Application Support (Medium Priority)

1. **rsky-firehose** - Event streaming
2. **Indigo events/** and **carstore/** - Go event handling and storage
3. **Database integration libraries** - PostgreSQL, SQLite adapters
4. **Authentication libraries** - OAuth, session management
5. **File storage libraries** - S3, local disk adapters

**Rationale**: Needed for production deployments and advanced features.

## Packaging Challenges and Solutions

### Cross-Language Compatibility

**Challenge**: ATProto applications often mix languages (e.g., Rust backend + TypeScript frontend)
**Solution**: 
- Package each language ecosystem separately
- Provide integration examples and templates
- Use consistent configuration patterns across languages

### Lexicon Code Generation

**Challenge**: Many applications generate code from lexicon schemas
**Solution**:
- Package lexicon CLI tools first
- Create Nix functions for code generation during build
- Cache generated code to avoid runtime dependencies

### Database Integration

**Challenge**: Applications support multiple database backends
**Solution**:
- Create modular database packages
- Use NixOS module system for database configuration
- Provide migration and setup utilities

### Cryptographic Dependencies

**Challenge**: Consistent cryptographic library versions across applications
**Solution**:
- Standardize on specific versions (e.g., secp256k1)
- Create shared cryptographic utility packages
- Ensure compatibility with system OpenSSL

## Implementation Strategy

### Phase 1: Core Libraries (Weeks 1-2)
1. Package @atproto/lexicon, @atproto/api, @atproto/xrpc
2. Package multiformats and supporting libraries
3. Create basic Rust rsky-lexicon and rsky-crypto packages
4. Establish packaging patterns and helper functions

### Phase 2: Identity and Repository (Weeks 3-4)
1. Package @atproto/did, @atproto/identity, @atproto/repo
2. Package rsky-identity, rsky-repo, rsky-common
3. Begin Indigo Go library packaging
4. Create development tooling (@atproto/lex-cli)

### Phase 3: Service Infrastructure (Weeks 5-6)
1. Package event streaming libraries (rsky-firehose, Indigo events)
2. Package storage libraries (carstore, database adapters)
3. Create authentication and session management libraries
4. Package file storage and blob handling utilities

### Phase 4: Application Support (Weeks 7-8)
1. Package remaining application-specific libraries
2. Create integration examples and templates
3. Develop cross-language compatibility utilities
4. Create comprehensive documentation and guides

## Success Metrics

1. **Coverage**: 80% of identified core libraries packaged
2. **Compatibility**: All major ATProto applications can build with packaged libraries
3. **Performance**: Build times comparable to or better than upstream
4. **Maintenance**: Automated dependency updates and security scanning
5. **Community**: Active contributions and package adoption

## Conclusion

The ATProto ecosystem has a well-defined set of core libraries that form the foundation for all applications. By focusing on packaging these libraries first, we can enable the broader ecosystem while establishing consistent patterns for future contributions. The multi-language nature of the ecosystem requires careful coordination, but the clear separation of concerns in the protocol design makes this manageable.

The priority matrix ensures we build the foundation first, then layer on increasingly specialized functionality. This approach minimizes rework and provides value to users at each stage of the implementation.