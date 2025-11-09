# Defines the NixOS module for the Indigo CollectionDir (collection discovery) service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.indigo-collectiondir;
in
{
  options.services.indigo-collectiondir = {
    enable = mkEnableOption "Indigo CollectionDir collection discovery service";

    package = mkOption {
      type = types.package;
      default = pkgs.bluesky-indigo-collectiondir;
      description = "The Indigo CollectionDir package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/indigo-collectiondir";
      description = "The absolute path to the directory to store Pebble KV data in.";
    };

    user = mkOption {
      type = types.str;
      default = "indigo-collectiondir";
      description = "User account for Indigo CollectionDir service.";
    };

    group = mkOption {
      type = types.str;
      default = "indigo-collectiondir";
      description = "Group for Indigo CollectionDir service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 2584;
            description = "Port for the CollectionDir service to listen on.";
          };

          firehoseUrl = mkOption {
            type = types.str;
            description = "URL to relay or PDS firehose for event subscription.";
            example = "wss://relay.bsky.social/xrpc/com.atproto.sync.subscribeRepos";
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
      description = "Indigo CollectionDir service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.firehoseUrl != "";
        message = "services.indigo-collectiondir: firehoseUrl must be specified";
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
    systemd.services.indigo-collectiondir = {
      description = "Indigo CollectionDir collection discovery service";
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
        COLLECTIONDIR_PORT = toString cfg.settings.port;
        COLLECTIONDIR_FIREHOSE_URL = cfg.settings.firehoseUrl;
      } // lib.optionalAttrs (cfg.settings.metrics.enable) {
        COLLECTIONDIR_METRICS_PORT = toString cfg.settings.metrics.port;
      };

      script = ''
        exec ${cfg.package}/bin/collectiondir
      '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.port ]
      ++ lib.optional cfg.settings.metrics.enable cfg.settings.metrics.port;
  };
}
