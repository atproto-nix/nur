# Red Dwarf Stack Setup Guide

This guide shows how to deploy Red Dwarf with its dependencies (Constellation and Slingshot) using the ATProto NUR.

## Overview

Red Dwarf is a Bluesky client that doesn't use AppView servers. Instead, it:
- Connects directly to each user's PDS
- Uses **Constellation** for backlinks (likes, replies, reposts)
- Uses **Slingshot** to reduce load on individual PDSs

## Available Packages

### 1. Constellation (`microcosm-constellation`)
**Purpose:** Global backlink index for AT Protocol
**What it does:** Tracks all interactions (likes, replies, reposts) across the network
**Required by:** Red Dwarf (for social features)

**Package:** `atproto-nur.packages.x86_64-linux.microcosm-constellation`
**Module:** `atproto-nur.nixosModules.microcosm` → `services.microcosm-constellation`

### 2. Slingshot (`microcosm-slingshot`)
**Purpose:** PDS edge cache and proxy
**What it does:** Caches records and reduces load on individual PDSs
**Required by:** Red Dwarf (for efficient PDS queries)

**Package:** `atproto-nur.packages.x86_64-linux.microcosm-slingshot`
**Module:** `atproto-nur.nixosModules.microcosm` → `services.microcosm-slingshot`

### 3. Red Dwarf (`whey-party-red-dwarf`)
**Purpose:** Bluesky web client
**What it does:** React SPA that provides a full Bluesky client experience
**Depends on:** Constellation (backlinks), Slingshot (PDS proxy)

**Package:** `atproto-nur.packages.x86_64-linux.whey-party-red-dwarf`
**Module:** `atproto-nur.nixosModules.whey-party` → `services.whey-party-red-dwarf`

## Quick Start

### Minimal Configuration

```nix
{
  imports = [ atproto-nur.nixosModules.default ];

  # Enable Constellation (internal service)
  services.microcosm-constellation = {
    enable = true;
    jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
    backend = "rocks"; # or "memory" for testing
  };

  # Enable Slingshot (public service)
  services.microcosm-slingshot = {
    enable = true;
    jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
    domain = "slingshot.example.com";
    acmeContact = "admin@example.com";
    openFirewall = true;
  };

  # Enable Red Dwarf
  services.whey-party-red-dwarf = {
    enable = true;
    settings = {
      server = {
        publicUrl = "https://reddwarf.example.com";
      };
      microcosm = {
        constellation.url = "http://localhost:4444"; # Internal
        slingshot.url = "https://slingshot.example.com"; # Public
      };
    };
  };
}
```

### Full Production Configuration

See [examples/red-dwarf-stack.nix](./examples/red-dwarf-stack.nix) for a complete example with:
- Database backups for Constellation
- Nginx reverse proxy for Red Dwarf
- ACME/Let's Encrypt TLS certificates
- Security hardening
- Proper firewall configuration

## Configuration Details

### Constellation Configuration

```nix
services.microcosm-constellation = {
  enable = true;

  # Jetstream connection (REQUIRED)
  jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";

  # Storage backend
  backend = "rocks"; # "rocks" (persistent) or "memory" (ephemeral)

  # Data directory
  dataDir = "/var/lib/microcosm-constellation";

  # Backups (optional but recommended)
  backup = {
    enable = true;
    interval = 24; # hours
    maxOldBackups = 7;
  };

  # Logging
  logLevel = "info"; # trace, debug, info, warn, error
};
```

**Note:** Constellation is an internal service and doesn't need to be publicly accessible.

### Slingshot Configuration

```nix
services.microcosm-slingshot = {
  enable = true;

  # Jetstream connection (REQUIRED)
  jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";

  # Public domain for TLS (optional but recommended)
  domain = "slingshot.example.com";
  acmeContact = "admin@example.com"; # Required if domain is set

  # Zstd compression (optional)
  jetstreamNoZstd = false;

  # Healthcheck URL (optional)
  healthcheckUrl = "https://healthchecks.io/ping/your-uuid";

  # Data directory
  dataDir = "/var/lib/microcosm-slingshot";

  # Open firewall for public access
  openFirewall = true;
};
```

**Note:** Slingshot should be publicly accessible for best performance.

