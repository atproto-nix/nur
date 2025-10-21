# ATProto Service Modules

This document describes the standardized configuration patterns for ATProto service modules, organized by their organizational ownership. This includes Microcosm services, official Bluesky services, and community applications from various organizations.

## Overview

All ATProto service modules in this repository follow a consistent pattern that provides:

- **Standardized Security**: Comprehensive systemd security hardening
- **Configuration Validation**: Type-safe configuration with helpful error messages
- **User Management**: Dedicated system users and groups for each service
- **Directory Management**: Declarative data directory creation and ownership
- **Logging Integration**: Structured logging with configurable levels
- **Firewall Integration**: Optional automatic firewall configuration

## Common Configuration Options

All ATProto services share these common configuration options:

```nix
services.microcosm-<service> = {
  enable = true;                                    # Enable the service
  package = pkgs.microcosm.<service>;              # Package to use (auto-detected)
  user = "microcosm-<service>";                    # Service user (auto-generated)
  group = "microcosm-<service>";                   # Service group (auto-generated)
  dataDir = "/var/lib/microcosm-<service>";       # Data directory (auto-generated)
  logLevel = "info";                               # Logging level: trace, debug, info, warn, error
  openFirewall = false;                            # Whether to open firewall ports
};
```

## Security Hardening

All services automatically include comprehensive systemd security restrictions:

- **Process Isolation**: `NoNewPrivileges`, `PrivateTmp`, `PrivateDevices`
- **System Protection**: `ProtectSystem=strict`, `ProtectHome`, `ProtectKernelTunables`
- **Network Restrictions**: `RestrictAddressFamilies` limited to necessary protocols
- **Capability Management**: Minimal required capabilities only
- **Memory Protection**: `MemoryDenyWriteExecute`, `LockPersonality`

## Service-Specific Configuration

### Constellation (Backlink Indexer)

```nix
services.microcosm-constellation = {
  enable = true;
  jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
  backend = "rocks";  # or "memory"
  
  backup = {
    enable = true;
    directory = "/var/lib/microcosm-constellation/backups";
    interval = 24;      # hours
    maxOldBackups = 7;
  };
};
```

### Spacedust

```nix
services.microcosm-spacedust = {
  enable = true;
  jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
  jetstreamNoZstd = false;  # Enable zstd compression
};
```

### Slingshot (TLS-enabled service)

```nix
services.microcosm-slingshot = {
  enable = true;
  jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
  domain = "slingshot.example.com";
  acmeContact = "admin@example.com";
  healthcheckUrl = "https://healthchecks.io/ping/uuid";
};
```

### UFOs

```nix
services.microcosm-ufos = {
  enable = true;
  jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
  backfill = false;     # Enable for initial sync
  reroll = false;       # WARNING: Resets cursor, may cause data loss
};
```

### Pocket (DID Document Service)

```nix
services.microcosm-pocket = {
  enable = true;
  domain = "pocket.example.com";
};
```

### Reflector (DID Document Reflection)

```nix
services.microcosm-reflector = {
  enable = true;
  serviceId = "atproto_pds";
  serviceType = "AtprotoPersonalDataServer";
  serviceEndpoint = "https://pds.example.com";
  domain = "example.com";
};
```

### Who-Am-I (Deprecated Identity Service)

```nix
services.microcosm-who-am-i = {
  enable = true;
  appSecret = "your-secret-key";
  jwtPrivateKey = "/path/to/jwt-private-key";
  oauthPrivateKey = "/path/to/oauth-private-key";  # optional
  baseUrl = "https://who-am-i.example.com";
  bind = "127.0.0.1:9997";
  allowedHosts = [ "example.com" "app.example.com" ];
  openFirewall = true;  # Opens port 9997
};
```

**Note**: The Who-Am-I service is deprecated and should not be used in production.

## Advanced ATProto Applications

### Tier 2 Applications

#### Leaflet (Hyperlink Academy)

```nix
services.hyperlink-academy-leaflet = {
  enable = true;
  settings = {
    port = 3000;
    hostname = "leaflet.example.com";
    nodeEnv = "production";
    database = {
      url = "postgresql://leaflet@localhost/leaflet";
      passwordFile = "/run/secrets/leaflet-db-password";
    };
    supabase = {
      url = "https://your-project.supabase.co";
      anonKey = "your-anon-key";
      serviceRoleKeyFile = "/run/secrets/supabase-service-key";
    };
    replicache = {
      licenseKeyFile = "/run/secrets/replicache-license";
    };
    oauth = {
      clientId = "your-oauth-client-id";
      clientSecretFile = "/run/secrets/oauth-client-secret";
      redirectUri = "https://leaflet.example.com/api/auth/callback";
    };
    appview = {
      enable = true;
      port = 8080;
    };
    feedService = {
      enable = true;
      port = 8081;
    };
  };
};
```

