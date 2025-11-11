# Secrets Management Abstraction

A pluggable secrets management system for the ATProto NUR that allows users to choose their preferred secrets backend (sops-nix, agenix, Vault, etc.) while providing a consistent API for NixOS modules.

## Features

- **Backend Agnostic**: Switch between sops-nix, agenix, Vault, or custom backends
- **Consistent API**: Modules use the same interface regardless of backend
- **Type Safe**: Leverages Nix type system for compile-time validation
- **Runtime Security**: Secrets loaded at service startup, not build time
- **Extensible**: Easy to implement custom backends

## Quick Start

### 1. Choose a Backend

The most common backend is sops-nix (default):

```nix
# In your flake.nix or configuration.nix
{ inputs, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.atproto-nur.nixosModules.default
  ];

  # Configure sops-nix
  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.keyFile = "/etc/secrets/age-key.txt";
}
```

### 2. Use in Your Services

Modules can now use secrets without knowing the backend:

```nix
# In a service configuration
{ config, lib, pkgs, ... }:

let
  cfg = config.services.myapp;

  # Secrets are automatically managed by the configured backend
in
{
  services.myapp = {
    enable = true;

    # Module defines what secrets it needs
    secrets = {
      database = "/run/secrets/myapp-db-password";
      apiKey = "/run/secrets/myapp-api-key";
    };
  };
}
```

## Available Backends

### sops-nix (Recommended)

Age/PGP encrypted secrets stored in repository.

```nix
# lib/secrets/sops.nix
secrets = (import ./lib/secrets.nix { inherit lib; }).withBackend
  (import ./lib/secrets/sops.nix { inherit lib config; });
```

**Pros:**
- Encrypted secrets can be committed to git
- Supports YAML, JSON, dotenv, binary formats
- Age or PGP encryption
- Built-in integration with systemd

**Cons:**
- Requires key management
- Secrets in repository (encrypted)

### agenix

Age-only encrypted secrets.

```nix
# lib/secrets/agenix.nix
secrets = (import ./lib/secrets.nix { inherit lib; }).withBackend
  (import ./lib/secrets/agenix.nix { inherit lib config; });
```

**Pros:**
- Simple age encryption
- Lightweight
- Fast

**Cons:**
- Age only (no PGP)
- Less format flexibility than sops-nix

### HashiCorp Vault

Enterprise secrets management with dynamic secrets.

```nix
# lib/secrets/vault.nix
secrets = (import ./lib/secrets.nix { inherit lib; }).withBackend
  (import ./lib/secrets/vault.nix { inherit lib config pkgs; });
```

**Pros:**
- Dynamic secrets (auto-rotation)
- Centralized management
- Audit logging
- PKI/certificate management

**Cons:**
- Requires Vault infrastructure
- More complex setup
- Network dependency

### File-based (Development Only)

Simple file-based secrets for testing.

```nix
# lib/secrets/file.nix
secrets = (import ./lib/secrets.nix { inherit lib; }).withBackend
  (import ./lib/secrets/file.nix { inherit lib; });
```

⚠️ **Warning:** No encryption. Use only for development/testing.

## Module Integration Examples

### Basic Service with Secrets

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.myapp;

  # For sops-nix backend (automatically configured)
  secretsConfig = {
    sops.secrets = {
      "myapp-db-password" = {
        owner = cfg.user;
        sopsFile = ./secrets.yaml;
      };
      "myapp-api-key" = {
        owner = cfg.user;
        sopsFile = ./secrets.yaml;
      };
    };
  };

in
{
  options.services.myapp = {
    enable = mkEnableOption "MyApp service";

    # Simple path-based approach (works with any backend)
    secrets = {
      database = mkOption {
        type = types.path;
        description = "Path to database password file";
        example = "/run/secrets/myapp-db-password";
      };

      apiKey = mkOption {
        type = types.path;
        description = "Path to API key file";
        example = "/run/secrets/myapp-api-key";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Service configuration
    {
      systemd.services.myapp = {
        description = "MyApp Service";
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          ExecStart = "${pkgs.myapp}/bin/myapp";
        };

        # Load secrets at startup
        script = ''
          export DB_PASSWORD=$(cat ${cfg.secrets.database})
          export API_KEY=$(cat ${cfg.secrets.apiKey})

          exec ${pkgs.myapp}/bin/myapp
        '';
      };
    }

    # sops-nix configuration (only used if sops-nix is enabled)
    (mkIf (config.sops or null != null) secretsConfig)
  ]);
}
```

### Advanced: Using the Secrets Abstraction Library

For module authors who want to provide first-class secrets support:

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.advanced-app;

  # Import secrets library
  secretsLib = import ../lib/secrets.nix { inherit lib; };

  # Create secrets manager with sops-nix backend
  # (users can override this)
  secrets = cfg.secretsBackend or (secretsLib.withBackend
    (import ../lib/secrets/sops.nix { inherit lib config; }));

  # Declare secrets
  dbSecret = secrets.declare "advanced-app-db" {
    sopsFile = ./secrets.yaml;
    key = "database/password";
    owner = cfg.user;
  };

  apiSecret = secrets.declare "advanced-app-api" {
    sopsFile = ./secrets.yaml;
    key = "api/key";
    owner = cfg.user;
  };

in
{
  options.services.advanced-app = {
    enable = mkEnableOption "Advanced App";

    user = mkOption {
      type = types.str;
      default = "advanced-app";
    };

    # Allow users to plug in their own secrets backend
    secretsBackend = mkOption {
      type = types.unspecified;
      default = null;
      description = "Custom secrets backend (advanced users)";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Service configuration
    {
      systemd.services.advanced-app = {
        description = "Advanced App Service";
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
        };

        # Use secrets library helpers
        script = ''
          ${secrets.loadEnvMulti {
            DB_PASSWORD = dbSecret;
            API_KEY = apiSecret;
          }}

          exec ${pkgs.advanced-app}/bin/advanced-app
        '';
      };
    }

    # Backend-specific configuration
    (secrets.getConfig dbSecret)
    (secrets.getConfig apiSecret)
  ]);
}
```

