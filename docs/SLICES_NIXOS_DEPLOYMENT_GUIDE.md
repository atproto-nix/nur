# Slices.Network NixOS Deployment Guide

⚠️ **Known Issue:** The Slices-network NixOS module is currently excluded from default module imports due to an infinite recursion issue with nested submodules. To use this guide, you must explicitly import the slices-network module or use individual service configurations.

A comprehensive guide to deploying a fully functional Slices.Network instance on NixOS, from development to production multi-tenant deployments.

**Table of Contents**
- [Quick Start](#quick-start-single-tenant-development)
- [Architecture Overview](#architecture-overview)
- [Infrastructure Requirements](#infrastructure-requirements)
- [Security Hardening](#security-hardening)
- [Single-Tenant Production](#single-tenant-production-deployment)
- [Multi-Tenant Production](#multi-tenant-production-deployment)
- [Database Management](#database-management)
- [Troubleshooting](#troubleshooting)
- [Performance Tuning](#performance-tuning)

---

## Quick Start: Single-Tenant Development

### Minimal Configuration

```nix
# configuration.nix
{ config, pkgs, ... }:

let
  # Import from NUR
  nur = builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz";
in
{
  imports = [
    "${nur}/modules/slices-network"
    # ... other imports
  ];

  # PostgreSQL Service
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "slices" ];
    ensureUsers = [{
      name = "slices";
      ensureDBOwnership = true;
    }];

    initialScript = pkgs.writeText "init.sql" ''
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    '';
  };

  # Slices Service
  services.slices-network-slices = {
    enable = true;

    settings = {
      database.url = "postgresql://slices@localhost/slices";

      oauth = {
        clientId = "dev-client-id";
        clientSecretFile = pkgs.writeText "oauth-secret" "dev-secret";
        redirectUri = "http://localhost:8080/oauth/callback";
        aipBaseUrl = "http://localhost:8081";  # Local AIP service
      };

      atproto = {
        systemSliceUri = "at://did:plc:example/network.slices.slice/system";
        sliceUri = "at://did:plc:example/network.slices.slice/default";
      };

      frontend.enable = true;
      logLevel = "debug";
    };
  };

  # Firewall (development - allow local access)
  networking.firewall.enable = false;  # Or allow specific ports
}
```

### First Run Steps

```bash
# 1. Apply configuration
sudo nixos-rebuild switch

# 2. Wait for services to start
sleep 5

# 3. Verify database connection
psql postgresql://slices@localhost/slices -c "SELECT 1"

# 4. Check service status
systemctl status slices-network-slices-api
systemctl status slices-network-slices-frontend

# 5. Access in browser
# Frontend: http://localhost:8080
# API: http://localhost:3000/xrpc/network.slices.slice.stats
```

---

## Architecture Overview

### Service Architecture

```
┌──────────────────────────────────────────────┐
│         Slices.Network Platform              │
├──────────────────────────────────────────────┤
│                                              │
│  ┌─────────────┐  ┌──────────────────────┐  │
│  │  Frontend   │  │   API (Rust)         │  │
│  │  (Deno)     │  │   - HTTP XRPC        │  │
│  │  :8080      │  │   - GraphQL          │  │
│  └──────┬──────┘  │   - Job Queue        │  │
│         │         │   - Jetstream        │  │
│         └────┬────┤   :3000              │  │
│              │    └──────────────────────┘  │
│  ┌───────────┴──────────────┐               │
│  │   PostgreSQL 15+         │               │
│  │   - Extensions:          │               │
│  │     • uuid-ossp         │               │
│  │     • pg_trgm           │               │
│  │   - Port: 5432          │               │
│  └──────────────────────────┘               │
│                                              │
│  ┌──────────────────────────┐               │
│  │   Redis (Optional)       │               │
│  │   - Cache + Pub/Sub      │               │
│  │   - Port: 6379           │               │
│  └──────────────────────────┘               │
│                                              │
│  External:                                   │
│  - AIP OAuth Service (https://auth/...)     │
│  - AT Protocol Relay (relay1.us-west...)    │
│  - AT Protocol Jetstream (jetstream2...)    │
└──────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Purpose | Technology | Port |
|-----------|---------|-----------|------|
| Frontend | Web UI + OAuth callback | Deno/TypeScript | 8080 |
| API | XRPC/GraphQL endpoints | Rust | 3000 |
| PostgreSQL | Data persistence | PostgreSQL 15+ | 5432 |
| Redis | Cache + messaging | Redis 7+ | 6379 |
| AIP | OAuth authentication | External | 8081 (dev) / 443 (prod) |
| Jetstream | Real-time events | External | WSS |

---

## Infrastructure Requirements

### PostgreSQL Setup

**Minimum Requirements:**
- PostgreSQL 15 or later
- 256MB+ shared buffers
- 1GB+ effective cache size
- Extensions: `uuid-ossp`, `pg_trgm`

**NixOS Configuration:**

```nix
services.postgresql = {
  enable = true;
  package = pkgs.postgresql_15;

  # Create database and user
  ensureDatabases = [ "slices" ];
  ensureUsers = [{
    name = "slices_user";
    ensureDBOwnership = true;
  }];

  # Enable required extensions
  initialScript = pkgs.writeText "init.sql" ''
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
  '';

  # Performance tuning
  settings = {
    max_connections = 200;
    shared_buffers = "256MB";
    effective_cache_size = "1GB";
    work_mem = "16MB";
  };
};
```

### Redis Setup (Optional but Recommended)

```nix
services.redis.servers.slices = {
  enable = true;
  port = 6379;
  bind = "127.0.0.1";

  # Memory management
  maxmemory = "512MB";
  maxmemoryPolicy = "allkeys-lru";

  # Optional: Password protection
  # requirePass = "secure-redis-password";
};
```

### Required AT Protocol Accounts

Before deployment, register:

1. **Service DID** (decentralized identifier)
   - Used to identify your Slices instance
   - Format: `did:plc:xxxxx` or `did:web:example.com`

2. **OAuth Application**
   - Register with AIP (AT Protocol OAuth provider)
   - Get client ID and secret
   - Configure redirect URIs

3. **Admin DID**
   - Administrator account on AT Protocol
   - Can perform privileged operations

---

## Security Hardening

### 1. Secret Management

**Use NixOS Secrets (agenix recommended):**

```nix
# Create secret files
age.secrets.slices-db-password = {
  file = ./secrets/db-password.age;
  owner = "postgres";
  group = "postgres";
  mode = "0600";
};

age.secrets.slices-oauth-secret = {
  file = ./secrets/oauth-secret.age;
  owner = "slices";
  group = "slices";
  mode = "0600";
};

# Use secrets in configuration
services.slices-network-slices = {
  settings.database.passwordFile = config.age.secrets.slices-db-password.path;
  settings.oauth.clientSecretFile = config.age.secrets.slices-oauth-secret.path;
};
```

### 2. Database Security

```nix
# Restrict database access
services.postgresql.settings = {
  # Local-only connections
  listen_addresses = "127.0.0.1";

  # Require password authentication
  password_encryption = "scram-sha-256";
};

# NixOS firewall rules
networking.firewall.rules = {
  databaseAccess = {
    from = [ "127.0.0.1" ];
    allowedTCPPorts = [ 5432 ];
  };
};
```

### 3. Reverse Proxy with HTTPS

```nix
services.nginx = {
  enable = true;
  recommendedProxySettings = true;
  recommendedTlsSettings = true;

  virtualHosts."slices.example.com" = {
    enableACME = true;
    forceSSL = true;

    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };

      "/api/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
      };
    };
  };
};

# ACME (Let's Encrypt)
security.acme = {
  acceptTerms = true;
  defaults.email = "admin@example.com";
};
```

### 4. Systemd Hardening

The NixOS module includes:

```nix
NoNewPrivileges = true;
ProtectSystem = "strict";
ProtectHome = true;
PrivateTmp = true;
ProtectKernelTunables = true;
RestrictSUIDSGID = true;
MemoryDenyWriteExecute = true;
```

---

## Single-Tenant Production Deployment

### Full Production Configuration

```nix
{ config, pkgs, ... }:

let
  nur = builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz";
in
{
  imports = [
    "${nur}/modules/slices-network"
  ];

  # === SECRETS ===
  age.secrets.slices-db-password = {
    file = ./secrets/db-password.age;
    owner = "postgres";
    mode = "0600";
  };

  age.secrets.slices-oauth-secret = {
    file = ./secrets/oauth-secret.age;
    mode = "0600";
  };

  age.secrets.redis-password = {
    file = ./secrets/redis-password.age;
    mode = "0600";
  };

  # === DATABASE ===
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;

    ensureDatabases = [ "slices" ];
    ensureUsers = [{
      name = "slices_user";
      ensureDBOwnership = true;
    }];

    initialScript = pkgs.writeText "init.sql" ''
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    '';

    settings = {
      # Connection settings
      max_connections = 200;
      shared_buffers = "512MB";
      effective_cache_size = "2GB";
      work_mem = "32MB";

      # Write performance
      wal_buffers = "16MB";
      checkpoint_completion_target = 0.9;

      # Query optimization
      random_page_cost = 1.1;  # For SSD

      # Logging
      log_min_duration_statement = 1000;
      log_checkpoints = true;
    };
  };

  # === BACKUP ===
  services.postgresqlBackup = {
    enable = true;
    databases = [ "slices" ];
    startAt = "daily";
    backupAll = false;
    location = "/var/backup/postgresql";
  };

  # === REDIS ===
  services.redis.servers.slices = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";
    requirePass = "redis-password";  # From secret

    maxmemory = "1GB";
    maxmemoryPolicy = "allkeys-lru";

    # Persistence
    save = [
      "900 1"      # 900 seconds, 1 change
      "300 10"     # 300 seconds, 10 changes
      "60 10000"   # 60 seconds, 10000 changes
    ];
  };

  # === SLICES SERVICE ===
  services.slices-network-slices = {
    enable = true;
    dataDir = "/var/lib/slices";
    user = "slices";
    group = "slices";

    settings = {
      # API Configuration
      api = {
        port = 3000;
        processType = "all";  # Single process handling everything

        multiTenantConfig = {
          tenantIsolation = "strict";
          crossTenantAccess = false;
        };
      };

      # Database Configuration
      database = {
        url = "postgresql://slices_user@localhost/slices";
        passwordFile = config.age.secrets.slices-db-password.path;

        multiTenantConfig = {
          isolationStrategy = "schema_per_tenant";
          connectionPooling = {
            enabled = true;
            maxConnectionsPerTenant = 20;
            globalMaxConnections = 150;
          };

          # Important: Manual migrations for production
          migrations = {
            autoMigrate = false;
            migrationTimeout = 600;
          };
        };
      };

      # OAuth Configuration
      oauth = {
        clientId = "prod-client-id";
        clientSecretFile = config.age.secrets.slices-oauth-secret.path;
        redirectUri = "https://slices.example.com/oauth/callback";
        aipBaseUrl = "https://auth.example.com";
      };

      # AT Protocol Configuration
      atproto = {
        relayEndpoint = "https://relay1.us-west.bsky.network";
        jetstreamHostname = "jetstream2.us-west.bsky.network";
        systemSliceUri = "at://did:plc:YOUR_DID/network.slices.slice/system";
        sliceUri = "at://did:plc:YOUR_DID/network.slices.slice/default";
      };

      # Redis Configuration
      redis = {
        url = "redis://:redis-password@localhost:6379";
        ttlSeconds = 7200;  # 2 hours

        multiTenantConfig = {
          keyPrefix = "slices";
          separateNamespaces = true;
        };
      };

      # Jetstream Configuration
      jetstream = {
        cursorWriteIntervalSecs = 60;

        multiTenantConfig = {
          perTenantCursors = true;
          sharedConnection = true;
        };
      };

      # Monitoring
      monitoring = {
        perTenantMetrics = true;
        tenantUsageTracking = true;
      };

      # Frontend
      frontend = {
        enable = true;
        port = 8080;

        multiTenantUI = {
          tenantSwitcher = true;
          customBranding = true;
        };
      };

      # Logging
      logLevel = "info";  # Use "warn" to reduce log volume
    };
  };

  # === REVERSE PROXY ===
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."slices.example.com" = {
      enableACME = true;
      forceSSL = true;

      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxyWebsockets = true;

          extraConfig = ''
            proxy_redirect off;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };

        "/api/" = {
          proxyPass = "http://127.0.0.1:3000";
          proxyWebsockets = true;

          extraConfig = ''
            proxy_redirect off;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };
  };

  # === FIREWALL ===
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  networking.firewall.rules = {
    # Restrict internal services to localhost
    databaseAccess = {
      from = [ "127.0.0.1" ];
      allowedTCPPorts = [ 5432 ];
    };

    redisAccess = {
      from = [ "127.0.0.1" ];
      allowedTCPPorts = [ 6379 ];
    };
  };

  # === ACME/SSL ===
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
  };

  # === SYSTEM TUNING ===
  boot.kernel.sysctl = {
    "net.core.somaxconn" = 1024;
    "net.ipv4.ip_local_port_range" = "10000 65000";
  };
}
```

### Deployment Steps

```bash
# 1. Create secret files with agenix
agenix -e secrets/db-password.age
agenix -e secrets/oauth-secret.age
agenix -e secrets/redis-password.age

# 2. Build and switch to new configuration
sudo nixos-rebuild switch

# 3. Wait for services to stabilize
sleep 10

# 4. Run database migrations (if not auto-migrating)
# Note: Migration command depends on your setup
# psql postgresql://slices_user@localhost/slices < migrations.sql

# 5. Register OAuth client with AIP
# Follow AIP documentation to register your client

# 6. Verify services are running
systemctl status slices-network-slices-api
systemctl status slices-network-slices-frontend
systemctl status nginx

# 7. Test health endpoints
curl https://slices.example.com/api/xrpc/network.slices.slice.stats
curl https://slices.example.com/

# 8. Monitor logs
journalctl -u slices-network-slices-api -f
```

---

## Multi-Tenant Production Deployment

### Multi-Tenant Configuration

```nix
{ config, pkgs, ... }:

let
  nur = builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz";
in
{
  imports = [
    "${nur}/modules/slices-network"
  ];

  # === SECRETS ===
  age.secrets = {
    slices-db-password.file = ./secrets/db-password.age;
    slices-oauth-secret.file = ./secrets/oauth-secret.age;
    tenant1-db-password.file = ./secrets/tenant1-db-password.age;
    tenant1-oauth-secret.file = ./secrets/tenant1-oauth-secret.age;
    tenant2-db-password.file = ./secrets/tenant2-db-password.age;
    tenant2-oauth-secret.file = ./secrets/tenant2-oauth-secret.age;
    redis-password.file = ./secrets/redis-password.age;
  };

  # === POSTGRESQL (Per-Tenant Databases) ===
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;

    ensureDatabases = [ "slices" "slices_tenant1" "slices_tenant2" ];

    ensureUsers = [
      { name = "slices_user"; ensureDBOwnership = true; }
      { name = "tenant1_user"; ensureDBOwnership = true; }
      { name = "tenant2_user"; ensureDBOwnership = true; }
    ];

    initialScript = pkgs.writeText "init.sql" ''
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    '';

    settings = {
      max_connections = 300;
      shared_buffers = "1GB";
      effective_cache_size = "4GB";
      work_mem = "32MB";
    };
  };

  # === SLICES SERVICE (Multi-Tenant) ===
  services.slices-network-slices = {
    enable = true;

    # Enable multi-tenancy
    multiTenant = {
      enable = true;
      defaultTenant = "tenant1";

      # Tenant resolution via subdomain
      tenantResolution = {
        method = "subdomain";  # tenant1.slices.example.com
      };

      # Tenant configurations
      tenants = {
        # === TENANT 1 ===
        tenant1 = {
          enable = true;
          sliceUri = "at://did:plc:tenant1did/network.slices.slice/main";
          adminDid = "did:plc:tenant1admin";

          database = {
            name = "slices_tenant1";
            isolationLevel = "database";
          };

          oauth = {
            clientId = "tenant1-client";
            clientSecretFile = config.age.secrets.tenant1-oauth-secret.path;
            redirectUri = "https://tenant1.slices.example.com/oauth/callback";
          };

          customDomain = "tenant1.slices.example.com";

          resourceLimits = {
            maxSyncRepos = 5000;
            maxStorageGB = 100;
            maxApiRequestsPerMinute = 10000;
          };

          features = {
            jetstreamEnabled = true;
            customLexicons = true;
            sdkGeneration = true;
          };
        };

        # === TENANT 2 ===
        tenant2 = {
          enable = true;
          sliceUri = "at://did:plc:tenant2did/network.slices.slice/main";
          adminDid = "did:plc:tenant2admin";

          database = {
            name = "slices_tenant2";
            isolationLevel = "database";
          };

          oauth = {
            clientId = "tenant2-client";
            clientSecretFile = config.age.secrets.tenant2-oauth-secret.path;
            redirectUri = "https://tenant2.slices.example.com/oauth/callback";
          };

          customDomain = "tenant2.slices.example.com";

          resourceLimits = {
            maxSyncRepos = 2000;
            maxStorageGB = 50;
            maxApiRequestsPerMinute = 5000;
          };
        };
      };
    };

    settings = {
      api = {
        port = 3000;
        processType = "all";

        multiTenantConfig = {
          tenantIsolation = "strict";
          rateLimiting.enabled = true;
          rateLimiting.globalLimit = 50000;
          crossTenantAccess = false;
        };
      };

      database = {
        url = "postgresql://slices_user@localhost/slices";
        passwordFile = config.age.secrets.slices-db-password.path;

        multiTenantConfig = {
          isolationStrategy = "database_per_tenant";
          connectionPooling = {
            enabled = true;
            maxConnectionsPerTenant = 30;
            globalMaxConnections = 250;
          };
          migrations.autoMigrate = false;  # Manual in production
        };
      };

      oauth = {
        aipBaseUrl = "https://auth.example.com";
      };

      redis = {
        url = "redis://:redis-password@localhost:6379";

        multiTenantConfig = {
          keyPrefix = "slices";
          separateNamespaces = true;
        };
      };

      monitoring = {
        perTenantMetrics = true;
        tenantUsageTracking = true;

        alerting = {
          tenantQuotaAlerts = true;
        };
      };

      frontend.enable = true;
      logLevel = "info";
    };
  };

  # === NGINX (Per-Tenant Routing) ===
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      # Main domain
      "slices.example.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
        };
      };

      # Tenant 1
      "tenant1.slices.example.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          extraConfig = ''
            proxy_set_header X-Tenant-ID tenant1;
          '';
        };
      };

      # Tenant 2
      "tenant2.slices.example.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          extraConfig = ''
            proxy_set_header X-Tenant-ID tenant2;
          '';
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

