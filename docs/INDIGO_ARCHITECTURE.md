# Indigo Services Architecture Guide

Understanding how Indigo services work together and when to use each one.

## Architecture Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                     ATProto Network                                │
│  (PDS instances, relay.bsky.social, other relays)                 │
└─────────────────────────────┬────────────────────────────────────┘
                              │
                    Firehose Events (WebSocket)
                              │
        ┌─────────────────────┴─────────────────────┐
        │                                           │
        ▼                                           ▼
┌───────────────────┐                    ┌──────────────────┐
│  Indigo Relay     │                    │  Indigo BigSky   │
│  (Modern)         │                    │  (Full Storage)  │
│  - Fast           │                    │  - Complete      │
│  - Light          │                    │  - Heavy         │
│  - Database       │                    │  - CAR Files     │
│  Port: 2470       │                    │  Port: 2470      │
└────────┬──────────┘                    └──────────────────┘
         │
    Firehose Output
         │
    ┌────┴─────────┬──────────────┬──────────────┬────────────┐
    │              │              │              │            │
    ▼              ▼              ▼              ▼            ▼
┌─────────┐  ┌────────────┐  ┌─────────────┐  ┌─────┐  ┌──────────┐
│ Rainbow │  │ Palomar    │  │ Bluepages   │  │Beemo│  │ Sonar    │
│         │  │            │  │             │  │     │  │          │
│ -Fanout │  │ - Search   │  │ - Identity  │  │-Bot │  │-Metrics  │
│ -Cache  │  │ - Full-text│  │ - Caching   │  │     │  │          │
│         │  │ - OpenSearch  │ - Redis     │  │Slack│  │Prometheus
│Port2473 │  │Port 2474   │  │Port 2586    │  │Port │  │Port 2471 │
└────┬────┘  └────┬───────┘  └──────┬──────┘  │None │  └──────────┘
     │            │                 │         └─────┘
Firehose Output  Database+Index  Caching
     │            │
     ▼            ▼
┌──────────────────────────────────────────────────┐
│                 Services                          │
│  (Read from Rainbow or Relay)                   │
│  (Write to Bluepages, Palomar, etc.)            │
└──────────────────────────────────────────────────┘
```

---

## Service Categorization

### Source Services (Produce Firehose)

These services READ from upstream (PDS, other relays) and OUTPUT a firehose:

#### Indigo Relay (Lightweight)
- **Input**: PDS hosts (from PLC directory)
- **Output**: Firehose at port 2470
- **Storage**: Database only (PostgreSQL/SQLite)
- **Best for**: Standard relay deployments
- **Advantages**: Fast startup, light memory, modern implementation
- **Disadvantages**: No historical CAR file storage

#### Indigo BigSky (Complete)
- **Input**: PDS hosts (from PLC directory)
- **Output**: Firehose at port 2470
- **Storage**: Database + millions of CAR files
- **Best for**: Complete network mirror, research
- **Advantages**: Full historical data, can browse offline
- **Disadvantages**: Slow startup, huge disk usage (1TB+), millions of files

### Distribution Services (Consume + Redistribute)

#### Indigo Rainbow
- **Input**: Firehose from relay/PDS
- **Output**: Local fanout at port 2473
- **Storage**: Pebble KV (backfill window)
- **Best for**: Internal service distribution
- **Use Case**: Run one relay, many internal services use Rainbow
- **Benefits**:
  - Single external relay subscription
  - Local buffering/caching
  - Reduce upstream bandwidth

```
                    ┌──────────────┐
                    │ Relay (ext)  │
                    └────────┬─────┘
                             │
                    ┌────────▼─────────┐
                    │ Rainbow (local)  │
                    └────────┬─────────┘
                             │
        ┌─────────┬──────────┼──────────┬─────────┐
        │         │          │          │         │
        ▼         ▼          ▼          ▼         ▼
    [App]   [Palomar]  [Sonar] [Hepa] [NetSync]
