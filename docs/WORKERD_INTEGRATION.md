# Cloudflare workerd Integration for Tangled Avatar Service

## Overview

This document outlines the integration of Cloudflare's `workerd` runtime with the Tangled avatar service for complete self-hosting without relying on external Cloudflare infrastructure.

## Architecture

### Current State
- Avatar service is a Cloudflare Worker (JavaScript/WASM runtime)
- Packaged with Node.js wrangler wrapper
- Requires `wrangler dev` to run locally

### Target State  
- Avatar runs on native `workerd` runtime
- No Node.js/wrangler overhead
- Full self-hosting with open-source Cloudflare runtime
- Better resource efficiency and maintainability

## Implementation Status

### ✅ Completed
- Created `/pkgs/workerd/workerd.nix` - Package definition for workerd binary
- Created `/pkgs/workerd/default.nix` - Organization metadata wrapper
- Version pinned: `1.20251106.1` (latest stable)

### 🔄 In Progress  
- Getting hash values for all platforms
- Creating avatar.nix update to use workerd
- Creating NixOS modules for workerd integration

### 📋 TODO

#### 1. Calculate workerd hashes for all platforms

Run these commands to get the correct hashes:

```bash
# darwin-arm64 (macOS ARM/M1/M2)
nix-prefetch-url "https://registry.npmjs.org/@cloudflare/workerd-darwin-arm64/-/workerd-darwin-arm64-1.20251106.1.tgz"

# darwin-64 (macOS Intel)
nix-prefetch-url "https://registry.npmjs.org/@cloudflare/workerd-darwin-64/-/workerd-darwin-64-1.20251106.1.tgz"

# linux-64 (Linux x86_64)
nix-prefetch-url "https://registry.npmjs.org/@cloudflare/workerd-linux-64/-/workerd-linux-64-1.20251106.1.tgz"

# linux-arm64 (Linux ARM)
nix-prefetch-url "https://registry.npmjs.org/@cloudflare/workerd-linux-arm64/-/workerd-linux-arm64-1.20251106.1.tgz"
```

Convert base32 output to sha256 using:
```bash
nix hash convert --from base32 --to base32 <base32-output>  # or to other formats
```

Update `pkgs/workerd/workerd.nix` hashes with results.

#### 2. Update avatar package to use workerd

Create new `pkgs/tangled/avatar-workerd.nix` or update `avatar.nix`:

```nix
{ lib
, buildNpmPackage  
, fetchFromTangled
, workerd
, nodejs
, makeWrapper
}:

let
  src = fetchFromTangled { ... };
in
buildNpmPackage rec {
  pname = "tangled-avatar";
  version = "0.1.0";

  inherit src;
  sourceRoot = "${src.name}/avatar";

  npmDepsHash = "sha256-...";

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ workerd ];

  # Install phase installs to bin/avatar
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -r . $out/lib/avatar
    
    # Create wrapper script that runs workerd
    makeWrapper ${workerd}/bin/workerd $out/bin/avatar \
      --add-flags "serve" \
      --add-flags "$out/lib/avatar/wrangler.jsonc" \
      --chdir "$out/lib/avatar"
    
    runHook postInstall
  '';
};
```

#### 3. Create generic workerd NixOS module

Create `modules/workerd/workerd.nix`:

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.workerd;
in
{
  options.services.workerd = {
    enable = mkEnableOption "Cloudflare workerd runtime";
    
    workers = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "this worker";
          script = mkOption {
            type = types.path;
            description = "Path to worker script (JS file)";
          };
          config = mkOption {
            type = types.path;
            description = "Path to wrangler.jsonc configuration";
          };
          environment = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Environment variables for worker";
          };
          environmentFile = mkOption {
            type = with types; nullOr path;
            default = null;
            description = "Environment file for secrets";
          };
          port = mkOption {
            type = types.port;
            description = "Port to listen on";
          };
        };
      });
      default = {};
    };
  };

  config = mkIf cfg.enable {
    # Create systemd services for each enabled worker
    systemd.services = lib.mapAttrs' (name: wcfg:
      lib.nameValuePair "workerd-${name}" (mkIf wcfg.enable {
        description = "Cloudflare workerd - ${name}";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.workerd}/bin/workerd serve ${wcfg.config}";
          
          EnvironmentFile = mkIf (wcfg.environmentFile != null) wcfg.environmentFile;
          Environment = lib.mapAttrsToList (k: v: "${k}=${v}") wcfg.environment;
          
          Restart = "always";
          RestartSec = "10s";
        };
      })
    ) cfg.workers;
  };
}
```

#### 4. Update tangled avatar module to use workerd

Update `modules/tangled/avatar.nix` to:
- Use workerd service instead of wrangler
- Configure proper environment variables
- Handle shared secret files

#### 5. Create workerd configuration for avatar

Create `pkgs/tangled/avatar-worker.toml` or similar TOML config file to configure the avatar worker with:
- Worker name
- Script path
- Bindings (environment variables)
- HTTP server configuration
- Port settings

## Testing

Once implemented:

```bash
# Build workerd package
nix build .#workerd

# Build avatar with workerd
nix build .#tangled-avatar

# Test avatar service
nixos-rebuild test --flake .#hostname

# Check service status
systemctl status tangled-avatar

# Test avatar endpoint
curl -H "AVATAR_SHARED_SECRET: test-secret" http://localhost:8787/
```

## Benefits

✅ **True Self-Hosting**: No external Cloudflare dependency  
✅ **Open Source**: Uses Cloudflare's open-source workerd runtime  
✅ **Performance**: Native binary runtime, no Node.js overhead  
✅ **Compatibility**: Same runtime as Cloudflare Workers  
✅ **Maintainability**: Cleaner dependency tree  
✅ **Cost**: Eliminates any potential cloud costs  

## References

- [workerd GitHub](https://github.com/cloudflare/workerd)
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Tangled Avatar Service](https://github.com/tangled-org/core/tree/main/avatar)

## Notes

- workerd binaries are distributed via npm for easier cross-platform packaging
- The avatar service source uses standard Cloudflare Worker APIs
- Configuration via wrangler.jsonc is compatible with workerd
- No code changes needed in avatar service - only runtime wrapper changes

