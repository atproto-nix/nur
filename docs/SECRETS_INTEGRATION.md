# Secrets Management Integration Guide

This guide explains how the ATProto NUR implements pluggable secrets management, allowing users to choose their preferred secrets backend (sops-nix, agenix, Vault, custom) while maintaining a consistent module API.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    NixOS Modules                         │
│  (tangled, microcosm, supabase, custom modules)         │
└────────────────┬────────────────────────────────────────┘
                 │ uses
                 ▼
┌─────────────────────────────────────────────────────────┐
│              Secrets Abstraction Layer                   │
│              (lib/secrets.nix)                           │
│  • declare()  • getPath()  • loadEnv()                  │
│  • getConfig() • Backend interface                      │
└────────────────┬────────────────────────────────────────┘
                 │ implements
                 ▼
┌──────────────────────────────────────────────────────────┐
│                  Backend Implementations                  │
│                                                           │
│  ┌─────────┐  ┌────────┐  ┌───────┐  ┌────────────┐   │
│  │ sops-nix│  │ agenix │  │ Vault │  │   Custom   │   │
│  │(default)│  │        │  │       │  │  (yours!)  │   │
│  └─────────┘  └────────┘  └───────┘  └────────────┘   │
└──────────────────────────────────────────────────────────┘
```

## Design Principles

1. **Backend Agnostic**: Modules don't know or care which secrets backend is used
2. **Zero Lock-in**: Users can switch backends without changing module code
3. **Gradual Adoption**: Can mix abstraction with traditional approaches
4. **Security First**: Secrets loaded at runtime, never at build time
5. **Type Safe**: Leverages Nix type system for validation

## For Module Authors

### Pattern 1: Simple Path-Based (Recommended for Most Modules)

This is the simplest approach and works with any backend:

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.myapp;
in
{
  options.services.myapp = {
    enable = mkEnableOption "MyApp";

    secrets = {
      database = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to database password file";
      };

      apiKey = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to API key file";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.myapp = {
      # Load secrets in startup script
      script = ''
        ${optionalString (cfg.secrets.database != null) ''
          export DB_PASSWORD=$(cat ${cfg.secrets.database})
        ''}
        ${optionalString (cfg.secrets.apiKey != null) ''
          export API_KEY=$(cat ${cfg.secrets.apiKey})
        ''}

        exec ${pkgs.myapp}/bin/myapp
      '';
    };
  };
}
```

**Pros:**
- Simple and explicit
- Works with any backend
- No library dependencies
- Easy to understand

**Cons:**
- Users must manually configure secrets
- No backend-specific features
- More boilerplate

### Pattern 2: Auto-Configuring with Backend Detection

Automatically configure secrets based on available backend:

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.myapp;

  # Import secrets library
  secretsLib = import ../lib/secrets.nix { inherit lib; };

  # Auto-detect backend
  secrets =
    if config.sops or null != null then
      secretsLib.withBackend (import ../lib/secrets/sops.nix { inherit lib config; })
    else if config.age or null != null then
      secretsLib.withBackend (import ../lib/secrets/agenix.nix { inherit lib config; })
    else
      secretsLib.withBackend secretsLib.nullBackend;

  # Declare secrets
  dbSecret = secrets.declare "myapp-db" {
    sopsFile = ./secrets.yaml;
    key = "myapp/database/password";
    owner = cfg.user;
  };

in
{
  options.services.myapp = {
    enable = mkEnableOption "MyApp";
    user = mkOption { type = types.str; default = "myapp"; };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      systemd.services.myapp = {
        script = ''
          ${secrets.loadEnv "DB_PASSWORD" dbSecret}
          exec ${pkgs.myapp}/bin/myapp
        '';
      };
    }

    # Backend-specific config (only if backend is active)
    (secrets.getConfig dbSecret)
  ]);
}
```

**Pros:**
- Zero user configuration for secrets
- Automatic backend integration
- First-class experience

**Cons:**
- Slightly more complex
- Requires secrets library
- Opinionated defaults

### Pattern 3: Hybrid Approach (Best of Both Worlds)

Combine auto-configuration with manual override:

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.myapp;

  secretsLib = import ../lib/secrets.nix { inherit lib; };

  # Auto-detect or use user-provided backend
  secrets = cfg.secretsBackend or (
    if config.sops or null != null then
      secretsLib.withBackend (import ../lib/secrets/sops.nix { inherit lib config; })
    else
      secretsLib.withBackend secretsLib.nullBackend
  );

  # Declare auto-configured secrets
  dbSecret = secrets.declare "myapp-db" {
    sopsFile = ./secrets.yaml;
    owner = cfg.user;
  };

in
{
  options.services.myapp = {
    enable = mkEnableOption "MyApp";

    # Allow users to override with custom backend
    secretsBackend = mkOption {
      type = types.nullOr types.unspecified;
      default = null;
      description = "Custom secrets backend";
    };

    # Also allow simple path-based override
    secrets.database = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to database password (overrides auto-config)";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.myapp = {
      script = ''
        # Use manual path if provided, otherwise use auto-configured
        ${if cfg.secrets.database != null then
            ''export DB_PASSWORD=$(cat ${cfg.secrets.database})''
          else
            secrets.loadEnv "DB_PASSWORD" dbSecret
        }

        exec ${pkgs.myapp}/bin/myapp
      '';
    };
  };
}
```

**Pros:**
- Automatic for most users
- Manual override available
- Maximum flexibility