#### Parakeet (Parakeet Social)

```nix
services.parakeet-social-parakeet = {
  enable = true;
  settings = {
    database = {
      url = "postgresql://parakeet@localhost/parakeet";
    };
    redis = {
      url = "redis://localhost:6379";
    };
    appview = {
      did = "did:web:parakeet.example.com";
      publicKey = "your-public-key";
      endpoint = "https://parakeet.example.com";
    };
  };
};
```

#### Teal (Teal.fm)

```nix
services.teal-fm-teal = {
  enable = true;
  settings = {
    database = {
      url = "postgresql://teal@localhost/teal";
    };
    oauth = {
      clientId = "your-oauth-client-id";
      clientSecretFile = "/run/secrets/oauth-client-secret";
      redirectUri = "https://teal.example.com/callback";
    };
    atproto = {
      handle = "teal.example.com";
      did = "did:plc:teal-did";
      signingKeyFile = "/run/secrets/teal-signing-key";
    };
  };
};
```

#### Slices (Slices Network)

```nix
services.slices-network-slices = {
  enable = true;
  settings = {
    database = {
      url = "postgresql://slices@localhost/slices";
    };
    oauth = {
      clientId = "your-oauth-client-id";
      clientSecretFile = "/run/secrets/oauth-client-secret";
      redirectUri = "https://slices.example.com/callback";
      aipBaseUrl = "https://auth.slices.example.com";
    };
    atproto = {
      systemSliceUri = "at://did:plc:system/network.slices.slice/system";
      sliceUri = "at://did:plc:user/network.slices.slice/user";
    };
  };
};
```

### Tier 3 Specialized Services

#### Streamplace (Stream.place)

```nix
services.stream-place-streamplace = {
  enable = true;
  settings = {
    port = 8080;
    publicUrl = "https://streamplace.example.com";
    video = {
      maxBitrate = 5000000;
      maxResolution = "1920x1080";
    };
    storage = {
      type = "s3";
      s3 = {
        bucket = "streamplace-media";
        region = "us-east-1";
      };
    };
  };
};
```

#### Red Dwarf (Red Dwarf Client)

```nix
services.red-dwarf-client-red-dwarf = {
  enable = true;
  settings = {
    port = 3768;
    publicUrl = "https://reddwarf.example.com";
    oauth = {
      clientId = "your-oauth-client-id";
      clientSecretFile = "/run/secrets/oauth-client-secret";
      redirectUri = "https://reddwarf.example.com/callback";
    };
  };
};
```

#### Tangled Development Services

```nix
# Tangled AppView
services.tangled-dev-appview = {
  enable = true;
  settings = {
    port = 8080;
    database = {
      url = "postgresql://appview@localhost/appview";
    };
    atproto = {
      handle = "appview.example.com";
      did = "did:plc:appview-did";
      signingKeyFile = "/run/secrets/appview-signing-key";
    };
    federation = {
      enabled = true;
      allowedDomains = [ "example.com" ];
    };
  };
};

# Tangled Knot (Git Server)
services.tangled-dev-knot = {
  enable = true;
  settings = {
    port = 8081;
    database = {
      url = "postgresql://knot@localhost/knot";
    };
    git = {
      dataDir = "/var/lib/tangled-dev-knot/git";
    };
  };
};

# Tangled Spindle (Event Processing)
services.tangled-dev-spindle = {
  enable = true;
  settings = {
    port = 8082;
    database = {
      url = "postgresql://spindle@localhost/spindle";
    };
    events = {
      queueSize = 1000;
    };
  };
};
```

### Production Tools

#### QuickDID (Smokesignal Events)

```nix
services.smokesignal-events-quickdid = {
  enable = true;
  settings = {
    port = 8080;
    hostname = "quickdid.example.com";
    database = {
      url = "postgresql://quickdid@localhost/quickdid";
    };
    plc = {
      endpoint = "https://plc.directory";
      cacheSize = 10000;
      cacheTtl = 3600;
    };
    cors = {
      allowedOrigins = [ "https://example.com" ];
    };
  };
};
```

#### Allegedly (Microcosm Blue)

```nix
services.microcosm-blue-allegedly = {
  enable = true;
  settings = {
    port = 8080;
    hostname = "allegedly.example.com";
    database = {
      url = "postgresql://allegedly@localhost/allegedly";
    };
  };
};
```

