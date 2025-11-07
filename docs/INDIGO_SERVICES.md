# Indigo Services - Complete Guide

Comprehensive documentation for all 10 Indigo services packaged in the NUR. This guide covers what each service does, how to configure them, and recommended deployment patterns.

## Table of Contents

1. [Core Relay Services](#core-relay-services)
2. [Search & Discovery Services](#search--discovery-services)
3. [Moderation & Monitoring Services](#moderation--monitoring-services)
4. [Operational Tools](#operational-tools)
5. [Quick Reference](#quick-reference)
6. [Deployment Patterns](#deployment-patterns)

---

## Core Relay Services

These are the foundational services that handle the ATProto firehose and repository data.

### Indigo Relay (cmd/relay)

**Type:** Core Relay Service
**Database:** PostgreSQL (recommended) or SQLite
**Port:** 2470 (default)
**Status:** Active (modern, sync v1.1)

#### What It Does

The NEW reference implementation of an ATProto relay. It:
- Subscribes to multiple PDS (Personal Data Server) hosts
- Collects and validates all repository events (commits, deletes, etc.)
- Stores events in a database (PostgreSQL preferred)
- Outputs a combined "firehose" event stream for consumers
- Verifies commit signatures and merkle tree proofs
- Provides admin web UI for management

**Key Features:**
- Modern sync v1.1 implementation
- Lightweight compared to BigSky (no repo storage)
- High throughput (~10k+ events/sec)
- Admin dashboard at `http://localhost:2470/admin`
- Prometheus metrics
- Rate limiting support

#### Configuration

```nix
services.indigo-relay = {
  enable = true;
  user = "indigo-relay";
  group = "indigo-relay";
  dataDir = "/var/lib/indigo-relay";

  settings = {
    # REQUIRED: The hostname this relay is accessible at
    hostname = "relay.example.com";

    # Server port
    port = 2470;

    # REQUIRED: Database connection
    database = {
      url = "postgres://relay:password@localhost:5432/relay";
      # Optional: Provide password via file instead of URL
      # passwordFile = "/run/secrets/db-password";
    };

    # Service discovery
    plcHost = "https://plc.directory";  # PLC directory (default is fine)
    bgsHost = null;  # Optional: BGS (Big Graph Service) host

    # REQUIRED: Admin access (choose one method)
    adminPassword = "your-secret-password";
    # OR: adminPasswordFile = "/run/secrets/relay-admin-password";

    # Logging
    logLevel = "info";  # debug, info, warn, error

    # Prometheus metrics (optional)
    metrics = {
      enable = true;
      port = 2471;
    };

    # Rate limiting (optional)
    rateLimit = {
      enable = true;
      requestsPerMinute = 100;  # Per IP
    };
  };

  # Open firewall ports
  openFirewall = true;
};
```

#### Database Setup

```bash
# PostgreSQL
createuser relay
createdb -O relay relay
psql relay -c "GRANT ALL PRIVILEGES ON DATABASE relay TO relay;"

# SQLite (simpler, single-user)
# Will be created automatically at $dataDir/relay.db
```

#### Running the Relay

The relay will:
1. Connect to PDS instances (configurable upstream hosts)
2. Download repository data
3. Validate commits and merkle trees
4. Store in database
5. Serve firehose via WebSocket at `wss://relay.example.com/xrpc/com.atproto.sync.subscribeRepos`

#### Monitoring

```bash
# Check metrics
curl http://localhost:2471/metrics | grep relay

# Access admin UI
open http://localhost:2470/admin

# Tail logs
journalctl -u indigo-relay -f
```

#### Common Issues

- **"Database connection refused"**: Ensure PostgreSQL is running and credentials are correct
- **"Cannot connect to PDS"**: Check `plcHost` and upstream PDS availability
- **"High memory usage"**: Relay caches commits; normal behavior under load

---

### Indigo BigSky (cmd/bigsky)

**Type:** Core Relay Service
**Database:** PostgreSQL (recommended) or SQLite + CAR files on disk
**Port:** 2470 (default, can conflict with relay)
**Status:** Active (original, feature-complete)

#### What It Does

The ORIGINAL relay implementation with full repository mirroring:
- Stores complete repository data in CAR (Content Addressable aRchive) files
- Maintains merkle search tree indices
- Performs "spidering" (auto-discovery of new repos)
- Supports repo compaction
- More resource-intensive than relay, but stores full history

**Key Differences from Relay:**
- Stores full repos on disk (tens of millions of CAR files)
- Supports repo browsing/analysis offline
- Heavier resource usage (CPU, disk I/O, memory)
- More complete data archival
- Longer startup time (indices need warming)

#### Configuration

```nix
services.indigo-bigsky = {
  enable = true;
  user = "indigo-bigsky";
  group = "indigo-bigsky";
  dataDir = "/var/lib/indigo-bigsky";

  settings = {
    # REQUIRED: The hostname this relay is accessible at
    hostname = "relay.example.com";

    port = 2470;  # Or different port if running with relay

    # REQUIRED: Two databases - one for relay, one for CAR storage
    database = {
      url = "postgres://bigsky:password@localhost:5432/relay";
    };

    # Service discovery
    plcHost = "https://plc.directory";
    bgsHost = null;

    # REQUIRED: Admin password
    adminPassword = "your-secret-password";
    # OR: adminPasswordFile = "/run/secrets/bigsky-admin-password";

    logLevel = "info";

    metrics = {
      enable = true;
      port = 2472;  # Different from relay
    };
  };

  openFirewall = true;
};
```

#### Storage Requirements

⚠️ **IMPORTANT**: BigSky creates millions of small files!

- **Disk Space**: 500GB - 1TB+ for production scale
- **File Count**: 30M+ inodes
- **Filesystem**: Use XFS, NOT ext4 or network storage
- **I/O**: Fast NVMe SSD recommended
- **NOT suitable for**: AWS EBS, network block storage (too slow)

#### Configuration Example

```nix
{
  # Use fast local NVMe SSD
  fileSystems."/var/lib/indigo-bigsky" = {
    device = "/dev/nvme0n1p1";
    fsType = "xfs";
    options = [ "defaults" "noatime" ];
  };

  services.indigo-bigsky = {
    enable = true;
    dataDir = "/var/lib/indigo-bigsky";
    settings = {
      hostname = "relay.example.com";
      database.url = "postgres://bigsky:pw@localhost/relay";
      adminPasswordFile = "/run/secrets/bigsky-admin";
    };
  };
}
```

#### Startup & Indexing

First start takes **several hours** because:
- Downloads repos from upstream PDS
- Builds merkle search tree indices
- Performs "spidering" to discover new repos

Monitor progress:
```bash
journalctl -u indigo-bigsky -f
du -sh /var/lib/indigo-bigsky  # Watch disk usage
```

---

### Indigo Rainbow (cmd/rainbow)

**Type:** Firehose Fanout Service
**Database:** Pebble KV (embedded, local only)
**Port:** 2473 (default)
**Status:** Active (modern)

#### What It Does

A WebSocket fanout service that:
- Subscribes to a relay or PDS firehose
- Distributes events to multiple subscribers
- Maintains a backfill window on disk (Pebble KV)
- Allows new subscribers to catch up to recent history
- Reduces load on upstream relay

**Use Cases:**
- Distribute firehose to many internal services
- Buffer events during upstream relay maintenance
- Reduce upstream bandwidth usage
- Local caching of recent events

#### Configuration

```nix
services.indigo-rainbow = {
  enable = true;
  user = "indigo-rainbow";
  group = "indigo-rainbow";
  dataDir = "/var/lib/indigo-rainbow";

  settings = {
    # REQUIRED: Upstream firehose URL
    upstreamHost = "https://relay.bsky.social";
    # Can be another relay, PDS, or local relay
    # Full URL: wss://relay.example.com/xrpc/com.atproto.sync.subscribeRepos

    port = 2473;  # WebSocket port for subscribers

    logLevel = "info";

    metrics = {
      enable = true;
      port = 2471;
    };
  };

  openFirewall = true;
};
```

#### Usage

Clients subscribe to Rainbow instead of relay:

```bash
# Subscribe to Rainbow
wscat -c wss://rainbow.example.com/xrpc/com.atproto.sync.subscribeRepos
```

#### Backfill Window

The backfill window (how far back events are stored) depends on:
- Available disk space
- Event rate
- Configuration (see upstream Indigo repo)

Monitor:
```bash
du -sh /var/lib/indigo-rainbow
journalctl -u indigo-rainbow -f
```

#### Deployment Pattern

```
┌─────────────────────┐
│ Public Relay        │ (relay.bsky.social)
│ (upstream)          │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Indigo Rainbow      │ (rainbow.internal)
│ (local fanout)      │
└──────────┬──────────┘
           │
      ┌────┴─────┬──────────┬──────────┐
      ↓          ↓          ↓          ↓
  [Palomar]  [Beemo]   [Sonar]   [Hepa]
  (search)  (notify)  (metrics) (moderation)
```

---

## Search & Discovery Services

These services provide indexing, caching, and data discovery capabilities.

### Indigo Palomar (cmd/palomar)

**Type:** Search Service
**Databases:** PostgreSQL/SQLite (cursor state) + OpenSearch cluster (required)
**Port:** 2474 (default)
**Status:** Active (production)

#### What It Does

Full-text search service for ATProto:
- Indexes posts and profile text
- Provides keyword search capability
- Stores results as "skeleton" (ATURIs + DIDs only)
- Supports query string syntax (AND, OR, NOT, phrases)
- Consumes firehose events continuously

**Features:**
- High-performance search (OpenSearch backend)
- Incrementally indexed (processes events in real-time)
- Read-only replica support (scale out horizontally)
- Prometheus metrics

#### Configuration

```nix
{
  # Palomar requires OpenSearch cluster
  # This is a simplified example; see OpenSearch docs for full setup

  services.indigo-palomar = {
    enable = true;
    dataDir = "/var/lib/indigo-palomar";

    settings = {
      port = 2474;

      # REQUIRED: Database for cursor state (how far we've indexed)
      database = {
        url = "postgres://palomar:pw@localhost:5432/palomar";
      };

      # REQUIRED: OpenSearch cluster URL
      # OpenSearch must have analysis-icu and analysis-kuromoji plugins
      opensearchUrl = "http://opensearch-cluster:9200";

      # PLC for handle resolution
      plcHost = "https://plc.directory";

      # Firehose subscription (consumed from here)
      firehoseUrl = "wss://relay.bsky.social/xrpc/com.atproto.sync.subscribeRepos";

      logLevel = "info";

      metrics = {
        enable = true;
        port = 2471;
      };
    };
  };
}
```

#### OpenSearch Setup

```bash
# With Docker Compose
docker-compose up opensearch

# Verify plugins
curl http://localhost:9200/_plugins/_list

# Check index
curl http://localhost:9200/_cat/indices
```

#### Search Queries

```bash
# Simple keyword
curl http://localhost:2474/xrpc/app.bsky.feed.search?q=hello

# Advanced (AND, OR, NOT)
curl http://localhost:2474/xrpc/app.bsky.feed.search?q=hello%20AND%20world

# Phrase search
curl http://localhost:2474/xrpc/app.bsky.feed.search?q=%22exact%20phrase%22
```

#### Scaling Palomar

Run multiple read-only replicas:

```nix
{
  # Primary indexer (one)
  services.indigo-palomar-primary = {
    enable = true;
    settings = {
      # ... config ...
      # This instance consumes from firehose and indexes
    };
  };

  # Read-only replicas (many)
  services.indigo-palomar-read-1 = {
    enable = true;
    settings = {
      port = 2475;
      # Same OpenSearch URL, but don't consume firehose
      # (would be done by primary)
    };
  };
}
```

---

### Indigo Bluepages (cmd/bluepages)

**Type:** Identity Caching Service
**Database:** Redis (required)
**Port:** 2586 (default)
**Status:** Active (production microservice)

#### What It Does

Caches handle/DID resolution to reduce duplicate lookups:
- Caches results from PLC directory
- Reduces traffic to PLC directory
- Provides three endpoints:
  - `com.atproto.identity.resolveHandle` - handle → DID
  - `com.atproto.identity.resolveDid` - DID → document
  - `com.atproto.identity.resolveIdentity` - unified resolution
- Admin endpoint to refresh cache

**Why Use It:**
- If you run many services, each making identity lookups
- Reduces PLC directory load
- Faster response times (cached)
- Single source of truth for identity data in your network

#### Configuration

```nix
{
  services.redis.enable = true;

  services.indigo-bluepages = {
    enable = true;

    settings = {
      port = 2586;

      # REQUIRED: Redis for caching
      redisUrl = "redis://localhost:6379";

      # PLC directory
      plcHost = "https://plc.directory";

      # Admin authentication
      adminTokenFile = "/run/secrets/bluepages-admin-token";

      logLevel = "info";

      metrics = {
        enable = true;
        port = 2471;
      };
    };
  };
}
```

#### Usage

Other services should point to Bluepages instead of PLC directory:

```nix
services.some-service = {
  settings = {
    # Instead of:
    # plcHost = "https://plc.directory";

    # Use:
    plcHost = "http://bluepages.internal:2586";
  };
};
```

#### Admin Operations

```bash
# Refresh a specific DID
curl -X POST http://localhost:2586/admin/refreshIdentity \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -d '{"did":"did:key:zQ3sh..."}'

# Check cache stats
curl http://localhost:2586/_health
```

---

### Indigo CollectionDir (cmd/collectiondir)

**Type:** Collection Discovery Service
**Database:** Pebble KV (embedded, local)
**Port:** 2584 (default)
**Status:** Active (production)

#### What It Does

Directory service that answers: "Which DIDs have data in collection X?"

- Maintains index: `collection` → `[DIDs]`
- Consumes firehose to stay up-to-date
- Provides `com.atproto.sync.listReposByCollection` endpoint
- Can bootstrap with `describeRepo` calls

**Use Cases:**
- Services discovering existing data
- Building collections index
- Understanding data distribution
- Starting a new relay quickly

#### Configuration

```nix
{
  services.indigo-collectiondir = {
    enable = true;
    dataDir = "/var/lib/indigo-collectiondir";

    settings = {
      port = 2584;

      # REQUIRED: Firehose URL to subscribe to
      firehoseUrl = "wss://relay.bsky.social/xrpc/com.atproto.sync.subscribeRepos";

      logLevel = "info";

      metrics = {
        enable = true;
        port = 2471;
      };
    };
  };
}
```

#### Querying

```bash
# Get all DIDs with posts in 'app.bsky.feed.post'
curl http://localhost:2584/xrpc/com.atproto.sync.listReposByCollection \
  ?collection=app.bsky.feed.post \
  ?limit=100
```

#### Index Building

On first start, CollectionDir:
1. Starts consuming firehose from current position
2. Builds index of recent repos
3. Index grows as firehose events are processed
4. Takes hours to build comprehensive index (can bootstrap with describeRepo)

Monitor:
```bash
du -sh /var/lib/indigo-collectiondir
journalctl -u indigo-collectiondir -f
```

---

## Moderation & Monitoring Services

These services handle moderation, notifications, and operational monitoring.

### Indigo Hepa (cmd/hepa)

**Type:** Auto-Moderation Service
**Database:** Redis (for state/caching)
**Port:** None (no external API)
**Status:** Active (moderation bot)

#### What It Does

Automated moderation service that:
- Consumes firehose events
- Applies configurable moderation rules
- Reports violations to Ozone (moderation service)
- Maintains state in Redis (labels, bans, etc.)

**Important:** The public Indigo version is limited; Bluesky runs a private fork with production rules.

#### Configuration

```nix
{
  services.redis.enable = true;

  services.indigo-hepa = {
    enable = true;

    settings = {
      # Admin password for management
      adminPasswordFile = "/run/secrets/hepa-admin-password";

      # Ozone moderation service URL
      ozoneHost = "https://ozone.example.com";
      ozoneAdminTokenFile = "/run/secrets/ozone-admin-token";

      # Firehose subscription
      firehoseUrl = "wss://relay.bsky.social/xrpc/com.atproto.sync.subscribeRepos";

      # Redis for state
      redisUrl = "redis://localhost:6379";

      logLevel = "info";
    };
  };
}
```

#### Rules Configuration

**⚠️ IMPORTANT:** Rules are compiled in at build time, not configured at runtime.

To modify rules, you must:
1. Edit `cmd/hepa/rules.go` in the Indigo repo
2. Rebuild the package
3. Deploy new version

This is a deliberate design choice (security).

---

### Indigo Beemo (cmd/beemo)

**Type:** Moderation Notification Bot
**Database:** None
**Port:** None (no external API)
**Status:** Active (Slack bot)

#### What It Does

Sends moderation reports to Slack:
- Consumes firehose
- Watches for flagged content
- Sends notifications to Slack channel
- Simple bot, no complex logic

**Use Cases:**
- Team notifications of policy violations
- Real-time moderation awareness
- Integration with Slack workflows

#### Configuration

```nix
{
  services.indigo-beemo = {
    enable = true;

    settings = {
      # REQUIRED: Firehose to monitor
      firehoseUrl = "wss://relay.bsky.social/xrpc/com.atproto.sync.subscribeRepos";

      # REQUIRED: PDS host for moderation
      pdsHost = "https://bsky.social";

      # REQUIRED: Admin token (for taking actions)
      adminTokenFile = "/run/secrets/beemo-admin-token";

      # REQUIRED: Slack webhook URL
      slackWebhookFile = "/run/secrets/slack-webhook-url";

      # PLC directory
      plcHost = "https://plc.directory";

      logLevel = "info";
    };
  };
}
```

#### Slack Setup

1. Create Slack App: https://api.slack.com/apps
2. Enable Incoming Webhooks
3. Create webhook for your channel
4. Save URL to `/run/secrets/slack-webhook-url`

```bash
# Test webhook
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H 'Content-type: application/json' \
  -d '{"text":"Test from Beemo"}'
```

#### Message Format

Beemo sends messages like:
```
🚨 Moderation Alert
User: @handle
Content: [text]
Reason: spam, harassment, etc.
Action: label applied / account suspended
```

---

### Indigo Sonar (cmd/sonar)

**Type:** Operational Monitoring
**Database:** None
**Port:** 2471 (metrics only)
**Status:** Active (monitoring tool)

#### What It Does

Monitors firehose and exports metrics:
- Event rate (events/second)
- Event types distribution
- Provider statistics
- Latency tracking
- Prometheus metrics output

**Use Cases:**
- Production monitoring/alerting
- Capacity planning
- Understanding network load
- Dashboards (Grafana)

#### Configuration

```nix
{
  services.indigo-sonar = {
    enable = true;

    settings = {
      # REQUIRED: Firehose to monitor
      firehoseUrl = "wss://relay.bsky.social/xrpc/com.atproto.sync.subscribeRepos";

      # Prometheus metrics port
      metricsPort = 2471;

      logLevel = "info";
    };
  };
}
```

#### Metrics Available

```
# Events per second
indigo_sonar_events_per_second

# Event types
indigo_sonar_create_events
indigo_sonar_update_events
indigo_sonar_delete_events

# Providers
indigo_sonar_providers{provider="bsky.social"}

# Latency
indigo_sonar_event_latency_ms
```

#### Grafana Integration

```json
{
  "panels": [
    {
      "title": "Firehose Event Rate",
      "targets": [
        {
          "expr": "indigo_sonar_events_per_second"
        }
      ]
    },
    {
      "title": "Event Types",
      "targets": [
        {
          "expr": "indigo_sonar_create_events"
        },
        {
          "expr": "indigo_sonar_update_events"
        }
      ]
    }
  ]
}
```

#### Alerting Rules

```yaml
# Prometheus alert rules
groups:
  - name: indigo-sonar
    rules:
      - alert: HighEventRate
        expr: indigo_sonar_events_per_second > 10000
        for: 5m
        annotations:
          summary: "Firehose events per second is {{ $value }}"

      - alert: HighLatency
        expr: indigo_sonar_event_latency_ms > 5000
        for: 5m
        annotations:
          summary: "Event latency is {{ $value }}ms"
```

---

## Operational Tools

These are utilities for archival, analysis, and administration.

### Indigo NetSync (cmd/netsync)

**Type:** Repository Archival Tool
**Database:** None
**Port:** 2471 (metrics only)
**Status:** Active (operational tool)

#### What It Does

Clones repositories from relay/PDS to local disk:
- Downloads entire repositories as tar.gz files
- Compresses with zstd compression
- Parallel workers for performance
- State tracking (which repos already cloned)
- Useful for:
  - Bulk data archival
  - Scientific research
  - Network analysis
  - Offline repository analysis

#### Configuration

```nix
{
  services.indigo-netsync = {
    enable = true;
    dataDir = "/archive/repos";  # Where repos are stored

    settings = {
      # REQUIRED: Endpoint to fetch repos from
      checkoutEndpoint = "https://bsky.social";

      # Number of parallel workers
      workers = 10;  # Adjust based on CPU/network

      # Metrics port
      metricsPort = 2471;

      logLevel = "info";
    };
  };
}
```

#### Storage Layout

```
/archive/repos/
├── did:plc:abc123.tar.gz
├── did:plc:def456.tar.gz
├── did:plc:ghi789.tar.gz
└── netsync.state.json  # Progress tracking
```

#### Running Netsync

```bash
# Start cloning
systemctl start indigo-netsync

# Monitor progress
journalctl -u indigo-netsync -f

# Check archived repos
ls -lh /archive/repos/ | head -20

# Extract a repo
tar -xzf /archive/repos/did:plc:abc123.tar.gz
```

#### Performance Tuning

```nix
services.indigo-netsync = {
  settings = {
    workers = 20;  # More workers = faster (if network allows)
  };
};
```

Throughput depends on:
- Number of workers
- Network bandwidth
- Upstream server capacity
- Disk I/O speed

#### Use Cases

```bash
# Archive all repos for research
netsync start && netsync wait

# Analyze repos offline
for repo in /archive/repos/*.tar.gz; do
  tar -tzf "$repo" | grep "posts" | wc -l
done

# Calculate network statistics
# (repos contain all commit history)
```

### Indigo GoSky (cmd/gosky)

**Type:** CLI Client Tool
**Database:** None
**Port:** None (CLI only)
**Status:** Development/operational tool

#### What It Does

Command-line interface for ATProto:
- Create/manage accounts
- Create/delete posts
- Follow/unfollow users
- Subscribe to firehose
- Query PDS/Relay
- Useful for testing and scripting

#### Installation

```bash
nix run 'github:atproto-nix/nur#indigo-gosky' -- --help
```

#### Common Commands

```bash
# Create account
gosky -pds https://bsky.social account create \
  -username newuser \
  -password password

# Create a post
gosky -pds https://bsky.social post create \
  -text "Hello Bluesky!"

# Follow user
gosky -pds https://bsky.social follow add \
  -did did:plc:abc123

# Subscribe to firehose
gosky -relay https://relay.bsky.social firehose subscribe

# Check PDS info
gosky -pds https://bsky.social server info
```

#### Configuration File

```bash
# Save credentials
cat > ~/.gosky/config.json << 'EOF'
{
  "pds": "https://bsky.social",
  "username": "yourhandle",
  "password": "yourpassword"
}
EOF

# Use config
gosky post create -text "Hello!"
```

---

## Quick Reference

### Service Dependencies Matrix

| Service | PostgreSQL | SQLite | Redis | Pebble | OpenSearch | Firehose | Notes |
|---------|-----------|--------|-------|--------|-----------|----------|-------|
| relay | ✅ | ✅ | ❌ | ❌ | ❌ | Outputs | Core |
| bigsky | ✅ | ✅ | ❌ | ❌ | ❌ | Outputs | Heavy |
| rainbow | ❌ | ❌ | ❌ | ✅ | ❌ | Consumes | Fanout |
| palomar | ✅ | ✅ | ❌ | ❌ | ✅ | Consumes | Search |
| bluepages | ❌ | ❌ | ✅ | ❌ | ❌ | No | Caching |
| collectiondir | ❌ | ❌ | ❌ | ✅ | ❌ | Consumes | Discovery |
| hepa | ❌ | ❌ | ✅ | ❌ | ❌ | Consumes | Moderation |
| beemo | ❌ | ❌ | ❌ | ❌ | ❌ | Consumes | Bot |
| sonar | ❌ | ❌ | ❌ | ❌ | ❌ | Consumes | Monitoring |
| netsync | ❌ | ❌ | ❌ | ❌ | ❌ | No | Archival |

### Port Reference

| Service | Port | Type |
|---------|------|------|
| relay | 2470 | Main |
| bigsky | 2470 | Main (can conflict) |
| rainbow | 2473 | WebSocket |
| palomar | 2474 | REST API |
| bluepages | 2586 | REST API |
| collectiondir | 2584 | REST API |
| sonar | 2471 | Metrics only |
| beemo | None | No API |
| hepa | None | No API |
| netsync | 2471 | Metrics only |

All services have optional metrics at port 2471 if enabled.

### Environment Variables

Every service can be configured via environment variables. Examples:

```bash
# Relay
RELAY_HOSTNAME=relay.example.com
RELAY_PORT=2470
RELAY_DATABASE_URL=postgres://...
RELAY_ADMIN_PASSWORD=secret
GOLOG_LOG_LEVEL=info

# Rainbow
RAINBOW_UPSTREAM_HOST=https://relay.bsky.social
RAINBOW_PORT=2473

# Palomar
PALOMAR_PORT=2474
PALOMAR_DATABASE_URL=postgres://...

# Bluepages
BLUEPAGES_PORT=2586
BLUEPAGES_REDIS_URL=redis://localhost:6379

# All services
GOLOG_LOG_LEVEL=debug|info|warn|error
```

---

## Deployment Patterns

### Pattern 1: Single Relay (Minimal)

```nix
{
  services.postgresql.enable = true;

  services.indigo-relay = {
    enable = true;
    settings = {
      hostname = "relay.example.com";
      database.url = "postgres://relay:pw@localhost/relay";
      adminPasswordFile = "/run/secrets/admin";
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

**Resources:** 4GB RAM, 100GB disk, 2 CPUs
**Throughput:** ~1000 events/sec
**Cost:** Low ($20-50/month)

---

### Pattern 2: Full Infrastructure Stack

```nix
{
  # Databases
  services.postgresql.enable = true;
  services.redis.enable = true;

  # Relay (primary data source)
  services.indigo-relay = {
    enable = true;
    settings = {
      hostname = "relay.example.com";
      database.url = "postgres://relay:pw@localhost/relay";
      adminPasswordFile = "/run/secrets/relay-admin";
    };
  };

  # Fanout (distribute to internal services)
  services.indigo-rainbow = {
    enable = true;
    settings = {
      upstreamHost = "wss://localhost:2470/xrpc/com.atproto.sync.subscribeRepos";
      port = 2473;
    };
  };

  # Search
  services.indigo-palomar = {
    enable = true;
    settings = {
      database.url = "postgres://palomar:pw@localhost/palomar";
      opensearchUrl = "http://opensearch:9200";
      firehoseUrl = "wss://localhost:2473/xrpc/com.atproto.sync.subscribeRepos";
    };
  };

  # Identity caching
  services.indigo-bluepages = {
    enable = true;
    settings = {
      redisUrl = "redis://localhost:6379";
      adminTokenFile = "/run/secrets/bluepages-admin";
    };
  };

  # Collection discovery
  services.indigo-collectiondir = {
    enable = true;
    settings = {
      firehoseUrl = "wss://localhost:2473/xrpc/com.atproto.sync.subscribeRepos";
    };
  };

  # Monitoring
  services.indigo-sonar = {
    enable = true;
    settings = {
      firehoseUrl = "wss://localhost:2473/xrpc/com.atproto.sync.subscribeRepos";
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

**Resources:** 16GB RAM, 500GB disk, 8 CPUs
**Throughput:** ~10k events/sec
**Cost:** Moderate ($100-300/month)

---

### Pattern 3: Research/Archival Stack

```nix
{
  services.postgresql.enable = true;

  # Primary relay for data
  services.indigo-bigsky = {
    enable = true;
    dataDir = "/mnt/nvme/bigsky";  # Fast NVMe SSD
    settings = {
      hostname = "relay.example.com";
      database.url = "postgres://bigsky:pw@localhost/relay";
      adminPasswordFile = "/run/secrets/bigsky-admin";
    };
  };

  # Archive repos to cold storage
  services.indigo-netsync = {
    enable = true;
    dataDir = "/mnt/archive/repos";  # Slow but large
    settings = {
      checkoutEndpoint = "http://localhost:2470";
      workers = 20;
    };
  };

  # Monitor what we're archiving
  services.indigo-sonar = {
    enable = true;
    settings = {
      firehoseUrl = "wss://localhost:2470/xrpc/com.atproto.sync.subscribeRepos";
    };
  };
}
```

**Resources:** 32GB RAM, 1-2TB fast SSD + large archive storage
**Purpose:** Complete network mirror + bulk analysis
**Cost:** High ($200-500/month)

---

## Troubleshooting

### Service won't start

```bash
journalctl -u indigo-SERVICENAME -n 50

# Common issues:
# - Port already in use: `lsof -i :2470`
# - Database not running: `systemctl status postgresql`
# - Network connectivity: `curl https://relay.bsky.social`
```

### High memory usage

```bash
# Check memory
free -h
ps aux | grep indigo

# Reduce if needed:
# - Smaller backfill window (Rainbow)
# - Fewer workers (NetSync)
# - Reduce metrics collection
```

### Slow performance

```bash
# Check disk I/O
iostat -x 1

# Check network
iftop -n

# Check CPU
top

# Solutions:
# - Use faster disk
# - Increase RAM
# - Reduce number of workers
# - Check upstream relay health
```

---

## Additional Resources

- [Bluesky ATProto Docs](https://docs.bsky.app)
- [Indigo GitHub Repository](https://github.com/bluesky-social/indigo)
- [PLC Directory](https://plc.directory)
- [Ozone Moderation Service](https://github.com/bluesky-social/ozone)

