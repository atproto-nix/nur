# Tangled Full Stack Deployment Guide

This guide shows how to deploy the complete Tangled stack using the ATProto NUR.

## Overview

Tangled is a Git forge built on the AT Protocol. The full stack consists of:

1. **Knot** - Git server with ATProto integration (Go)
2. **AppView** - Web interface for browsing repositories (Go + frontend)
3. **Spindle** - Event processor and CI/CD system (Go)
4. **Avatar** - Bluesky avatar proxy service (Node.js/Wrangler)
5. **Camo** - Image proxy for anonymized URLs (Node.js/Wrangler)

## Available Packages

### Core Services (Go-based)

All packages use the `tangled-*` prefix:

- `tangled-knot` - Git server
- `tangled-appview` - Web interface
- `tangled-spindle` - Event processor

### Utility Services (Node.js-based)

- `tangled-avatar` - Avatar proxy (Cloudflare Worker adapted for server)
- `tangled-camo` - Image proxy (Cloudflare Worker adapted for server)

### Build Tools

- `tangled-genjwks` - JWT key set generator
- `tangled-lexgen` - Lexicon generator
- `tangled-appview-static-files` - Frontend assets (CSS, JS, fonts, icons)

## NixOS Modules

All services have corresponding modules under `services.tangled-dev.*`:

- `services.tangled-dev.knot`
- `services.tangled-dev.appview`
- `services.tangled-dev.spindle`
- `services.tangled-avatar`
- `services.tangled-camo`

## Quick Start - Minimal Configuration

```nix
{
  imports = [ atproto-nur.nixosModules.tangled ];

  # Knot Git Server
  services.tangled-dev.knot = {
    enable = true;
    server = {
      hostname = "git.example.com";
      owner = "did:plc:your-did-here";  # Get from https://tangled.org/settings
    };
    openFirewall = true;  # Opens SSH port 22
  };

  # AppView Web Interface
  services.tangled-dev.appview = {
    enable = true;
    port = 3000;
    cookieSecret = "your-secret-cookie-key-here";  # Change this!
  };

  # Optional: Spindle Event Processor
  services.tangled-dev.spindle = {
    enable = true;
    server = {
      hostname = "spindle.example.com";
      owner = "did:plc:your-did-here";
    };
  };
}
```

## Full Production Configuration

See [examples/tangled-stack.nix](./examples/tangled-stack.nix) for a complete example with:
- Nginx reverse proxies
- ACME/Let's Encrypt TLS certificates
- Avatar and Camo services
- Security hardening
- Proper firewall configuration
- Environment file integration

## Service Dependencies

### Knot (Git Server)
**Required:**
- SSH server (configured automatically)
- Git user account (created automatically)

**Depends on:**
- AppView endpoint (for web integration)

**Port:** 22 (SSH)

### AppView (Web Interface)
**Depends on:**
- Knot endpoint (for git operations)
- Optional: Avatar service endpoint
- Optional: Camo service endpoint

**Port:** 3000 (default, configurable)

### Spindle (Event Processor)
**Depends on:**
- Knot endpoint
- AppView endpoint
- Jetstream endpoint (for ATProto events)

**Port:** 6555 (default)

