# ATproto Package Discovery and Comparison

This guide helps you discover, compare, and choose the right ATproto packages for your needs.

## Table of Contents

1. [Package Categories](#package-categories)
2. [Service Comparison Matrix](#service-comparison-matrix)
3. [Implementation Comparison](#implementation-comparison)
4. [Use Case Guides](#use-case-guides)
5. [Package Search](#package-search)
6. [Migration Guides](#migration-guides)

## Package Categories

### Foundation Infrastructure (Tier 1)

Essential services that form the backbone of ATproto networks.

| Package | Organization | Language | Services | Status |
|---------|--------------|----------|----------|--------|
| `microcosm-blue-allegedly` | Microcosm Blue | Rust | PLC operations, DID management | ✅ Stable |
| `smokesignal-events-quickdid` | Smokesignal Events | Rust | DID resolution, identity lookup | ✅ Stable |
| `bluesky-social-frontpage` | Bluesky Social | TypeScript | PDS, relay, AppView | ✅ Official |
| `bluesky-social-indigo` | Bluesky Social | Go | Relay, palomar, rainbow | ✅ Official |
| `individual-pds-gatekeeper` | Individual | Rust | PDS registration, 2FA | ✅ Stable |

**When to use Foundation packages:**
- Setting up core ATproto infrastructure
- Need maximum reliability and compatibility
- Building production networks
- Require official protocol compliance

### Ecosystem Services (Tier 2)

Applications and platforms that extend ATproto functionality.

| Package | Organization | Language | Services | Status |
|---------|--------------|----------|----------|--------|
| `hyperlink-academy-leaflet` | Hyperlink Academy | TypeScript | Collaborative writing, social publishing | ✅ Stable |
| `slices-network-slices` | Slices Network | Rust + Deno | Custom AppView, SDK generation | ✅ Stable |
| `parakeet-social-parakeet` | Parakeet Social | Rust | Full AppView, indexer, backfill | ✅ Stable |
| `teal-fm-teal` | Teal.fm | Multiple | Music platform, social features | ✅ Stable |
| `witchcraft-systems-pds-dash` | Witchcraft Systems | Svelte + Deno | PDS monitoring, management | ✅ Stable |

**When to use Ecosystem packages:**
- Building custom applications on ATproto
- Need specialized functionality
- Want to extend existing ATproto networks
- Developing user-facing applications

### Specialized Applications (Tier 3)

Complex applications with advanced features and dependencies.

| Package | Organization | Language | Services | Status |
|---------|--------------|----------|----------|--------|
| `stream-place-streamplace` | Stream.place | Multiple | Video streaming, media processing | 🚧 Complex |
| `yoten-app-yoten` | Yoten App | Multiple | Language learning, progress tracking | 🚧 Complex |
| `red-dwarf-client-red-dwarf` | Red Dwarf Client | Multiple | Enhanced Bluesky client | 🚧 Complex |
| `atbackup-pages-dev-atbackup` | ATBackup Pages Dev | Tauri | Desktop backup application | 📋 Placeholder |

**When to use Specialized packages:**
- Need advanced multimedia capabilities
- Building complex user applications
- Require desktop integration
- Want cutting-edge features

### Development Tools

Utilities and tools for ATproto development.

| Package | Organization | Language | Purpose | Status |
|---------|--------------|----------|---------|--------|
| `tangled-dev-lexgen` | Tangled Dev | Go | Lexicon code generation | ✅ Stable |
| `tangled-dev-genjwks` | Tangled Dev | Go | JWKS key generation | ✅ Stable |
| `microcosm-constellation` | Microcosm | Rust | Backlink indexing | ✅ Stable |
| `microcosm-spacedust` | Microcosm | Rust | ATproto utilities | ✅ Stable |

## Service Comparison Matrix

### Personal Data Server (PDS) Implementations

| Feature | Frontpage (Official) | Community Alternative | Notes |
|---------|---------------------|----------------------|-------|
| **Language** | TypeScript | - | Official implementation |
| **Database** | PostgreSQL | - | Production-ready |
| **Storage** | S3, Local | - | Flexible storage options |
| **Performance** | High | - | Optimized for scale |
| **Compliance** | Full | - | Complete ATproto compliance |
| **Maintenance** | Bluesky Team | - | Official support |

**Recommendation**: Use `bluesky-social-frontpage` for all PDS deployments.

### Relay Implementations

| Feature | Indigo (Official) | Community Alternative | Notes |
|---------|------------------|----------------------|-------|
| **Language** | Go | - | Official implementation |
| **Firehose** | Full support | - | Complete event streaming |
| **Jetstream** | Native | - | Real-time capabilities |
| **Scalability** | Enterprise | - | Handles high throughput |
| **Compliance** | Full | - | Reference implementation |

**Recommendation**: Use `bluesky-social-indigo` for relay services.

### AppView Implementations

| Feature | Leaflet | Slices | Parakeet | Notes |
|---------|---------|--------|----------|-------|
| **Language** | TypeScript | Rust + Deno | Rust | Different approaches |
| **Focus** | Collaborative writing | Custom feeds | Full AppView | Specialized vs general |
| **Real-time** | WebSocket | WebSocket | Jetstream | All support real-time |
| **Customization** | High | Very High | Medium | Slices most flexible |
| **Complexity** | Medium | High | Medium | Setup complexity |
| **Use Case** | Content creation | Custom algorithms | General purpose | Different strengths |

**Recommendations**:
- **Content platforms**: Use `hyperlink-academy-leaflet`
- **Custom algorithms**: Use `slices-network-slices`
- **General AppView**: Use `parakeet-social-parakeet`

### Identity Services

| Feature | QuickDID | Allegedly | Notes |
|---------|----------|-----------|-------|
| **Language** | Rust | Rust | Both high-performance |
| **Purpose** | DID resolution | PLC operations | Complementary services |
| **Database** | SQLite/PostgreSQL | PostgreSQL | Different storage needs |
| **Performance** | Very High | High | QuickDID optimized for speed |
| **Caching** | Advanced | Basic | QuickDID has better caching |
| **Operations** | Read-heavy | Write-heavy | Different workload patterns |

**Recommendations**:
- **DID resolution**: Use `smokesignal-events-quickdid`
- **PLC operations**: Use `microcosm-blue-allegedly`
- **Both together**: Recommended for complete identity infrastructure

## Implementation Comparison

### Language Ecosystem Comparison

#### Rust Implementations

**Advantages**:
- High performance and memory safety
- Excellent concurrency support
- Strong type system
- Growing ATproto ecosystem

**Packages**: Allegedly, QuickDID, Slices backend, Parakeet, Microcosm services

**Best for**: Infrastructure services, high-performance components, system-level tools

#### TypeScript/Node.js Implementations

**Advantages**:
- Rapid development and prototyping
- Large ecosystem and community
- Official ATproto SDK support
- Easy integration with web technologies

**Packages**: Frontpage, Leaflet, Grain

**Best for**: Web applications, rapid prototyping, frontend services

#### Go Implementations

**Advantages**:
- Simple deployment and operations
- Excellent standard library
- Good performance characteristics
- Strong concurrency primitives

**Packages**: Indigo, Tangled tools

**Best for**: Network services, CLI tools, system utilities

#### Multi-language Implementations

**Advantages**:
- Use best tool for each component
- Leverage existing expertise
- Optimize different parts differently

**Packages**: Slices (Rust + Deno), Streamplace (Multiple), Teal (Multiple)

**Best for**: Complex applications, specialized requirements

### Architecture Patterns

#### Monolithic Services

**Examples**: Frontpage PDS, Indigo Relay
**Advantages**: Simple deployment, easier debugging, lower latency
**Disadvantages**: Harder to scale components independently

#### Microservices

**Examples**: Microcosm collection, Tangled components
**Advantages**: Independent scaling, technology diversity, fault isolation
**Disadvantages**: Network complexity, operational overhead

#### Hybrid Approaches

**Examples**: Slices (monolithic backend + separate frontend)
**Advantages**: Balance of simplicity and flexibility
**Disadvantages**: Requires careful interface design

## Use Case Guides

### Personal ATproto Server

**Goal**: Run your own PDS and basic services

**Recommended Stack**:
```nix
services = {
  # Core PDS
  bluesky-social-frontpage.enable = true;
  
  # Identity services
  smokesignal-events-quickdid.enable = true;
  microcosm-blue-allegedly.enable = true;
  
  # Management tools
  witchcraft-systems-pds-dash.enable = true;
  individual-pds-gatekeeper.enable = true;
};
```

**Why this stack**:
- Official PDS implementation for maximum compatibility
- Fast identity resolution with QuickDID
- PLC operations with Allegedly
- Web dashboard for management
- Registration control with Gatekeeper

### Development Environment

**Goal**: Local development and testing

**Recommended Stack**:
```nix
services = {
  # Lightweight services for development
  smokesignal-events-quickdid = {
    enable = true;
    settings.database.type = "sqlite";
  };
  
  # Development tools
  tangled-dev-lexgen.enable = true;
  tangled-dev-genjwks.enable = true;
  
  # Monitoring
  witchcraft-systems-pds-dash.enable = true;
};
```

**Why this stack**:
- SQLite for easy setup
- Code generation tools
- Minimal resource usage
- Quick iteration

### Custom Social Platform

**Goal**: Build a specialized social application

**Recommended Stack**:
```nix
services = {
  # Custom AppView
  hyperlink-academy-leaflet = {
    enable = true;
    settings = {
      # Collaborative features
      realtime.enable = true;
      publishing.enable = true;
    };
  };
  
  # Or for more customization
  slices-network-slices = {
    enable = true;
    settings = {
      # Custom algorithms
      feeds = [ "trending" "local" "custom" ];
    };
  };
  
  # Supporting services
  smokesignal-events-quickdid.enable = true;
  microcosm-constellation.enable = true;
};
```

**Why this stack**:
- Leaflet for content-focused platforms
- Slices for algorithm-heavy platforms
- Constellation for backlink indexing
- QuickDID for identity resolution

### Enterprise ATproto Network

**Goal**: Production-ready, scalable ATproto infrastructure

**Recommended Stack**:
```nix
services = {
  # Core infrastructure
  bluesky-social-frontpage.enable = true;
  bluesky-social-indigo.enable = true;
  
  # Identity infrastructure
  smokesignal-events-quickdid.enable = true;
  microcosm-blue-allegedly.enable = true;
  
  # Supporting services
  microcosm-constellation.enable = true;
  parakeet-social-parakeet.enable = true;
  
  # Management and monitoring
  witchcraft-systems-pds-dash.enable = true;
  individual-pds-gatekeeper.enable = true;
};
```

**Why this stack**:
- Official implementations for reliability
- Comprehensive identity services
- Full AppView with Parakeet
- Professional management tools
- Enterprise-grade security

### Content Creator Platform

**Goal**: Platform focused on content creation and collaboration

**Recommended Stack**:
```nix
services = {
  # Content-focused AppView
  hyperlink-academy-leaflet = {
    enable = true;
    settings = {
      collaboration.enable = true;
      publishing.socialFeatures = true;
      realtime.enable = true;
    };
  };
  
  # Media processing (if needed)
  stream-place-streamplace = {
    enable = true;
    settings = {
      video.processing = true;
      streaming.enable = true;
    };
  };
  
  # Core services
  bluesky-social-frontpage.enable = true;
  smokesignal-events-quickdid.enable = true;
};
```

**Why this stack**:
- Leaflet optimized for content creation
- Streamplace for media handling
- Real-time collaboration features
- Social publishing capabilities

## Package Search

### By Service Type

**PDS (Personal Data Server)**:
- `bluesky-social-frontpage` - Official TypeScript implementation

**Relay**:
- `bluesky-social-indigo` - Official Go implementation

**AppView**:
- `hyperlink-academy-leaflet` - Collaborative writing platform
- `slices-network-slices` - Custom feed algorithms
- `parakeet-social-parakeet` - Full-featured AppView

**Identity Services**:
- `smokesignal-events-quickdid` - Fast DID resolution
- `microcosm-blue-allegedly` - PLC operations

**Feed Generators**:
- `slices-network-slices` - Custom algorithm engine
- `microcosm-constellation` - Backlink indexing

**Management Tools**:
- `witchcraft-systems-pds-dash` - PDS dashboard
- `individual-pds-gatekeeper` - Registration control
- `atbackup-pages-dev-atbackup` - Backup utility

### By Language

**Rust**:
- `smokesignal-events-quickdid`
- `microcosm-blue-allegedly`
- `individual-pds-gatekeeper`
- `parakeet-social-parakeet`
- `slices-network-slices` (backend)
- All `microcosm-*` services

**TypeScript/Node.js**:
- `bluesky-social-frontpage`
- `hyperlink-academy-leaflet`
- `bluesky-social-grain`

**Go**:
- `bluesky-social-indigo`
- `tangled-dev-lexgen`
- `tangled-dev-genjwks`

**Deno**:
- `witchcraft-systems-pds-dash`
- `slices-network-slices` (frontend)

**Multi-language**:
- `stream-place-streamplace`
- `yoten-app-yoten`
- `red-dwarf-client-red-dwarf`

### By Organization

**Official Bluesky**:
- `bluesky-social-frontpage`
- `bluesky-social-indigo`
- `bluesky-social-grain`

**Community Organizations**:
- `hyperlink-academy-leaflet`
- `slices-network-slices`
- `smokesignal-events-quickdid`
- `microcosm-blue-allegedly`
- `witchcraft-systems-pds-dash`

**Individual Developers**:
- `individual-pds-gatekeeper`
- `individual-drainpipe`

**Development Tools**:
- `tangled-dev-*` (Tangled ecosystem)
- `microcosm-*` (Microcosm utilities)

## Migration Guides

### From Manual Installation

If you're currently running ATproto services manually:

1. **Identify current services**: List what you're running
2. **Find NUR equivalents**: Use the comparison tables above
3. **Plan migration**: Start with non-critical services
4. **Test configuration**: Use development environment first
5. **Migrate incrementally**: One service at a time

### Between Implementations

#### From Community PDS to Official

```nix
# Before (hypothetical community PDS)
services.community-pds.enable = false;

# After (official implementation)
services.bluesky-social-frontpage = {
  enable = true;
  settings = {
    # Migrate configuration
    hostname = config.services.community-pds.hostname;
    database = config.services.community-pds.database;
  };
};
```

#### Between AppView Implementations

```nix
# From basic AppView to Leaflet
services.basic-appview.enable = false;

services.hyperlink-academy-leaflet = {
  enable = true;
  settings = {
    # Enhanced features
    collaboration.enable = true;
    publishing.enable = true;
  };
};
```

### Configuration Migration

Most services support configuration migration through:

1. **Export current configuration**: Use service-specific tools
2. **Convert format**: Usually JSON to Nix attribute set
3. **Test new configuration**: In development environment
4. **Deploy with rollback plan**: Use NixOS generations

### Data Migration

For services with persistent data:

1. **Backup current data**: Always backup before migration
2. **Check compatibility**: Ensure data format compatibility
3. **Use migration tools**: Many packages include migration utilities
4. **Verify data integrity**: Test after migration

This comprehensive discovery guide helps you navigate the rich ATproto package ecosystem and make informed decisions for your specific use case.