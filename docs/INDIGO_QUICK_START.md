# Indigo Services - Quick Start Guide

Fast reference for setting up Indigo services. For detailed documentation, see [INDIGO_SERVICES.md](INDIGO_SERVICES.md).

## TL;DR - Just Want a Relay?

```nix
{
  services.postgresql.enable = true;

  services.indigo-relay = {
    enable = true;
    settings = {
      hostname = "relay.example.com";
      database = {
        url = "postgres://relay:password@localhost:5432/relay";
      };
      adminPasswordFile = "/run/secrets/relay-admin-password";
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

Then:
```bash
# Create database
createuser relay
createdb -O relay relay

# Add admin password
mkdir -p /run/secrets
echo "your-secret-password" > /run/secrets/relay-admin-password
chmod 600 /run/secrets/relay-admin-password

# Deploy
nixos-rebuild switch
```

Access relay at: `wss://relay.example.com/xrpc/com.atproto.sync.subscribeRepos`

---

## Service Selector

**Choose based on your needs:**

### "I need a relay"
→ Use `indigo-relay` (modern) or `indigo-bigsky` (with full storage)
- Port: 2470
- Database: PostgreSQL
- Requires: Admin password, hostname

### "I need to search posts"
→ Use `indigo-palomar`
- Port: 2474
- Requires: PostgreSQL + OpenSearch cluster
- Also needs: Relay or firehose subscription

### "I'm running many services"
→ Use `indigo-bluepages` (caches identity lookups)
- Port: 2586
- Requires: Redis
- Other services point to it instead of PLC directory

### "I want local copy of all repos"
→ Use `indigo-bigsky` (stores CAR files)
- Port: 2470
- Requires: FAST NVMe SSD, XFS filesystem
- Database: PostgreSQL
- WARNING: Creates millions of files!

### "I want to distribute the firehose internally"
→ Use `indigo-rainbow`
- Port: 2473
- Requires: Upstream relay/PDS
- Other services subscribe to Rainbow instead of relay

### "I want operational visibility"
→ Use `indigo-sonar`
- Port: 2471 (metrics only)
- Requires: Firehose subscription
- Exports: Prometheus metrics

### "I want to send moderation alerts to Slack"
→ Use `indigo-beemo`
- Requires: Slack webhook URL, firehose subscription
- No exposed ports

### "I want to archive all repos"
→ Use `indigo-netsync`
- Requires: Disk space, checkout endpoint
- Output: tar.gz files per repo

---

## Configuration Templates

### Minimal Relay
```nix
services.indigo-relay = {
  enable = true;
  settings = {
    hostname = "relay.example.com";
    database.url = "postgres://relay:pw@localhost/relay";
    adminPasswordFile = "/run/secrets/relay-admin";
  };
};
```

### Relay + Monitoring
```nix
services.indigo-relay = {
  enable = true;
  settings = {
    hostname = "relay.example.com";
    database.url = "postgres://relay:pw@localhost/relay";
    adminPasswordFile = "/run/secrets/relay-admin";
    metrics.enable = true;
    metrics.port = 2471;
  };
};

services.indigo-sonar = {
  enable = true;
  settings = {
    firehoseUrl = "wss://localhost:2470/xrpc/com.atproto.sync.subscribeRepos";
  };
};
```

### Search (Palomar)
```nix
services.indigo-palomar = {
  enable = true;
  settings = {
    port = 2474;
    database.url = "postgres://palomar:pw@localhost/palomar";
    opensearchUrl = "http://opensearch-cluster:9200";
    firehoseUrl = "wss://relay.example.com/xrpc/com.atproto.sync.subscribeRepos";
  };
};
```

### Identity Caching (Bluepages)
```nix
services.indigo-bluepages = {
  enable = true;
  settings = {
    port = 2586;
    redisUrl = "redis://localhost:6379";
    adminTokenFile = "/run/secrets/bluepages-admin";
  };
};
```

### Local Fanout (Rainbow)
```nix
services.indigo-relay = {
  enable = true;
  # ... relay config ...
};

services.indigo-rainbow = {
  enable = true;
  settings = {
    upstreamHost = "wss://localhost:2470/xrpc/com.atproto.sync.subscribeRepos";
    port = 2473;
  };
};
```

Then other services use: `firehoseUrl = "wss://localhost:2473/..."`

---

## Common Tasks

### Check if relay is working
```bash
# Check service status
systemctl status indigo-relay

# Check logs
journalctl -u indigo-relay -f

# Test firehose connection
wscat -c wss://relay.example.com/xrpc/com.atproto.sync.subscribeRepos

# Check metrics
curl http://localhost:2471/metrics | grep relay
```