### Red Dwarf Configuration

```nix
services.whey-party-red-dwarf = {
  enable = true;

  # Data directory
  dataDir = "/var/lib/red-dwarf";

  settings = {
    server = {
      port = 3768;
      hostname = "reddwarf.example.com";

      # OAuth callback URL (REQUIRED)
      publicUrl = "https://reddwarf.example.com";

      # Development URL (optional)
      devUrl = null;
    };

    microcosm = {
      # Constellation configuration
      constellation = {
        enable = true;
        url = "http://localhost:4444"; # Point to your Constellation
      };

      # Slingshot configuration
      slingshot = {
        enable = true;
        url = "https://slingshot.example.com"; # Point to your Slingshot
      };
    };

    features = {
      # Password auth (development only!)
      passwordAuth = false;

      # Custom feeds support
      customFeeds = true;
    };

    ui = {
      # Theme: "light", "dark", or "auto"
      theme = "auto";
    };
  };

  # Use Nginx reverse proxy instead
  openFirewall = false;
};
```

## Building the Packages

```bash
# Build Constellation
nix build .#microcosm-constellation

# Build Slingshot
nix build .#microcosm-slingshot

# Build Red Dwarf
nix build .#whey-party-red-dwarf

# Build all three
nix build .#microcosm-constellation .#microcosm-slingshot .#whey-party-red-dwarf
```

## Testing Locally

```bash
# Run Constellation (in-memory mode)
nix run .#microcosm-constellation -- \
  --jetstream wss://jetstream1.us-east.bsky.network/subscribe \
  --backend memory

# Run Slingshot (in another terminal)
nix run .#microcosm-slingshot -- \
  --jetstream wss://jetstream1.us-east.bsky.network/subscribe \
  --cache-dir ./cache

# Run Red Dwarf (in another terminal)
nix run .#whey-party-red-dwarf
# Then open http://localhost:3768
```

## Architecture

```
┌─────────────────┐
│   Red Dwarf     │ ← User's browser
│  (React SPA)    │
└────────┬────────┘
         │
         ├──→ Slingshot ──→ Individual PDSs
         │    (cache)       (user data)
         │
         └──→ Constellation
              (backlinks)
                  │
                  └──→ Jetstream
                       (firehose)
```

## Port Requirements

- **Constellation**: Internal only (no external port needed)
- **Slingshot**: Port 443 (HTTPS) if using `domain` option
- **Red Dwarf**: Port 3768 (behind Nginx reverse proxy on 80/443)

## Storage Requirements

- **Constellation**:
  - Memory backend: ~2-4GB RAM
  - RocksDB backend: ~10-50GB disk (grows over time)

- **Slingshot**: ~5-20GB disk for cache

- **Red Dwarf**: ~100MB for static files

## OAuth Setup

Red Dwarf requires OAuth configuration. The `publicUrl` setting is critical:

1. Set `publicUrl` to your public domain (e.g., `https://reddwarf.example.com`)
2. OAuth client metadata will be generated at `/client-metadata.json`
3. Users will authenticate via AT Protocol OAuth
4. Callback URL: `${publicUrl}/callback`

## Troubleshooting

### Constellation won't start
- Check Jetstream URL is accessible
- Verify RocksDB permissions if using `backend = "rocks"`
- Check logs: `journalctl -u microcosm-constellation`

### Slingshot TLS errors
- Ensure `domain` and `acmeContact` are set
- Check firewall allows port 443
- Check DNS points to your server
- Check logs: `journalctl -u microcosm-slingshot`

### Red Dwarf shows errors
- Verify Constellation and Slingshot are running
- Check the URLs in `microcosm.constellation.url` and `microcosm.slingshot.url`
- Verify `publicUrl` is correctly set
- Check browser console for errors

## Resources

- Red Dwarf: https://tangled.org/@whey.party/red-dwarf
- Constellation: https://constellation.microcosm.blue
- Slingshot: https://slingshot.microcosm.blue
- Microcosm: https://microcosm.blue

## Support

For issues with:
- Red Dwarf package/module: File issue in ATProto NUR
- Red Dwarf application: https://tangled.org/@whey.party/red-dwarf
- Constellation/Slingshot: https://microcosm.blue
