# Defines the NixOS module for the Indigo Beemo (moderation notification bot) service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.indigo-beemo;
in
{
  options.services.indigo-beemo = {
    enable = mkEnableOption "Indigo Beemo moderation notification bot";

    package = mkOption {
      type = types.package;
      default = pkgs.bluesky-indigo-beemo;
      description = "The Indigo Beemo package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "indigo-beemo";
      description = "User account for Indigo Beemo service.";
    };

    group = mkOption {
      type = types.str;
      default = "indigo-beemo";
      description = "Group for Indigo Beemo service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          firehoseUrl = mkOption {
            type = types.str;
            description = "URL to relay or PDS firehose for event subscription.";
            example = "wss://relay.bsky.social/xrpc/com.atproto.sync.subscribeRepos";
          };

          pdsHost = mkOption {
            type = types.str;
            description = "PDS host for moderation operations.";
            example = "https://bsky.social";
          };

          adminToken = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Admin token for moderation actions (plain text, not recommended).";
          };

          adminTokenFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "File containing admin token for moderation actions.";
          };

          slackWebhook = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Slack webhook URL for notifications (plain text, not recommended).";
          };

          slackWebhookFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "File containing Slack webhook URL.";
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
        };
      };
      default = {};
      description = "Indigo Beemo service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.firehoseUrl != "";
        message = "services.indigo-beemo: firehoseUrl must be specified";
      }
      {
        assertion = cfg.settings.pdsHost != "";
        message = "services.indigo-beemo: pdsHost must be specified";
      }
      {
        assertion = (cfg.settings.adminToken != null) != (cfg.settings.adminTokenFile != null);
        message = "services.indigo-beemo: exactly one of adminToken or adminTokenFile must be specified";
      }
      {
        assertion = (cfg.settings.slackWebhook != null) != (cfg.settings.slackWebhookFile != null);
        message = "services.indigo-beemo: exactly one of slackWebhook or slackWebhookFile must be specified";
      }
    ];

    warnings = lib.optionals (cfg.settings.adminToken != null) [
      "Indigo Beemo admin token is specified in plain text - consider using adminTokenFile instead"
    ] ++ lib.optionals (cfg.settings.slackWebhook != null) [
      "Indigo Beemo Slack webhook is specified in plain text - consider using slackWebhookFile instead"
    ];

    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };

    users.groups.${cfg.group} = {};

    # systemd service
    systemd.services.indigo-beemo = {
      description = "Indigo Beemo moderation notification bot";
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
        BEEMO_FIREHOSE_URL = cfg.settings.firehoseUrl;
        BEEMO_PDS_HOST = cfg.settings.pdsHost;
        BEEMO_PLC_HOST = cfg.settings.plcHost;
      };

      script =
        let
          tokenEnv = if cfg.settings.adminTokenFile != null
            then "BEEMO_ADMIN_TOKEN=$(cat ${cfg.settings.adminTokenFile})"
            else "BEEMO_ADMIN_TOKEN=${cfg.settings.adminToken}";

          webhookEnv = if cfg.settings.slackWebhookFile != null
            then "BEEMO_SLACK_WEBHOOK=$(cat ${cfg.settings.slackWebhookFile})"
            else "BEEMO_SLACK_WEBHOOK=${cfg.settings.slackWebhook}";
        in
        ''
          ${tokenEnv}
          ${webhookEnv}
          export BEEMO_ADMIN_TOKEN
          export BEEMO_SLACK_WEBHOOK

          exec ${cfg.package}/bin/beemo
        '';
    };
  };
}
