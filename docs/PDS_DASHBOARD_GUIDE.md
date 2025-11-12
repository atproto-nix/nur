# PDS Dashboard Guide

**Date**: November 4, 2025
**Status**: ✅ Complete implementation with standalone and integrated support
**Themes**: default, express, sunset, witchcraft

---

## Overview

This comprehensive guide explains how to deploy and configure themed pds-dash dashboards with your PDS services. The implementation supports:

1. **Standalone Dashboards** - Use pds-dash module independently with theme selection
2. **Integrated Dashboards** - Add dashboard as part of PDS service configuration (future)
3. **Full Configuration** - All dashboard settings customizable at build time
4. **Theme Support** - Built-in themes with custom configuration

---

## Quick Start

### Simplest: Standalone Dashboard

```nix
services.witchcraft-systems.pds-dash = {
  enable = true;
  buildTheme = true;
  theme = "sunset";
  virtualHost = "dash.example.com";
  pdsUrl = "http://pds.example.com:3000";
  frontendUrl = "https://bsky.app";
};
```

### With SSL/HTTPS

```nix
services.witchcraft-systems.pds-dash = {
  enable = true;
  buildTheme = true;
  theme = "sunset";
  virtualHost = "dash.example.com";
  pdsUrl = "http://pds.example.com:3000";
  frontendUrl = "https://bsky.app";
  enableSSL = true;
  acmeHost = "example.com";
};
```

### Future: Integrated with PDS

```nix
services.blacksky.pds = {
  enable = true;
  hostname = "pds.example.com";

  dashboard = {
    enable = true;
    theme = "sunset";
    virtualHost = "dash.example.com";
  };
};
```

---

## Components

### 1. Parameterized Builder: `pds-dash-themed.nix`

A reusable builder that creates themed pds-dash packages with custom configuration.

**Location**: `pkgs/witchcraft-systems/pds-dash-themed.nix`

**Parameters**:
- `theme` (string, default: "default") - Theme to use
- `pdsUrl` (string) - PDS instance URL
- `frontendUrl` (string) - Frontend service URL
- `maxPosts` (int) - Posts per request
- `footerText` (string) - Dashboard footer
- `showFuturePosts` (bool) - Show future-dated posts

**Example Usage**:
```nix
myDash = pkgs.callPackage ./pds-dash-themed.nix {
  theme = "sunset";
  pdsUrl = "http://pds.local:3000";
  frontendUrl = "https://bsky.app";
};
```

### 2. Enhanced NixOS Module

The witchcraft-systems pds-dash module now supports theme selection and full configuration.

**Location**: `modules/witchcraft-systems/pds-dash.nix`

**New Options**:
```nix
services.witchcraft-systems.pds-dash = {
  # Build control
  buildTheme = true;                           # Enable themed build
  theme = "sunset";                            # Theme choice

  # Configuration
  pdsUrl = "http://pds.example.com:3000";     # PDS URL
  frontendUrl = "https://bsky.app";           # Frontend URL
  maxPosts = 20;                              # Posts per request
  footerText = "My PDS";                      # Custom footer
  showFuturePosts = false;                    # Future posts visibility

  # Existing options still available
  virtualHost = "dash.example.com";
  enableSSL = true;
  acmeHost = "example.com";
};
```

### 3. Shared Library: `pds-dash.nix`

Helper functions for building dashboard support into PDS modules.

**Location**: `lib/pds-dash.nix`

**Functions**:
- `mkDashboardOptions` - Create dashboard options for any PDS
- `mkDashboardModule` - Build complete dashboard submodule
- `addDashboardSupport` - Add dashboard support to existing PDS module
- `validateTheme` - Validate theme names
- `availableThemes` - List of available themes

---

## Detailed Usage Examples

### Example 1: Simple Standalone Dashboard

**File**: `/etc/nixos/configuration.nix`

```nix
{ config, lib, pkgs, ... }:

{
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
sudo nixos-rebuild switch
firefox http://dash.localhost
```

---

### Example 2: Multiple Dashboards (Dev/Staging/Prod)