```

### Consumer Services (Read Firehose)

These services CONSUME a firehose but don't output one:

#### Palomar (Search)
- **Input**: Firehose
- **Output**: OpenSearch index (HTTP API)
- **Databases**: PostgreSQL (cursor) + OpenSearch (data)
- **Query**: `GET /xrpc/app.bsky.feed.search?q=keyword`

#### Bluepages (Identity Caching)
- **Input**: None (on-demand from PLC)
- **Output**: Cached identity responses
- **Database**: Redis
- **Purpose**: Reduce PLC directory load
- **Query**: `GET /xrpc/com.atproto.identity.resolveHandle?handle=user`

#### CollectionDir (Collection Discovery)
- **Input**: Firehose
- **Output**: Collection → DIDs index
- **Database**: Pebble KV
- **Query**: `GET /xrpc/com.atproto.sync.listReposByCollection?collection=app.bsky.feed.post`

#### Hepa (Auto-Moderation)
- **Input**: Firehose
- **Output**: Moderation reports to Ozone
- **Database**: Redis (state)
- **Purpose**: Automated content moderation
- **Rules**: Compiled at build time

#### Beemo (Notification Bot)
- **Input**: Firehose
- **Output**: Slack messages
- **Database**: None
- **Purpose**: Team notifications on flagged content

#### Sonar (Monitoring)
- **Input**: Firehose
- **Output**: Prometheus metrics
- **Database**: None
- **Query**: `GET /metrics` (Prometheus scrape)

#### NetSync (Archival)
- **Input**: Checkout endpoint (API calls)
- **Output**: tar.gz files on disk
- **Database**: JSON state file
- **Purpose**: Archive repos for offline analysis

---

## Data Flow Patterns

### Pattern 1: Simple Relay
```
PDS Hosts → Relay → Clients (WebSocket)
```

### Pattern 2: Relay + Monitoring
```
PDS Hosts → Relay → Sonar (metrics)
                 ↘ Clients (WebSocket)
```

### Pattern 3: Relay + Fanout + Services
```
                    ┌─ Relay (external)
                    │
                    ▼
