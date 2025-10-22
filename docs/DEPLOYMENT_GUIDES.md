# ATproto Deployment Guides

This guide provides comprehensive deployment instructions for all ATproto service combinations available in the NUR ecosystem.

## Quick Reference

| Service Type | Complexity | Use Case | Guide Section |
|--------------|------------|----------|---------------|
| Simple PDS | Basic | Personal server | [Simple PDS](#simple-pds-deployment) |
| Full ATproto Node | Advanced | Network participant | [Full Node](#full-atproto-node) |
| Development Cluster | Intermediate | Local development | [Dev Cluster](#development-cluster) |
| Production Cluster | Expert | High availability | [Production Cluster](#production-cluster) |
| Custom AppView | Intermediate | Custom applications | [Custom AppView](#custom-appview-deployment) |
| Identity Services | Basic | DID/PLC management | [Identity Services](#identity-services) |

## Prerequisites

### System Requirements

**Minimum Requirements:**
- 2 CPU cores
- 4GB RAM
- 50GB storage
- NixOS 23.05 or later

**Recommended for Production:**
- 4+ CPU cores
- 8GB+ RAM
- 200GB+ SSD storage
- Dedicated network interface

### Network Configuration

```nix
# Basic network setup
networking = {
  hostName = "atproto-node";
  domain = "example.com";
  
  # Enable IPv6 for ATproto
  enableIPv6 = true;
  
  # Firewall configuration
  firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
    # Service-specific ports will be configured per deployment
  };
};
```

### SSL/TLS Setup

All ATproto services require HTTPS. Configure ACME certificates:

```nix
security.acme = {
  acceptTerms = true;
  defaults.email = "admin@example.com";
  
  certs."atproto.example.com" = {
    domain = "atproto.example.com";
    extraDomainNames = [
      "pds.example.com"
      "relay.example.com" 
      "appview.example.com"
    ];
  };
};

services.nginx = {
  enable = true;
  recommendedTlsSettings = true;
  recommendedOptimisation = true;
  recommendedGzipSettings = true;
  recommendedProxySettings = true;
};
```

## Simple PDS Deployment

A Personal Data Server (PDS) is the foundation of ATproto identity. This deployment provides a basic PDS with management tools.

### Configuration

```nix
{
  imports = [
    # ATproto NUR
    inputs.atproto-nur.nixosModules.default
  ];

  # Use the simple PDS profile
  profiles.pds-simple = {
    enable = true;
    hostname = "pds.example.com";
    enableDashboard = true;
    dashboardPort = 3001;
  };

  # PDS service configuration
  services.bluesky-social-frontpage = {
    enable = true;
    settings = {
      hostname = "pds.example.com";
      port = 3000;
      
      # Database configuration
      database = {
        type = "postgresql";
        host = "localhost";
        port = 5432;
        name = "pds";
        user = "pds";
        passwordFile = "/run/secrets/pds-db-password";
      };
      
      # Identity configuration
      identity = {
        plcUrl = "https://plc.directory";
        didMethod = "plc";
      };
      
      # Storage configuration
      storage = {
        type = "local";
        path = "/var/lib/pds/storage";
      };
    };
  };

  # PDS Dashboard for management
  services.witchcraft-systems-pds-dash = {
    enable = true;
    settings = {
      pdsUrl = "https://pds.example.com";
      port = 3001;
      theme = "default";
    };
  };

  # Database setup
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "pds" ];
    ensureUsers = [{
      name = "pds";
      ensurePermissions = {
        "DATABASE pds" = "ALL PRIVILEGES";
      };
    }];
  };

  # Reverse proxy configuration
  services.nginx.virtualHosts = {
    "pds.example.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        proxyWebsockets = true;
      };
    };
    
    "dash.pds.example.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3001";
      };
    };
  };
}
```

### Deployment Steps

1. **Prepare the system:**
   ```bash
   # Update system
   sudo nixos-rebuild switch
   
   # Create secrets
   sudo mkdir -p /run/secrets
   echo "your-secure-password" | sudo tee /run/secrets/pds-db-password
   sudo chmod 600 /run/secrets/pds-db-password
   ```

2. **Deploy the configuration:**
   ```bash
   sudo nixos-rebuild switch --flake .#pds-node
   ```

3. **Verify services:**
   ```bash
   # Check PDS service
   sudo systemctl status bluesky-social-frontpage
   
   # Check dashboard
   sudo systemctl status witchcraft-systems-pds-dash
   
   # Test endpoints
   curl -k https://pds.example.com/.well-known/atproto-did
   curl -k https://dash.pds.example.com/
   ```

4. **Create your first account:**
   ```bash
   # Use the PDS dashboard or API
   curl -X POST https://pds.example.com/xrpc/com.atproto.server.createAccount \
     -H "Content-Type: application/json" \
     -d '{"handle": "alice.pds.example.com", "password": "secure-password"}'
   ```

## Full ATproto Node

A complete ATproto network node includes PDS, relay, AppView, and supporting services.

### Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client Apps   │    │   Web Frontend  │    │  Admin Tools    │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────┴─────────────┐
                    │      Load Balancer       │
                    │        (nginx)           │
                    └─────────────┬─────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
    ┌─────▼─────┐         ┌───────▼───────┐       ┌───────▼───────┐
    │    PDS    │         │     Relay     │       │   AppView     │
    │ (Frontpage)│         │   (Indigo)    │       │  (Leaflet)    │
    └─────┬─────┘         └───────┬───────┘       └───────┬───────┘
          │                       │                       │
          └───────────────────────┼───────────────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │      Shared Services      │
                    │  ┌─────────┐ ┌─────────┐  │
                    │  │PostgreSQL│ │  Redis  │  │
                    │  └─────────┘ └─────────┘  │
                    └───────────────────────────┘
```

### Configuration

```nix
{
  imports = [
    inputs.atproto-nur.nixosModules.default
  ];

  # Use the full node profile
  services.atproto-stacks = {
    profile = "full-node";
    domain = "atproto.example.com";
    
    discovery = {
      backend = "consul";
      consulAddress = "127.0.0.1:8500";
    };
    
    coordination = {
      strategy = "hub-spoke";
      enableHealthChecks = true;
      dependencyTimeout = 60;
    };
  };

  # PDS Service
  services.bluesky-social-frontpage = {
    enable = true;
    settings = {
      hostname = "pds.atproto.example.com";
      port = 3000;
      database.url = "postgresql://pds@localhost/pds";
      relay.endpoint = "https://relay.atproto.example.com";
    };
  };

  # Relay Service (Indigo)
  services.bluesky-social-indigo = {
    enable = true;
    services = [ "relay" "palomar" ];
    settings = {
      relay = {
        hostname = "relay.atproto.example.com";
        port = 3001;
        database.url = "postgresql://relay@localhost/relay";
      };
      palomar = {
        port = 3002;
        jetstream.endpoint = "wss://jetstream.atproto.example.com";
      };
    };
  };

  # AppView Service (Leaflet)
  services.hyperlink-academy-leaflet = {
    enable = true;
    settings = {
      hostname = "app.atproto.example.com";
      port = 3003;
      database.url = "postgresql://leaflet@localhost/leaflet";
      atproto = {
        pds = "https://pds.atproto.example.com";
        relay = "https://relay.atproto.example.com";
      };
    };
  };

  # Supporting Services
  services.microcosm-constellation = {
    enable = true;
    settings = {
      jetstream = "wss://relay.atproto.example.com/jetstream";
      backend = "rocks";
      port = 3004;
    };
  };

  services.smokesignal-events-quickdid = {
    enable = true;
    settings = {
      port = 3005;
      database.url = "postgresql://quickdid@localhost/quickdid";
      plc.endpoint = "https://plc.directory";
    };
  };

  # Service Discovery
  services.consul = {
    enable = true;
    webUi = true;
    extraConfig = {
      datacenter = "atproto-dc1";
      server = true;
      bootstrap_expect = 1;
      ui_config.enabled = true;
    };
  };

  # Database cluster
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    ensureDatabases = [ "pds" "relay" "leaflet" "quickdid" "constellation" ];
    ensureUsers = [
      { name = "pds"; ensurePermissions."DATABASE pds" = "ALL PRIVILEGES"; }
      { name = "relay"; ensurePermissions."DATABASE relay" = "ALL PRIVILEGES"; }
      { name = "leaflet"; ensurePermissions."DATABASE leaflet" = "ALL PRIVILEGES"; }
      { name = "quickdid"; ensurePermissions."DATABASE quickdid" = "ALL PRIVILEGES"; }
    ];
  };

  services.redis.servers.atproto = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";
  };

  # Load balancer configuration
  services.nginx.virtualHosts = {
    "atproto.example.com" = {
      enableACME = true;
      forceSSL = true;
      locations = {
        "/pds/" = {
          proxyPass = "http://127.0.0.1:3000/";
          proxyWebsockets = true;
        };
        "/relay/" = {
          proxyPass = "http://127.0.0.1:3001/";
          proxyWebsockets = true;
        };
        "/app/" = {
          proxyPass = "http://127.0.0.1:3003/";
        };
        "/constellation/" = {
          proxyPass = "http://127.0.0.1:3004/";
        };
        "/quickdid/" = {
          proxyPass = "http://127.0.0.1:3005/";
        };
      };
    };
  };
}
```

### Deployment Steps

1. **System preparation:**
   ```bash
   # Ensure adequate resources
   free -h  # Check memory
   df -h    # Check disk space
   
   # Create service directories
   sudo mkdir -p /var/lib/{pds,relay,leaflet,constellation,quickdid}
   ```

2. **Deploy services incrementally:**
   ```bash
   # Deploy database first
   sudo nixos-rebuild switch --flake .#full-node --target-host database.internal
   
   # Deploy core services
   sudo nixos-rebuild switch --flake .#full-node
   
   # Verify each service before proceeding
   curl -f https://pds.atproto.example.com/.well-known/atproto-did
   curl -f https://relay.atproto.example.com/.well-known/atproto-did
   ```

3. **Configure service discovery:**
   ```bash
   # Check Consul cluster
   consul members
   consul catalog services
   
   # Verify service registration
   consul catalog service pds
   consul catalog service relay
   ```

4. **Test full stack:**
   ```bash
   # Create test account
   curl -X POST https://atproto.example.com/pds/xrpc/com.atproto.server.createAccount \
     -H "Content-Type: application/json" \
     -d '{"handle": "test.atproto.example.com", "password": "test123"}'
   
   # Test cross-service communication
   curl https://atproto.example.com/app/api/posts
   ```

## Development Cluster

A development cluster provides a complete ATproto environment with relaxed security for testing and development.

### Configuration

```nix
{
  imports = [
    inputs.atproto-nur.nixosModules.default
  ];

  # Development profile with relaxed security
  services.atproto-stacks = {
    profile = "dev-cluster";
    domain = "dev.atproto.local";
    
    coordination = {
      strategy = "peer-to-peer";
      enableHealthChecks = false;  # Faster startup
    };
  };

  # Development-specific overrides
  services.bluesky-social-frontpage.settings = {
    debug = true;
    cors.allowAll = true;
    rateLimit.disable = true;
  };

  services.hyperlink-academy-leaflet.settings = {
    debug = true;
    hotReload = true;
  };

  # In-memory databases for faster iteration
  services.postgresql.settings = {
    fsync = "off";
    synchronous_commit = "off";
    full_page_writes = "off";
  };

  # Development tools
  environment.systemPackages = with pkgs; [
    curl
    jq
    postgresql
    redis
    consul
  ];

  # Relaxed firewall for development
  networking.firewall.enable = false;
}
```

## Production Cluster

A production-ready cluster with high availability, monitoring, and security hardening.

### High Availability Architecture

```
                    ┌─────────────────┐
                    │   Load Balancer │
                    │    (HAProxy)    │
                    └─────────┬───────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
        ┌─────▼─────┐   ┌─────▼─────┐   ┌─────▼─────┐
        │  Node 1   │   │  Node 2   │   │  Node 3   │
        │ (Primary) │   │(Secondary)│   │(Secondary)│
        └─────┬─────┘   └─────┬─────┘   └─────┬─────┘
              │               │               │
              └───────────────┼───────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Database Cluster │
                    │   (PostgreSQL)    │
                    └───────────────────┘
```

### Configuration

```nix
{
  imports = [
    inputs.atproto-nur.nixosModules.default
  ];

  services.atproto-stacks = {
    profile = "prod-cluster";
    domain = "atproto.example.com";
    
    discovery = {
      backend = "consul";
      consulAddress = "consul.internal:8500";
    };
    
    coordination = {
      strategy = "leader-follower";
      enableHealthChecks = true;
      dependencyTimeout = 120;
    };
  };

  # Production security hardening
  security = {
    # Enable AppArmor/SELinux
    apparmor.enable = true;
    
    # Audit logging
    auditd.enable = true;
    
    # Fail2ban for intrusion prevention
    fail2ban = {
      enable = true;
      jails.atproto = {
        filter = "atproto";
        logpath = "/var/log/atproto/*.log";
        maxretry = 3;
        bantime = 3600;
      };
    };
  };

  # Monitoring and observability
  services.prometheus = {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "atproto-services";
        static_configs = [{
          targets = [
            "localhost:3000"  # PDS metrics
            "localhost:3001"  # Relay metrics
            "localhost:3003"  # AppView metrics
          ];
        }];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server.http_port = 3010;
      security.admin_password = "$__file{/run/secrets/grafana-password}";
    };
  };

  # Log aggregation
  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3100;
      ingester.lifecycler.ring.kvstore.store = "inmemory";
    };
  };

  # Backup configuration
  services.restic.backups.atproto = {
    repository = "s3:backup-bucket/atproto";
    passwordFile = "/run/secrets/restic-password";
    environmentFile = "/run/secrets/restic-env";
    paths = [
      "/var/lib/pds"
      "/var/lib/relay"
      "/var/lib/leaflet"
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Database clustering
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    
    # Performance tuning
    settings = {
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      maintenance_work_mem = "64MB";
      checkpoint_completion_target = "0.9";
      wal_buffers = "16MB";
      default_statistics_target = "100";
    };
    
    # Replication setup
    extraConfig = ''
      wal_level = replica
      max_wal_senders = 3
      wal_keep_segments = 8
    '';
  };
}
```

## Custom AppView Deployment

Deploy custom AppView applications using the Slices platform or Leaflet.

### Slices Custom AppView

```nix
{
  services.slices-network-slices = {
    enable = true;
    settings = {
      hostname = "myapp.example.com";
      port = 3000;
      
      # ATproto configuration
      atproto = {
        pds = "https://pds.example.com";
        handle = "myapp.example.com";
        password = "app-password";
      };
      
      # Custom feed configuration
      feeds = [
        {
          name = "trending";
          algorithm = "engagement";
          filters = [ "image" "video" ];
        }
        {
          name = "local";
          algorithm = "chronological";
          filters = [ "local-users" ];
        }
      ];
      
      # API configuration
      api = {
        rateLimit = {
          requests = 1000;
          window = 3600;
        };
        cors = {
          origins = [ "https://myapp.example.com" ];
        };
      };
    };
  };

  # Frontend configuration (Deno)
  systemd.services.slices-frontend = {
    description = "Slices Frontend";
    wantedBy = [ "multi-user.target" ];
    after = [ "slices-network-slices.service" ];
    
    serviceConfig = {
      Type = "simple";
      User = "slices";
      Group = "slices";
      WorkingDirectory = "/var/lib/slices/frontend";
      ExecStart = "${pkgs.deno}/bin/deno run --allow-net --allow-read app.ts";
      Restart = "always";
    };
  };
}
```

## Identity Services

Deploy DID and PLC management services.

### QuickDID + Allegedly Setup

```nix
{
  # QuickDID for fast identity resolution
  services.smokesignal-events-quickdid = {
    enable = true;
    settings = {
      port = 8080;
      hostname = "did.example.com";
      
      database = {
        url = "postgresql://quickdid@localhost/quickdid";
        maxConnections = 20;
      };
      
      plc = {
        endpoint = "https://plc.directory";
        cacheTimeout = 3600;
      };
      
      performance = {
        workers = 4;
        cacheSize = 10000;
      };
    };
  };

  # Allegedly for PLC operations
  services.microcosm-blue-allegedly = {
    enable = true;
    settings = {
      port = 8081;
      hostname = "plc.example.com";
      
      database = {
        url = "postgresql://allegedly@localhost/allegedly";
      };
      
      plc = {
        signingKey = "/run/secrets/plc-signing-key";
        rotationKeys = [
          "/run/secrets/plc-rotation-key-1"
          "/run/secrets/plc-rotation-key-2"
        ];
      };
    };
  };

  # Reverse proxy
  services.nginx.virtualHosts = {
    "did.example.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        extraConfig = ''
          proxy_cache_valid 200 1h;
          proxy_cache_key "$scheme$request_method$host$request_uri";
        '';
      };
    };
    
    "plc.example.com" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8081";
      };
    };
  };
}
```

## Troubleshooting

### Common Issues

**Service won't start:**
```bash
# Check service status
sudo systemctl status service-name

