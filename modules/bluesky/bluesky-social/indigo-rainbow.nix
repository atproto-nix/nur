# Defines the NixOS module for the Indigo Rainbow (firehose fanout/splitter) service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.indigo-rainbow;
in
{
  options.services.indigo-rainbow = {
    enable = mkEnableOption "Indigo Rainbow firehose fanout service";

    package = mkOption {
      type = types.package;
      default = pkgs.bluesky-indigo-rainbow;
      description = "The Indigo Rainbow package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/indigo-rainbow";
      description = "The absolute path to the directory to store Pebble KV data in.";
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
            default = 2473;
            description = "Port for the Rainbow WebSocket subscriptions to listen on.";
          };

          upstreamHost = mkOption {
            type = types.str;
            description = "Upstream relay or PDS host to subscribe to for firehose events.";
            example = "https://relay.bsky.social";
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
      description = "Indigo Rainbow service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.upstreamHost != "";
        message = "services.indigo-rainbow: upstreamHost must be specified";
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
      description = "Indigo Rainbow firehose fanout service";
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
        RAINBOW_UPSTREAM_HOST = cfg.settings.upstreamHost;
        RAINBOW_PORT = toString cfg.settings.port;
      } // lib.optionalAttrs (cfg.settings.metrics.enable) {
        RAINBOW_METRICS_PORT = toString cfg.settings.metrics.port;
      };

      script = ''
        exec ${cfg.package}/bin/rainbow
      '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.port ]
      ++ lib.optional cfg.settings.metrics.enable cfg.settings.metrics.port;
  };
}
