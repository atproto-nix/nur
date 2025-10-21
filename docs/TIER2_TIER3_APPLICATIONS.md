# Tier 2 and Tier 3 ATProto Applications

This document provides detailed information about the advanced ATProto applications available in the repository, including their features, configuration options, and deployment patterns.

## Overview

The ATProto NUR includes comprehensive support for advanced ATProto applications beyond the core infrastructure services. These are organized into tiers based on complexity and specialization:

- **Tier 2**: Advanced applications with broad appeal and moderate complexity
- **Tier 3**: Specialized services with complex dependencies or niche use cases

All applications include full NixOS modules with security hardening, comprehensive configuration options, and production-ready deployment patterns.

## Tier 2 Applications

### Leaflet - Collaborative Writing Platform

**Package**: `atproto-leaflet`  
**Module**: `services.atproto-leaflet`

A collaborative writing platform that combines real-time editing with social publishing through ATProto.

**Key Features**:
- Real-time collaborative editing with Replicache
- Supabase backend integration for data persistence
- ATProto OAuth authentication
- Social publishing to Bluesky network
- Next.js web application with TypeScript

**Configuration Example**:
```nix
services.atproto-leaflet = {
  enable = true;
  settings = {
    port = 3000;
    hostname = "leaflet.example.com";
    
    database = {
      url = "postgresql://user:pass@localhost:5432/leaflet";
      passwordFile = "/run/secrets/leaflet-db-password";
    };
    
    supabase = {
      url = "https://your-project.supabase.co";
      anonKey = "your-anon-key";
      serviceRoleKeyFile = "/run/secrets/supabase-service-key";
    };
    
    replicache = {
      licenseKeyFile = "/run/secrets/replicache-license";
    };
    
    oauth = {
      clientId = "your-oauth-client-id";
      clientSecretFile = "/run/secrets/oauth-client-secret";
      redirectUri = "https://leaflet.example.com/auth/callback";
    };
  };
};
```

**Use Cases**:
- Collaborative documentation platforms
- Social writing communities
- Content creation with ATProto publishing
- Real-time editing applications

### Slices - Custom AppView Platform

**Package**: `atproto-slices`  
**Module**: `services.atproto-slices`

A platform for creating custom ATProto AppViews with automatic SDK generation and OAuth integration.

**Key Features**:
- Custom AppView creation and management
- Automatic SDK generation for multiple languages
- OAuth integration with AT Protocol Identity Provider (AIP)
- PostgreSQL backend for data persistence
- RESTful API with comprehensive endpoints

**Configuration Example**:
```nix
services.atproto-slices = {
  enable = true;
  settings = {
    api = {
      port = 8080;
      hostname = "api.slices.example.com";
    };
    
    database = {
      url = "postgresql://user:pass@localhost:5432/slices";
      passwordFile = "/run/secrets/slices-db-password";
    };
    
    oauth = {
      clientId = "your-oauth-client-id";
      clientSecretFile = "/run/secrets/oauth-client-secret";
      redirectUri = "https://slices.example.com/auth/callback";
      aipBaseUrl = "https://auth.slices.example.com";
    };
    
    atproto = {
      systemSliceUri = "at://did:plc:system/network.slices.slice/system";
      sliceUri = "at://did:plc:your-slice/network.slices.slice/main";
    };
  };
};
```

**Use Cases**:
- Custom social media applications
- Specialized content aggregation
- Developer platforms and tools
- Multi-tenant AppView hosting

### Parakeet - Full-Featured ATProto AppView

**Package**: `atproto-parakeet`  
**Module**: `services.atproto-parakeet`

A comprehensive ATProto AppView implementation with consumer, indexer, and backfill capabilities.

**Key Features**:
- Complete ATProto AppView server
- Real-time consumer service for relay data
- Index service for fast queries
- Backfill service for historical data
- PostgreSQL and Redis integration
- Configurable indexing and processing

**Configuration Example**:
```nix
services.atproto-parakeet = {
  enable = true;
  settings = {
    appview = {
      port = 6000;
      did = "did:web:parakeet.example.com";
      publicKey = "your-public-key";
      endpoint = "https://parakeet.example.com";
    };
    
    consumer = {
      enable = true;
      indexer = {
        relaySource = "wss://bsky.network";
        historyMode = "realtime";
        workers = 4;
      };
      backfill = {
        workers = 4;
        downloadWorkers = 25;
      };
    };
    
    index = {
      enable = true;
      port = 6001;
    };
    
    database = {
      url = "postgresql://user:pass@localhost:5432/parakeet";
      passwordFile = "/run/secrets/parakeet-db-password";
    };
    
    redis = {
      url = "redis://localhost:6379";
    };
  };
};
```

**Use Cases**:
- Alternative AppView implementations
- Custom content indexing and search
- ATProto data analysis platforms
- High-performance social applications

### Teal - Comprehensive ATProto Platform

**Package**: `atproto-teal`  
**Module**: `services.atproto-teal`

A multi-service ATProto platform with web application, backend services, and specialized components.

