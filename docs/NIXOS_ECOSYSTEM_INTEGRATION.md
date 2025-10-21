# NixOS Ecosystem Integration

This document describes how ATProto services integrate with the broader NixOS ecosystem, including common services, monitoring tools, and security features.

## Overview

The ATProto NUR provides comprehensive integration with standard NixOS services and tools, enabling production-ready deployments with minimal configuration. The integration system automatically handles service dependencies, configuration validation, and operational concerns.

## Integration Features

### Database Integration

ATProto services can automatically integrate with PostgreSQL and MySQL databases:

```nix
{
  # Enable global database integration
  atproto.integration.database = {
    postgresql.enable = true;
    autoCreate = true; # Automatically create databases and users
  };

  # Configure service-specific database settings
  services.microcosm-constellation = {
    enable = true;
    database = {
      type = "postgres";
      url = "postgresql://constellation:password@localhost/constellation";
      createDatabase = true; # Auto-create database and user
    };
  };
}
```

**Features:**
- Automatic database and user creation for local PostgreSQL/MySQL
- Service dependency management (services wait for database to be ready)
- Connection validation and error handling
- Performance tuning for ATProto workloads

### Redis Integration

Services can integrate with Redis for caching and real-time features:

```nix
{
  atproto.integration.redis.enable = true;

  services.grain-notifications = {
    enable = true;
    settings.redis = {
      url = "redis://localhost:6379";
      passwordFile = "/etc/redis-password";
    };
  };
}
```

**Features:**
- Automatic Redis server configuration
- Service-specific Redis instances
- Password management through files
- Connection pooling and retry logic

### Nginx Reverse Proxy

Automatic reverse proxy configuration with SSL support:

```nix
{
  atproto.integration.nginx = {
    enable = true;
    ssl.enable = true;
    ssl.email = "admin@example.com";
  };

  services.bluesky-pds = {
    enable = true;
    nginx = {
      enable = true;
      serverName = "pds.example.com";
      ssl.enable = true;
    };
  };
}
```

**Features:**
- Automatic virtual host configuration
- ACME certificate management
- WebSocket proxy support for real-time features
- Security headers and rate limiting
- Load balancing for multiple instances

### Monitoring and Metrics

Comprehensive monitoring with Prometheus and Grafana:

```nix
{
  atproto.integration.monitoring = {
    enable = true;
    prometheus.enable = true;
    grafana.enable = true;
  };

  services.microcosm-constellation = {
    enable = true;
    metrics = {
      enable = true;
      port = 9090;
    };
  };
}
```

**Features:**
- Automatic Prometheus scrape configuration
- Pre-built Grafana dashboards for ATProto services
- Alerting rules for common issues
- Service health checks and uptime monitoring
- Performance metrics and resource usage tracking

### Logging Integration

Structured logging with centralized collection:

```nix
{
  atproto.integration.logging = {
    enable = true;
    structured = true;
    loki.enable = true;
  };
}
```

**Features:**
- Structured JSON logging for all services
- Centralized log collection with Loki
- Automatic log rotation and retention
- Integration with Grafana for log visualization
- Configurable log levels per service

### Security Integration

Enhanced security with multiple layers of protection:

```nix
{
  atproto.integration.security = {
    enable = true;
    fail2ban.enable = true;
    apparmor.enable = true;
    firewall.enable = true;
  };

  services.bluesky-pds = {
    enable = true;
    security = {
      apparmor.enable = true;
      firewall = {
        enable = true;
        allowedPorts = [ 3000 ];
      };
    };
  };
}
```

**Features:**
- Fail2ban intrusion prevention
- AppArmor mandatory access control profiles
- Automatic firewall rule management
- systemd security hardening (NoNewPrivileges, ProtectSystem, etc.)
- Network isolation options

### Backup Integration

Automated backup solutions:

```nix
{
  atproto.integration.backup = {
    enable = true;
    restic.enable = true;
  };

  services.microcosm-constellation = {
    enable = true;
    backup = {
      enable = true;
      restic = {
        enable = true;
        repository = "s3:s3.amazonaws.com/my-backups/constellation";
        passwordFile = "/etc/restic-password";
      };
    };
  };
}
```

**Features:**
- Restic and BorgBackup integration
- Automated backup scheduling
- Configurable retention policies
- Encrypted remote storage support
- Database dump integration

## Service Dependencies and Ordering

The integration system automatically manages service dependencies:

```nix
# Services automatically wait for their dependencies
services.bluesky-pds = {
  enable = true;
  database.type = "postgres"; # Will wait for postgresql.service
};

services.grain-notifications = {
  enable = true;
  settings.redis.url = "redis://localhost:6379"; # Will wait for redis.service
};
```

**Dependency Types:**
- **Database services**: PostgreSQL, MySQL, SQLite
- **Cache services**: Redis, Memcached
- **Network services**: Nginx, network.target
- **Storage services**: File systems, blob storage
- **Monitoring services**: Prometheus, Grafana

## Configuration Examples

### Simple PDS Deployment

