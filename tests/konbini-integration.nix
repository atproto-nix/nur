# Integration test for konbini AppView module
# This demonstrates a complete konbini deployment configuration
#
# Test with: nixos-rebuild build-vm -I nixos-config=./tests/konbini-integration.nix
# Or eval with: nix-instantiate --eval '<nixpkgs/nixos>' -A config.services.whyrusleeping.konbini.enable --arg configuration ./tests/konbini-integration.nix

{ config, pkgs, lib, ... }:

{
  # Import konbini module
  imports = [
    ../modules/whyrusleeping/konbini.nix
  ];

  # Minimal system config for testing
  system.stateVersion = "24.05";
  boot.loader.grub.enable = false;
  fileSystems."/" = { device = "/dev/null"; };

  # Konbini configuration
  services.whyrusleeping.konbini = {
    enable = true;

    # Network configuration
    port = 4444;
    hostname = "konbini.example.com";

    # Database setup (creates local PostgreSQL automatically)
    database = {
      createLocally = true;
      url = "postgresql://konbini@localhost/konbini";
    };

    # Bluesky credentials (file-based for security)
    bluesky = {
      handleFile = "/run/secrets/konbini-handle";
      passwordFile = "/run/secrets/konbini-password";
    };

    # Sync backend configuration (default: bsky.network firehose)
    syncConfig = {
      backends = [
        {
          type = "firehose";
          host = "bsky.network";
        }
      ];
    };

    # Additional environment variables
    extraEnv = {
      LOG_LEVEL = "info";
    };

    # Open firewall for API port
    openFirewall = true;
  };

  # Example: Using jetstream instead of firehose (lower bandwidth)
  # services.whyrusleeping.konbini.syncConfig = {
  #   backends = [
  #     {
  #       type = "jetstream";
  #       host = "jetstream1.us-west.bsky.network";
  #     }
  #   ];
  # };

  # Example: Multiple backends (main relay + specific PDSs)
  # services.whyrusleeping.konbini.syncConfig = {
  #   backends = [
  #     {
  #       type = "firehose";
  #       host = "bsky.network";
  #     }
  #     {
  #       type = "firehose";
  #       host = "my-pds.example.com";
  #     }
  #   ];
  # };

  # Example: Using environmentFile for all configuration
  # services.whyrusleeping.konbini = {
  #   enable = true;
  #   environmentFile = "/run/secrets/konbini-env";
  # };
  #
  # Where /run/secrets/konbini-env contains:
  # DATABASE_URL=postgresql://konbini:password@localhost:5432/konbini
  # BSKY_HANDLE=user.bsky.social
  # BSKY_PASSWORD=app-password-here
  # LOG_LEVEL=debug
}
