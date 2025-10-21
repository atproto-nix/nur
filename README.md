# ATProto NUR

Nix User Repository for ATProto Services and Tools

Development is primarily done on [Tangled](https://tangled.org) at [@atproto-nix.org/nur](tangled.sh/@atproto-nix.org/nur) with a Github [mirror](https://github.com/atproto-nix/nur).

[![Cachix Cache](https://img.shields.io/badge/cachix-atproto-blue.svg)](https://atproto.cachix.org)

## Overview

The ATProto NUR provides comprehensive Nix packaging for the AT Protocol ecosystem, including:

- **Core ATProto Libraries**: Fundamental libraries and utilities for ATProto development
- **Official Bluesky Services**: PDS, relay, feed generators, and management tools
- **Community Applications**: Third-party ATProto applications and specialized services
- **Development Tools**: Templates, utilities, and development environments
- **NixOS Modules**: Declarative service configuration with security hardening

### Organizational Structure

Packages are organized by their actual organizational ownership rather than arbitrary technical categories. This provides better clarity about project relationships and maintenance responsibilities. See the [Organizational Framework](docs/ORGANIZATIONAL_FRAMEWORK.md) documentation for details.

**🔄 Recent Reorganization**: The repository has been restructured from technical categories to organizational ownership. Old package names continue to work with deprecation warnings during the transition period. See the [Organizational Migration Guide](docs/ORGANIZATIONAL_MIGRATION.md) for detailed migration instructions.

## Quick Start

### Using Packages

Install ATProto packages directly:

```bash
# Install a specific service (organizational naming)
nix profile install github:atproto-nix/nur#smokesignal-events-quickdid

# Run temporarily (organizational naming)
nix run github:atproto-nix/nur#hyperlink-academy-leaflet

# Use in shell (organizational naming)
nix shell github:atproto-nix/nur#microcosm-blue-allegedly

# Existing Microcosm services (unchanged)
nix run github:atproto-nix/nur#microcosm-constellation

# Backward compatibility (old names still work with deprecation warnings)
nix run github:atproto-nix/nur#quickdid  # -> smokesignal-events-quickdid
nix run github:atproto-nix/nur#leaflet   # -> hyperlink-academy-leaflet
```

### NixOS Integration

Add to your NixOS configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    atproto-nur.url = "github:atproto-nix/nur";
  };

  outputs = { nixpkgs, atproto-nur, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        atproto-nur.nixosModules.default
        {
          # Enable ATProto services (using new organizational structure)
          services.microcosm-constellation.enable = true;
          services.smokesignal-events-quickdid.enable = true;
          services.witchcraft-systems-pds-dash.enable = true;
          services.hyperlink-academy-leaflet.enable = true;
          services.individual-pds-gatekeeper.enable = true;
          services.tangled-dev-appview.enable = true;
        }
      ];
    };
  };
}
```

### Development Templates

Create new ATProto services using templates:

```bash
# Rust service template
nix flake init -t github:atproto-nix/nur#rust-atproto

# Node.js/TypeScript template  
nix flake init -t github:atproto-nix/nur#nodejs-atproto

# Go service template
nix flake init -t github:atproto-nix/nur#go-atproto
```

## Available Packages

### Organizational Structure

Packages are organized by their actual organizational ownership for better clarity and maintenance:

#### Hyperlink Academy
- `hyperlink-academy-leaflet` - Collaborative writing platform with social publishing

#### Slices Network  
- `slices-network-slices` - Custom AppView platform with automatic SDK generation

#### Teal.fm
- `teal-fm-teal` - Music social platform built on ATProto

#### Parakeet Social
- `parakeet-social-parakeet` - Full-featured ATProto AppView implementation

#### Stream.place
- `stream-place-streamplace` - Video infrastructure platform with ATProto integration

#### Yoten App
- `yoten-app-yoten` - Language learning social platform

#### Red Dwarf Client
- `red-dwarf-client-red-dwarf` - Constellation-based Bluesky client

#### Tangled Development
- `tangled-dev-appview` - Web interface for git forge
- `tangled-dev-knot` - Git server with ATProto integration
- `tangled-dev-spindle` - Event processing component
- `tangled-dev-genjwks` - JWKS generator utility
- `tangled-dev-lexgen` - Lexicon generator for ATProto schemas

#### Smokesignal Events
- `smokesignal-events-quickdid` - Fast and scalable identity resolution service

#### Microcosm Blue
- `microcosm-blue-allegedly` - PLC (Public Ledger for Credentials) tools and services

#### Witchcraft Systems
- `witchcraft-systems-pds-dash` - Web dashboard for PDS monitoring and management

#### ATBackup Pages Dev
- `atbackup-pages-dev-atbackup` - One-click Bluesky backups desktop application

#### Official Bluesky Social
- `bluesky-social-indigo` - Official Go implementation of ATProto services
- `bluesky-social-grain` - Official TypeScript implementation of ATProto services
- `bluesky-social-frontpage` - Official Bluesky frontpage application

#### Individual Developers
- `individual-pds-gatekeeper` - Security microservice with 2FA and rate limiting
- `individual-drainpipe` - Individual developer package

### Microcosm Collection (`microcosm-*`)

Rust-based ATProto service suite:
- `microcosm-constellation` - Backlink indexer service
- `microcosm-spacedust` - ATProto service component  
- `microcosm-slingshot` - ATProto service component with TLS support
- `microcosm-ufos` - ATProto service component
- `microcosm-who-am-i` - Identity service (deprecated)
- `microcosm-quasar` - ATProto service component
- `microcosm-pocket` - DID document service
- `microcosm-reflector` - DID document reflection service

### Community Tools (`blacksky-*`)

- `blacksky-rsky-*` - Community ATProto implementation suite (Rust)

## NixOS Service Modules

All packages include corresponding NixOS modules with:

- **Security Hardening**: Comprehensive systemd security restrictions by default
- **User Management**: Dedicated system users and groups for isolation
- **Configuration Validation**: Type-safe configuration with helpful error messages
- **Logging Integration**: Structured logging with configurable levels
- **Firewall Integration**: Optional automatic firewall configuration

### Example Service Configuration

```nix
# Microcosm Constellation backlink indexer
services.microcosm-constellation = {
  enable = true;
  settings = {
    jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
    backend = "rocks";
    logLevel = "info";
  };
  backup = {
    enable = true;
    interval = 24; # hours
    maxOldBackups = 7;
  };
  openFirewall = true;
};