┌─────────────────────────────┐
│ Your Infrastructure          │
│  ┌────────────────────────┐  │
│  │ Relay (internal copy)  │  │
│  └─────────┬──────────────┘  │
│            │                 │
│   ┌────────▼──────────┐      │
│   │    Rainbow        │      │
│   │ (local fanout)    │      │
│   └────────┬──────────┘      │
│            │                 │
│   ┌────────┼──────────┐      │
│   │        │          │      │
│   ▼        ▼          ▼      │
│ Palomar  Sonar      Hepa     │
│ (search) (metrics) (moderation)
└─────────────────────────────┘
```

### Pattern 4: Research/Archive
```
PDS Hosts → BigSky (full mirror with CAR files)
                ↘ NetSync (archive to cold storage)
                ↘ Sonar (monitor what we're archiving)
```

---

## Service Dependencies

### What does each service need?

```
Relay          → PostgreSQL + PLC directory
BigSky         → PostgreSQL + PLC directory + Fast NVMe
Rainbow        → Upstream firehose
Palomar        → PostgreSQL + OpenSearch + firehose
Bluepages      → Redis
CollectionDir  → Firehose
Hepa           → Redis + firehose + Ozone
Beemo          → Firehose + Slack webhook
Sonar          → Firehose
NetSync        → Checkout endpoint
```

### What does each service provide?

```
Relay          → Firehose (port 2470)
BigSky         → Firehose (port 2470)
Rainbow        → Firehose (port 2473)
Palomar        → Search API (port 2474)
Bluepages      → Identity API (port 2586)
CollectionDir  → Collection API (port 2584)
Hepa           → Moderation reports
Beemo          → Slack messages
Sonar          → Prometheus metrics (port 2471)
NetSync        → tar.gz files
```

---

## Decision Trees

### "What relay should I run?"

```
Do you want full historical data?
├─ YES → Use BigSky
│       (store all CAR files)
│       ⚠️ Requires: Fast NVMe, 1TB+ disk, 32GB+ RAM
│
└─ NO → Use Relay
        (database only, lighter)
        ✓ Requires: PostgreSQL, 4GB+ RAM, 100GB disk
```

### "Do I need multiple services consuming the firehose?"

```
Are you running many services?
├─ YES, many (5+)
│  └─ Use Rainbow as fanout
│     - One relay → Rainbow → many services
│     - Reduces upstream bandwidth
│     - Local buffering
│
└─ NO, just a few
   └─ Let each service connect directly to relay
      - Simpler setup
      - Each maintains own cursor
```

### "Do I need search capability?"

```
Do you want to search posts?
├─ YES
│  └─ Use Palomar
│     - Requires: OpenSearch cluster
│     - Requires: PostgreSQL (cursor)
│     - Requires: Firehose subscription
│     - Provides: Full-text search API
│
└─ NO
   └─ Don't deploy Palomar
      - Complex to operate
      - Significant resource usage
```

### "Should I cache identity lookups?"

```
Are identity lookups a bottleneck?
├─ YES (many services doing handle resolution)
│  └─ Use Bluepages
│     - Caches PLC responses
│     - Requires: Redis
│     - Reduces PLC directory load
│
└─ NO (few services, PLC is fine)
   └─ Don't deploy Bluepages
      - Services use PLC directly
```

---

## Common Deployment Topologies

### Topology 1: Single Instance Relay

```
┌─────────────────────────────────┐
│ Single Server                   │
│  - PostgreSQL                   │
│  - Indigo Relay                 │
│  - Nginx (reverse proxy)        │
└─────────────────────────────────┘
         ↑              ↓
    External         Clients
  PDS Hosts
```

**When**: Small deployment, single relay, <1k clients

---

### Topology 2: Relay + Internal Services

```
┌──────────────────────────────────────────┐
│ Relay Server                             │
│  - PostgreSQL (relay)                    │
│  - Indigo Relay                          │
│  - Indigo Rainbow (fanout)               │
│  - Indigo Sonar (monitoring)             │
└──────────────┬───────────────────────────┘
               │
      ┌────────┴────────┬─────────┐
      ▼                 ▼         ▼
  ┌─────────┐     ┌──────────┐  ┌────────┐
  │Palomar  │     │Bluepages │  │ Others │
  │ Server  │     │ Server   │  │Servers │
  │-Search  │     │-Caching  │  │-Custom │
  │-OpenS   │     │-Redis    │  │-Apps   │
  └─────────┘     └──────────┘  └────────┘
```

**When**: Growing deployment, internal services, need search

---

### Topology 3: Full Infrastructure (Enterprise)

```
┌─────────────────────────────────────────────────────────────┐
│ Load Balancer / Reverse Proxy                              │
│  - HTTPS/TLS termination                                   │
│  - Rate limiting                                            │
└─────────────┬──────────────────────────────────────────────┘
              │
      ┌───────┴───────┐
      ▼               ▼
┌──────────────┐  ┌──────────────┐
│ Relay Pool   │  │ Service Pool │
│ (replicated) │  │(load balanced)
│              │  │              │
│- Relay 1     │  │ - Palomar    │
│- Relay 2     │  │ - Bluepages  │
│- Relay 3     │  │ - Sonar      │
│(3-5 relays)  │  │ - Hepa       │
└──────┬───────┘  └──────┬───────┘
       │                 │
       └────┬────────────┘
            │
    ┌───────▼────────┐
    │ Shared Databases│
    │ - PostgreSQL   │
    │ - Redis        │
    │ - OpenSearch   │
    └────────────────┘
```

**When**: High availability, many users, enterprise SLA

---

## Database Architecture

### PostgreSQL Layout

```
Database: relay
├── table: events (commits, creates, deletes)
├── table: repos (DID → root CID)
├── table: msa_updates (master store access updates)
├── table: blocks (block records)
└── indices: (handles, DIDs, timestamps)

Database: palomar (if search enabled)
├── table: search_cursor (how far indexed)
└── (OpenSearch stores actual indices)

Database: custom-apps
└── (your application data)
```

### Redis Layout (if using Bluepages/Hepa)

```
redis://localhost:6379/0
├── key: did:* → {handle, document, metadata}
├── key: handle:* → {did, metadata}
├── key: cache:* → {temporary data}
└── (all with TTL for automatic expiry)
```

### Pebble KV Layout (Rainbow/CollectionDir)

```
/var/lib/indigo-rainbow/
├── events (backfill window)
│   ├── 2024-11-07T00:00:00.json
│   ├── 2024-11-07T01:00:00.json
│   └── ... (configurable retention)
└── index (pebble internal files)

/var/lib/indigo-collectiondir/
├── collection-index (DID → collections)
└── index (pebble internal files)
```

### OpenSearch Layout (Palomar)

```
opensearch://opensearch-cluster:9200/
├── index: bsky.feed.post
│   ├── mapping: {text, author, createdAt, ...}
│   └── documents: {id → post data}
│
├── index: app.bsky.actor.profile
│   ├── mapping: {displayName, description, ...}
│   └── documents: {id → profile data}
│
└── other indices...
```

---

## Network Architecture

### Ports Reference

```
External (Internet)
        ↓
    [Firewall]
        ↓
80/443  → Nginx (reverse proxy/TLS)
        ↓
2470    → Relay (internal)
2473    → Rainbow (internal)
2474    → Palomar (internal)
2471    → Sonar metrics (internal or restricted)
2586    → Bluepages (internal)
2584    → CollectionDir (internal)
5432    → PostgreSQL (internal only)
6379    → Redis (internal only)
9200    → OpenSearch (internal only)
```

### Firewall Configuration

```nix
networking.firewall = {
  # Public
  allowedTCPPorts = [ 80 443 ];

  # Internal only (if on same network)
  # Or use firewall rules to restrict to subnet
  allowedTCPPorts = [ 80 443 2470 ];
};

# Better: Use separate interfaces or VPN
networking.firewall.interfaces = {
  "eth0" = {
    allowedTCPPorts = [ 80 443 ];  # External
  };
  "eth1" = {
    allowedTCPPorts = [ 2470 2473 2474 ];  # Internal
  };
};
```

---

## Health Checks

### Service Health Endpoints

```bash
# Relay
curl http://localhost:2470/_health

# Rainbow
curl http://localhost:2473/_health

# Palomar
curl http://localhost:2474/_health

# All services
curl http://localhost:PORT/_health
```

### Database Health

```bash
# PostgreSQL
psql -U relay -d relay -c "SELECT COUNT(*) FROM events;"

# Redis
redis-cli ping

# OpenSearch
curl http://localhost:9200/_cluster/health
```

### Firehose Health

```bash
# Is relay producing events?
wscat -c wss://relay.example.com/xrpc/com.atproto.sync.subscribeRepos \
  | head -5 | wc -l  # Should see events

# How many per second?
wscat -c wss://relay.example.com/xrpc/com.atproto.sync.subscribeRepos \
  | pv -l > /dev/null  # See lines/sec with pv

# Monitor with sonar
curl http://localhost:2471/metrics | grep events_per_second
```

---

## Failure Modes & Recovery

### Relay Connection Lost

```
Symptom: "Cannot connect to PDS"
Cause:   Network, PDS down, PLC unreachable
Fix:     Check upstream, verify firewall, check logs
```

### Database Connection Lost

```
Symptom: "Connection refused on 5432"
Cause:   PostgreSQL not running, permissions, disk full
Fix:     systemctl restart postgresql
         Check: du -sh /var/lib/postgresql
```

### Out of Disk Space

```
Symptom: "No space left on device"
Cause:   BigSky CAR files, PostgreSQL, or backups
Fix:     Clean old backups, expand partition
         Priority: CAR > database > logs
```

### Memory Pressure

```
Symptom: Services killed, high memory usage
Cause:   Large firehose, many indexed repos
Fix:     Add RAM, reduce backfill window
         Monitor: free -h, top, vmstat
```

### High Latency

```
Symptom: "Events delayed, firehose lagging"
Cause:   CPU, disk I/O, or network saturated
Fix:     Check: iostat, top, iftop
         Reduce: workers, connections, rate limit
```

---

## Monitoring Strategy

### Metrics to Track

```
Firehose Health:
- Events per second
- Firehose lag (how far behind)
- Connection status
- Error rate

Database Health:
- Connections
- Query performance
- Disk usage
- CPU usage

Service Health:
- Uptime
- Memory usage
- Disk I/O
- Network I/O
```

### Alerting Rules

```
CRITICAL:
- Firehose stopped (0 events for 5 min)
- PostgreSQL unavailable
- Disk >90%
- Service down

WARNING:
- Firehose lag > 1 hour
- Event latency > 5 sec
- Memory > 80%
- Disk > 75%
```

---

## References

- [ATProto Firehose Spec](https://docs.bsky.app/docs/advanced-guides/firehose)
- [Indigo Repository](https://github.com/bluesky-social/indigo)
- [PLC Directory Spec](https://github.com/did-method-plc/did-method-plc)

