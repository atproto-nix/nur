# pds-dash Themed Integration Examples

**Date**: November 4, 2025
**Purpose**: Real-world configuration examples for themed pds-dash

## Table of Contents

1. [Simple Standalone Dashboard](#simple-standalone)
2. [Multiple Dashboards](#multiple-dashboards)
3. [With SSL/ACME](#with-ssl-acme)
4. [Custom Configuration](#custom-configuration)
5. [Docker-like Deployment](#docker-deployment)
6. [Development vs Production](#dev-vs-prod)

---

## Simple Standalone Dashboard {#simple-standalone}

The easiest way to get started with a themed pds-dash.

**File**: `/etc/nixos/configuration.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # ... other config ...

  services.witchcraft-systems.pds-dash = {
    enable = true;
    buildTheme = true;
    theme = "sunset";

    virtualHost = "dash.localhost";
    pdsUrl = "http://localhost:3000";
    frontendUrl = "https://bsky.app";
  };

  # Required for local testing
  networking.hosts = {
    "127.0.0.1" = [ "dash.localhost" ];
  };
}
```

**Usage**:
```bash
# Rebuild the system
sudo nixos-rebuild switch

# Access dashboard
firefox http://dash.localhost
```

**Notes**:
- `buildTheme = true` builds the dashboard at configuration time
- Theme choice is baked into the package
- No SSL/HTTPS for localhost development

---

## Multiple Dashboards {#multiple-dashboards}

Deploy separate dashboards for different PDS instances or purposes.

**File**: `/etc/nixos/configuration.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # Development dashboard - minimal config, default theme
  services.witchcraft-systems.pds-dash-dev = {
    enable = true;
    buildTheme = true;
    theme = "default";

    virtualHost = "dash-dev.local";
    pdsUrl = "http://pds-dev.local:3000";
    frontendUrl = "https://bsky.app";
    maxPosts = 10;  # Lower for testing
  };

  # Staging dashboard - standard config, express theme
  services.witchcraft-systems.pds-dash-staging = {
    enable = true;
    buildTheme = true;
    theme = "express";

    virtualHost = "dash-staging.local";
    pdsUrl = "http://pds-staging.local:3000";
    frontendUrl = "https://staging.bsky.app";
    maxPosts = 20;
  };

  # Production dashboard - full config, sunset theme
  services.witchcraft-systems.pds-dash-prod = {
    enable = true;
    buildTheme = true;
    theme = "sunset";

    virtualHost = "dash-prod.local";
    pdsUrl = "http://pds-prod.local:3000";
    frontendUrl = "https://bsky.app";
    maxPosts = 30;
    footerText = "Production PDS Dashboard - Enterprise Edition";
  };

  # Configure local resolution for all three
  networking.hosts = {
    "127.0.0.1" = [
      "dash-dev.local"
      "dash-staging.local"
      "dash-prod.local"
    ];
  };
}
```

**Usage**:
```bash
# Access each dashboard
firefox http://dash-dev.local       # Default theme
firefox http://dash-staging.local   # Express theme
firefox http://dash-prod.local      # Sunset theme

# Each dashboard targets its own PDS instance
```

**Benefits**:
- Separate configurations for each environment
- Different themes for visual distinction
- Independent resource allocation

---

## With SSL/ACME {#with-ssl-acme}

Production-ready configuration with automatic HTTPS.

**File**: `/etc/nixos/configuration.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # ACME configuration (required for SSL)
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
    defaults.provider = "letsencrypt";
  };

  # Production pds-dash with SSL
  services.witchcraft-systems.pds-dash = {
    enable = true;
    buildTheme = true;
    theme = "sunset";

    # Hosted at https://dashboard.example.com
    virtualHost = "dashboard.example.com";
    pdsUrl = "https://pds.example.com";
    frontendUrl = "https://bsky.app";

    # Enable SSL with automatic certificate
    enableSSL = true;
    acmeHost = "example.com";  # Domain for certificate
  };

  # Configure firewall to allow HTTP/HTTPS
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];  # HTTP/HTTPS
  };
}
```

**Usage**:
```bash
# Rebuild system (will provision Let's Encrypt certificate)
sudo nixos-rebuild switch

# Check certificate status
sudo systemctl status acme-dashboard.example.com.service

# Access dashboard (HTTPS automatic)
firefox https://dashboard.example.com
```

**Certificate Management**:
```bash
# View certificates
sudo ls -la /var/lib/acme/

# Renewal is automatic (before expiry)
sudo systemctl list-timers acme-*
```

**Notes**:
- Requires valid DNS records pointing to server
- Certificate renewal happens automatically
- HTTP is redirected to HTTPS

---

## Custom Configuration {#custom-configuration}

Full customization of dashboard appearance and behavior.

**File**: `/etc/nixos/configuration.nix`

```nix
{ config, lib, pkgs, ... }:

{
  services.witchcraft-systems.pds-dash = {
    enable = true;
    buildTheme = true;
    theme = "witchcraft";

    # Network configuration
    virtualHost = "dashboard.example.com";
    pdsUrl = "https://pds.example.com";
    frontendUrl = "https://my-frontend.example.com";

    # UI customization
    maxPosts = 50;  # Show more posts
    showFuturePosts = true;  # Include future-dated posts

    # Custom footer with branding
    footerText = ''
      <div style="text-align: center;">
        <p>
          <strong>Enterprise PDS Dashboard</strong><br>
          Powered by <a href="https://git.witchcraft.systems/scientific-witchery/pds-dash">pds-dash</a><br>
          <small>© 2025 My Company</small>
        </p>
      </div>
    '';

    # SSL configuration
    enableSSL = true;
    acmeHost = "example.com";
  };

  # Additional nginx configuration for caching
  services.nginx.virtualHosts."dashboard.example.com".extraConfig = ''
    # Cache static assets for 1 day
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp)$ {
      expires 1d;
      add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
  '';
}
```

**Result**:
- Dashboard with witchcraft theme (dark, purple accents)
- Shows 50 posts per request
- Custom branded footer
- HTTPS with automatic certificate renewal
- Optimized caching for static assets
- Security headers for protection

---

## Docker-like Deployment {#docker-deployment}

Containerized dashboard deployment pattern.

**File**: `/etc/nixos/configuration.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # Virtual network for PDS services
  networking = {
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
  };

  # Internal service discovery
  networking.hosts = {
    "127.0.0.1" = [
      "pds.internal"
      "dashboard.internal"
      "localhost"
    ];
  };

  # Dashboard container (systemd service acts like container)
  services.witchcraft-systems.pds-dash = {
    enable = true;
    buildTheme = true;
    theme = "express";

    virtualHost = "dashboard.internal";
    pdsUrl = "http://pds.internal:3000";  # Internal service name
    frontendUrl = "https://bsky.app";
  };

  # Reverse proxy for external access
  services.nginx = {
    enable = true;

    virtualHosts."dashboard.example.com" = {
      # Proxy to internal dashboard
      locations."/" = {
        proxyPass = "http://dashboard.internal";
        proxyWebsockets = true;

        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };

      enableACME = true;
      useACMEHost = "example.com";
      forceSSL = true;
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

**Architecture**:
```
External Traffic
    ↓
HTTPS (Let's Encrypt)
    ↓
Nginx Reverse Proxy (dashboard.example.com)
    ↓
Internal HTTP
    ↓
pds-dash (dashboard.internal:80)
    ↓
PDS Service (pds.internal:3000)
```

**Benefits**:
- Service isolation via hostnames
- External access via reverse proxy
- HTTPS termination at proxy
- Internal services use HTTP

---

## Development vs Production {#dev-vs-prod}

Different configurations for development and production environments.

**File**: `/etc/nixos/configuration.nix`

```nix
{ config, lib, pkgs, ... }:

let
  # Environment variable
  isProduction = builtins.getEnv "PRODUCTION" == "1";

  # Shared configuration
  baseConfig = {
    buildTheme = true;
    frontendUrl = "https://bsky.app";
  };

  # Development configuration
  devConfig = baseConfig // {
    enable = !isProduction;
    theme = "default";
    virtualHost = "dash-dev.local";
    pdsUrl = "http://localhost:3000";
    maxPosts = 10;
    footerText = "Development Dashboard";
  };

  # Production configuration
  prodConfig = baseConfig // {
    enable = isProduction;
    theme = "sunset";
    virtualHost = "dashboard.example.com";
    pdsUrl = "https://pds.example.com";
    maxPosts = 30;
    footerText = "Production PDS Dashboard";
    enableSSL = true;
    acmeHost = "example.com";
  };

in
{
  services.witchcraft-systems.pds-dash = if isProduction then prodConfig else devConfig;
}
```

**Usage**:
```bash
# Development rebuild
sudo nixos-rebuild switch
# → Starts dev dashboard on dash-dev.local

# Production rebuild
PRODUCTION=1 sudo nixos-rebuild switch
# → Starts prod dashboard on dashboard.example.com with SSL

# Check which environment is active
echo $PRODUCTION
```

**Environment-specific Settings**:
- **Dev**: Default theme, localhost, low maxPosts for testing
- **Prod**: Sunset theme, domain-based, SSL, higher maxPosts

---

## Advanced: Parameterized Configuration {#parameterized}

Create reusable dashboard configurations.

**File**: `/etc/nixos/pds-dash-config.nix`

```nix
# Reusable dashboard configuration generator
{ theme, host, pdsUrl, maxPosts ? 20 }:

{
  enable = true;
  buildTheme = true;

  inherit theme;
  virtualHost = host;
  inherit pdsUrl;
  inherit maxPosts;

  frontendUrl = "https://bsky.app";
  enableSSL = true;
  acmeHost = builtins.elemAt (builtins.split "\\." host) 0;  # Extract domain
}
```

**File**: `/etc/nixos/configuration.nix`

```nix
{ config, lib, pkgs, ... }:

let
  mkDashboard = import ./pds-dash-config.nix;
in
{
  services.witchcraft-systems = {
    # Internal development dashboard
    pds-dash-dev = mkDashboard {
      theme = "default";
      host = "dash-dev.internal";
      pdsUrl = "http://pds-dev:3000";
      maxPosts = 10;
    };

    # Staging dashboard
    pds-dash-staging = mkDashboard {
      theme = "express";
      host = "dash-staging.example.com";
      pdsUrl = "https://pds-staging.example.com";
      maxPosts = 20;
    };

    # Production dashboard
    pds-dash-prod = mkDashboard {
      theme = "sunset";
      host = "dashboard.example.com";
      pdsUrl = "https://pds.example.com";
      maxPosts = 50;
    };
  };
}
```

**Benefits**:
- DRY principle - reusable configuration
- Consistent settings across environments
- Easy to add new dashboards
- Single source of truth for configuration

---

## Theme Showcase {#theme-showcase}

Quick reference for choosing themes.

### Default Theme
```nix
services.witchcraft-systems.pds-dash = {
  theme = "default";
  # Modern indigo-based design
  # Best for professional/enterprise use
};
```

### Express Theme
```nix
services.witchcraft-systems.pds-dash = {
  theme = "express";
  # Sleek blue design with smooth transitions
  # Best for modern, minimalist deployments
};
```

### Sunset Theme
```nix
services.witchcraft-systems.pds-dash = {
  theme = "sunset";
  # Warm orange/golden design
  # Best for friendly, community-focused instances
};
```

### Witchcraft Theme
```nix
services.witchcraft-systems.pds-dash = {
  theme = "witchcraft";
  # Dark with purple accents, sophisticated
  # Best for dark mode users, aesthetic customization
};
```

---

## Troubleshooting Examples {#troubleshooting}

### Issue: Dashboard not accessible after rebuild

```bash
# Check nginx status
sudo systemctl status nginx

# Check nginx logs
sudo journalctl -u nginx -n 50

# Test nginx configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

### Issue: Wrong theme appears

```bash
# Verify buildTheme is true
grep -A5 "buildTheme" /etc/nixos/configuration.nix

# Verify theme name is correct
grep -A5 "theme =" /etc/nixos/configuration.nix

# Force rebuild (bypasses cache)
sudo nixos-rebuild switch --show-trace

# Check what was built
nix path-info /run/current-system | grep pds-dash
```

### Issue: SSL certificate not working

```bash
# Check ACME status
sudo systemctl list-timers acme-*

# View certificate logs
sudo journalctl -u acme-*.service -n 100

# Check if certificate exists
sudo ls -la /var/lib/acme/example.com/

# Verify domain DNS
nslookup dashboard.example.com
```

---

## Production Checklist {#checklist}

Before deploying to production:

- [ ] DNS records configured and pointing to server
- [ ] `security.acme.acceptTerms = true` set
- [ ] ACME email address configured
- [ ] Firewall allows ports 80 and 443
- [ ] `enableSSL = true` and `acmeHost` set correctly
- [ ] `pdsUrl` points to real PDS instance
- [ ] Theme selection matches branding
- [ ] Custom footer text added
- [ ] Tested dashboard at https://domain.com
- [ ] Certificate auto-renewal configured
- [ ] Backups of configuration in place
- [ ] Monitoring/alerting set up

---

## Questions & Support

- **pds-dash**: https://git.witchcraft.systems/scientific-witchery/pds-dash
- **NixOS NUR**: https://github.com/nix-community/NUR
- **NixOS Manual**: https://nixos.org/manual/nixos/stable/

---

**Examples Created**: November 4, 2025
**Status**: Ready for production use ✅
