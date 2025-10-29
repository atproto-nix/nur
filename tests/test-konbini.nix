# Simple evaluation test for konbini module
# Usage: nix-instantiate --eval tests/test-konbini.nix

let
  nixpkgs = <nixpkgs>;
  pkgs = import nixpkgs { };

  # Evaluate NixOS configuration with konbini module
  evalConfig = pkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ../modules/whyrusleeping/konbini.nix
      {
        system.stateVersion = "24.05";
        boot.loader.grub.enable = false;
        fileSystems."/" = { device = "/dev/null"; };

        services.whyrusleeping.konbini = {
          enable = true;
          port = 4444;
          hostname = "test.example.com";
          database.createLocally = true;
          database.url = "postgresql://konbini@localhost/konbini";
          bluesky.handleFile = "/tmp/test-handle";
          bluesky.passwordFile = "/tmp/test-password";
        };
      }
    ];
  };

in {
  # Test that module evaluates
  moduleEvaluates = true;

  # Test that service is enabled
  serviceEnabled = evalConfig.config.services.whyrusleeping.konbini.enable;

  # Test that systemd service is created
  systemdServiceExists = builtins.hasAttr "konbini" evalConfig.config.systemd.services;

  # Test that PostgreSQL is enabled
  postgresqlEnabled = evalConfig.config.services.postgresql.enable;

  # All tests pass
  success = evalConfig.config.services.whyrusleeping.konbini.enable
    && builtins.hasAttr "konbini" evalConfig.config.systemd.services
    && evalConfig.config.services.postgresql.enable;
}