---

## Database Management

### Migrations

**For Development** (automatic):
```nix
settings.database.multiTenantConfig.migrations.autoMigrate = true;
```

**For Production** (manual, recommended):

```bash
# 1. Disable auto-migrations
# Set: autoMigrate = false

# 2. Run migrations manually
sqlx migrate run \
  --database-url "postgresql://slices_user@localhost/slices"

# 3. For multi-tenant (per database)
sqlx migrate run \
  --database-url "postgresql://tenant1_user@localhost/slices_tenant1"

sqlx migrate run \
  --database-url "postgresql://tenant2_user@localhost/slices_tenant2"
```

### Backup and Restore

**Automated Backups:**
```nix
services.postgresqlBackup = {
  enable = true;
  databases = [ "slices" "slices_tenant1" "slices_tenant2" ];
  startAt = "02:00";  # 2 AM daily
  location = "/var/backup/postgresql";
};
```

**Manual Backup:**
```bash
# Full backup
pg_dump postgresql://slices_user@localhost/slices \
  > backup_$(date +%Y%m%d).sql

# Compressed backup
pg_dump postgresql://slices_user@localhost/slices \
  | gzip > backup_$(date +%Y%m%d).sql.gz
```

**Restore from Backup:**
```bash
# Stop services first
sudo systemctl stop slices-network-slices-api slices-network-slices-frontend

# Drop and recreate database
psql -U postgres -c "DROP DATABASE IF EXISTS slices;"
psql -U postgres -c "CREATE DATABASE slices OWNER slices_user;"

# Restore backup
psql postgresql://slices_user@localhost/slices < backup_20251107.sql

# Restart services
sudo systemctl start slices-network-slices-api slices-network-slices-frontend
```

