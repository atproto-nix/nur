# PDS Ecosystem Integration Guide

This document describes the integration patterns between Personal Data Server (PDS) and its management tools in the ATProto NUR repository.

## Overview

The PDS ecosystem consists of several components that work together to provide a complete ATProto hosting solution:

- **PDS Core**: The main ATProto Personal Data Server
- **PDS Dashboard**: Web interface for monitoring and statistics
- **PDS Gatekeeper**: Security microservice with 2FA and rate limiting
- **Backup Tools**: Automated backup and recovery systems
- **Monitoring**: Metrics collection and alerting

## Package Structure

### PDS Dashboard (`pds-dash`)

A Svelte-based web application that provides:
- Real-time PDS statistics and monitoring
- User activity visualization
- Post analytics and trends
- System health indicators

**Key Features:**
- Configurable themes
- Customizable post limits and filtering
- Integration with external frontend services
- Responsive design for mobile and desktop

### PDS Gatekeeper (`pds-gatekeeper`)

A Rust-based security microservice that adds:
- Two-factor authentication (2FA)
- Rate limiting for account creation
- Enhanced login security
- Email verification workflows

**Key Features:**
- Transparent proxy integration
- Configurable rate limiting
- Custom email templates
- SQLite database for 2FA tokens

## Integration Patterns

### Reverse Proxy Integration

Both PDS Dashboard and PDS Gatekeeper are designed to work behind a reverse proxy (Caddy, Nginx, etc.):

```
Internet → Reverse Proxy → PDS Gatekeeper → PDS Core
                       → PDS Dashboard
```

**Gatekeeper Intercepts:**
- `/xrpc/com.atproto.server.getSession`
- `/xrpc/com.atproto.server.updateEmail`
- `/xrpc/com.atproto.server.createSession`
- `/xrpc/com.atproto.server.createAccount`
- `/@atproto/oauth-provider/~api/sign-in`

**Dashboard Access:**
- Can be served on main domain: `/dashboard/*`
- Or on subdomain: `dashboard.pds.example.com`

### Service Dependencies

The services have the following dependency chain:

1. **Database** (PostgreSQL/SQLite) - Must start first
2. **PDS Core** - Depends on database
3. **PDS Gatekeeper** - Depends on PDS Core and database
4. **PDS Dashboard** - Depends on PDS Core (can run independently)

### Configuration Sharing

Services share configuration through:
- **Environment Variables**: Common settings in `pds.env`
- **Data Directory**: Shared access to PDS data directory
- **Database**: Gatekeeper uses same database as PDS for user data

## Deployment Profiles

### Simple PDS (`profiles.pds-simple`)

Minimal setup for development or small instances:

```nix
profiles.pds-simple = {
  enable = true;
  hostname = "pds.example.com";
  enableDashboard = true;
  dashboardPort = 3001;
};
```

**Includes:**
- PDS Dashboard on port 3001
- Basic firewall configuration
- Shared data directory setup

### Managed PDS (`profiles.pds-managed`)

Enhanced setup with security features:

```nix
profiles.pds-managed = {
  enable = true;
  hostname = "pds.example.com";
  
  dashboard = {
    enable = true;
    port = 3001;
    theme = "default";
  };
  
  gatekeeper = {
    enable = true;
    port = 8080;
    rateLimiting = {
      createAccountPerSecond = 60;
      createAccountBurst = 5;
    };
  };
};
```

**Includes:**
- PDS Dashboard with customizable settings
- PDS Gatekeeper with 2FA and rate limiting
- Reverse proxy configuration templates
- Service dependency management

### Enterprise PDS (`profiles.pds-enterprise`)

Production-ready setup with full management suite:

```nix
profiles.pds-enterprise = {
  enable = true;
  hostname = "pds.example.com";
  
  database.type = "postgres";
  
  monitoring = {
    enable = true;
    prometheus.enable = true;
    grafana.enable = true;
  };
  
  backup = {
    enable = true;
    schedule = "daily";
    retention = 30;
  };
  
  ssl.acme = {
    enable = true;
    email = "admin@example.com";
  };
};
```

