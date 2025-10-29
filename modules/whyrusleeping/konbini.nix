{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.whyrusleeping.konbini;

  # Sync configuration file
  syncConfigFile = pkgs.writeText "sync-config.json" (builtins.toJSON cfg.syncConfig);

in
{
  options.services.whyrusleeping.konbini = {
    enable = mkEnableOption "Konbini - Friends of Friends Bluesky AppView";

    package = mkOption {
      type = types.package;
      default = pkgs.whyrusleeping-konbini;
      defaultText = literalExpression "pkgs.whyrusleeping-konbini";
      description = "The Konbini package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "konbini";
      description = "User account under which Konbini runs.";
    };

    group = mkOption {
      type = types.str;
      default = "konbini";
      description = "Group under which Konbini runs.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/konbini";
      description = "Directory where Konbini stores its data.";
    };

    port = mkOption {
      type = types.port;
      default = 4444;
      description = "Port for the Konbini API server.";
    };

    hostname = mkOption {
      type = types.str;
      default = "localhost";
      example = "konbini.example.com";
      description = "Hostname for the Konbini AppView.";
    };

    database = {
      url = mkOption {
        type = types.str;
        description = "PostgreSQL database URL.";
        example = "postgresql://konbini:password@localhost:5432/konbini";
      };

      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = "Create a local PostgreSQL database for Konbini.";
      };
    };

    bluesky = {
      handleFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/konbini-handle";
        description = ''
          Path to file containing Bluesky handle (e.g., user.bsky.social).
          Used for authenticating with Bluesky to access the firehose.
        '';
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/konbini-password";
        description = ''
          Path to file containing Bluesky app password.
          Create an app password at https://bsky.app/settings/app-passwords
        '';
      };
    };

    syncConfig = mkOption {
      type = types.attrs;
      default = {
        backends = [
          {
            type = "firehose";
            host = "bsky.network";
          }
        ];
      };
      description = ''
        Sync backend configuration. Supports multiple backends including
        firehose and jetstream endpoints.
      '';
      example = literalExpression ''
        {
          backends = [
            {
              type = "jetstream";
              host = "jetstream1.us-west.bsky.network";
            }
          ];
        }
      '';
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/konbini-env";
      description = ''
        Path to environment file containing additional configuration.
        This file can contain DATABASE_URL, BSKY_HANDLE, BSKY_PASSWORD, etc.
        Format: KEY=value (one per line).
      '';
    };

    extraEnv = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          LOG_LEVEL = "debug";
        }
      '';
      description = "Additional environment variables to set.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the firewall for the Konbini API port.";
    };
  };

  config = mkIf cfg.enable {
    # Assertions
    assertions = [
      {
        assertion = cfg.bluesky.handleFile != null || cfg.environmentFile != null;
        message = "services.whyrusleeping.konbini: either bluesky.handleFile or environmentFile must be set";
      }
      {
        assertion = cfg.bluesky.passwordFile != null || cfg.environmentFile != null;
        message = "services.whyrusleeping.konbini: either bluesky.passwordFile or environmentFile must be set";
      }
      {
        assertion = cfg.database.createLocally -> (cfg.database.url == "postgresql://konbini@localhost/konbini" || cfg.database.url == "postgresql://${cfg.user}@localhost/${cfg.user}");
        message = "services.whyrusleeping.konbini: database.createLocally requires database.url to use local socket authentication";
      }
    ];

    # User and group configuration
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      description = "Konbini service user";
    };

    users.groups.${cfg.group} = {};

    # PostgreSQL database
    services.postgresql = mkIf cfg.database.createLocally {
      enable = true;
      ensureDatabases = [ "konbini" ];
      ensureUsers = [
        {
          name = cfg.user;
          ensureDBOwnership = true;
        }
      ];
    };

    # systemd service
    systemd.services.konbini = {
      description = "Konbini - Friends of Friends Bluesky AppView";
      documentation = [ "https://github.com/whyrusleeping/konbini" ];
      after = [ "network.target" ] ++ optional cfg.database.createLocally "postgresql.service";
      requires = optional cfg.database.createLocally "postgresql.service";
      wantedBy = [ "multi-user.target" ];

      environment = {
        # Database URL (can be overridden by environmentFile)
        DATABASE_URL = if cfg.database.createLocally
          then "postgresql:///${cfg.user}?host=/run/postgresql"
          else cfg.database.url;

        # Port and hostname
        PORT = toString cfg.port;
        KONBINI_HOSTNAME = cfg.hostname;

        # Sync configuration
        SYNC_CONFIG = syncConfigFile;
      } // cfg.extraEnv;

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/konbini";
        Restart = "on-failure";
        RestartSec = "10s";

        # Load credentials from files
        LoadCredential = flatten [
          (optional (cfg.bluesky.handleFile != null) "bsky-handle:${cfg.bluesky.handleFile}")
          (optional (cfg.bluesky.passwordFile != null) "bsky-password:${cfg.bluesky.passwordFile}")
        ];

        # Environment file for secrets
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        SystemCallFilter = [ "@system-service" "~@privileged" ];
        PrivateNetwork = false;

        # Working directory
        WorkingDirectory = "/var/lib/konbini";
        StateDirectory = "konbini";
        StateDirectoryMode = "0750";

        # Resource limits
        LimitNOFILE = 65536;
      };

      # Set credentials as environment variables if provided
      script = mkIf (cfg.bluesky.handleFile != null || cfg.bluesky.passwordFile != null) ''
        ${optionalString (cfg.bluesky.handleFile != null) ''
          export BSKY_HANDLE="$(cat $CREDENTIALS_DIRECTORY/bsky-handle)"
        ''}
        ${optionalString (cfg.bluesky.passwordFile != null) ''
          export BSKY_PASSWORD="$(cat $CREDENTIALS_DIRECTORY/bsky-password)"
        ''}
        exec ${cfg.package}/bin/konbini
      '';
    };

    # Firewall
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