### Environment File Format

For secrets that are already in `KEY=VALUE` format:

```nix
systemd.services.myapp = {
  serviceConfig = {
    EnvironmentFile = cfg.secrets.envFile;
    # or with secrets library:
    # EnvironmentFile = secrets.asEnvFile envSecret;
  };
};
```

## Creating Custom Backends

Implement the backend interface:

```nix
# custom-backend.nix
{ lib, config }:

with lib;

{
  # Required: Create a secret definition
  mkSecret = args@{ name, ... }: {
    inherit name;
    # Your backend-specific fields
  };

  # Required: Get runtime path to secret
  getSecretPath = secret: "/your/custom/path/${secret.name}";

  # Required: Generate NixOS config for secret
  getSecretOptions = secret: {
    # Your NixOS configuration
  };

  # Required: Generate shell code to load secret
  mkSecretEnvVar = varName: secret:
    ''export ${varName}=$(cat ${getSecretPath secret})'';

  # Optional: Additional helpers
  extra = {
    # Custom helper functions
  };
}
```

## Security Best Practices

1. **Never commit unencrypted secrets** - Use sops-nix/agenix to encrypt
2. **Restrict file permissions** - Use `mode = "0400"` for secrets
3. **Use service users** - Set `owner` to the service user, not root
4. **Rotate secrets regularly** - Especially for production
5. **Audit access** - Use Vault or similar for audit logging
6. **Limit secret scope** - One secret per service when possible

## Migration Guide

### From Manual Secret Management

Before:
```nix
systemd.services.myapp.script = ''
  export DB_PASS=$(cat /etc/secrets/db-password)
  exec myapp
'';
```

After (with sops-nix):
```nix
sops.secrets."myapp-db-password" = {
  owner = "myapp";
  sopsFile = ./secrets.yaml;
};

systemd.services.myapp.script = ''
  export DB_PASS=$(cat ${config.sops.secrets."myapp-db-password".path})
  exec myapp
'';
```

### From agenix to sops-nix

1. Decrypt your agenix secrets:
   ```bash
   for secret in secrets/*.age; do
     agenix -d "$secret" > "$(basename "$secret" .age).txt"
   done
   ```

2. Create sops-nix secrets file:
   ```bash
   sops secrets.yaml  # Add decrypted secrets
   ```

3. Update configuration:
   ```nix
   # Before (agenix)
   age.secrets."myapp-db" = {
     file = ./secrets/db.age;
     owner = "myapp";
   };

   # After (sops-nix)
   sops.secrets."myapp-db" = {
     sopsFile = ./secrets.yaml;
     owner = "myapp";
   };
   ```

4. Update service references (paths change):
   ```nix
   # agenix: /run/agenix/secret-name
   # sops-nix: /run/secrets/secret-name
   ```

## Troubleshooting

### Secret file not found

**Symptom:** Service fails with "No such file or directory"

**Solution:** Ensure the secret is properly declared in sops/agenix config:

```nix
# For sops-nix
sops.secrets."my-secret" = {
  sopsFile = ./secrets.yaml;
};

# Check secret exists
nix-shell -p sops --run "sops -d secrets.yaml"
```

### Permission denied

**Symptom:** Service can't read secret file

**Solution:** Set correct owner in secret definition:

```nix
sops.secrets."my-secret" = {
  owner = "myservice";  # Must match service user
  mode = "0400";
};
```

### Secret not decrypted

**Symptom:** Encrypted content in secret file

**Solution:** Ensure age/GPG key is configured:

```nix
sops.age.keyFile = "/etc/secrets/age-key.txt";
# Key file must exist and be readable by root
```

## API Reference

See the inline documentation in:
- `lib/secrets.nix` - Core abstraction
- `lib/secrets/sops.nix` - Sops-nix backend
- `lib/secrets/agenix.nix` - Agenix backend
- `lib/secrets/vault.nix` - Vault backend
- `lib/secrets/file.nix` - File backend (example)

## Contributing

To add a new backend:

1. Create `lib/secrets/yourbackend.nix`
2. Implement the backend interface
3. Add documentation and examples
4. Submit a PR with tests

## License

Same as the ATProto NUR (see main LICENSE file).