---

## Troubleshooting

### Service Won't Start

**Check logs:**
```bash
journalctl -u slices-network-slices-api -n 50
journalctl -u slices-network-slices-frontend -n 50
```

**Common issues:**

1. **Database connection failed**
   ```bash
   # Verify database exists
   psql -l

   # Test connection
   psql postgresql://slices_user@localhost/slices -c "SELECT 1;"
   ```

2. **Extensions missing**
   ```bash
   psql postgresql://slices_user@localhost/slices -c "\\dx"
   ```

3. **Port already in use**
   ```bash
   ss -tlnp | grep -E "3000|8080"
   ```

### Database Issues

**Check table structure:**
```sql
\dt  -- List tables
\d record  -- Describe table
```

**Check migrations:**
```sql
SELECT * FROM _sqlx_migrations;
```

**Monitor connections:**
```sql
SELECT datname, count(*) as connections
FROM pg_stat_activity
GROUP BY datname;
```

### OAuth Login Fails

**Verify configuration:**
```bash
echo $OAUTH_CLIENT_ID
cat /run/secrets/oauth-secret

# Test OAuth endpoint
curl https://auth.example.com/.well-known/oauth-authorization-server
```

**Check logs for details:**
```bash
journalctl -u slices-network-slices-frontend | grep -i oauth
```

