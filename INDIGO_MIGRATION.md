# Indigo Services Migration Guide

This document describes the breaking changes and new features added to the Indigo services in the NUR.

## Overview

The Bluesky Indigo repository has been significantly expanded in the NUR:

- **Before**: 4 services packaged (relay, rainbow, palomar, hepa)
- **After**: 10 services packaged + 1 CLI tool
- **Breaking Change**: `services.indigo-rainbow` renamed to `services.indigo-bigsky`

## ⚠️ Breaking Changes

### Service Name Change: rainbow → bigsky

The `services.indigo-rainbow` NixOS option has been renamed to `services.indigo-bigsky` to accurately reflect what it does.

**What changed:**
- The old "rainbow" was actually building from `cmd/bigsky` (original relay with full mirroring)
- The new "rainbow" is the actual firehose fanout/splitter service from `cmd/rainbow`
- These are fundamentally different services with different purposes

**Migration path:**

**Old configuration (no longer works):**
```nix
services.indigo-rainbow = {
  enable = true;
  settings = {
    hostname = "relay.example.com";
    database.url = "postgres://user:pass@localhost/relay";
    # ... other settings
  };
};
```

**New configuration:**
```nix
services.indigo-bigsky = {  # Was: services.indigo-rainbow
  enable = true;
  settings = {
    hostname = "relay.example.com";
    database.url = "postgres://user:pass@localhost/relay";
    # ... other settings (unchanged)
  };
};
```

## New Services

### 1. Indigo Rainbow (NEW - Firehose Fanout)

The actual firehose fanout/splitter service. Subscribes to a relay/PDS firehose and distributes events via WebSocket.

```nix
services.indigo-rainbow = {
  enable = true;
  settings = {
    upstreamHost = "https://relay.bsky.social";  # Upstream relay/PDS
    port = 2473;
    logLevel = "info";
    metrics.enable = true;
  };
};
```

### 2. Indigo Bluepages (Identity Caching)

Caches handle/DID resolution responses in Redis. Reduces duplicate identity lookups across services.

```nix
services.indigo-bluepages = {
  enable = true;
  settings = {
    redisUrl = "redis://localhost:6379";
    adminTokenFile = "/run/secrets/bluepages-admin-token";
    port = 2586;
    logLevel = "info";
  };
};
```

### 3. Indigo CollectionDir (Collection Discovery)

Discovers which DIDs have data in which collections. Useful for new services bootstrapping existing data.

```nix
services.indigo-collectiondir = {
  enable = true;
  dataDir = "/var/lib/indigo-collectiondir";  # Pebble KV storage
  settings = {
    firehoseUrl = "wss://relay.bsky.social/xrpc/com.atproto.sync.subscribeRepos";
    port = 2584;
    logLevel = "info";
  };
};
```

### 4. Indigo Sonar (Operational Monitoring)

Monitors firehose events and exports Prometheus metrics. Essential for operational visibility.

```nix
services.indigo-sonar = {
  enable = true;
  settings = {
    firehoseUrl = "wss://relay.bsky.social/xrpc/com.atproto.sync.subscribeRepos";
    metricsPort = 2471;
    logLevel = "info";
  };
};
```

### 5. Indigo Beemo (Moderation Notifications)

Consumes firehose and sends moderation reports to Slack. Requires Slack webhook.

```nix
services.indigo-beemo = {
  enable = true;
  settings = {
    firehoseUrl = "wss://relay.bsky.social/xrpc/com.atproto.sync.subscribeRepos";
    pdsHost = "https://bsky.social";
    adminTokenFile = "/run/secrets/beemo-admin-token";
    slackWebhookFile = "/run/secrets/slack-webhook";
    logLevel = "info";
  };
};
```

### 6. Indigo NetSync (Repository Archival)

Clones repositories from relay/PDS to local disk for bulk archival and analysis.

```nix
services.indigo-netsync = {
  enable = true;
  dataDir = "/var/lib/indigo-netsync";  # Where repos are stored
  settings = {
    checkoutEndpoint = "https://bsky.social";  # Source for repos
    workers = 10;  # Parallel workers
    metricsPort = 2471;
    logLevel = "info";
  };
};
```

## Complete Service List