```nix
{
  imports = [ ./atproto-nur/modules ];

  # Enable basic integrations
  atproto.integration = {
    database.postgresql.enable = true;
    nginx.enable = true;
    monitoring.prometheus.enable = true;
    logging.enable = true;
    security.firewall.enable = true;
  };

  # Configure PDS service
  services.bluesky-pds = {
    enable = true;
    settings = {
      hostname = "pds.example.com";
      database = {
        type = "postgres";
        createDatabase = true;
      };
    };
    nginx = {
      enable = true;
      serverName = "pds.example.com";
      ssl.enable = true;
    };
    metrics.enable = true;
  };
}
```

### Production Relay Deployment

```nix
{
  imports = [ ./atproto-nur/modules ];

  # Full production integrations
  atproto.integration = {
    database.postgresql = {
      enable = true;
      settings = {
        shared_buffers = "1GB";
        effective_cache_size = "4GB";
      };
    };
    redis.enable = true;
    nginx = {
      enable = true;
      ssl.enable = true;
    };
    monitoring = {
      enable = true;
      prometheus.enable = true;
      grafana.enable = true;
      alertmanager.enable = true;
    };
    logging = {
      enable = true;
      loki.enable = true;
    };
    security = {
      enable = true;
      fail2ban.enable = true;
      apparmor.enable = true;
    };
    backup = {
      enable = true;
      restic.enable = true;
    };
  };

  # Configure relay service
  services.bluesky-relay = {
    enable = true;
    settings = {
      hostname = "relay.example.com";
      upstreamRelays = [ "bsky.network" ];
      database.type = "postgres";
    };
    nginx = {
      enable = true;
      serverName = "relay.example.com";
      ssl.enable = true;
    };
    metrics.enable = true;
    backup = {
      enable = true;
      restic = {
        enable = true;
        repository = "s3:s3.amazonaws.com/relay-backups";
        passwordFile = "/etc/restic-password";
      };
    };
  };
}
```

### Development Environment

```nix
{
  imports = [ ./atproto-nur/modules ];

  # Minimal integrations for development
  atproto.integration = {
    database.postgresql.enable = true;
    monitoring.prometheus.enable = true;
    logging.enable = true;
  };

  # Multiple services for testing
  services = {
    microcosm-constellation = {
      enable = true;
      jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
      metrics.enable = true;
    };

    bluesky-pds = {
      enable = true;
      settings = {
        hostname = "localhost";
        port = 3000;
        database.type = "postgres";
      };
      metrics.enable = true;
    };

    grain-notifications = {
      enable = true;
      settings = {
        database.type = "postgres";
        redis.url = "redis://localhost:6379";
      };
    };
  };
}
```

## Troubleshooting

### Common Issues

1. **Service fails to start**: Check dependencies with `systemctl list-dependencies service-name`
2. **Database connection errors**: Verify database service is running and credentials are correct
3. **Nginx proxy errors**: Check virtual host configuration and upstream service status
4. **Metrics not appearing**: Verify Prometheus scrape configuration and service metrics endpoint

### Debugging Commands

```bash
# Check service status and dependencies
systemctl status microcosm-constellation.service
systemctl list-dependencies microcosm-constellation.service

# Check database connectivity
sudo -u postgres psql -c '\l'
redis-cli ping

# Check nginx configuration
nginx -t
curl -I http://localhost/

# Check metrics endpoint
curl http://localhost:9090/metrics

# Check logs
journalctl -u microcosm-constellation.service -f
```

### Performance Tuning

The integration system includes performance optimizations:

- **Database**: Tuned PostgreSQL settings for ATProto workloads
- **Redis**: Optimized memory usage and persistence settings
- **Nginx**: Compression, caching, and connection pooling
- **Monitoring**: Efficient metrics collection with minimal overhead

## Security Considerations

### Default Security Measures

All ATProto services include comprehensive security hardening:

- **systemd security**: NoNewPrivileges, ProtectSystem, PrivateTmp
- **Network isolation**: Services only bind to necessary interfaces
- **File system protection**: Read-only access to system directories
- **User isolation**: Dedicated system users and groups
- **Capability dropping**: Minimal required capabilities

### Additional Security Options

- **AppArmor profiles**: Mandatory access control for enhanced isolation
- **Fail2ban**: Automatic IP blocking for suspicious activity
- **Firewall integration**: Automatic port management
- **SSL/TLS**: Automatic certificate management with ACME

## Migration and Updates

The integration system supports seamless updates:

- **Atomic updates**: NixOS generation-based rollbacks
- **Database migrations**: Automatic schema updates
- **Configuration validation**: Pre-deployment validation
- **Zero-downtime updates**: Rolling updates for clustered services

## Contributing

To add integration support for new services:

1. Import the integration library: `nixosIntegration = import ../../lib/nixos-integration.nix`
2. Add integration options to service module
3. Use integration helpers: `mkDatabaseIntegration`, `mkNginxIntegration`, etc.
4. Add integration tests to verify functionality
5. Update documentation with examples

See `modules/microcosm/constellation-enhanced.nix` for a complete example.