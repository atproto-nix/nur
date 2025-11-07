# Example: Service Module with Secrets Management Integration
#
# This example demonstrates how to write a NixOS module that supports
# pluggable secrets management backends (sops-nix, agenix, Vault, etc.)
#
# This module can be used as a template for creating your own services
# with first-class secrets support.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.example-secure-app;

  # Import the secrets abstraction library
  secretsLib = import ../lib/secrets.nix { inherit lib; };

  # Determine which backend to use:
  # 1. User-provided backend (cfg.secretsBackend)
  # 2. Auto-detect sops-nix if available
  # 3. Auto-detect agenix if available
  # 4. Fall back to file-based for development
  detectBackend =
    if cfg.secretsBackend != null then
      cfg.secretsBackend
    else if config.sops or null != null then
      # sops-nix is configured, use it
      secretsLib.withBackend (import ../lib/secrets/sops.nix { inherit lib config; })
    else if config.age or null != null then
      # agenix is configured, use it
      secretsLib.withBackend (import ../lib/secrets/agenix.nix { inherit lib config; })
    else
      # No secrets manager detected, use file-based (dev only)
      secretsLib.withBackend (import ../lib/secrets/file.nix { inherit lib; });

  secrets = detectBackend;

  # Declare the secrets this service needs
  # These are backend-agnostic declarations
  dbPasswordSecret = secrets.declare "example-app-db-password" {
    # Backend-specific options are passed through
    # For sops-nix:
    sopsFile = ./secrets.yaml;
    key = "example_app/database/password";
    owner = cfg.user;
    mode = "0400";

    # For agenix, only 'file' would be used:
    # file = ./secrets/example-app-db-password.age;

    # For Vault:
    # vaultPath = "secret/data/example-app/database";
    # vaultKey = "password";
  };

  apiKeySecret = secrets.declare "example-app-api-key" {
    sopsFile = ./secrets.yaml;
    key = "example_app/api/key";
    owner = cfg.user;
    mode = "0400";
  };

  jwtSecretSecret = secrets.declare "example-app-jwt" {
    sopsFile = ./secrets.yaml;
    key = "example_app/jwt/secret";
    owner = cfg.user;
    mode = "0400";
  };

in

{
  ###### Interface

  options.services.example-secure-app = {
    enable = mkEnableOption "Example Secure App with pluggable secrets";

    package = mkOption {
      type = types.package;
      default = pkgs.example-secure-app or (pkgs.writeScriptBin "example-secure-app" ''
        #!/bin/sh
        echo "Example app running with secrets:"
        echo "DB_PASSWORD: $DB_PASSWORD"
        echo "API_KEY: $API_KEY"
        echo "JWT_SECRET: $JWT_SECRET"
        sleep infinity
      '');
      description = "Package to use for the example app";
    };

    user = mkOption {
      type = types.str;
      default = "example-app";
      description = "User account for the service";
    };

    group = mkOption {
      type = types.str;
      default = "example-app";
      description = "Group for the service";
    };

    secretsBackend = mkOption {
      type = types.nullOr types.unspecified;
      default = null;
      description = ''
        Custom secrets backend to use.

        If null, will auto-detect based on available secrets managers:
        - sops-nix (preferred)
        - agenix
        - file-based (development only)

        Advanced users can provide their own backend implementation.
      '';
      example = literalExpression ''
        (pkgs.callPackage ./lib/secrets.nix { }).withBackend
          (import ./lib/secrets/vault.nix { inherit lib config pkgs; })
      '';
    };

    # Alternative: Simple path-based secrets (backend agnostic)
    simpleSecrets = {
      databasePassword = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to database password file.
          Overrides the auto-configured secret if set.
        '';
      };

      apiKey = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to API key file.
          Overrides the auto-configured secret if set.
        '';
      };
    };

    settings = {
      port = mkOption {
        type = types.port;
        default = 8080;
        description = "Port to listen on";
      };

      logLevel = mkOption {
        type = types.enum [ "debug" "info" "warn" "error" ];
        default = "info";
        description = "Logging level";
      };
    };
  };

  ###### Implementation

  config = mkIf cfg.enable (mkMerge [
    # Main service configuration
    {
      # Create user and group
      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        description = "Example Secure App user";
      };

      users.groups.${cfg.group} = {};

      # Systemd service
      systemd.services.example-secure-app = {
        description = "Example Secure App with Secrets Management";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          Restart = "on-failure";
          RestartSec = "10s";

          # Security hardening
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
        };

        environment = {
          PORT = toString cfg.settings.port;
          LOG_LEVEL = cfg.settings.logLevel;
        };

        # Load secrets at startup
        script = ''
          # Method 1: Using secrets library (preferred)
          ${secrets.loadEnvMulti {
            DB_PASSWORD = dbPasswordSecret;
            API_KEY = apiKeySecret;
            JWT_SECRET = jwtSecretSecret;
          }}

          # Method 2: Using simple path-based secrets (if configured)
          ${optionalString (cfg.simpleSecrets.databasePassword != null) ''
            export DB_PASSWORD=$(cat ${cfg.simpleSecrets.databasePassword})
          ''}
          ${optionalString (cfg.simpleSecrets.apiKey != null) ''
            export API_KEY=$(cat ${cfg.simpleSecrets.apiKey})
          ''}

          # Start the application
          exec ${cfg.package}/bin/example-secure-app
        '';
      };
    }

    # Backend-specific configuration
    # These configs are only applied if using the secrets library
    (secrets.getConfig dbPasswordSecret)
    (secrets.getConfig apiKeySecret)
    (secrets.getConfig jwtSecretSecret)
  ]);

  ###### Tests

  # Include assertions to validate configuration
  meta.maintainers = with lib.maintainers; [ ];

  # Example test configuration (can be run with nixos-test)
  meta.tests = {
    example = pkgs.nixosTest {
      name = "example-secure-app";
      nodes.machine = { config, pkgs, ... }: {
        imports = [ ./. ];

        services.example-secure-app = {
          enable = true;
          # Use file backend for testing
          secretsBackend = secretsLib.withBackend
            (import ../lib/secrets/file.nix { inherit lib; });

          simpleSecrets = {
            databasePassword = pkgs.writeText "db-pass" "test-password";
            apiKey = pkgs.writeText "api-key" "test-key-123";
          };
        };
      };

      testScript = ''
        machine.wait_for_unit("example-secure-app.service")
        machine.succeed("systemctl status example-secure-app.service")
      '';
    };
  };
}