**Includes:**
- All managed PDS features
- PostgreSQL database configuration
- Prometheus metrics and Grafana dashboards
- Automated backup system
- ACME SSL certificate management
- Enhanced security hardening

## Configuration Examples

### Caddy Reverse Proxy

```caddyfile
pds.example.com {
    # Gatekeeper paths
    @gatekeeper {
        path /xrpc/com.atproto.server.getSession
        path /xrpc/com.atproto.server.updateEmail
        path /xrpc/com.atproto.server.createSession
        path /xrpc/com.atproto.server.createAccount
        path /@atproto/oauth-provider/~api/sign-in
    }
    
    handle @gatekeeper {
        reverse_proxy http://localhost:8080
    }
    
    # Dashboard
    handle /dashboard* {
        reverse_proxy http://localhost:3001
    }
    
    # Main PDS
    reverse_proxy http://localhost:3000
}

# Dashboard subdomain
dashboard.pds.example.com {
    reverse_proxy http://localhost:3001
}
```

### Nginx Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name pds.example.com;
    
    # Gatekeeper paths
    location ~ ^/(xrpc/com\.atproto\.server\.(getSession|updateEmail|createSession|createAccount)|@atproto/oauth-provider/~api/sign-in) {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Dashboard
    location /dashboard {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Main PDS
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Security Considerations

### PDS Gatekeeper Security

- Runs with minimal privileges using systemd security features
- Read-only access to PDS data directory
- Network isolation options available
- Rate limiting prevents abuse
- 2FA tokens stored securely in database

### PDS Dashboard Security

- No write access to PDS data
- Configurable network binding
- Content Security Policy headers recommended
- Should be served over HTTPS in production

### Service Isolation

Each service runs with:
- Dedicated system user and group
- Restricted file system access
- Network namespace isolation (optional)
- Capability dropping
- Memory execution protection

## Monitoring and Observability

### Metrics Collection

Services expose metrics for monitoring:
- **PDS Core**: ATProto-specific metrics
- **Gatekeeper**: Authentication and rate limiting metrics
- **Dashboard**: Usage and performance metrics

### Log Management

All services integrate with systemd journaling:
- Structured JSON logging
- Configurable log levels
- Centralized log collection
- Log rotation and retention

### Health Checks

Services provide health check endpoints:
- **PDS**: `/xrpc/com.atproto.server.describeServer`
- **Gatekeeper**: Proxies PDS health checks
- **Dashboard**: Built-in health monitoring

## Backup and Recovery

### Automated Backups

Enterprise profile includes:
- Daily database backups
- PDS data directory snapshots
- Configurable retention policies
- Backup verification and testing

### Recovery Procedures

1. **Database Recovery**: Restore from SQL dump
2. **Data Recovery**: Restore from data directory backup
3. **Configuration Recovery**: NixOS configuration rollback
4. **Service Recovery**: Systemd service restart and validation

## Troubleshooting

### Common Issues

1. **Gatekeeper Connection Errors**
   - Verify PDS is running and accessible
   - Check PDS data directory permissions
   - Validate environment file exists

2. **Dashboard Empty Data**
   - Confirm PDS URL configuration
   - Check network connectivity to PDS
   - Verify PDS has user data

3. **2FA Email Issues**
   - Check email template configuration
   - Verify SMTP settings in PDS
   - Test email delivery manually

### Diagnostic Commands

```bash
# Check service status
systemctl status pds-dash pds-gatekeeper

# View service logs
journalctl -u pds-dash -f
journalctl -u pds-gatekeeper -f

# Test connectivity
curl -f http://localhost:3001/  # Dashboard
curl -f http://localhost:8080/xrpc/com.atproto.server.describeServer  # Gatekeeper

# Validate configuration
nixos-rebuild dry-build
```

## Migration and Updates

### Service Updates

NixOS provides atomic updates:
1. Build new configuration
2. Switch to new generation
3. Restart affected services
4. Rollback if issues occur

### Data Migration

When updating services:
1. Stop services gracefully
2. Backup current data
3. Apply updates
4. Migrate data if needed
5. Restart services
6. Validate functionality

### Configuration Migration

Profile configurations handle:
- Breaking changes in service options
- Database schema migrations
- File format updates
- Security policy changes