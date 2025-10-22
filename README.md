# ATProto NUR

Nix User Repository for ATProto (AT Protocol) and Bluesky ecosystem packages.

[![Cachix Cache](https://img.shields.io/badge/cachix-atproto-blue.svg)](https://atproto.cachix.org)

## Overview

This NUR provides Nix packages and NixOS modules for the AT Protocol ecosystem, including:

- **Microcosm Services**: constellation, spacedust, slingshot, ufos, and more
- **Bluesky Official**: indigo (Go) and grain (TypeScript) implementations
- **Blacksky/Rsky**: Community-maintained AT Protocol tools
- **Third-party Apps**: leaflet, parakeet, teal, yoten, slices, and others
- **Development Tools**: Tangled infrastructure, ATProto core libraries
- **NixOS Modules**: Declarative service configuration for all packages

**Total Packages**: 48+ and growing

## Quick Start

### Using with Nix Flakes

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    atproto-nur.url = "github:atproto-nix/nur";
  };

  outputs = { nixpkgs, atproto-nur, ... }: {
    # Use packages
    packages.x86_64-linux.default = atproto-nur.packages.x86_64-linux.microcosm-constellation;

    # Or in NixOS configuration
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        atproto-nur.nixosModules.default
        {
          services.microcosm-constellation.enable = true;
          services.bluesky-social-indigo.enable = true;
        }
      ];
    };
  };
}
```

### Direct Installation

```bash
# Run a package temporarily
nix run github:atproto-nix/nur#microcosm-constellation

# Install to profile
nix profile install github:atproto-nix/nur#microcosm-slingshot

# Try in a shell
nix shell github:atproto-nix/nur#smokesignal-events-quickdid
```

## Available Packages

### Microcosm Services (Rust)

Core ATProto infrastructure services:

- `microcosm-constellation` - Global backlink index
- `microcosm-spacedust` - Interactions firehose
- `microcosm-slingshot` - Edge cache for records and identities
- `microcosm-ufos` - Timeseries stats and sample records
- `microcosm-pocket` - Non-public user data storage
- `microcosm-quasar` - Event stream replay and fan-out
- `microcosm-reflector` - DID:web service server
- `microcosm-who-am-i` - Identity bridge (deprecated)

### Bluesky Official

- `bluesky-social-indigo` - Official Go implementation (placeholder)
- `bluesky-social-grain` - Official TypeScript implementation (placeholder)

### Blacksky/Rsky (Community)

Community-maintained Rust implementations:

- `blacksky-pds` - Personal Data Server
- `blacksky-relay` - Relay server
- `blacksky-feedgen` - Feed generator
- `blacksky-firehose` - Firehose subscriber
- `blacksky-labeler` - Labeling service
- `blacksky-jetstreamSubscriber` - Jetstream subscriber
- `blacksky-satnav` - Archive traversal and verification
- `blacksky-{common,crypto,identity,lexicon,repo,syntax}` - Libraries

### ATProto Core Libraries (TypeScript)

- `atproto-atproto-api` - API client library
- `atproto-atproto-did` - DID utilities
- `atproto-atproto-identity` - Identity resolution
- `atproto-atproto-lexicon` - Schema validation
- `atproto-atproto-repo` - Repository utilities
- `atproto-atproto-syntax` - Syntax validation
- `atproto-atproto-xrpc` - XRPC client/server

### Third-Party Applications

- `hyperlink-academy-leaflet` - Collaborative writing platform
- `parakeet-social-parakeet` - Full-featured AppView
- `teal-fm-teal` - Music social platform
- `yoten-app-yoten` - Language learning platform
- `slices-network-slices` - Custom AppView with SDK generation
- `stream-place-streamplace` - Video infrastructure
- `red-dwarf-client-red-dwarf` - Constellation-based client
- `smokesignal-events-quickdid` - Fast identity resolution
- `witchcraft-systems-pds-dash` - PDS monitoring dashboard
- `individual-pds-gatekeeper` - PDS security microservice
- `atbackup-pages-dev-atbackup` - One-click Bluesky backups
- `microcosm-blue-allegedly` - PLC tools

### Tangled Infrastructure

- `tangled-dev-appview` - Tangled AppView
- `tangled-dev-knot` - Git server
- `tangled-dev-spindle` - Event processor/CI-CD
- `tangled-dev-genjwks` - JWKS generator
- `tangled-dev-lexgen` - Lexicon generator

## NixOS Modules

Each package has a corresponding NixOS module for declarative configuration:

```nix
{
  services.microcosm-constellation = {
    enable = true;
    settings = {
      jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
      backend = "rocks";  # or "memory"
      dataDir = "/var/lib/constellation";
    };
    openFirewall = true;
  };

  services.blacksky-pds = {
    enable = true;
    settings = {
      hostname = "pds.example.com";
      port = 3000;
    };
  };
}
```

Modules are organized by organization:
- `atproto-nur.nixosModules.microcosm`
- `atproto-nur.nixosModules.blacksky`
- `atproto-nur.nixosModules.bluesky-social`
- `atproto-nur.nixosModules.tangled-dev`
- ... and more

## Development

### Building Packages

```bash
# Build a specific package
nix build .#microcosm-constellation

# Build all packages
nix flake check

# Enter development shell
nix develop
```

### Adding New Packages

1. Create package file in appropriate organization directory under `pkgs/`
2. Add to `pkgs/ORGANIZATION/default.nix`
3. Create NixOS module in `modules/ORGANIZATION/`
4. Test build and module configuration

## Cachix

Pre-built binaries are available via Cachix:

```bash
# Add to /etc/nix/nix.conf or ~/.config/nix/nix.conf
substituters = https://cache.nixos.org https://atproto.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= atproto.cachix.org-1:[KEY_HERE]
```

## Contributing

Contributions welcome! Please:

1. Follow existing package structure and naming conventions
2. Pin all source versions (no `rev = "main"` or `lib.fakeHash`)
3. Add NixOS modules for services
4. Test builds on your platform
5. Update this README if adding new packages

See `PINNING_NEEDED.md` for packages that need version pinning.

## Organizational Structure

Packages are organized by their maintainer/organization:

- `microcosm/` - Microcosm Rust services
- `blacksky/` - Community Blacksky tools
- `bluesky-social/` - Official Bluesky packages
- `atproto/` - Core ATProto libraries
- `tangled-dev/` - Tangled infrastructure
- `hyperlink-academy/`, `parakeet-social/`, `teal-fm/`, etc. - Third-party apps
- `individual/` - Individual developer packages

This structure makes it easy to find packages by their maintainer and understand the ecosystem.

## License

Each package has its own license. See individual package definitions for details.

Most packages are MIT or Apache-2.0 licensed.

## Resources

- [AT Protocol Docs](https://atproto.com)
- [Bluesky](https://bsky.social)
- [Tangled](https://tangled.org)
- [NUR Documentation](https://github.com/nix-community/NUR)

## Status

✅ 48 packages available
✅ Multi-platform support (Linux x86_64/aarch64, macOS x86_64/aarch64)
✅ NixOS modules for all services
⚠️  Some packages need version pinning (see PINNING_NEEDED.md)

---

**Development**: Primary development on [Tangled](https://tangled.org) at [@atproto-nix.org/nur](https://tangled.sh/@atproto-nix.org/nur)

**Mirror**: [GitHub](https://github.com/atproto-nix/nur)
