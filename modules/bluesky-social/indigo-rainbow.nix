# Defines the NixOS module for the Indigo Rainbow (firehose splitter) service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.indigo-rainbow;
in
{
  options.services.indigo-rainbow = {
    enable = mkEnableOption "Indigo Rainbow firehose splitter service";

    package = mkOption {
      type = types.package;
      default = pkgs.bluesky-social-indigo-rainbow or pkgs.indigo-rainbow;
      description = "The Indigo Rainbow package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/indigo-rainbow";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "indigo-rainbow";
      description = "User account for Indigo Rainbow service.";
    };

    group = mkOption {
      type = types.str;
      default = "indigo-rainbow";
      description = "Group for Indigo Rainbow service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 2472;
            description = "Port for the rainbow service to listen on.";
          };

          hostname = mkOption {
            type = types.str;
            description = "Hostname for the rainbow service.";
            example = "rainbow.example.com";
          };

          upstreamHost = mkOption {
            type = types.str;
            description = "Upstream firehose host to connect to.";
            example = "bsky.network";
          };

          database = {
            url = mkOption {
              type = types.str;
              description = "Database connection URL.";
              example = "postgres://user:pass@localhost/rainbow";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing database password.";
            };
          };

          plcHost = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "PLC directory host URL.";
          };

          maxConnections = mkOption {
            type = types.int;
            default = 1000;
            description = "Maximum number of concurrent connections.";
          };

          bufferSize = mkOption {
            type = types.int;
            default = 1000;
            description = "Buffer size for event processing.";
          };

          logLevel = mkOption {
            type = types.enum [ "debug" "info" "warn" "error" ];
            default = "info";
            description = "Logging level.";
          };

          metrics = {
            enable = mkEnableOption "Prometheus metrics endpoint";
            
            port = mkOption {
              type = types.port;
              default = 2473;
              description = "Port for metrics endpoint.";
            };
          };

          compression = {
            enable = mkEnableOption "gzip compression for responses";
          };
        };
      };
      default = {};
      description = "Indigo Rainbow service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.hostname != "";
        message = "services.indigo-rainbow: hostname must be specified";
      }
      {
        assertion = cfg.settings.upstreamHost != "";
        message = "services.indigo-rainbow: upstreamHost must be specified";
      }
      {
        assertion = cfg.settings.database.url != "";
        message = "services.indigo-rainbow: database URL must be specified";
      }
    ];

    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
    };

    users.groups.${cfg.group} = {};

    # Directory management
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # systemd service
    systemd.services.indigo-rainbow = {
      description = "Indigo Rainbow firehose splitter service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
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
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;

        # File system access
        ReadWritePaths = [ cfg.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };

      environment = {
        GOLOG_LOG_LEVEL = cfg.settings.logLevel;
        RAINBOW_HOSTNAME = cfg.settings.hostname;
        RAINBOW_PORT = toString cfg.settings.port;
        RAINBOW_UPSTREAM_HOST = cfg.settings.upstreamHost;
        RAINBOW_PLC_HOST = cfg.settings.plcHost;
        RAINBOW_DATABASE_URL = cfg.settings.database.url;
        RAINBOW_MAX_CONNECTIONS = toString cfg.settings.maxConnections;
        RAINBOW_BUFFER_SIZE = toString cfg.settings.bufferSize;
      } // lib.optionalAttrs (cfg.settings.metrics.enable) {
        RAINBOW_METRICS_PORT = toString cfg.settings.metrics.port;
      } // lib.optionalAttrs (cfg.settings.compression.enable) {
        RAINBOW_COMPRESSION_ENABLED = "true";
      };

      script = 
        let
          dbPasswordEnv = if cfg.settings.database.passwordFile != null
            then "RAINBOW_DATABASE_URL=$(sed \"s/:pass@/:$(cat ${cfg.settings.database.passwordFile})@/\" <<< \"${cfg.settings.database.url}\")"
            else "";
        in
        ''
          ${lib.optionalString (cfg.settings.database.passwordFile != null) dbPasswordEnv}
          ${lib.optionalString (cfg.settings.database.passwordFile != null) "export RAINBOW_DATABASE_URL"}
          
          exec ${cfg.package}/bin/rainbow
        '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.port ] 
      ++ lib.optional cfg.settings.metrics.enable cfg.settings.metrics.port;
  };
}