### Monitor event rate
```bash
# If using sonar
curl http://localhost:2471/metrics | grep indigo_sonar_events_per_second

# Manual check (count events in 10 seconds)
wscat -c wss://relay.example.com/xrpc/com.atproto.sync.subscribeRepos | head -100
```

### Add admin to running relay
```bash
# Create new password
echo "new-secret" > /run/secrets/relay-admin-password-new
chmod 600 /run/secrets/relay-admin-password-new

# Update config to use new password
# (edit configuration.nix)

# Rebuild
nixos-rebuild switch
```

### Backup relay database
```bash
# PostgreSQL backup
pg_dump -U relay relay > relay-backup.sql

# Compressed
pg_dump -U relay relay | gzip > relay-backup-$(date +%Y%m%d).sql.gz
```

### Monitor disk usage
```bash
# Overall
df -h

# Relay data
du -sh /var/lib/indigo-relay

# BigSky CAR files
du -sh /var/lib/indigo-bigsky

# Rainbow backfill
du -sh /var/lib/indigo-rainbow
```

---

## Database Setup

### PostgreSQL for Relay

```bash
# Create user
sudo -u postgres psql << EOF
CREATE USER relay WITH PASSWORD 'secure-password';
CREATE DATABASE relay OWNER relay;
GRANT ALL PRIVILEGES ON DATABASE relay TO relay;
EOF
```

### Redis for Bluepages/Hepa

```bash
# Default setup (no auth)
systemctl enable redis
systemctl start redis

# Or with NixOS
services.redis = {
  enable = true;
  port = 6379;
};
```

### OpenSearch for Palomar

```bash
# Requires plugins: analysis-icu, analysis-kuromoji
# Use official Docker image or NixOS package

services.opensearch = {
  enable = true;
  plugins = [ opensearch-analysis-icu opensearch-analysis-kuromoji ];
  settings.cluster.name = "opensearch";
};
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Service won't start | `journalctl -u indigo-SERVICE -n 50` |
| "Port already in use" | `lsof -i :PORT` then kill or change port |
| Database connection error | Verify PostgreSQL is running, credentials correct |
| High memory usage | Check relay is not indexing huge repos |
| Slow firehose | Check network bandwidth, upstream relay health |
| Metrics endpoint 404 | Ensure `metrics.enable = true` |

---

## Security Checklist

- [ ] Admin password is strong (20+ chars, random)
- [ ] Store passwords in `/run/secrets` with 600 permissions
- [ ] Use `/root` only for secrets (has 700 perms)
- [ ] Don't commit secrets to git
- [ ] Enable firewall, only open needed ports
- [ ] Use HTTPS for public endpoints (reverse proxy)
- [ ] Regularly update packages

---

## Performance Tuning

### High-throughput relay (>10k events/sec)

```nix
services.postgresql = {
  enable = true;
  settings = {
    shared_buffers = "8GB";        # 25% of RAM
    effective_cache_size = "24GB"; # 75% of RAM
    work_mem = "20MB";
    maintenance_work_mem = "2GB";
    max_parallel_workers_per_gather = 4;
  };
};

services.indigo-relay = {
  enable = true;
  settings = {
    # ... other settings ...
    # Increase connection pool if needed
  };
};
```

### High-throughput search (Palomar)

```nix
services.indigo-palomar = {
  enable = true;
  settings = {
    # Use dedicated OpenSearch cluster
    # Multiple read replicas behind load balancer
  };
};
```

### Full network mirror (BigSky)

```nix
fileSystems."/var/lib/indigo-bigsky" = {
  device = "/dev/nvme0n1p1";
  fsType = "xfs";
  options = [ "defaults" "noatime" "nodiratime" ];
};

# Allocate lots of RAM for caching
boot.kernel.sysctl."vm.dirty_ratio" = 20;
boot.kernel.sysctl."vm.dirty_background_ratio" = 5;
```

---

## Useful Links

- **Indigo Repo**: https://github.com/bluesky-social/indigo
- **ATProto Docs**: https://docs.bsky.app
- **PLC Directory**: https://plc.directory
- **NUR Repo**: https://github.com/atproto-nix/nur

---

## Next Steps

1. Choose your service(s) from the selector above
2. Copy the configuration template
3. Set up required databases
4. Deploy with `nixos-rebuild switch`
5. Monitor with `journalctl -u indigo-SERVICE -f`
6. For details, see [INDIGO_SERVICES.md](INDIGO_SERVICES.md)