| Service | Type | New? | Purpose |
|---------|------|------|---------|
| **indigo-relay** | Core | ✗ | NEW relay (sync v1.1) - modern lightweight relay |
| **indigo-bigsky** | Core | ✗ | Original relay with full repo mirroring + CAR storage |
| **indigo-rainbow** | Core | ✓ | Firehose fanout/splitter for distributing events |
| **indigo-palomar** | Search | ✗ | Full-text search service |
| **indigo-bluepages** | Discovery | ✓ | Identity caching/directory |
| **indigo-collectiondir** | Discovery | ✓ | Collection discovery service |
| **indigo-hepa** | Moderation | ✗ | Auto-moderation service |
| **indigo-beemo** | Moderation | ✓ | Slack notification bot |
| **indigo-sonar** | Monitoring | ✓ | Operational monitoring/metrics |
| **indigo-netsync** | Tools | ✓ | Repository cloning/archival |

## Database Requirements

Here's which services need which databases:

| Service | PostgreSQL | SQLite | Redis | Pebble | OpenSearch |
|---------|-----------|--------|-------|--------|-----------|
| relay | Recommended | Yes | No | No | No |
| bigsky | Recommended | Yes | No | No | No |
| rainbow | No | No | No | Yes | No |
| palomar | Optional | Yes | No | No | **Yes** |
| bluepages | No | No | **Yes** | No | No |
| collectiondir | No | No | No | Yes | No |
| hepa | No | No | **Yes** | No | No |
| beemo | No | No | No | No | No |
| sonar | No | No | No | No | No |
| netsync | No | No | No | No | No |

## Recommended Deployment Patterns

### Minimal Relay Stack

```nix
{
  services.postgresql.enable = true;

  services.indigo-relay = {
    enable = true;
    settings = {
      hostname = "relay.example.com";
      database.url = "postgres://relay:password@localhost/relay";
      adminPasswordFile = "/run/secrets/relay-admin";
    };
  };

  services.indigo-sonar = {
    enable = true;
    settings = {
      firehoseUrl = "wss://localhost:2470/xrpc/com.atproto.sync.subscribeRepos";
    };
  };
}
```

### Full Production Stack

```nix
{
  # Databases
  services.postgresql.enable = true;
  services.redis.enable = true;

  # Core relay
  services.indigo-relay = {
    enable = true;
    settings = {
      hostname = "relay.example.com";
      database.url = "postgres://relay:pw@localhost/relay";
      adminPasswordFile = "/run/secrets/relay-admin";
    };
  };

  # Discovery & search
  services.indigo-bluepages = {
    enable = true;
    settings = {
      redisUrl = "redis://localhost:6379";
      adminTokenFile = "/run/secrets/bluepages-admin";
    };
  };

  services.indigo-collectiondir = {
    enable = true;
    settings = {
      firehoseUrl = "wss://localhost:2470/xrpc/com.atproto.sync.subscribeRepos";
    };
  };

  # Monitoring
  services.indigo-sonar = {
    enable = true;
    settings = {
      firehoseUrl = "wss://localhost:2470/xrpc/com.atproto.sync.subscribeRepos";
    };
  };
}
```

## Package Names

All packages follow the naming pattern: `indigo-<service>`

- `indigo-relay`
- `indigo-bigsky`
- `indigo-rainbow`
- `indigo-palomar`
- `indigo-bluepages`
- `indigo-collectiondir`
- `indigo-hepa`
- `indigo-beemo`
- `indigo-sonar`
- `indigo-netsync`
- `indigo-gosky` (CLI tool, no module)

## Timeline for Upgrade

1. **Step 1**: Update your configuration to rename `services.indigo-rainbow` → `services.indigo-bigsky`
2. **Step 2**: Rebuild: `nixos-rebuild switch`
3. **Step 3**: Test the relay still works
4. **Step 4**: Optionally add new services (bluepages, sonar, etc.)
5. **Step 5**: Reconfigure and verify new services

## Questions?

- See `/Users/jack/Software/indigo/` for the Indigo source code
- Check individual module files in `/Users/jack/Software/nur-vps/modules/bluesky/bluesky-social/` for all available options
- Example configuration: `examples/indigo-relay-example.nix`

## Version Information

- Indigo Relay (cmd/relay): NEW (sync v1.1) - modern, lightweight
- Indigo BigSky (cmd/bigsky): Original relay with full mirroring
- All services build from `github.com/bluesky-social/indigo` main branch
