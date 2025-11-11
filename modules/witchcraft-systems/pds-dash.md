# pds-dash NixOS Module

This module provides easy deployment of [pds-dash](https://git.witchcraft.systems/scientific-witchery/pds-dash), a web-based monitoring dashboard for ATProto PDS instances.

## Features

- Serves static pds-dash frontend via nginx
- Automatic proxy configuration to your PDS instance
- Optional SSL/TLS with ACME or manual certificates
- SPA routing support
- WebSocket proxy support for real-time updates

## Basic Usage

```nix
{
  services.witchcraft-systems.pds-dash = {
    enable = true;
    virtualHost = "dash.example.com";
    pdsUrl = "http://localhost:3000";
  };
}
```

## With SSL (ACME)

```nix
{
  services.witchcraft-systems.pds-dash = {
    enable = true;
    virtualHost = "dash.example.com";
    pdsUrl = "http://localhost:3000";
    enableSSL = true;
    acmeHost = "example.com";
  };

  # Ensure ACME is configured
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "admin@example.com";
}
```

## With Blacksky PDS

```nix
{
  # Run blacksky PDS
  services.blacksky.pds = {
    enable = true;
    hostname = "pds.example.com";
    port = 3000;
  };

  # Monitor with pds-dash
  services.witchcraft-systems.pds-dash = {
    enable = true;
    virtualHost = "dash.example.com";
    pdsUrl = "http://127.0.0.1:3000";
  };
}
```

## Configuration Options

### `enable`
**Type:** `boolean`
**Default:** `false`
Enable the pds-dash service.

### `package`
**Type:** `package`
**Default:** `pkgs.witchcraft-systems-pds-dash`
The pds-dash package to use.

### `virtualHost`
**Type:** `string`
**Default:** `"dash.localhost"`
The nginx virtual host to serve pds-dash on.

### `pdsUrl`
**Type:** `string`
**Default:** `"http://127.0.0.1:3000"`
The URL of the PDS instance to monitor.

### `enableSSL`
**Type:** `boolean`
**Default:** `false`
Whether to enable SSL for the pds-dash virtual host.

### `sslCertificate`
**Type:** `null or path`
**Default:** `null`
Path to SSL certificate file (manual SSL configuration).

### `sslCertificateKey`
**Type:** `null or path`
**Default:** `null`
Path to SSL certificate key file (manual SSL configuration).

### `acmeHost`
**Type:** `null or string`
**Default:** `null`
ACME host to use for automatic SSL certificate generation.

### `extraNginxConfig`
**Type:** `string`
**Default:** `""`
Additional nginx configuration for the virtual host.

## Examples

### Multiple PDS Instances

Monitor multiple PDS instances with separate dashboards:

```nix
{
  services.witchcraft-systems.pds-dash = {
    enable = true;
    virtualHost = "dash1.example.com";
    pdsUrl = "http://pds1:3000";
  };

  # Create another instance manually with nginx
  services.nginx.virtualHosts."dash2.example.com" = {
    locations."/" = {
      root = pkgs.witchcraft-systems-pds-dash;
      index = "index.html";
      tryFiles = "$uri $uri/ /index.html";
    };
    locations."/xrpc/" = {
      proxyPass = "http://pds2:3000";
      proxyWebsockets = true;
    };
  };
}
```

### Custom Nginx Configuration

```nix
{
  services.witchcraft-systems.pds-dash = {
    enable = true;
    virtualHost = "dash.example.com";
    pdsUrl = "http://localhost:3000";

    extraNginxConfig = ''
      # Rate limiting
      limit_req_zone $binary_remote_addr zone=dash:10m rate=10r/s;
      limit_req zone=dash burst=20;

      # Custom headers
      add_header X-Frame-Options "SAMEORIGIN";
      add_header X-Content-Type-Options "nosniff";
    '';
  };
}
```

## Troubleshooting

### Dashboard shows "Cannot connect to PDS"

Check that:
1. PDS is running: `systemctl status your-pds-service`
2. PDS URL is correct in configuration
3. Firewall allows connection from nginx to PDS
4. PDS is listening on the specified port: `netstat -tlnp | grep 3000`

### SSL certificate errors

If using ACME, ensure:
1. DNS points to your server
2. Port 80/443 are open
3. ACME terms are accepted: `security.acme.acceptTerms = true`
4. Email is configured: `security.acme.defaults.email = "..."`

### Nginx fails to start

Check nginx configuration:
```bash
nginx -t
journalctl -u nginx -n 50
```

## See Also

- [pds-dash repository](https://git.witchcraft.systems/scientific-witchery/pds-dash)
- [Blacksky PDS module](../blacksky/rsky/pds.nix)
- [nginx documentation](https://nixos.org/manual/nixos/stable/index.html#module-services-nginx)
