# ATProto NUR

Nix User Repository for ATProto (AT Protocol) and Bluesky ecosystem packages.

[![Cachix Cache](https://img.shields.io/badge/cachix-atproto-blue.svg)](https://atproto.cachix.org)
[![MCP-NixOS](https://img.shields.io/badge/MCP-NixOS-blue)](https://mcp-nixos.io/)

## Overview

This NUR provides Nix packages and NixOS modules for the AT Protocol ecosystem, including:

- **Microcosm Services**: constellation, spacedust, slingshot, ufos, and more
- **Bluesky Official**: indigo (Go) implementation
- **Blacksky/Rsky**: Community-maintained AT Protocol tools
- **Third-party Apps**: leaflet, parakeet, teal, yoten, slices, and others
- **Development Tools**: Tangled infrastructure, ATProto core libraries
- **NixOS Modules**: Declarative service configuration for all packages

**Total Packages**: 50+ and growing

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
- `whey-party-red-dwarf` - Appview-less Bluesky client using Constellation (Vite/React)
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

### Grain Social

Photo-sharing platform for ATProto (by Chad Miller):

- `grain-social-grain` - Complete photo-sharing platform (placeholder)
  - AppView: Main web application (Deno, TypeScript, HTMX)
  - Darkroom: Image processing service (Rust)
  - Notifications: Real-time notification system
  - Labeler: Content moderation service
  - CLI: Command-line management tools

**Website**: https://grain.social
**Repository**: https://tangled.org/@grain.social/grain

### Mackuba

ATProto tools and feed generators by @mackuba.eu:

- `mackuba-lycan` - Custom feed generator (Ruby/Sinatra)
  - Firehose integration via Skyfall
  - PostgreSQL database backend
  - OAuth authentication support
  - Uses minisky, didkit, and skyfall gems

**Repository**: https://tangled.org/@mackuba.eu/lycan

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

  # Deploy static sites from Nix packages
  services.static-site-deploy.sites.my-app = {
    enable = true;
    package = pkgs.my-static-site;
    sourceDir = "share/my-app";
    targetDir = "/var/www/example.com";
    user = "caddy";
    group = "caddy";
    reloadServices = [ "caddy.service" ];
  };
}
```

**Recommended: Use the default module** (imports everything automatically):
- `atproto-nur.nixosModules.default` - **All modules + package overlay** (easiest option)

**Individual module collections** (for selective imports):
- `atproto-nur.nixosModules.common` - **Common utilities** (static-site-deploy, nixos-integration)
- `atproto-nur.nixosModules.microcosm` - Microcosm services (constellation, slingshot, etc.)
- `atproto-nur.nixosModules.blacksky` - Blacksky/rsky services (PDS, relay, etc.)
- `atproto-nur.nixosModules.bluesky-social` - Official Bluesky Indigo services
- `atproto-nur.nixosModules.grain-social` - Grain Social photo-sharing platform
- `atproto-nur.nixosModules.tangled` - Tangled infrastructure (appview, knot, spindle)
- `atproto-nur.nixosModules.likeandscribe` - Frontpage and drainpipe services
- `atproto-nur.nixosModules.hyperlink-academy` - Leaflet collaborative writing
- `atproto-nur.nixosModules.slices-network` - Slices AppView (⚠️  excluded from default due to recursion issue)
- `atproto-nur.nixosModules.teal-fm` - Teal music platform
- `atproto-nur.nixosModules.parakeet-social` - Parakeet AppView
- `atproto-nur.nixosModules.yoten-app` - Yoten language learning
- `atproto-nur.nixosModules.stream-place` - Streamplace video platform
- `atproto-nur.nixosModules.red-dwarf-client` - Red Dwarf client
- `atproto-nur.nixosModules.witchcraft-systems` - PDS dashboard
- `atproto-nur.nixosModules.smokesignal-events` - QuickDID service
- `atproto-nur.nixosModules.individual` - PDS gatekeeper
- `atproto-nur.nixosModules.mackuba` - Lycan feed generator

**Package Access**: The default module provides packages in multiple naming conventions:
```nix
# All naming patterns work:
pkgs.microcosm-spacedust       # Flat (full name)
pkgs.microcosm.spacedust       # Nested namespace
pkgs.spacedust                 # Convenient alias

# Available short aliases:
pkgs.quickdid    # → smokesignal-events-quickdid
pkgs.spacedust   # → microcosm-spacedust
pkgs.ufos        # → microcosm-ufos
pkgs.slingshot   # → microcosm-slingshot
```

### Common Utility Modules

The `common` module collection provides reusable utilities:

**static-site-deploy** - Deploy static sites from Nix packages to web directories
- Automatic rsync deployment with proper ownership
- Service reload/restart hooks after deployment
- Support for multiple sites with different configurations
- See `modules/common/README.md` for detailed documentation

Example: Deploying Red Dwarf static site
```nix
services.static-site-deploy.sites.red-dwarf = {
  enable = true;
  package = pkgs.whey-party-red-dwarf;
  sourceDir = "share/red-dwarf";
  targetDir = "/var/www/example.com/red-dwarf";
  user = "caddy";
  group = "caddy";
  before = [ "caddy.service" ];
  reloadServices = [ "caddy.service" ];
};
```

## Secrets Management

The NUR provides a pluggable secrets management abstraction that allows you to use any secrets backend (sops-nix, agenix, Vault, custom) with a consistent API.

### Quick Start with sops-nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    atproto-nur.url = "github:atproto-nix/nur";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { nixpkgs, atproto-nur, sops-nix, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        sops-nix.nixosModules.sops
        atproto-nur.nixosModules.default
        {
          # Configure sops-nix
          sops.defaultSopsFile = ./secrets.yaml;
          sops.age.keyFile = "/etc/secrets/age-key.txt";

          # Secrets are automatically managed
          services.microcosm-constellation = {
            enable = true;
            # Module handles secrets configuration
          };

          # Or configure manually
          sops.secrets."constellation-secret" = {
            owner = "constellation";
            sopsFile = ./secrets.yaml;
          };
        }
      ];
    };
  };
}
```

### Available Backends

- **sops-nix** (recommended) - Age/PGP encrypted secrets in repository
- **agenix** - Age-only encrypted secrets
- **HashiCorp Vault** - Enterprise secrets management with dynamic secrets
- **file-based** - Simple files for development (no encryption)
- **custom** - Implement your own backend

### Backend-Agnostic Modules

Services work with any secrets backend:

```nix
# Works with sops-nix, agenix, Vault, or custom backend
services.myapp = {
  enable = true;
  secrets.database = "/run/secrets/myapp-db-password";
};

# Backend determines where secret comes from:
# - sops-nix: decrypts from secrets.yaml
# - agenix: decrypts from .age file
# - Vault: fetches from Vault server
# - file: reads from plain file
```

### Creating Custom Backends

Implement the simple backend interface:

```nix
# custom-backend.nix
{ lib, config }:

{
  mkSecret = args: { inherit (args) name; /* ... */ };
  getSecretPath = secret: "/custom/path/${secret.name}";
  getSecretOptions = secret: { /* NixOS config */ };
  mkSecretEnvVar = varName: secret: ''export ${varName}=$(cat ...)'';
}
```

Then use it:

```nix
let
  secretsLib = import "${inputs.atproto-nur}/lib/secrets.nix" { inherit lib; };
  mySecrets = secretsLib.withBackend (import ./custom-backend.nix { inherit lib config; });
in
{
  services.myapp.secretsBackend = mySecrets;
}
```

### Documentation

- **[Secrets Integration Guide](./docs/SECRETS_INTEGRATION.md)** - Complete architecture and patterns
- **[Secrets API Reference](./lib/secrets/README.md)** - API documentation and troubleshooting
- **[Example Module](./examples/secrets-integration-example.nix)** - Working example implementation

**Key Features:**
- 🔌 **Pluggable**: Switch backends without changing module code
- 🔒 **Secure**: Secrets loaded at runtime, never in Nix store
- 🎯 **Type-safe**: Compile-time validation
- 📦 **Zero lock-in**: Use any secrets manager
- 🚀 **Auto-detect**: Automatically uses available backend

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

See [MCP_INTEGRATION.md](./docs/MCP_INTEGRATION.md) for detailed setup instructions.

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

## Binary Cache (Cachix)

Pre-built binaries are available via Cachix to avoid building from source:

```bash
# One-time setup using cachix (recommended)
nix-env -iA cachix -f https://cachix.org/api/v1/install
cachix use atproto

# Or manually add to /etc/nixos/configuration.nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org"
    "https://atproto.cachix.org"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "atproto.cachix.org-1:mgH0q9dt3ZI9puHEfIGDnkRBfT80I3vfEh4Wda2B0rk="
  ];
};

# Or for non-NixOS users, add to ~/.config/nix/nix.conf
substituters = https://cache.nixos.org https://atproto.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= atproto.cachix.org-1:mgH0q9dt3ZI9puHEfIGDnkRBfT80I3vfEh4Wda2B0rk=
```

**Multi-Language Support:**
- **Rust packages**: Crane caching for dependencies + Cachix for binaries
- **Go packages**: Cachix caches vendored dependencies and final binaries
- **Node.js packages**: Cachix caches npm dependencies and webpack outputs
- **Ruby packages**: Cachix caches bundled gems and native extensions

Binary cache is automatically populated by GitHub Actions CI on every push.

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
- `bluesky-social/` - Official Bluesky packages (indigo)
- `grain-social/` - Grain Social photo-sharing platform
- `atproto/` - Core ATProto TypeScript libraries
- `tangled/` - Tangled git forge infrastructure
- `likeandscribe/` - Frontpage community platform
- `hyperlink-academy/`, `parakeet-social/`, `teal-fm/`, etc. - Third-party apps
- `whey-party/` - Bluesky client applications (Red Dwarf)
- `mackuba/` - Feed generators and ATProto tools by @mackuba.eu
- `individual/` - Individual developer packages

This structure makes it easy to find packages by their maintainer and understand the ecosystem.

**Recent Changes:**
- Phase 1: Renamed `tangled-dev` → `tangled` (correct organization)
- Phase 2: Pinned leaflet and slices to specific commits with hashes
- Phase 3: Moved frontpage/drainpipe from atproto to `likeandscribe` (correct maintainer)
- Phase 4: Moved grain from bluesky-social to `grain-social` (correct maintainer - Chad Miller)
- **New**: Fixed `yoten-app/yoten` complex build (templ + Tailwind CSS v4 + frontend assets)
- **New**: Added `mackuba/lycan` - Ruby feed generator with bundlerEnv packaging
- **New**: Added `whey-party/red-dwarf` - Appview-less Bluesky client (Vite/React)
- **New**: Added `common/static-site-deploy` - Reusable module for deploying static sites

## License

Each package has its own license. See individual package definitions for details.

Most packages are MIT or Apache-2.0 licensed.

## Resources

- [AT Protocol Docs](https://atproto.com)
- [Bluesky](https://bsky.social)
- [Tangled](https://tangled.org)
- [NUR Documentation](https://github.com/nix-community/NUR)

## Status

✅ 50+ packages available (8 Rust, 5 Go, 12 Node.js/TypeScript, 1 Ruby, 24+ others)
✅ Multi-platform support (Linux x86_64/aarch64, macOS x86_64/aarch64)
✅ NixOS modules for all services (100% coverage)
✅ All packages pinned to specific commits
✅ Binary cache via Cachix (instant downloads, no compilation)

**Repository Health**: 🟡 90% Production Ready

See [docs/ROADMAP.md](./docs/ROADMAP.md) for development roadmap and [docs/CACHIX.md](./docs/CACHIX.md) for binary cache setup.

---

**Development**: Primary development on [Tangled](https://tangled.org) at [@atproto-nix.org/nur](https://tangled.sh/@atproto-nix.org/nur)

**Mirror**: [GitHub](https://github.com/atproto-nix/nur)
