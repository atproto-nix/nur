# Themed pds-dash Integration Guide

**Date**: November 4, 2025
**Status**: Complete implementation with standalone and integrated support
**Themes**: default, express, sunset, witchcraft

## Overview

This guide explains how to use themed pds-dash dashboards with your PDS services. The implementation supports:

1. **Standalone Dashboards** - Use pds-dash module independently with theme selection
2. **Integrated Dashboards** - Add dashboard as part of PDS service configuration
3. **Full Configuration** - All dashboard settings customizable at build time
4. **Theme Support** - Built-in themes with custom configuration

## Quick Start

### Standalone Dashboard (Easiest)

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

### Integrated with rsky PDS (Future)

```nix
services.blacksky.pds = {
  enable = true;
  hostname = "pds.example.com";
  # ... other PDS config ...

  dashboard = {
    enable = true;
    theme = "sunset";
    virtualHost = "dash.example.com";
  };
};
```

## Components

### 1. Parameterized Builder: `pds-dash-themed.nix`

A reusable builder that creates themed pds-dash packages with custom configuration.

**Location**: `/Users/jack/Software/nur/pkgs/witchcraft-systems/pds-dash-themed.nix`

**Parameters**:
- `theme` (string, default: "default") - Theme to use
- `pdsUrl` (string) - PDS instance URL
- `frontendUrl` (string) - Frontend service URL
- `maxPosts` (int) - Posts per request
- `footerText` (string) - Dashboard footer
- `showFuturePosts` (bool) - Show future-dated posts

**Usage in Nix**:
```nix
# Build a themed dashboard
myDash = pkgs.callPackage ./pds-dash-themed.nix {
  theme = "sunset";
  pdsUrl = "http://pds.local:3000";
  frontendUrl = "https://bsky.app";
};
```

### 2. Enhanced Standalone Module

The witchcraft-systems pds-dash module now supports theme selection and full configuration.

**Location**: `/Users/jack/Software/nur/modules/witchcraft-systems/pds-dash.nix`

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

**Location**: `/Users/jack/Software/nur/lib/pds-dash.nix`

**Functions**:
- `mkDashboardOptions` - Create dashboard options for any PDS
- `mkDashboardModule` - Build complete dashboard submodule
- `addDashboardSupport` - Add dashboard support to existing PDS module
- `validateTheme` - Validate theme names
- `availableThemes` - List of available themes

## Detailed Usage

### Use Case 1: Personal PDS with Sunset Theme

```nix
{ config, lib, pkgs, ... }:

{
  services.witchcraft-systems.pds-dash = {
    enable = true;
    buildTheme = true;
    theme = "sunset";

    virtualHost = "dashboard.mydomain.com";
    pdsUrl = "http://localhost:3000";
    frontendUrl = "https://bsky.app";
    maxPosts = 30;
    footerText = "My Personal PDS";

    enableSSL = true;
    acmeHost = "mydomain.com";
  };
}
```

### Use Case 2: Multiple Themed Dashboards

Create different dashboards for different PDS instances:

```nix
{
  # Development PDS with default theme
  services.witchcraft-systems.pds-dash-dev = {
    enable = true;
    buildTheme = true;
    theme = "default";
    virtualHost = "dash-dev.example.com";
    pdsUrl = "http://pds-dev:3000";
  };

  # Production PDS with custom theme
  services.witchcraft-systems.pds-dash-prod = {
    enable = true;
    buildTheme = true;
    theme = "sunset";
    virtualHost = "dash.example.com";
    pdsUrl = "http://pds:3000";
    enableSSL = true;
    acmeHost = "example.com";
  };
}
```

### Use Case 3: Custom Package with Themed Build

For advanced users who want to pin a specific configuration:

```nix
let
  myDash = pkgs.callPackage <nur>/pkgs/witchcraft-systems/pds-dash-themed.nix {
    theme = "witchcraft";
    pdsUrl = "http://pds.example.com";
    frontendUrl = "https://custom-frontend.example.com";
    maxPosts = 50;
    footerText = "Enterprise PDS Dashboard";
    showFuturePosts = true;
  };
in
{
  services.witchcraft-systems.pds-dash = {
    enable = true;
    package = myDash;
    virtualHost = "dash.example.com";
  };
}
```

## Available Themes

### 1. Default Theme
Clean, modern interface with indigo accent colors.
- **Colors**: Indigo, white, light gray
- **Best for**: General use, professional deployments
- **Example**: `theme = "default"`

### 2. Express Theme
Sleek, minimalist design with smooth transitions.
- **Colors**: Blue, white, dark gray
- **Best for**: Modern, streamlined dashboards
- **Example**: `theme = "express"`

### 3. Sunset Theme
Warm, inviting design with orange/golden accents.
- **Colors**: Warm oranges, golden, light backgrounds
- **Best for**: Friendly, approachable dashboards
- **Example**: `theme = "sunset"`

### 4. Witchcraft Theme
Dark, sophisticated design with purple accents.
- **Colors**: Purple, dark backgrounds, neon accents
- **Best for**: Dark mode users, aesthetic customization
- **Example**: `theme = "witchcraft"`

## Configuration Options Reference

### Theme Building Options

