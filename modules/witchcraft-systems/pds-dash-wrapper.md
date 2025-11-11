# pds-dash Auto-Wrapper for nixpkgs bluesky-pds

This module automatically configures pds-dash to monitor a nixpkgs `services.bluesky.pds` instance. It detects PDS settings and configures the dashboard with sensible defaults.

## Features

- Automatic PDS URL detection from `services.bluesky.pds` settings
- Automatic hostname configuration (dash.{PDS_HOSTNAME})
- Automatic SSL/ACME setup matching PDS configuration
- Zero-configuration monitoring for standard PDS deployments

## Quick Start

### Minimal Configuration

```nix
{
  # Enable nixpkgs bluesky PDS
  services.bluesky.pds = {
    enable = true;
    settings = {
      PDS_HOSTNAME = "pds.example.com";
      PDS_PORT = 3000;
    };
  };

  # Enable pds-dash monitoring (that's it!)
  services.witchcraft-systems.pds-dash-auto.enable = true;
  # Dashboard will be available at dash.pds.example.com
}
```

This automatically:
- Serves pds-dash at `dash.pds.example.com`
- Proxies to PDS at `http://127.0.0.1:3000`
- Enables SSL with ACME (since PDS_HOSTNAME != localhost)

### Localhost Development

```nix
{
  services.bluesky.pds = {
    enable = true;
    settings.PDS_HOSTNAME = "localhost";
  };

  services.witchcraft-systems.pds-dash-auto.enable = true;
  # Dashboard at http://dash.localhost (no SSL)
}
```

## Configuration Options

### `enable`
**Type:** `boolean`
**Default:** `false`

Enable automatic pds-dash configuration for nixpkgs bluesky-pds.

### `dashHostname`
**Type:** `string`
**Default:** `"dash.${config.services.bluesky.pds.settings.PDS_HOSTNAME}"`

Hostname to serve pds-dash on. Automatically prefixes PDS hostname with "dash.".

**Example:**
```nix
services.witchcraft-systems.pds-dash-auto.dashHostname = "monitor.example.com";
```

### `enableSSL`
**Type:** `boolean`
**Default:** `true` if PDS_HOSTNAME is not localhost

Whether to enable SSL for the dashboard.

### `useACME`
**Type:** `boolean`
**Default:** same as `enableSSL`

Whether to use ACME for SSL certificate generation.

## Advanced Examples

### Custom Dashboard Hostname

```nix
{
  services.bluesky.pds = {
    enable = true;
    settings.PDS_HOSTNAME = "pds.example.com";
  };

  services.witchcraft-systems.pds-dash-auto = {
    enable = true;
    dashHostname = "admin.example.com";  # Custom hostname
  };
}
```

### Manual SSL Certificates

```nix
{
  services.bluesky.pds = {
    enable = true;
    settings.PDS_HOSTNAME = "pds.example.com";
  };

  services.witchcraft-systems.pds-dash-auto = {
    enable = true;
    enableSSL = true;
    useACME = false;  # Don't use ACME
  };

  # Configure manual SSL in the underlying pds-dash module
  services.witchcraft-systems.pds-dash = {
    sslCertificate = "/path/to/cert.pem";
    sslCertificateKey = "/path/to/key.pem";
  };
}
```

### Distributed PDS Setup

If your PDS runs on a different machine:

```nix
{
  services.bluesky.pds = {
    enable = true;
    settings = {
      PDS_HOSTNAME = "pds.example.com";
      PDS_PORT = 3000;
    };
  };

  services.witchcraft-systems.pds-dash-auto = {
    enable = true;
    # Auto-wrapper will connect to http://pds.example.com:3000
  };

  # Override if PDS is actually on another internal address
  services.witchcraft-systems.pds-dash.pdsUrl = "http://10.0.0.5:3000";
}
```

### Additional nginx Configuration

```nix
{
  services.bluesky.pds.enable = true;
  services.witchcraft-systems.pds-dash-auto.enable = true;

  # Add extra nginx config
  services.witchcraft-systems.pds-dash.extraNginxConfig = ''
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=dash:10m rate=10r/s;
    limit_req zone=dash burst=20;

    # Security headers
    add_header X-Frame-Options "DENY";
    add_header X-Content-Type-Options "nosniff";
    add_header Referrer-Policy "no-referrer";
  '';
}
```

## How It Works

The auto-wrapper module:

1. **Detects** when `services.bluesky.pds` is enabled
2. **Reads** PDS_HOSTNAME and PDS_PORT from PDS settings
3. **Configures** pds-dash with:
   - Virtual host: `dash.${PDS_HOSTNAME}`
   - PDS URL: Auto-detected from settings
   - SSL: Enabled if PDS_HOSTNAME != localhost
   - ACME: Uses same domain as PDS

4. **Proxies** dashboard requests to PDS via nginx

## Comparison with Manual Configuration

### Auto-Wrapper (Recommended)
```nix
services.bluesky.pds.enable = true;
services.witchcraft-systems.pds-dash-auto.enable = true;
```

### Manual Configuration
```nix
services.bluesky.pds = {
  enable = true;
  settings = {
    PDS_HOSTNAME = "pds.example.com";
    PDS_PORT = 3000;
  };
};

services.witchcraft-systems.pds-dash = {
  enable = true;
  virtualHost = "dash.pds.example.com";
  pdsUrl = "http://127.0.0.1:3000";
  enableSSL = true;
  acmeHost = "pds.example.com";
};
```

Use auto-wrapper for convenience; use manual config for full control.

## Troubleshooting

### "Dashboard cannot connect to PDS"

Check:
```bash
# Verify PDS is running
systemctl status bluesky-pds

# Check PDS port
netstat -tlnp | grep 3000

# Test PDS directly
curl http://localhost:3000/xrpc/_health
```

### "services.witchcraft-systems.pds-dash-auto requires services.bluesky.pds to be enabled"

The auto-wrapper only works with nixpkgs bluesky-pds. For other PDS implementations (blacksky, etc.), use the manual `pds-dash` module instead.

### DNS not resolving for dash.{hostname}

Ensure your DNS has a record for the dashboard hostname:
```bash
dig dash.pds.example.com
```

Add an A/AAAA record pointing to your server IP.

## See Also

- [pds-dash module](./pds-dash.md) - Manual configuration
- [nixpkgs bluesky-pds](https://search.nixos.org/options?query=services.bluesky.pds)
- [pds-dash repository](https://git.witchcraft.systems/scientific-witchery/pds-dash)
