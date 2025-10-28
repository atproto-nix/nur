{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.whyrusleeping-konbini;

  # Sync configuration file
  syncConfigFile = pkgs.writeText "sync-config.json" (builtins.toJSON cfg.syncConfig);

in
{
  options.services.whyrusleeping-konbini = {
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

    frontendPort = mkOption {
      type = types.port;
      default = 3000;
      description = "Port for serving the frontend (optional, can use reverse proxy).";
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
      handle = mkOption {
        type = types.str;
        description = "Bluesky handle for initial authentication.";
        example = "username.bsky.social";
      };

      passwordFile = mkOption {
        type = types.path;
        description = "Path to file containing Bluesky app password.";
        example = "/run/secrets/konbini-bsky-password";
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

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the firewall for the Konbini API port.";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional environment variables for Konbini.";
      example = literalExpression ''
        {
          LOG_LEVEL = "debug";
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Assertions
    assertions = [
      {
        assertion = cfg.bluesky.handle != "";
        message = "Konbini requires a Bluesky handle to be configured.";
      }
      {
        assertion = cfg.database.url != "" || cfg.database.createLocally;
        message = "Konbini requires either a database URL or createLocally = true.";
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

    # Directory management
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/logs' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # systemd service
    systemd.services.konbini = {
      description = "Konbini - Friends of Friends Bluesky AppView";
      documentation = [ "https://github.com/whyrusleeping/konbini" ];
      after = [ "network.target" ] ++ optional cfg.database.createLocally "postgresql.service";
      wants = optional cfg.database.createLocally "postgresql.service";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/konbini";
        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];

        # File system access
        ReadWritePaths = [ cfg.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];

        # Resource limits
        LimitNOFILE = 65536;
      };

      environment = {
        DATABASE_URL = if cfg.database.createLocally
          then "postgresql:///${cfg.user}?host=/run/postgresql"
          else cfg.database.url;
        BSKY_HANDLE = cfg.bluesky.handle;
        PORT = toString cfg.port;
        SYNC_CONFIG = syncConfigFile;
      } // cfg.settings;

      # Load password from file
      script = ''
        export BSKY_PASSWORD=$(cat ${cfg.bluesky.passwordFile})
        exec ${cfg.package}/bin/konbini
      '';
    };

    # Firewall
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
