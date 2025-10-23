# ATProto NUR

Nix User Repository for ATProto (AT Protocol) and Bluesky ecosystem packages.

[![Cachix Cache](https://img.shields.io/badge/cachix-atproto-blue.svg)](https://atproto.cachix.org)
[![MCP-NixOS](https://img.shields.io/badge/MCP-NixOS-blue)](https://mcp-nixos.io/)

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

**Web Services** (with NixOS modules):
- `hyperlink-academy-leaflet` - Collaborative writing platform (Next.js)
- `teal-fm-teal` - Music social platform
- `yoten-app-yoten` - Language learning platform
- `red-dwarf-client-red-dwarf` - Constellation-based Bluesky client
- `witchcraft-systems-pds-dash` - PDS monitoring dashboard (Deno)
- `parakeet-social-parakeet` - Full-featured AppView (placeholder)
- `slices-network-slices` - Custom AppView with SDK generation
- `stream-place-streamplace` - Video infrastructure
- `smokesignal-events-quickdid` - Fast identity resolution service
- `individual-pds-gatekeeper` - PDS security microservice
- `microcosm-blue-allegedly` - PLC tools and services

**Desktop App** (package only, no module):
- `atbackup-pages-dev-atbackup` - One-click Bluesky backups (Tauri desktop app)

### Tangled Infrastructure

Git forge and development tools for ATProto:

- `tangled-appview` - Tangled AppView web interface
- `tangled-knot` - Git server with ATProto integration
- `tangled-spindle` - Event processor and CI/CD
- `tangled-genjwks` - JWKS generator utility
- `tangled-lexgen` - Lexicon generator utility

**Website**: https://tangled.org

### likeandscribe

Community platform for ATProto:

- `likeandscribe-frontpage` - Hacker News-style community (9 sub-packages)
  - Main frontend application
  - ATProto browser interface
  - Drainpipe firehose consumer
  - OAuth components
  - Unravel utility

## NixOS Modules

**Service packages** (servers/daemons/web apps) have corresponding NixOS modules for declarative server deployment.

**Note**: Only `atbackup` (Tauri desktop app) is package-only with no NixOS module.

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

Available module collections:
- `atproto-nur.nixosModules.microcosm` - Microcosm services (constellation, slingshot, etc.)
- `atproto-nur.nixosModules.blacksky` - Blacksky/rsky services (PDS, relay, etc.)
- `atproto-nur.nixosModules.bluesky-social` - Official Bluesky services (indigo, grain)
- `atproto-nur.nixosModules.tangled` - Tangled infrastructure (appview, knot, spindle)
- `atproto-nur.nixosModules.likeandscribe` - Frontpage and drainpipe services
- `atproto-nur.nixosModules.hyperlink-academy` - Leaflet collaborative writing
- `atproto-nur.nixosModules.slices-network` - Slices AppView
- `atproto-nur.nixosModules.teal-fm` - Teal music platform
- `atproto-nur.nixosModules.parakeet-social` - Parakeet AppView
- `atproto-nur.nixosModules.yoten-app` - Yoten language learning
- `atproto-nur.nixosModules.stream-place` - Streamplace video platform
- `atproto-nur.nixosModules.red-dwarf-client` - Red Dwarf client
- `atproto-nur.nixosModules.witchcraft-systems` - PDS dashboard
- `atproto-nur.nixosModules.smokesignal-events` - QuickDID service
- `atproto-nur.nixosModules.individual` - PDS gatekeeper

## AI-Assisted Development

This repository uses [MCP-NixOS](https://mcp-nixos.io/) for AI-assisted development with Claude Code and other MCP-compatible assistants.

**Benefits:**
- Real-time NixOS package information (130K+ packages)
- Accurate configuration options (22K+ options)
- Version tracking across nixpkgs channels
- Prevents AI hallucinations about package availability

**Setup:**
```bash
# Create MCP configuration for Claude Code
cat > ~/.claude-code/mcp.json << 'EOF'
{
  "mcpServers": {
    "mcp-nixos": {
      "command": "nix",
      "args": ["run", "github:utensils/mcp-nixos"]
    }
  }
}
EOF
# Restart Claude Code to load the MCP server
```

See [MCP_INTEGRATION.md](./MCP_INTEGRATION.md) for detailed setup instructions.

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

**Complex Builds:**
Some packages require multi-stage builds with frontend tooling. See `pkgs/yoten-app/yoten.nix` for an example of:
- Template generation (templ)
- Frontend library fetching (htmx, lucide, alpinejs)
- Tailwind CSS v4 (standalone binary with autoPatchelfHook)
- Static asset preparation for Go embed directives

See `CLAUDE.md` for detailed build patterns and best practices.

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
- `blacksky/` - Community Blacksky/Rsky tools
- `bluesky-social/` - Official Bluesky packages (indigo, grain)
- `atproto/` - Core ATProto TypeScript libraries
- `tangled/` - Tangled git forge infrastructure
- `likeandscribe/` - Frontpage community platform
- `hyperlink-academy/`, `parakeet-social/`, `teal-fm/`, etc. - Third-party apps
- `individual/` - Individual developer packages

This structure makes it easy to find packages by their maintainer and understand the ecosystem.

**Recent Changes:**
- Phase 1: Renamed `tangled-dev` → `tangled` (correct organization)
- Phase 2: Pinned leaflet and slices to specific commits with hashes
- Phase 3: Moved frontpage/drainpipe from atproto to `likeandscribe` (correct maintainer)
- **New**: Fixed `yoten-app/yoten` complex build (templ + Tailwind CSS v4 + frontend assets)

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
✅ NixOS modules for all services (100% coverage)
✅ All packages pinned to specific commits
⚠️  6 packages need hash calculation on Linux (see PINNING_NEEDED.md)

**Repository Health**: 🟡 90% Production Ready

See [NEXT_STEPS.md](./NEXT_STEPS.md) for development roadmap.

---

**Development**: Primary development on [Tangled](https://tangled.org) at [@atproto-nix.org/nur](https://tangled.sh/@atproto-nix.org/nur)

**Mirror**: [GitHub](https://github.com/atproto-nix/nur)