### Jetstream Connection Issues

**Check status:**
```bash
curl http://localhost:3000/xrpc/network.slices.slice.getJetstreamStatus
```

**Monitor reconnection attempts:**
```bash
journalctl -u slices-network-slices-api | grep -i jetstream
```

**Note:** Jetstream auto-reconnects with exponential backoff (max 5 retries per minute).

---

## Performance Tuning

### Database Tuning

**For High Load:**
```nix
services.postgresql.settings = {
  max_connections = 500;
  shared_buffers = "2GB";
  effective_cache_size = "8GB";
  work_mem = "64MB";
  wal_buffers = "32MB";
};
```

**Check slow queries:**
```bash
journalctl -u postgresql | grep "duration:" | sort -t: -k2 -rn
```

### Redis Configuration

**For High Memory Load:**
```nix
services.redis.servers.slices = {
  maxmemory = "4GB";
  maxmemoryPolicy = "allkeys-lru";  # Evict least-used keys
};
```

### Connection Pool Tuning

```nix
multiTenantConfig.connectionPooling = {
  enabled = true;
  maxConnectionsPerTenant = 50;  # Increase for high concurrency
  globalMaxConnections = 300;
};
```

### Monitoring

**Set up logging for slow queries:**
```nix
services.postgresql.settings = {
  log_min_duration_statement = 500;  # Log queries > 500ms
  log_statement = "all";
};
```

