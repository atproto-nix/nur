# Defines the NixOS module for the Indigo Bluepages (identity directory service) service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.indigo-bluepages;
in
{
  options.services.indigo-bluepages = {
    enable = mkEnableOption "Indigo Bluepages identity directory service";

    package = mkOption {
      type = types.package;
      default = pkgs.bluesky-indigo-bluepages;
      description = "The Indigo Bluepages package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "indigo-bluepages";
      description = "User account for Indigo Bluepages service.";
    };

    group = mkOption {
      type = types.str;
      default = "indigo-bluepages";
      description = "Group for Indigo Bluepages service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 2586;
            description = "Port for the Bluepages service to listen on.";
          };

          redisUrl = mkOption {
            type = types.str;
            description = "Redis connection URL for caching identity data.";
            example = "redis://localhost:6379";
          };

          adminToken = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Admin token for refresh operations (plain text, not recommended).";
          };

          adminTokenFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "File containing admin token for refresh operations.";
          };

          plcHost = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "PLC directory host URL.";
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
        };
      };
      default = {};
      description = "Indigo Bluepages service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.redisUrl != "";
        message = "services.indigo-bluepages: redisUrl must be specified";
      }
      {
        assertion = (cfg.settings.adminToken != null) != (cfg.settings.adminTokenFile != null);
        message = "services.indigo-bluepages: exactly one of adminToken or adminTokenFile must be specified";
      }
    ];

    warnings = lib.optionals (cfg.settings.adminToken != null) [
      "Indigo Bluepages admin token is specified in plain text - consider using adminTokenFile instead"
    ];

    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };

    users.groups.${cfg.group} = {};

    # systemd service
    systemd.services.indigo-bluepages = {
      description = "Indigo Bluepages identity directory service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "redis.service" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Type = "exec";
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
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;

        # Read-only access to /nix/store
        ReadOnlyPaths = [ "/nix/store" ];
      };

      environment = {
        GOLOG_LOG_LEVEL = cfg.settings.logLevel;
        BLUEPAGES_PORT = toString cfg.settings.port;
        BLUEPAGES_REDIS_URL = cfg.settings.redisUrl;
        BLUEPAGES_PLC_HOST = cfg.settings.plcHost;
      } // lib.optionalAttrs (cfg.settings.metrics.enable) {
        BLUEPAGES_METRICS_PORT = toString cfg.settings.metrics.port;
      };

      script =
        let
          tokenEnv = if cfg.settings.adminTokenFile != null
            then "BLUEPAGES_ADMIN_TOKEN=$(cat ${cfg.settings.adminTokenFile})"
            else "BLUEPAGES_ADMIN_TOKEN=${cfg.settings.adminToken}";
        in
        ''
          ${tokenEnv}
          export BLUEPAGES_ADMIN_TOKEN

          exec ${cfg.package}/bin/bluepages
        '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.port ]
      ++ lib.optional cfg.settings.metrics.enable cfg.settings.metrics.port;
  };
}