```nix
{ config, lib, pkgs, ... }:

{
  # Development dashboard
  services.witchcraft-systems.pds-dash-dev = {
    enable = true;
    buildTheme = true;
    theme = "default";
    virtualHost = "dash-dev.local";
    pdsUrl = "http://pds-dev.local:3000";
    frontendUrl = "https://bsky.app";
    maxPosts = 10;
  };

  # Staging dashboard
  services.witchcraft-systems.pds-dash-staging = {
    enable = true;
    buildTheme = true;
    theme = "express";
    virtualHost = "dash-staging.local";
    pdsUrl = "http://pds-staging.local:3000";
    frontendUrl = "https://staging.bsky.app";
    maxPosts = 20;
  };

  # Production dashboard
  services.witchcraft-systems.pds-dash-prod = {
    enable = true;
    buildTheme = true;
    theme = "sunset";
    virtualHost = "dash-prod.local";
    pdsUrl = "http://pds-prod.local:3000";
    frontendUrl = "https://bsky.app";
    maxPosts = 30;
    footerText = "Production PDS Dashboard";
  };

  # Local DNS resolution
  networking.hosts = {
    "127.0.0.1" = [
      "dash-dev.local"
      "dash-staging.local"
      "dash-prod.local"
    ];
  };
}
```

---

### Example 3: Production with SSL/ACME

```nix
{ config, lib, pkgs, ... }:

{
  # ACME configuration
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
    defaults.provider = "letsencrypt";
  };

  # Production dashboard
  services.witchcraft-systems.pds-dash = {
    enable = true;
    buildTheme = true;
    theme = "sunset";

    virtualHost = "dashboard.example.com";
    pdsUrl = "https://pds.example.com";
    frontendUrl = "https://bsky.app";

    enableSSL = true;
    acmeHost = "example.com";
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };
}
```

---

### Example 4: Custom Configuration with Branding

```nix
{ config, lib, pkgs, ... }:

{
  services.witchcraft-systems.pds-dash = {
    enable = true;
    buildTheme = true;
    theme = "witchcraft";

    # Network
    virtualHost = "dashboard.example.com";
    pdsUrl = "https://pds.example.com";
    frontendUrl = "https://my-frontend.example.com";

    # UI customization
    maxPosts = 50;
    showFuturePosts = true;

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

    # SSL
    enableSSL = true;
    acmeHost = "example.com";
  };

  # Additional nginx caching
  services.nginx.virtualHosts."dashboard.example.com".extraConfig = ''
    # Cache static assets
    location ~* \.(js|css|png|jpg|gif|ico|svg|webp)$ {
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

---

### Example 5: Docker-like Deployment Pattern

```nix
{ config, lib, pkgs, ... }:

