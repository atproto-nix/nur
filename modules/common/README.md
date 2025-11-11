# Common NixOS Modules

This directory contains reusable NixOS modules that can be used across different services and applications.

## Modules

### static-site-deploy.nix

A module for deploying static websites from Nix packages to web directories.

#### Features

- Simple declarative configuration for static site deployment
- Automatic file synchronization using rsync
- Configurable ownership and permissions
- Service reload/restart hooks after deployment
- Systemd integration with proper ordering

#### Usage Example

```nix
services.static-site-deploy.sites.my-app = {
  enable = true;
  package = pkgs.my-static-app;
  sourceDir = "share/my-app";
  targetDir = "/var/www/example.com/my-app";
  user = "caddy";
  group = "caddy";
  before = [ "caddy.service" ];
  reloadServices = [ "caddy.service" ];
};
```

#### Options

- `enable` - Enable deployment of this site
- `package` - The Nix package containing the static files
- `sourceDir` - Subdirectory within the package (default: `share/{name}`)
- `targetDir` - Where to deploy the files
- `user` - Owner of deployed files (default: `root`)
- `group` - Group of deployed files (default: `root`)
- `before` - Systemd services this should run before
- `after` - Systemd services this should run after (default: `["network.target"]`)
- `wantedBy` - Systemd targets (default: `["multi-user.target"]`)
- `reloadServices` - Services to reload after deployment
- `restartServices` - Services to restart after deployment

#### Real-World Example

Red Dwarf deployment at `/etc/nixos/configuration.nix`:

```nix
services.static-site-deploy.sites.red-dwarf = {
  enable = true;
  package = pkgs.whey-party-red-dwarf;
  sourceDir = "share/red-dwarf";
  targetDir = "/var/www/snek.cc/red-dwarf";
  user = "caddy";
  group = "caddy";
  before = [ "caddy.service" ];
  reloadServices = [ "caddy.service" ];
};
```

This creates a systemd service `deploy-red-dwarf.service` that:
1. Copies files from the Nix store to `/var/www/snek.cc/red-dwarf/`
2. Sets ownership to `caddy:caddy`
3. Runs before Caddy starts
4. Reloads Caddy after deployment

### nixos-integration.nix

Common integration utilities for NixOS services.
