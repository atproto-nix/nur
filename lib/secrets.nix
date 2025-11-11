# Secrets Management Abstraction Layer
#
# This library provides a pluggable secrets management system that allows
# users to choose their preferred secrets backend (sops-nix, agenix, Vault, etc.)
# while providing a consistent API for NixOS modules.
#
# Usage:
#   1. Import this library in your flake
#   2. Configure a secrets backend (sops-nix is default)
#   3. Use helper functions in modules to declare and access secrets

{ lib }:

with lib;

let
  # Secret backend interface
  # Backends must implement these functions:
  backendInterface = {
    # mkSecret :: AttrSet -> Secret
    # Creates a secret definition with backend-specific configuration
    mkSecret = throw "Backend must implement mkSecret";

    # getSecretPath :: Secret -> Path
    # Returns the runtime path where the secret will be available
    getSecretPath = throw "Backend must implement getSecretPath";

    # getSecretOptions :: Secret -> AttrSet
    # Returns NixOS options needed for the secret (added to config)
    getSecretOptions = throw "Backend must implement getSecretOptions";

    # mkSecretEnvVar :: String -> Secret -> String
    # Returns shell code to load secret into environment variable
    mkSecretEnvVar = throw "Backend must implement mkSecretEnvVar";
  };

in

{
  # Create a secrets manager with a specific backend
  #
  # Example:
  #   secrets = (pkgs.callPackage ./lib/secrets.nix { }).withBackend
  #     (import ./lib/secrets/sops.nix { inherit lib config; });
  withBackend = backend: {
    inherit backend;

    # Declare a secret with metadata
    #
    # Args:
    #   name: Unique identifier for the secret
    #   options: Backend-specific options (see backend documentation)
    #
    # Example:
    #   mySecret = secrets.declare "database-password" {
    #     sopsFile = ./secrets.yaml;
    #     owner = "postgres";
    #     group = "postgres";
    #     mode = "0400";
    #   };
    declare = name: options: backend.mkSecret ({ inherit name; } // options);

    # Get the runtime path for a secret
    #
    # Example:
    #   path = secrets.getPath mySecret;
    #   # => "/run/secrets/database-password"
    getPath = secret: backend.getSecretPath secret;

    # Get NixOS module configuration for a secret
    # This should be merged into your config
    #
    # Example:
    #   config = secrets.getConfig mySecret;
    getConfig = secret: backend.getSecretOptions secret;

    # Generate shell code to load secret into environment variable
    #
    # Example:
    #   script = ''
    #     ${secrets.loadEnv "DB_PASSWORD" mySecret}
    #     psql -c "ALTER USER postgres PASSWORD '$DB_PASSWORD'"
    #   '';
    loadEnv = varName: secret: backend.mkSecretEnvVar varName secret;

    # Helper: Generate EnvironmentFile= directive for systemd
    #
    # For secrets that are already in key=value format
    #
    # Example:
    #   serviceConfig.EnvironmentFile = secrets.asEnvFile myEnvSecret;
    asEnvFile = secret: backend.getSecretPath secret;

    # Helper: Read secret file content in preStart script
    #
    # Example:
    #   preStart = ''
    #     ${secrets.injectFile mySecret "/etc/myapp/config.json"}
    #     chown myapp:myapp /etc/myapp/config.json
    #   '';
    injectFile = secret: targetPath: ''
      install -m 0600 -D ${backend.getSecretPath secret} ${targetPath}
    '';

    # Helper: Create multiple secret environment variable loads
    #
    # Example:
    #   script = ''
    #     ${secrets.loadEnvMulti {
    #       DB_PASSWORD = dbSecret;
    #       API_KEY = apiSecret;
    #       JWT_SECRET = jwtSecret;
    #     }}
    #     exec myapp
    #   '';
    loadEnvMulti = secretsMap: concatStringsSep "\n"
      (mapAttrsToList (varName: secret: backend.mkSecretEnvVar varName secret) secretsMap);
  };

  # Null backend (for testing or when secrets aren't needed)
  nullBackend = {
    mkSecret = attrs: attrs;
    getSecretPath = secret: "/dev/null";
    getSecretOptions = secret: {};
    mkSecretEnvVar = varName: secret: "export ${varName}=''";
  };

  # Helper function for modules to define secret-related options
  #
  # This generates standard option definitions for secrets that work
  # across all backends.
  #
  # Example in a module:
  #   options.services.myapp = {
  #     secrets = lib.atproto.secrets.mkSecretOptions {
  #       database = "Database password";
  #       apiKey = "API authentication key";
  #     };
  #   };
  mkSecretOptions = descriptions: mapAttrs (name: desc: mkOption {
    type = types.nullOr types.path;
    default = null;
    description = ''
      Path to file containing ${desc}.

      The file will be read at service startup and should be managed
      by your secrets manager (sops-nix, agenix, etc.).
    '';
    example = "/run/secrets/${name}";
  }) descriptions;

  # Helper: Generate assertions for required secrets
  #
  # Example:
  #   config = mkIf cfg.enable {
  #     assertions = lib.atproto.secrets.requireSecrets {
  #       inherit (cfg.secrets) database apiKey;
  #     } cfg.enable;
  #   };
  requireSecrets = secretPaths: enabled:
    map (name: {
      assertion = !enabled || secretPaths.${name} != null;
      message = "Secret '${name}' must be configured when service is enabled";
    }) (attrNames secretPaths);
}