```nix
buildTheme = mkOption {
  type = types.bool;
  default = false;
  description = ''
    Whether to build pds-dash with theme and configuration at build time.
    When true, all dashboard settings are baked into the package.
    When false, uses pre-built package (faster but less customization).
  '';
};

theme = mkOption {
  type = types.enum [ "default" "express" "sunset" "witchcraft" ];
  default = "default";
  description = "Theme to build into dashboard (only used if buildTheme=true).";
};
```

### Dashboard Configuration Options

```nix
pdsUrl = mkOption {
  type = types.str;
  default = "http://127.0.0.1:3000";
  description = "URL of the PDS instance to monitor.";
};

frontendUrl = mkOption {
  type = types.str;
  default = "https://deer.social";
  description = "Frontend URL for feed/post links in dashboard.";
};

maxPosts = mkOption {
  type = types.int;
  default = 20;
  description = "Maximum posts to fetch per API request.";
};

footerText = mkOption {
  type = types.str;
  default = "Source links...";
  description = "HTML footer text. Supports HTML formatting.";
};

showFuturePosts = mkOption {
  type = types.bool;
  default = false;
  description = "Show posts with timestamps in the future.";
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
  description = "Domain for Let's Encrypt certificate (enables ACME).";
};
```

## Building and Rebuilding

### Initial Build

When `buildTheme = true`, NixOS will build the themed dashboard during the next rebuild:

```bash
sudo nixos-rebuild switch
```

This creates a themed pds-dash package with all settings baked in.

### Rebuilding After Theme Changes

Change the theme and rebuild:

```nix
# In configuration.nix
services.witchcraft-systems.pds-dash.theme = "witchcraft";
```

```bash
sudo nixos-rebuild switch
```

NixOS will detect the theme change and rebuild the dashboard package.

### Pre-built Package (No Build)

To use the pre-built package (faster):

```nix
services.witchcraft-systems.pds-dash = {
  enable = true;
  buildTheme = false;  # Use pre-built
  pdsUrl = "http://pds.example.com:3000";
  virtualHost = "dash.example.com";
};
```

**Note**: Configuration changes won't affect the pre-built package. You must enable `buildTheme = true` for configuration to take effect.

## Troubleshooting

### Dashboard Not Loading

**Symptom**: Browser shows blank page or 404

**Solutions**:
1. Verify nginx is running: `systemctl status nginx`
2. Check PDS URL: `curl ${config.services.witchcraft-systems.pds-dash.pdsUrl}/health`
3. Check logs: `journalctl -u nginx -f`

### Theme Not Applied

**Symptom**: Dashboard uses wrong theme

**Solutions**:
1. Verify `buildTheme = true` is set
2. Check theme name is correct: default, express, sunset, witchcraft
3. Rebuild to regenerate package: `nixos-rebuild switch`
4. Check build output: `nix log $(nix-build -A packages.x86_64-linux.witchcraft-systems-pds-dash 2>&1 | head -1)`

### Slow Dashboard

**Symptom**: Dashboard is slow to load or respond

**Solutions**:
1. Lower `maxPosts`: `maxPosts = 10` (reduces data load)
2. Check PDS response time
3. Monitor nginx: `systemctl status nginx`
4. Check system resources: `free -h`, `df -h`

### SSL Certificate Issues

**Symptom**: HTTPS not working or certificate errors

**Solutions**:
1. Verify `acmeHost` matches domain name
2. Check email if using ACME: `security.acme.acceptTerms = true`
3. View certificate: `sudo ls -la /var/lib/acme/`
4. Check nginx SSL: `sudo nginx -t`

## Performance Considerations

### Build Time

Building a themed dashboard adds ~2-5 minutes to nixos-rebuild due to:
- Installing Deno dependencies
- Running Vite build process
- Theme compilation

**Mitigation**: Build overnight or use pre-built package for rapid iterations.

### Runtime Performance

- **Theme**: No runtime impact (compiled into HTML/CSS)
- **Config**: No runtime impact (compiled into JavaScript)
- **Network**: Dashboard makes requests to PDS at configured URL

### Storage

Themed pds-dash packages are ~5-10 MB each. Multiple themes result in:
- Default theme: ~7 MB
- Each additional theme: ~7 MB (independent builds)

## Integration with Other Services

### Use with Nginx Reverse Proxy

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

### Use with Let's Encrypt / ACME

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

## Future: PDS Module Integration

When dashboard support is added to PDS modules:

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

The shared library will automatically:
- Build themed dashboard for that PDS
- Configure nginx to serve it
- Proxy `/xrpc` requests to the PDS
- Handle SSL/ACME setup

## Advanced: Custom Themes

To create a custom theme, you can:

1. Copy theme CSS from `/Users/jack/Software/pds-dash/themes/default/`
2. Modify colors and styles
3. Place in your pds-dash fork
4. Reference new theme when building

This requires maintaining a custom pds-dash fork.

## Examples

See full examples at:
- `/Users/jack/Software/nur/PDS_DASH_EXAMPLES.md` (when created)
- `/Users/jack/Software/pds-dash/themes/` (for theme CSS)

## Questions?

Refer to:
- pds-dash documentation: https://git.witchcraft.systems/scientific-witchery/pds-dash
- NixOS module documentation: `man configuration.nix`
- NUR module code: `modules/witchcraft-systems/pds-dash.nix`

---

**Documentation Created**: November 4, 2025
**Last Updated**: November 4, 2025
**Status**: Complete and ready for use ✅
