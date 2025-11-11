# Sops-nix Backend for Secrets Management
#
# This backend integrates with sops-nix for encrypted secrets management.
# Secrets are stored encrypted in the repository and decrypted at runtime.
#
# Usage:
#   secrets = (pkgs.callPackage ./lib/secrets.nix { }).withBackend
#     (import ./lib/secrets/sops.nix { inherit lib config; });
#
# Reference: https://github.com/Mic92/sops-nix

{ lib, config }:

with lib;

let
  # Extract sops configuration from the system
  sopsConfig = config.sops or {};

in

{
  # Create a secret definition with sops-nix specific options
  #
  # Args:
  #   name: Secret identifier (used as sops.secrets.<name>)
  #   sopsFile: Path to encrypted secrets file (default: config.sops.defaultSopsFile)
  #   key: Key path in YAML/JSON file (default: same as name)
  #   owner: File owner (default: "root")
  #   group: File group (default: owner)
  #   mode: File permissions (default: "0400")
  #   format: File format - "yaml", "json", "dotenv", "binary" (default: "yaml")
  #   path: Custom runtime path (default: /run/secrets/<name>)
  #   restartUnits: List of systemd units to restart when secret changes
  #   reloadUnits: List of systemd units to reload when secret changes
  #   neededForUsers: Make available during user creation (default: false)
  #
  # Example:
  #   mkSecret {
  #     name = "postgres-password";
  #     sopsFile = ./secrets.yaml;
  #     key = "database/postgres/password";
  #     owner = "postgres";
  #     mode = "0400";
  #   }
  mkSecret = args@{
    name,
    sopsFile ? sopsConfig.defaultSopsFile or null,
    key ? name,
    owner ? "root",
    group ? owner,
    mode ? "0400",
    format ? "yaml",
    path ? null,
    restartUnits ? [],
    reloadUnits ? [],
    neededForUsers ? false,
    ...
  }:
  let
    # Remove our custom args, pass rest to sops
    sopsArgs = removeAttrs args [ "name" ];

    secretDef = {
      inherit name sopsFile key owner group mode format restartUnits reloadUnits neededForUsers;
      path = if path != null then path else "/run/secrets/${name}";
    } // sopsArgs;

  in secretDef;

  # Get the runtime path where sops-nix will place the decrypted secret
  #
  # Returns: /run/secrets/<name> or custom path if specified
  getSecretPath = secret:
    if secret.path != null && secret.path != "/run/secrets/${secret.name}"
    then secret.path
    else config.sops.secrets.${secret.name}.path or "/run/secrets/${secret.name}";

  # Generate NixOS config options for sops-nix
  #
  # Returns: { sops.secrets.<name> = { ... }; }
  getSecretOptions = secret: {
    sops.secrets.${secret.name} = {
      inherit (secret) owner group mode format restartUnits reloadUnits neededForUsers;
    } // optionalAttrs (secret.sopsFile != null) {
      inherit (secret) sopsFile;
    } // optionalAttrs (secret.key != secret.name) {
      inherit (secret) key;
    } // optionalAttrs (secret.path != null) {
      inherit (secret) path;
    };
  };

  # Generate shell code to load secret into environment variable
  #
  # The secret is read from the runtime path that sops-nix provides.
  #
  # Example output:
  #   export DB_PASSWORD=$(cat /run/secrets/postgres-password)
  mkSecretEnvVar = varName: secret:
    let
      secretPath = getSecretPath secret;
    in
    ''export ${varName}=$(cat ${secretPath})'';

  # Additional sops-nix specific helpers
  extra = {
    # Create a secret from a nested key path
    #
    # Example:
    #   fromPath "database.postgres.password" { sopsFile = ./secrets.yaml; }
    #   # Creates secret with key "database.postgres.password"
    fromPath = keyPath: args: mkSecret (args // {
      name = replaceStrings ["."] ["-"] keyPath;
      key = keyPath;
    });

    # Create multiple secrets from the same file
    #
    # Example:
    #   fromFile ./secrets.yaml {
    #     "postgres-password" = { key = "database/postgres/password"; owner = "postgres"; };
    #     "redis-password" = { key = "cache/redis/password"; owner = "redis"; };
    #   }
    fromFile = sopsFile: secrets:
      mapAttrs (name: opts: mkSecret ({ inherit name sopsFile; } // opts)) secrets;

    # Template a secret file with multiple values
    #
    # Useful for config files that need multiple secrets interpolated
    #
    # Example:
    #   template "myapp-config" {
    #     file = ./config.template;
    #     owner = "myapp";
    #     substitutions = {
    #       DB_PASSWORD = dbSecret;
    #       API_KEY = apiSecret;
    #     };
    #   }
    template = name: { file, owner ? "root", group ? owner, substitutions }:
      mkSecret {
        inherit name owner group;
        format = "binary";
        # Note: Actual templating would need sops-nix templates feature
        # This is a simplified interface
      };
  };
}