### Avatar Service
**Depends on:**
- Bluesky API (https://public.api.bsky.app)

**Port:** 8787 (default)

### Camo Service
**No dependencies** (proxies external images)

**Port:** 8788 (default)

## Configuration Details

### Knot Configuration

```nix
services.tangled-dev.knot = {
  enable = true;

  # Server configuration (REQUIRED)
  server = {
    hostname = "git.example.com";  # Your knot domain
    owner = "did:plc:abc123...";   # Your DID

    listenAddr = "0.0.0.0:5555";          # External HTTP
    internalListenAddr = "127.0.0.1:5444"; # Internal API

    dbPath = "/var/lib/tangled-knot/knotserver.db";
    dev = false;  # Set true to disable signature verification
  };

  # Repository configuration
  repo = {
    mainBranch = "main";  # Default branch name
  };

  # Message of the day (shown on git operations)
  motd = "Welcome to this knot!\n";
  # OR: motdFile = /path/to/motd.txt;

  # Service endpoints
  endpoints = {
    appview = "https://tangled.example.com";
    jetstream = "wss://jetstream.example.com";
    nixery = "https://nixery.example.com";
    atproto = "https://bsky.social";
    plc = "https://plc.directory";
  };

  # Users
  user = "tangled-knot";   # Service user
  gitUser = "git";         # Git operations user

  # Directories
  dataDir = "/var/lib/tangled-knot";
  repoDir = "/var/lib/tangled-knot/repos";

  openFirewall = true;  # Opens port 22 for SSH
};
```

### AppView Configuration

```nix
services.tangled-dev.appview = {
  enable = true;

  port = 3000;
  host = "127.0.0.1";  # Bind address

  # Cookie secret for session management (REQUIRED)
  cookieSecret = "change-this-to-a-random-32-char-string";

  # Or use environment file for secrets
  environmentFile = "/run/secrets/tangled-appview.env";

  # Service endpoints
  endpoints = {
    knot = "https://git.example.com";
    jetstream = "wss://jetstream.example.com";
    nixery = "https://nixery.example.com";
    atproto = "https://bsky.social";
    plc = "https://plc.directory";
  };

  # Data directory
  dataDir = "/var/lib/tangled-appview";

  # Additional environment variables
  extraEnvironment = {
    AVATAR_ENDPOINT = "https://avatar.example.com";
    CAMO_ENDPOINT = "https://camo.example.com";
  };

  openFirewall = false;  # Use nginx reverse proxy
};
```

### Spindle Configuration

```nix
services.tangled-dev.spindle = {
  enable = true;

  # Server configuration (REQUIRED)
  server = {
    hostname = "spindle.example.com";
    owner = "did:plc:abc123...";

    listenAddr = "0.0.0.0:6555";
    dbPath = "/var/lib/tangled-spindle/spindle.db";

    # Jetstream for ATProto events
    jetstreamEndpoint = "wss://jetstream1.us-west.bsky.network/subscribe";

    dev = false;
    maxJobCount = 2;      # Concurrent jobs
    queueSize = 100;      # Max queued jobs

    # Secret management
    secrets = {
      provider = "sqlite";  # or "openbao"
      openbao = {
        proxyAddr = "http://127.0.0.1:8200";
        mount = "spindle";
      };
    };
  };

  # Service endpoints
  endpoints = {
    appview = "https://tangled.example.com";
    knot = "https://git.example.com";
    jetstream = "wss://jetstream.example.com";
    nixery = "https://nixery.example.com";
    atproto = "https://bsky.social";
    plc = "https://plc.directory";
  };

  # Pipeline configuration
  pipelines = {
    workflowTimeout = "5m";
  };

  # Environment file for secrets
  environmentFile = "/run/secrets/tangled-spindle.env";

  dataDir = "/var/lib/tangled-spindle";
  openFirewall = false;
};
```

### Avatar Service Configuration

```nix
services.tangled-avatar = {
  enable = true;
  port = 8787;

  # Shared secret for HMAC verification (REQUIRED)
  # Must match the secret used by appview
  sharedSecretFile = "/run/secrets/avatar-shared-secret";

  user = "tangled-avatar";
  group = "tangled-avatar";

  openFirewall = false;  # Use nginx reverse proxy
};
```

**Secret file format:**
```bash
# /run/secrets/avatar-shared-secret
AVATAR_SHARED_SECRET=your-random-secret-here
```

### Camo Service Configuration

```nix
services.tangled-camo = {
  enable = true;
  port = 8788;

  # Shared secret for HMAC verification (REQUIRED)
  # Must match the secret used by appview/knot
  sharedSecretFile = "/run/secrets/camo-shared-secret";

  user = "tangled-camo";
  group = "tangled-camo";

  openFirewall = false;  # Use nginx reverse proxy
};
```

**Secret file format:**
```bash
# /run/secrets/camo-shared-secret
CAMO_SHARED_SECRET=your-random-secret-here
```

## Building the Packages

```bash
# Build individual components
nix build .#tangled-knot
nix build .#tangled-appview
nix build .#tangled-spindle
nix build .#tangled-avatar
nix build .#tangled-camo

# Build all tangled packages
nix build .#tangled-knot .#tangled-appview .#tangled-spindle \
         .#tangled-avatar .#tangled-camo
```

## Testing Locally

```bash
# Run knot server
nix run .#tangled-knot -- server

# Run appview (in another terminal)
nix run .#tangled-appview

# Run spindle (in another terminal)
nix run .#tangled-spindle

# Run avatar service (in another terminal)
nix run .#tangled-avatar

# Run camo service (in another terminal)
nix run .#tangled-camo
```

## Architecture

```
┌──────────────────┐
│  User's Browser  │
└────────┬─────────┘
         │
         ├──→ AppView (Port 3000) ──→ SQLite DB
         │      │
         │      ├──→ Knot (SSH Port 22 + HTTP 5555)
         │      │      └──→ Git Repositories
         │      │
         │      ├──→ Avatar Service (Port 8787)
         │      │      └──→ Bluesky API
         │      │
         │      └──→ Camo Service (Port 8788)
         │             └──→ External Images
         │
         └──→ Spindle (Port 6555) ──→ SQLite DB
                │
                ├──→ Jetstream (ATProto Events)
                ├──→ Knot (Repository Events)
                └──→ Nixery (Container Builds)
```

## Port Requirements

- **22** - SSH (Knot git operations)
- **3000** - AppView web interface (behind nginx)
- **5555** - Knot HTTP API (internal)
- **5444** - Knot Internal API (for SSH key lookup)
- **6555** - Spindle event processor (optional)
- **8787** - Avatar service (behind nginx)
- **8788** - Camo service (behind nginx)
- **80/443** - Nginx reverse proxy (if used)

## Storage Requirements

- **Knot**: ~100MB + size of all repositories
- **AppView**: ~500MB for database + static assets
- **Spindle**: ~100MB for database
- **Avatar**: Minimal (uses Wrangler cache)
- **Camo**: Minimal (uses Wrangler cache)

## Environment Variables

### AppView
- `TANGLED_DB_PATH` - Database path
- `TANGLED_COOKIE_SECRET` - Cookie secret
- `TANGLED_HOST` - Listen host
- `TANGLED_PORT` - Listen port
- `KNOT_ENDPOINT` - Knot server URL
- `AVATAR_ENDPOINT` - Avatar service URL (optional)
- `CAMO_ENDPOINT` - Camo service URL (optional)

### Knot
- `KNOT_REPO_SCAN_PATH` - Repository directory
- `KNOT_SERVER_HOSTNAME` - Public hostname
- `KNOT_SERVER_OWNER` - DID of server owner
- `KNOT_SERVER_LISTEN_ADDR` - External HTTP address
- `KNOT_SERVER_INTERNAL_LISTEN_ADDR` - Internal API address
- `APPVIEW_ENDPOINT` - AppView URL

### Spindle
- `SPINDLE_SERVER_HOSTNAME` - Public hostname
- `SPINDLE_SERVER_OWNER` - DID of server owner
- `SPINDLE_SERVER_LISTEN_ADDR` - HTTP listen address
- `SPINDLE_SERVER_DB_PATH` - Database path
- `SPINDLE_SERVER_JETSTREAM` - Jetstream endpoint
- `SPINDLE_SERVER_MAX_JOB_COUNT` - Max concurrent jobs
- `KNOT_ENDPOINT` - Knot server URL
- `APPVIEW_ENDPOINT` - AppView URL

### Avatar
- `AVATAR_SHARED_SECRET` - HMAC secret (required)

### Camo
- `CAMO_SHARED_SECRET` - HMAC secret (required)

## Nginx Configuration

Example nginx configuration for reverse proxying the services:

```nginx
# AppView
server {
    listen 80;
    listen [::]:80;
    server_name tangled.example.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Knot (HTTP interface)
server {
    listen 80;
    listen [::]:80;
    server_name git.example.com;

    location / {
        proxy_pass http://localhost:5555;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket endpoint for git events
    location /events {
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Host $http_host;
        proxy_set_header Upgrade websocket;
        proxy_set_header Connection Upgrade;
        proxy_pass http://localhost:5555;
    }
}

# Avatar Service
server {
    listen 80;
    listen [::]:80;
    server_name avatar.example.com;

    location / {
        proxy_pass http://localhost:8787;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# Camo Service
server {
    listen 80;
    listen [::]:80;
    server_name camo.example.com;

    location / {
        proxy_pass http://localhost:8788;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## Getting Your DID

1. Visit https://tangled.org/settings (or your Bluesky app settings)
2. Look for your DID (starts with `did:plc:`)
3. Use this DID for `server.owner` configuration

## Troubleshooting

### Knot won't start
- Check that SSH server is running: `systemctl status sshd`
- Verify git user exists: `id git`
- Check knot logs: `journalctl -u tangled-knot`

### AppView shows errors
- Verify Knot is running and accessible
- Check cookie secret is set
- Check appview logs: `journalctl -u tangled-appview`

### Avatar/Camo signature errors
- Ensure shared secrets match between appview and avatar/camo
- Check that secret files exist and are readable
- Verify HMAC signatures are being generated correctly

### Git operations fail
- Check SSH configuration: `ssh git@git.example.com`
- Verify authorized keys command is working
- Check knot internal API is accessible
- Review `/tmp/tangled-knotguard.log`

## Resources

- Tangled: https://tangled.org
- Source Code: https://tangled.org/@tangled.org/core
- Knot Hosting Guide: https://tangled.org/@tangled.org/core/blob/master/docs/knot-hosting.md
- AT Protocol: https://atproto.com

## Support

For issues with:
- Tangled packages/modules: File issue in ATProto NUR
- Tangled application: https://tangled.org/@tangled.org/core
- Join Discord: https://chat.tangled.org
