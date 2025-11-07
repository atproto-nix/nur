# Agenix Backend for Secrets Management
#
# This backend integrates with agenix for age-encrypted secrets management.
# Secrets are encrypted with age and decrypted at runtime.
#
# Usage:
#   secrets = (pkgs.callPackage ./lib/secrets.nix { }).withBackend
#     (import ./lib/secrets/agenix.nix { inherit lib config; });
#
# Reference: https://github.com/ryantm/agenix

{ lib, config }:

with lib;

{
  # Create a secret definition with agenix specific options
  #
  # Args:
  #   name: Secret identifier (used as age.secrets.<name>)
  #   file: Path to encrypted .age file (required)
  #   owner: File owner (default: "root")
  #   group: File group (default: owner)
  #   mode: File permissions (default: "0400")
  #   path: Custom runtime path (default: /run/agenix/<name>)
  #   symlink: Whether to symlink (default: true)
  #
  # Example:
  #   mkSecret {
  #     name = "postgres-password";
  #     file = ./secrets/postgres-password.age;
  #     owner = "postgres";
  #     mode = "0400";
  #   }
  mkSecret = args@{
    name,
    file,
    owner ? "root",
    group ? owner,
    mode ? "0400",
    path ? null,
    symlink ? true,
    ...
  }:
  let
    agenixArgs = removeAttrs args [ "name" ];

    secretDef = {
      inherit name file owner group mode symlink;
      path = if path != null then path else "/run/agenix/${name}";
    } // agenixArgs;

  in secretDef;

  # Get the runtime path where agenix will place the decrypted secret
  getSecretPath = secret:
    if secret.path != null && secret.path != "/run/agenix/${secret.name}"
    then secret.path
    else config.age.secrets.${secret.name}.path or "/run/agenix/${secret.name}";

  # Generate NixOS config options for agenix
  getSecretOptions = secret: {
    age.secrets.${secret.name} = {
      inherit (secret) file owner group mode symlink;
    } // optionalAttrs (secret.path != null) {
      inherit (secret) path;
    };
  };

  # Generate shell code to load secret into environment variable
  mkSecretEnvVar = varName: secret:
    let
      secretPath = getSecretPath secret;
    in
    ''export ${varName}=$(cat ${secretPath})'';

  # Additional agenix specific helpers
  extra = {
    # Create multiple secrets from a directory of .age files
    #
    # Example:
    #   fromDirectory ./secrets {
    #     postgres-password = { owner = "postgres"; };
    #     redis-password = { owner = "redis"; };
    #   }
    fromDirectory = dir: secrets:
      mapAttrs (name: opts: mkSecret ({
        inherit name;
        file = "${dir}/${name}.age";
      } // opts)) secrets;
  };
}
