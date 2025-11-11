# File-based Backend for Secrets Management
#
# This is a simple example backend that reads secrets from plain files.
# Useful for development, testing, or simple deployments.
#
# ⚠️  WARNING: This backend provides no encryption. Use only for:
#    - Local development
#    - Testing
#    - Non-sensitive configuration
#    - As a template for custom backends
#
# Usage:
#   secrets = (pkgs.callPackage ./lib/secrets.nix { }).withBackend
#     (import ./lib/secrets/file.nix { inherit lib; });
#
# This backend demonstrates the minimum interface needed to create
# a custom secrets backend.

{ lib }:

with lib;

{
  # Create a secret definition that points to a file
  #
  # Args:
  #   name: Secret identifier
  #   file: Path to file containing the secret (required)
  #   owner: File owner (default: "root") - NOTE: not enforced by this backend
  #   group: File group (default: owner) - NOTE: not enforced by this backend
  #   mode: File permissions (default: "0400") - NOTE: not enforced by this backend
  #
  # Example:
  #   mkSecret {
  #     name = "api-key";
  #     file = /etc/secrets/api-key;
  #   }
  mkSecret = args@{
    name,
    file,
    owner ? "root",
    group ? owner,
    mode ? "0400",
    ...
  }:
  {
    inherit name file owner group mode;
  };

  # Get the runtime path where the secret file is located
  getSecretPath = secret: secret.file;

  # No special NixOS configuration needed for plain files
  getSecretOptions = secret: {};

  # Generate shell code to load secret into environment variable
  mkSecretEnvVar = varName: secret:
    ''export ${varName}=$(cat ${secret.file})'';
}