{
  # Internal service discovery
  networking.hosts = {
    "127.0.0.1" = [
      "pds.internal"
      "dashboard.internal"
    ];
  };

  # Internal dashboard
  services.witchcraft-systems.pds-dash = {
    enable = true;
    buildTheme = true;
    theme = "express";

    virtualHost = "dashboard.internal";
    pdsUrl = "http://pds.internal:3000";
    frontendUrl = "https://bsky.app";
  };

  # External reverse proxy
  services.nginx = {
    enable = true;

    virtualHosts."dashboard.example.com" = {
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

---

### Example 6: Development vs Production

```nix
{ config, lib, pkgs, ... }:

let
  isProduction = builtins.getEnv "PRODUCTION" == "1";

  baseConfig = {
    buildTheme = true;
    frontendUrl = "https://bsky.app";
  };

  devConfig = baseConfig // {
    enable = !isProduction;
    theme = "default";
    virtualHost = "dash-dev.local";
    pdsUrl = "http://localhost:3000";
    maxPosts = 10;
    footerText = "Development Dashboard";
  };

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
# Development
sudo nixos-rebuild switch

# Production
PRODUCTION=1 sudo nixos-rebuild switch
```

---

### Example 7: Parameterized Configuration

**File**: `/etc/nixos/pds-dash-config.nix`

```nix
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
  acmeHost = builtins.elemAt (builtins.split "\\." host) 0;
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
    pds-dash-dev = mkDashboard {
      theme = "default";
      host = "dash-dev.internal";
      pdsUrl = "http://pds-dev:3000";
      maxPosts = 10;
    };

    pds-dash-staging = mkDashboard {
      theme = "express";
      host = "dash-staging.example.com";
      pdsUrl = "https://pds-staging.example.com";
      maxPosts = 20;
    };

    pds-dash-prod = mkDashboard {
      theme = "sunset";
      host = "dashboard.example.com";
      pdsUrl = "https://pds.example.com";
      maxPosts = 50;
    };
  };
}
```

---

## Available Themes

### Default Theme
- **Colors**: Indigo, white, light gray
- **Style**: Clean, modern interface
- **Best for**: General use, professional deployments
- **Usage**: `theme = "default"`

### Express Theme
- **Colors**: Blue, white, dark gray
- **Style**: Sleek, minimalist design with smooth transitions
- **Best for**: Modern, streamlined dashboards
- **Usage**: `theme = "express"`

### Sunset Theme
- **Colors**: Warm oranges, golden, light backgrounds
- **Style**: Warm, inviting design
- **Best for**: Friendly, approachable dashboards
- **Usage**: `theme = "sunset"`

### Witchcraft Theme
- **Colors**: Purple, dark backgrounds, neon accents
- **Style**: Dark, sophisticated design
- **Best for**: Dark mode users, aesthetic customization
- **Usage**: `theme = "witchcraft"`

---

## Configuration Reference

### Build Control Options

```nix
buildTheme = mkOption {
  type = types.bool;
  default = false;
  description = ''
    Build pds-dash with theme and configuration at build time.
    When true, all settings are baked into the package.
    When false, uses pre-built package (faster but less customization).
  '';
};

theme = mkOption {
  type = types.enum [ "default" "express" "sunset" "witchcraft" ];
  default = "default";
  description = "Theme to build into dashboard (if buildTheme=true).";
};
```

### Dashboard Configuration

```nix
pdsUrl = mkOption {
  type = types.str;
  default = "http://127.0.0.1:3000";
  description = "URL of the PDS instance to monitor.";
};

frontendUrl = mkOption {
  type = types.str;
  default = "https://bsky.app";
  description = "Frontend URL for feed/post links.";
};

maxPosts = mkOption {
  type = types.int;
  default = 20;
  description = "Maximum posts to fetch per API request.";
};

footerText = mkOption {
  type = types.str;
  default = "Source links...";
  description = "HTML footer text (supports HTML formatting).";
};

showFuturePosts = mkOption {
  type = types.bool;
  default = false;
  description = "Show posts with future timestamps.";
};
```

### SSL/Security Options

```nix
enableSSL = mkOption {
  type = types.bool;
  default = false;
  description = "Enable HTTPS for the dashboard.";
};

acmeHost = mkOption {
  type = types.nullOr types.str;
  default = null;
  description = "Domain for Let's Encrypt certificate.";
};
```

---

## Building and Rebuilding

### Initial Build

When `buildTheme = true`, NixOS builds the themed dashboard during rebuild:

```bash
sudo nixos-rebuild switch
```

This creates a themed pds-dash package with all settings baked in (~2-5 minutes).

### Rebuilding After Changes

Change the theme or configuration and rebuild:

```nix
services.witchcraft-systems.pds-dash.theme = "witchcraft";
```

```bash
sudo nixos-rebuild switch
```

### Using Pre-built Package

For faster rebuilds without theme building:

```nix
services.witchcraft-systems.pds-dash = {
  enable = true;
  buildTheme = false;  # Use pre-built
  pdsUrl = "http://pds.example.com:3000";
  virtualHost = "dash.example.com";
};
```

**Note**: Configuration changes won't affect pre-built packages. Enable `buildTheme = true` for changes to take effect.

---

## Troubleshooting

### Dashboard Not Loading

**Symptom**: Browser shows blank page or 404

**Solutions**:
```bash
# Check nginx
systemctl status nginx

# Verify PDS connectivity
curl http://pds.example.com:3000/health

# View logs
journalctl -u nginx -f
```

### Theme Not Applied

**Symptom**: Dashboard uses wrong theme

**Solutions**:
1. Verify `buildTheme = true` is set
2. Check theme name is correct: default, express, sunset, witchcraft
3. Rebuild: `sudo nixos-rebuild switch`
4. Check build: `nix path-info /run/current-system | grep pds-dash`

### Slow Dashboard

**Symptom**: Dashboard slow to load/respond

**Solutions**:
1. Lower `maxPosts = 10` (reduces data load)
2. Check PDS response time
3. Monitor nginx: `systemctl status nginx`
4. Check resources: `free -h`, `df -h`

### SSL Certificate Issues

**Symptom**: HTTPS not working or certificate errors

**Solutions**:
1. Verify `acmeHost` matches domain
2. Ensure `security.acme.acceptTerms = true`
3. View certificate: `sudo ls -la /var/lib/acme/`
4. Test nginx: `sudo nginx -t`

---

## Performance Considerations

### Build Time
- First build: +2-5 minutes (Deno + Vite)
- Subsequent builds: Cached unless theme/config changes
- Pre-built package: No build time

### Runtime Performance
- **Theme**: No runtime impact (compiled into CSS)
- **Config**: No runtime impact (compiled into JavaScript)
- **Network**: Dashboard makes requests to configured PDS

### Storage
- Per-theme package: ~7 MB
- Multiple themes: 7 MB each (independent builds)

---

## Integration with Other Services

### With Nginx Reverse Proxy

```nix
services.nginx.virtualHosts."example.com" = {
  locations."/dashboard" = {
    proxyPass = "http://dash.internal.example.com";
  };
};

services.witchcraft-systems.pds-dash = {
  enable = true;
  buildTheme = true;
  theme = "sunset";
  virtualHost = "dash.internal.example.com";
};
```

### With Let's Encrypt / ACME

```nix
security.acme = {
  acceptTerms = true;
  defaults.email = "admin@example.com";
};

services.witchcraft-systems.pds-dash = {
  enable = true;
  buildTheme = true;
  theme = "sunset";
  virtualHost = "dash.example.com";
  enableSSL = true;
  acmeHost = "example.com";
};
```

---

## Production Deployment Checklist

Before deploying to production:

- [ ] DNS records configured and pointing to server
- [ ] `security.acme.acceptTerms = true` set
- [ ] ACME email address configured
- [ ] Firewall allows ports 80 and 443
- [ ] `enableSSL = true` and `acmeHost` set correctly
- [ ] `pdsUrl` points to real PDS instance
- [ ] Theme selection matches branding
- [ ] Custom footer text added (if desired)
- [ ] Tested dashboard at HTTPS domain
- [ ] Certificate auto-renewal configured
- [ ] Backups of configuration in place
- [ ] Monitoring/alerting set up
- [ ] Nginx test passes: `sudo nginx -t`

---

## Architecture Overview

```
Build Process:
  Theme selection (default/express/sunset/witchcraft)
    ↓
  Generate config.ts with user settings
    ↓
  Deno + Vite build
    ↓
  Themed HTML/CSS/JS bundle
    ↓
  Static files ready to serve

Runtime:
  User Browser
    ↓
  HTTPS (Let's Encrypt)
    ↓
  Nginx (serves static files)
    ↓
  Proxies /xrpc to PDS instance
    ↓
  PDS Services
```

---

## Implementation Details

### Build-Time Configuration

All settings are compiled into the package:
1. Select theme (e.g., "sunset")
2. Load theme.css from themes/sunset/
3. Vite plugin replaces app.css with theme.css
4. Build produces themed CSS bundle
5. Package includes themed styles

**Result**: Theme CSS is completely integrated, no dynamic switching.

### Nginx Configuration

Automatic nginx setup:
- `/` → Serve static files from pds-dash package
- `/xrpc` → Proxy to PDS instance
- SPA routing → index.html for client-side routing
- HTTPS → Automatic ACME certificates

---

## Support Resources

### In This Repository
- `modules/witchcraft-systems/pds-dash.nix` - Module code
- `pkgs/witchcraft-systems/pds-dash-themed.nix` - Builder code
- `lib/pds-dash.nix` - Library code

### External Resources
- pds-dash: https://git.witchcraft.systems/scientific-witchery/pds-dash
- NixOS: https://nixos.org
- Nginx: https://nginx.org
- Let's Encrypt: https://letsencrypt.org

---

**Documentation Created**: November 4, 2025
**Last Updated**: November 11, 2025
**Status**: ✅ Complete and production-ready