#### PDS Gatekeeper (Individual Developer)

```nix
services.individual-pds-gatekeeper = {
  enable = true;
  settings = {
    port = 8080;
    hostname = "gatekeeper.example.com";
    database = {
      url = "postgresql://gatekeeper@localhost/gatekeeper";
      maxConnections = 50;
    };
    email = {
      smtpHost = "smtp.example.com";
      smtpPort = 587;
      smtpUser = "noreply@example.com";
      smtpPasswordFile = "/run/secrets/smtp-password";
      fromAddress = "noreply@example.com";
      fromName = "PDS Gatekeeper";
    };
    registration = {
      enabled = true;
      requireInvite = false;
      maxAccountsPerEmail = 3;
    };
    security = {
      rateLimitRequests = 100;
      rateLimitWindow = 900;
      sessionTimeout = 86400;
    };
  };
};
```

#### PDS Dashboard (Witchcraft Systems)

```nix
services.witchcraft-systems-pds-dash = {
  enable = true;
  settings = {
    port = 3000;
    hostname = "dash.example.com";
    pds = {
      endpoint = "https://pds.example.com";
      adminPassword = "admin-password";
      adminPasswordFile = "/run/secrets/pds-admin-password";
    };
    ui = {
      title = "PDS Dashboard";
      theme = "dark";
      refreshInterval = 30;
    };
    monitoring = {
      enabled = true;
      metricsPort = 9101;
    };
  };
};
```

#### ATBackup (ATBackup Pages Dev)

```nix
services.atbackup-pages-dev-atbackup = {
  enable = true;
  settings = {
    port = 3000;
    database = {
      url = "postgresql://atbackup@localhost/atbackup";
    };
    atproto = {
      handle = "backup.example.com";
      did = "did:plc:backup-did";
      signingKeyFile = "/run/secrets/atbackup-signing-key";
    };
  };
};
```

## Configuration Validation

All modules include comprehensive configuration validation:

- **Required Fields**: Ensures all mandatory configuration is provided
- **Format Validation**: Validates URLs, email addresses, hostnames, and ports
- **Security Checks**: Warns about insecure configurations
- **Dependency Validation**: Ensures related options are configured correctly

Example validation errors:

```
error: Jetstream URL must start with ws:// or wss://.
error: ACME contact email is required when domain is specified for TLS certificate generation.
warning: Debug logging enabled for microcosm-constellation - this may impact performance in production
```

## Logging and Monitoring

### Structured Logging

All services use structured JSON logging with configurable levels:

```bash
# View service logs
journalctl -u microcosm-constellation.service -f

# Filter by log level
journalctl -u microcosm-constellation.service | jq 'select(.level == "ERROR")'
```

### Health Monitoring

Services include systemd watchdog and restart policies:

- **Automatic Restart**: Services restart on failure with exponential backoff
- **Health Checks**: Built-in health monitoring where supported
- **Resource Limits**: Configurable memory and CPU limits

### Diagnostics

Use the provided diagnostic script for troubleshooting:

```bash
# Check service status and recent logs
atproto-diagnostics
```

## Best Practices

### Production Deployment

1. **Use dedicated users**: Never run services as root or shared users
2. **Configure logging**: Set appropriate log levels (warn/error for production)
3. **Enable backups**: Configure regular backups for stateful services
4. **Monitor resources**: Set up monitoring for CPU, memory, and disk usage
5. **Secure secrets**: Use proper secret management for keys and passwords

### Development Setup

1. **Use debug logging**: Set `logLevel = "debug"` for development
2. **Enable dev mode**: Use development-specific options where available
3. **Local networking**: Bind to localhost for development services
4. **Quick iteration**: Use memory backends for faster development cycles

### Security Considerations

1. **Firewall rules**: Only open necessary ports with `openFirewall = true`
2. **TLS certificates**: Use proper ACME configuration for production domains
3. **Secret files**: Store secrets in `/run/secrets/` or similar secure locations
4. **Network isolation**: Consider network isolation for internal-only services

## Troubleshooting

### Common Issues

1. **Service fails to start**: Check configuration validation errors
2. **Permission denied**: Verify data directory ownership and permissions
3. **Network connectivity**: Ensure jetstream URLs are accessible
4. **Certificate issues**: Check ACME configuration and DNS settings

### Debug Commands

```bash
# Check service status
systemctl status microcosm-constellation.service

# View configuration
systemctl show microcosm-constellation.service

# Check security settings
systemctl show microcosm-constellation.service --property=NoNewPrivileges,ProtectSystem

# Test configuration
nixos-rebuild dry-build
```