# PDS Dashboard (Witchcraft Systems)
services.witchcraft-systems-pds-dash = {
  enable = true;
  settings = {
    port = 3000;
    pds = {
      endpoint = "https://pds.example.com";
      adminPassword = "admin-password";
    };
    ui = {
      title = "PDS Dashboard";
      theme = "default";
    };
  };
};

# QuickDID identity resolution (Smokesignal Events)
services.smokesignal-events-quickdid = {
  enable = true;
  settings = {
    port = 8080;
    hostname = "quickdid.example.com";
    database = {
      url = "postgresql://quickdid@localhost/quickdid";
    };
    plc = {
      endpoint = "https://plc.directory";
    };
  };
};

# Leaflet collaborative writing (Hyperlink Academy)
services.hyperlink-academy-leaflet = {
  enable = true;
  settings = {
    port = 3000;
    hostname = "leaflet.example.com";
    database = {
      url = "postgresql://leaflet@localhost/leaflet";
    };
    supabase = {
      url = "https://your-project.supabase.co";
      anonKey = "your-anon-key";
      serviceRoleKeyFile = "/run/secrets/supabase-service-key";
    };
    oauth = {
      clientId = "your-oauth-client-id";
      clientSecretFile = "/run/secrets/oauth-client-secret";
      redirectUri = "https://leaflet.example.com/api/auth/callback";
    };
  };
};

# PDS Gatekeeper (Individual Developer)
services.individual-pds-gatekeeper = {
  enable = true;
  settings = {
    port = 8080;
    database = {
      url = "postgresql://gatekeeper@localhost/gatekeeper";
    };
    email = {
      smtpHost = "smtp.example.com";
      smtpPort = 587;
      smtpUser = "noreply@example.com";
      smtpPasswordFile = "/run/secrets/smtp-password";
      fromAddress = "noreply@example.com";
    };
  };
};
```

## Development

### Using the Development Shell

```bash
# Clone the repository
git clone https://github.com/atproto-nix/nur
cd nur

# Enter development environment
nix develop

# Build all packages
nix build

# Run tests
nix build .#tests

# Check flake
nix flake check
```

### Package Development

The repository provides helper functions for consistent ATProto packaging:

```nix
# Rust service
atprotoLib.mkRustAtprotoService {
  pname = "my-service";
  version = "1.0.0";
  src = fetchFromGitHub { /* ... */ };
  type = "application";
  services = [ "my-service" ];
  protocols = [ "com.atproto" ];
}

# Node.js application  
atprotoLib.mkNodeAtprotoApp {
  inherit buildNpmPackage;
  pname = "my-app";
  version = "1.0.0";
  src = fetchFromGitHub { /* ... */ };
  type = "application";
  services = [ "my-app" ];
}
```

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- **[Organizational Framework](docs/ORGANIZATIONAL_FRAMEWORK.md)** - Understanding the organizational structure
- **[Organizational Migration](docs/ORGANIZATIONAL_MIGRATION.md)** - Migrating from old to new organizational structure
- **[Migration Guide](docs/MIGRATION.md)** - General migration guidance
- **[Packaging Guidelines](docs/PACKAGING.md)** - How to package ATProto applications
- **[Contributing Guide](docs/CONTRIBUTING.md)** - How to contribute packages and improvements
- **[Service Modules](docs/MICROCOSM_MODULES.md)** - NixOS module configuration patterns
- **[PDS Ecosystem](docs/PDS_ECOSYSTEM.md)** - PDS deployment and management
- **[Templates Guide](docs/TEMPLATES.md)** - Using and customizing development templates
- **[Testing Guide](docs/TESTING.md)** - Core library testing and validation infrastructure

## Contributing

We welcome contributions! Please see our [Contributing Guide](docs/CONTRIBUTING.md) for:

- Packaging new ATProto applications
- Improving existing packages and modules
- Adding new language templates
- Documentation improvements

## License

This repository is licensed under the MIT License. Individual packages may have different licenses - see their respective metadata for details.