**Monitor in real-time:**
```bash
# Watch logs
journalctl -u slices-network-slices-api -f

# Check CPU/memory usage
top
htop

# Monitor database connections
watch -n 1 'psql -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"'
```

---

## Next Steps

1. **Security Review**
   - [ ] Rotate all secrets regularly
   - [ ] Enable firewall rules
   - [ ] Set up SSL/TLS
   - [ ] Configure backup encryption

2. **Monitoring Setup**
   - [ ] Configure alerting for service failures
   - [ ] Monitor database performance
   - [ ] Track disk usage
   - [ ] Monitor Jetstream connection health

3. **Operational Documentation**
   - [ ] Document runbooks for common issues
   - [ ] Create disaster recovery procedures
   - [ ] Document tenant onboarding process
   - [ ] Create operational dashboards

4. **Testing**
   - [ ] Load test the deployment
   - [ ] Test failover procedures
   - [ ] Verify backup/restore works
   - [ ] Test multi-tenant isolation

---

## Related Documentation

- **[CLAUDE.md](./CLAUDE.md)** - Implementation patterns and troubleshooting
- **[JAVASCRIPT_DENO_BUILDS.md](./JAVASCRIPT_DENO_BUILDS.md)** - Deno package build patterns
- **[SECRETS_INTEGRATION.md](./SECRETS_INTEGRATION.md)** - Secret management strategies

---

## Support & Community

- **Slices.Network**: https://slices.network
- **AT Protocol**: https://atproto.com
- **Bluesky**: https://bsky.social
- **Tangled.org**: https://tangled.org (@slices.network/slices)
