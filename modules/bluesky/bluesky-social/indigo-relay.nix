# Defines the NixOS module for the Indigo Relay service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.indigo-relay;
in
{
  options.services.indigo-relay = {
    enable = mkEnableOption "Indigo ATProto Relay service";

    package = mkOption {
      type = types.package;
      default = pkgs.bluesky-indigo-relay;
      description = "The Indigo Relay package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/indigo-relay";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "indigo-relay";
      description = "User account for Indigo Relay service.";
    };

    group = mkOption {
      type = types.str;
      default = "indigo-relay";
      description = "Group for Indigo Relay service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 2470;
            description = "Port for the relay service to listen on.";
          };

          hostname = mkOption {
            type = types.str;
            description = "Hostname for the relay service.";
            example = "relay.example.com";
          };

          database = {
            url = mkOption {
              type = types.str;
              description = "Database connection URL.";
              example = "postgres://user:pass@localhost/relay";
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

          bgsHost = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "BGS (Big Graph Service) host URL.";
          };

          adminPassword = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Admin password for relay management.";
          };

          adminPasswordFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "File containing admin password.";
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
              default = 2471;
              description = "Port for metrics endpoint.";
            };
          };

          rateLimit = {
            enable = mkEnableOption "rate limiting";

            requestsPerMinute = mkOption {
              type = types.int;
              default = 100;
              description = "Maximum requests per minute per IP.";
            };
          };
        };
      };
      default = {};
      description = "Indigo Relay service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.hostname != "";
        message = "services.indigo-relay: hostname must be specified";
      }
      {
        assertion = cfg.settings.database.url != "";
        message = "services.indigo-relay: database URL must be specified";
      }
      {
        assertion = (cfg.settings.adminPassword != null) != (cfg.settings.adminPasswordFile != null);
        message = "services.indigo-relay: exactly one of adminPassword or adminPasswordFile must be specified";
      }
    ];

    warnings = lib.optionals (cfg.settings.adminPassword != null) [
      "Indigo Relay admin password is specified in plain text - consider using adminPasswordFile instead"
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
    systemd.services.indigo-relay = {
      description = "Indigo ATProto Relay service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" ];
      wants = [ "network.target" ];

      preStart = lib.optionalString (cfg.package ? adminUi) ''
        # Copy admin UI to data directory
        mkdir -p ${cfg.dataDir}/public
        cp -rf ${cfg.package.adminUi}/* ${cfg.dataDir}/public/
        chmod -R u+w ${cfg.dataDir}/public
      '';

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
        RELAY_HOSTNAME = cfg.settings.hostname;
        RELAY_PORT = toString cfg.settings.port;
        RELAY_PLC_HOST = cfg.settings.plcHost;
        RELAY_DATABASE_URL = cfg.settings.database.url;
      } // lib.optionalAttrs (cfg.settings.bgsHost != null) {
        RELAY_BGS_HOST = cfg.settings.bgsHost;
      } // lib.optionalAttrs (cfg.settings.metrics.enable) {
        RELAY_METRICS_PORT = toString cfg.settings.metrics.port;
      } // lib.optionalAttrs (cfg.settings.rateLimit.enable) {
        RELAY_RATE_LIMIT_ENABLED = "true";
        RELAY_RATE_LIMIT_RPM = toString cfg.settings.rateLimit.requestsPerMinute;
      };

      script = 
        let
          passwordEnv = if cfg.settings.adminPasswordFile != null 
            then "RELAY_ADMIN_PASSWORD=$(cat ${cfg.settings.adminPasswordFile})"
            else "RELAY_ADMIN_PASSWORD=${cfg.settings.adminPassword}";
          
          dbPasswordEnv = if cfg.settings.database.passwordFile != null
            then "RELAY_DATABASE_URL=$(sed \"s/:pass@/:$(cat ${cfg.settings.database.passwordFile})@/\" <<< \"${cfg.settings.database.url}\")"
            else "";
        in
        ''
          ${lib.optionalString (cfg.settings.database.passwordFile != null) dbPasswordEnv}
          ${passwordEnv}
          export RELAY_ADMIN_PASSWORD
          ${lib.optionalString (cfg.settings.database.passwordFile != null) "export RELAY_DATABASE_URL"}

          exec ${cfg.package}/bin/relay serve
        '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.port ] 
      ++ lib.optional cfg.settings.metrics.enable cfg.settings.metrics.port;
  };
}