**Key Features**:
- Aqua web application (Node.js/TypeScript)
- Garnet and Amethyst backend services (Rust)
- Piper music scraper service
- PostgreSQL database integration
- S3 storage support
- Comprehensive OAuth integration

**Configuration Example**:
```nix
services.atproto-teal = {
  enable = true;
  settings = {
    aqua = {
      enable = true;
      port = 3000;
      hostname = "teal.example.com";
    };
    
    services = {
      garnet.enable = true;
      amethyst.enable = true;
      piper.enable = true;
    };
    
    database = {
      url = "postgresql://user:pass@localhost:5432/teal";
      passwordFile = "/run/secrets/teal-db-password";
    };
    
    oauth = {
      clientId = "your-oauth-client-id";
      clientSecretFile = "/run/secrets/oauth-client-secret";
      redirectUri = "https://teal.example.com/api/auth/callback";
    };
    
    atproto = {
      handle = "teal.example.com";
      did = "did:plc:your-teal-did";
      signingKeyFile = "/run/secrets/atproto-signing-key";
    };
    
    s3 = {
      enable = true;
      bucket = "teal-storage";
      region = "us-east-1";
      accessKeyFile = "/run/secrets/s3-access-key";
      secretKeyFile = "/run/secrets/s3-secret-key";
    };
  };
};
```

**Use Cases**:
- Comprehensive social platforms
- Multi-service ATProto applications
- Music and media platforms
- Enterprise ATProto deployments

## Tier 3 Specialized Services

### Streamplace - Video Infrastructure Platform

**Package**: `atproto-streamplace`  
**Module**: `services.atproto-streamplace`

A video infrastructure platform with ATProto integration for live streaming and video processing.

**Key Features**:
- GStreamer pipeline integration
- FFmpeg video encoding
- Hardware acceleration support
- S3 storage for media files
- PostgreSQL backend
- ATProto identity integration

**Configuration Example**:
```nix
services.atproto-streamplace = {
  enable = true;
  settings = {
    server = {
      port = 8080;
      hostname = "streamplace.example.com";
      publicUrl = "https://streamplace.example.com";
    };
    
    database = {
      url = "postgresql://user:pass@localhost:5432/streamplace";
      passwordFile = "/run/secrets/streamplace-db-password";
    };
    
    atproto = {
      handle = "streamplace.example.com";
      did = "did:plc:your-streamplace-did";
      signingKeyFile = "/run/secrets/atproto-signing-key";
    };
    
    video = {
      maxBitrate = 5000000; # 5 Mbps
      maxResolution = "1920x1080";
      ffmpegArgs = [ "-c:v" "libx264" "-preset" "fast" ];
    };
    
    storage = {
      type = "s3";
      s3 = {
        bucket = "streamplace-media";
        region = "us-east-1";
        accessKeyFile = "/run/secrets/s3-access-key";
        secretKeyFile = "/run/secrets/s3-secret-key";
      };
    };
  };
};

# Enable hardware acceleration
hardware.opengl = {
  enable = true;
  driSupport = true;
};
```

**Use Cases**:
- Live streaming platforms
- Video processing services
- Media hosting with ATProto integration
- Content creation platforms

### Yoten - Language Learning Platform

**Package**: `atproto-yoten`  
**Module**: `services.atproto-yoten`

A social platform for tracking language learning progress with ATProto integration.

**Key Features**:
- Progress tracking and analytics
- Social features for language learners
- ATProto OAuth authentication
- PostgreSQL backend
- Redis caching support
- PostHog analytics integration

**Configuration Example**:
```nix
services.atproto-yoten = {
  enable = true;
  settings = {
    server = {
      port = 8080;
      hostname = "yoten.example.com";
      publicUrl = "https://yoten.example.com";
    };
    
    database = {
      url = "postgresql://user:pass@localhost:5432/yoten";
      passwordFile = "/run/secrets/yoten-db-password";
    };
    
    atproto = {
      handle = "yoten.example.com";
      did = "did:plc:your-yoten-did";
      signingKeyFile = "/run/secrets/atproto-signing-key";
      jetstream = {
        url = "wss://jetstream.atproto.tools/subscribe";
        enable = true;
      };
    };
    
    oauth = {
      clientId = "your-oauth-client-id";
      clientSecretFile = "/run/secrets/oauth-client-secret";
      redirectUri = "https://yoten.example.com/auth/callback";
    };
    
    session = {
      secretFile = "/run/secrets/session-secret";
      maxAge = 86400; # 24 hours
    };
    
    redis = {
      url = "redis://localhost:6379";
    };
    
    analytics = {
      posthog = {
        enable = true;
        apiKey = "your-posthog-api-key";
        host = "https://app.posthog.com";
      };
    };
  };
};
```

**Use Cases**:
- Language learning communities
- Educational social platforms
- Progress tracking applications
- Gamified learning systems

### Red Dwarf - Enhanced Bluesky Client

**Package**: `atproto-red-dwarf`  
**Module**: `services.atproto-red-dwarf`

An enhanced Bluesky client that uses Constellation for backlinks and Slingshot for PDS optimization.