**Cons:**
- Most complex implementation
- More code to maintain

## For NUR Maintainers

### Adding New Backend

1. Create `lib/secrets/yourbackend.nix`:

```nix
{ lib, config }:

with lib;

{
  mkSecret = args: {
    # Your secret definition
  };

  getSecretPath = secret: "/your/path/${secret.name}";

  getSecretOptions = secret: {
    # NixOS config for your backend
  };

  mkSecretEnvVar = varName: secret:
    ''export ${varName}=$(cat ${getSecretPath secret})'';
}
```

2. Add documentation in `lib/secrets/README.md`

3. Add example in `examples/`

4. Test with existing modules

### Updating Existing Modules

To add secrets support to existing modules:

1. **Choose a pattern** (simple path-based recommended for most)

2. **Add secret options**:
   ```nix
   secrets.mySecret = mkOption {
     type = types.nullOr types.path;
     default = null;
   };
   ```

3. **Load secrets at runtime**:
   ```nix
   script = ''
     export SECRET=$(cat ${cfg.secrets.mySecret})
     exec myapp
   '';
   ```

4. **Document in module**:
   ```nix
   description = ''
     Path to secret file.
     Configure with your secrets manager:

     sops-nix:
       sops.secrets."myapp-secret" = {
         owner = "myapp";
         sopsFile = ./secrets.yaml;
       };

     agenix:
       age.secrets."myapp-secret" = {
         file = ./secrets/myapp.age;
         owner = "myapp";
       };
   '';
   ```

### Migration Strategy

For gradual adoption across the NUR:

**Phase 1**: Add simple path-based options
- Minimal changes
- Works with all backends
- Users configure secrets manually

**Phase 2**: Add auto-configuration
- Import secrets library
- Auto-detect backend
- Declare secrets

**Phase 3**: Full integration
- Advanced features
- Custom backends
- Helper functions

## For Users

### Quick Setup with sops-nix

1. **Add sops-nix to your flake**:
   ```nix
   inputs.sops-nix.url = "github:Mic92/sops-nix";
   ```

2. **Configure sops**:
   ```nix
   imports = [ inputs.sops-nix.nixosModules.sops ];

   sops.defaultSopsFile = ./secrets.yaml;
   sops.age.keyFile = "/etc/secrets/age-key.txt";
   ```

3. **Add secrets to YAML**:
   ```yaml
   # secrets.yaml (encrypted)
   myapp:
     database:
       password: supersecret123
     api:
       key: apikey456
   ```

4. **Reference in services**:
   ```nix
   services.myapp = {
     enable = true;
     secrets = {
       database = config.sops.secrets."myapp-db".path;
       apiKey = config.sops.secrets."myapp-api".path;
     };
   };

   sops.secrets."myapp-db" = {
     owner = "myapp";
     key = "myapp/database/password";
   };

   sops.secrets."myapp-api" = {
     owner = "myapp";
     key = "myapp/api/key";
   };
   ```

### Using Custom Backend

Example with Vault:

```nix
{ config, pkgs, ... }:

let
  secretsLib = pkgs.callPackage "${inputs.atproto-nur}/lib/secrets.nix" { };

  mySecrets = secretsLib.withBackend
    (import "${inputs.atproto-nur}/lib/secrets/vault.nix" {
      inherit (pkgs) lib config pkgs;
    });

in
{
  services.myapp = {
    enable = true;
    secretsBackend = mySecrets;
  };
}
```

## Security Considerations

1. **Build vs Runtime**:
   - ✅ Secrets loaded at runtime (secure)
   - ❌ Secrets in Nix store (insecure)

2. **File Permissions**:
   ```nix
   mode = "0400";  # Read-only, owner only
   owner = "myapp"; # Service user, not root
   ```

3. **Secret Storage**:
   - sops-nix/agenix: Encrypted in repository ✅
   - Vault: Not in repository ✅
   - File-based: Unencrypted ❌ (dev only)

4. **Cleanup**:
   ```nix
   # Secrets automatically cleaned up by systemd on service stop
   # For extra security, use PrivateTmp=true
   ```

## Troubleshooting

### Module doesn't support secrets

If a module hasn't adopted secrets support:

```nix
systemd.services.myapp = {
  preStart = ''
    export MY_SECRET=$(cat /run/secrets/my-secret)
    echo "SECRET=$MY_SECRET" > /etc/myapp/config
  '';
};
```

### Secret not available

Check secret is properly declared:

```bash
# For sops-nix
ls -la /run/secrets/

# For agenix
ls -la /run/agenix/

# Check service can read
sudo -u myapp cat /run/secrets/my-secret
```

### Backend detection fails

Explicitly set backend:

```nix
services.myapp.secretsBackend = secretsLib.withBackend
  (import ./lib/secrets/sops.nix { inherit lib config; });
```

## Examples

See:
- `examples/secrets-integration-example.nix` - Complete working example
- `lib/secrets/README.md` - API documentation
- Module implementations in `modules/supabase/` - Real-world usage

## Contributing

To improve secrets integration:

1. Report issues with current modules
2. Submit PRs for new backends
3. Update modules to use abstraction
4. Improve documentation

## References

- [sops-nix documentation](https://github.com/Mic92/sops-nix)
- [agenix documentation](https://github.com/ryantm/agenix)
- [Vault documentation](https://www.vaultproject.io/)
- [NixOS secrets management guide](https://nixos.wiki/wiki/Comparison_of_secret_managing_schemes)