# Check logs
sudo journalctl -u service-name -f

# Check configuration
sudo nixos-rebuild dry-run --flake .#config-name
```

**Database connection issues:**
```bash
# Test database connectivity
sudo -u postgres psql -l

# Check database permissions
sudo -u postgres psql -c "\du"

# Reset database
sudo systemctl restart postgresql
```

**Network connectivity issues:**
```bash
# Check port bindings
sudo netstat -tlnp

# Test service endpoints
curl -v http://localhost:3000/.well-known/atproto-did

# Check firewall
sudo iptables -L
```

### Performance Tuning

**Database optimization:**
```nix
services.postgresql.settings = {
  # Memory settings
  shared_buffers = "25% of RAM";
  effective_cache_size = "75% of RAM";
  
  # Connection settings
  max_connections = 200;
  
  # Performance settings
  random_page_cost = 1.1;  # For SSD
  effective_io_concurrency = 200;  # For SSD
};
```

**Service optimization:**
```nix
# Rust services
systemd.services.microcosm-constellation.serviceConfig = {
  # CPU scheduling
  CPUSchedulingPolicy = "fifo";
  CPUSchedulingPriority = 50;
  
  # Memory management
  MemoryHigh = "1G";
  MemoryMax = "2G";
};
```

### Monitoring

**Health check endpoints:**
```bash
# PDS health
curl https://pds.example.com/.well-known/atproto-did

# Relay health  
curl https://relay.example.com/xrpc/_health

# AppView health
curl https://app.example.com/api/health
```

**Metrics collection:**
```nix
services.prometheus.scrapeConfigs = [
  {
    job_name = "atproto-metrics";
    metrics_path = "/metrics";
    static_configs = [{
      targets = [
        "pds.example.com:3000"
        "relay.example.com:3001"
        "app.example.com:3003"
      ];
    }];
  }
];
```

This completes the comprehensive deployment guide covering all major ATproto service combinations and deployment scenarios.