# Defines the NixOS module for the Indigo NetSync (repo cloning/archival tool) service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.indigo-netsync;
in
{
  options.services.indigo-netsync = {
    enable = mkEnableOption "Indigo NetSync repository cloning tool";

    package = mkOption {
      type = types.package;
      default = pkgs.bluesky-indigo-netsync;
      description = "The Indigo NetSync package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/indigo-netsync";
      description = "The absolute path to the directory to store cloned repositories.";
    };

    user = mkOption {
      type = types.str;
      default = "indigo-netsync";
      description = "User account for Indigo NetSync service.";
    };

    group = mkOption {
      type = types.str;
      default = "indigo-netsync";
      description = "Group for Indigo NetSync service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          checkoutEndpoint = mkOption {
            type = types.str;
            description = "Endpoint for fetching repositories (PDS or relay).";
            example = "https://bsky.social";
          };

          workers = mkOption {
            type = types.int;
            default = 10;
            description = "Number of parallel worker threads for cloning.";
          };

          metricsPort = mkOption {
            type = types.port;
            default = 2471;
            description = "Port for Prometheus metrics endpoint.";
          };

          logLevel = mkOption {
            type = types.enum [ "debug" "info" "warn" "error" ];
            default = "info";
            description = "Logging level.";
          };
        };
      };
      default = {};
      description = "Indigo NetSync service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.checkoutEndpoint != "";
        message = "services.indigo-netsync: checkoutEndpoint must be specified";
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
    systemd.services.indigo-netsync = {
      description = "Indigo NetSync repository cloning and archival tool";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
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
        NETSYNC_CHECKOUT_ENDPOINT = cfg.settings.checkoutEndpoint;
        NETSYNC_WORKERS = toString cfg.settings.workers;
        NETSYNC_METRICS_PORT = toString cfg.settings.metricsPort;
      };

      script = ''
        exec ${cfg.package}/bin/netsync
      '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.metricsPort ];
  };
}