**Key Features**:
- React-based web application
- Constellation integration for enhanced backlinks
- Slingshot integration for reduced PDS load
- OAuth authentication
- Customizable UI themes and features
- Performance optimizations

**Configuration Example**:
```nix
services.atproto-red-dwarf = {
  enable = true;
  settings = {
    server = {
      port = 3768;
      hostname = "reddwarf.example.com";
      publicUrl = "https://reddwarf.example.com";
    };
    
    microcosm = {
      constellation = {
        url = "https://constellation.microcosm.blue";
        enable = true;
      };
      slingshot = {
        url = "https://slingshot.microcosm.blue";
        enable = true;
      };
    };
    
    oauth = {
      clientId = "your-oauth-client-id";
      clientSecretFile = "/run/secrets/oauth-client-secret";
      redirectUri = "https://reddwarf.example.com/auth/callback";
    };
    
    features = {
      customFeeds = true;
      notifications = true;
      keepAlive = true;
    };
    
    ui = {
      theme = "auto";
      iconSet = "material-symbols";
      maxPostsPerPage = 50;
    };
    
    caching = {
      enable = true;
      maxAge = 300000; # 5 minutes
    };
  };
};
```

**Use Cases**:
- Enhanced Bluesky clients
- Performance-optimized social applications
- Custom social media interfaces
- ATProto client development

## Production ATProto Tools

### Allegedly - PLC Tools

**Package**: `atproto-allegedly`  
**Module**: `services.atproto-allegedly`

Production-ready tools for the Public Ledger for Credentials (PLC) system.

**Key Features**:
- PLC server implementation
- PostgreSQL backend support
- Comprehensive CLI tools
- Production-ready deployment

**Use Cases**:
- PLC infrastructure deployment
- Identity management systems
- ATProto infrastructure services

### QuickDID - Identity Resolution

**Package**: `atproto-quickdid`  
**Module**: `services.atproto-quickdid`

Fast and scalable identity resolution service for ATProto.

**Key Features**:
- High-performance DID resolution
- SQLite backend for fast queries
- Scalable architecture
- Production deployment ready

**Use Cases**:
- Identity resolution services
- ATProto infrastructure
- High-performance DID lookups

## Deployment Patterns

### Multi-Service Deployments

Many Tier 2 and Tier 3 applications work well together:

```nix
# Comprehensive ATProto platform
services = {
  # Core infrastructure
  microcosm-constellation.enable = true;
  atproto-quickdid.enable = true;
  
  # Application layer
  atproto-parakeet.enable = true;
  atproto-leaflet.enable = true;
  atproto-red-dwarf.enable = true;
  
  # Specialized services
  atproto-streamplace.enable = true;
};
```

### Database Sharing

Services can share database instances:

```nix
services.postgresql = {
  enable = true;
  ensureDatabases = [ "leaflet" "slices" "parakeet" "teal" ];
  ensureUsers = [
    { name = "leaflet"; ensurePermissions = { "DATABASE leaflet" = "ALL PRIVILEGES"; }; }
    { name = "slices"; ensurePermissions = { "DATABASE slices" = "ALL PRIVILEGES"; }; }
    { name = "parakeet"; ensurePermissions = { "DATABASE parakeet" = "ALL PRIVILEGES"; }; }
    { name = "teal"; ensurePermissions = { "DATABASE teal" = "ALL PRIVILEGES"; }; }
  ];
};
```

### Reverse Proxy Integration

Use nginx or Caddy for unified access:

```nix
services.nginx = {
  enable = true;
  virtualHosts = {
    "leaflet.example.com" = {
      locations."/".proxyPass = "http://localhost:3000";
    };
    "slices.example.com" = {
      locations."/".proxyPass = "http://localhost:8080";
    };
    "parakeet.example.com" = {
      locations."/".proxyPass = "http://localhost:6000";
    };
  };
};
```

## Security Considerations

All Tier 2 and Tier 3 applications include comprehensive security hardening:

- **Dedicated system users** for each service
- **systemd security restrictions** (NoNewPrivileges, ProtectSystem, etc.)
- **Network isolation** options
- **File system access controls**
- **Secret management** integration
- **Input validation** and sanitization

## Monitoring and Observability

Services provide monitoring capabilities:

- **Structured logging** with configurable levels
- **Metrics endpoints** where supported
- **Health checks** for service validation
- **systemd integration** for service management

## Development and Testing

All applications include development support:

- **Development shells** with required tools
- **Hot reloading** for rapid iteration
- **Comprehensive testing** frameworks
- **CI/CD integration** with Nix builds

## Contributing

To add new Tier 2 or Tier 3 applications:

1. **Package the application** following ATProto packaging guidelines
2. **Create NixOS module** with comprehensive configuration options
3. **Add security hardening** using standard patterns
4. **Include comprehensive tests** (unit, integration, VM tests)
5. **Document configuration** and use cases
6. **Submit pull request** with complete implementation

See [PACKAGING.md](PACKAGING.md) for detailed guidelines.