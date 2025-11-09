# Defines the NixOS module for the Indigo Sonar (monitoring and metrics) service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.indigo-sonar;
in
{
  options.services.indigo-sonar = {
    enable = mkEnableOption "Indigo Sonar operational monitoring service";

    package = mkOption {
      type = types.package;
      default = pkgs.bluesky-indigo-sonar;
      description = "The Indigo Sonar package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "indigo-sonar";
      description = "User account for Indigo Sonar service.";
    };

    group = mkOption {
      type = types.str;
      default = "indigo-sonar";
      description = "Group for Indigo Sonar service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          firehoseUrl = mkOption {
            type = types.str;
            description = "URL to relay or PDS firehose for monitoring events.";
            example = "wss://relay.bsky.social/xrpc/com.atproto.sync.subscribeRepos";
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
      description = "Indigo Sonar service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.firehoseUrl != "";
        message = "services.indigo-sonar: firehoseUrl must be specified";
      }
    ];

    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };

    users.groups.${cfg.group} = {};

    # systemd service
    systemd.services.indigo-sonar = {
      description = "Indigo Sonar operational monitoring service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
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
        SONAR_FIREHOSE_URL = cfg.settings.firehoseUrl;
        SONAR_METRICS_PORT = toString cfg.settings.metricsPort;
      };

      script = ''
        exec ${cfg.package}/bin/sonar
      '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.metricsPort ];
  };
}
