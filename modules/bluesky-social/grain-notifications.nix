# Defines the NixOS module for the Grain Notifications service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.grain-notifications;
in
{
  options.services.grain-notifications = {
    enable = mkEnableOption "Grain Notifications service";

    package = mkOption {
      type = types.package;
      default = pkgs.bluesky-social-grain-notifications or pkgs.grain-notifications;
      description = "The Grain Notifications package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/grain-notifications";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "grain-notifications";
      description = "User account for Grain Notifications service.";
    };

    group = mkOption {
      type = types.str;
      default = "grain-notifications";
      description = "Group for Grain Notifications service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 3002;
            description = "Port for the notifications service to listen on.";
          };

          hostname = mkOption {
            type = types.str;
            default = "localhost";
            description = "Hostname for the notifications service.";
          };

          firehoseHost = mkOption {
            type = types.str;
            description = "Firehose host to connect to for real-time events.";
            example = "bsky.network";
          };

          database = {
            url = mkOption {
              type = types.str;
              description = "Database connection URL.";
              example = "postgres://user:pass@localhost/grain_notifications";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing database password.";
            };
          };

          redis = {
            url = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Redis connection URL for real-time features.";
              example = "redis://localhost:6379";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing Redis password.";
            };
          };

          notifications = {
            batchSize = mkOption {
              type = types.int;
              default = 100;
              description = "Batch size for processing notifications.";
            };

            workers = mkOption {
              type = types.int;
              default = 2;
              description = "Number of notification worker threads.";
            };

            retentionDays = mkOption {
              type = types.int;
              default = 30;
              description = "Number of days to retain notifications.";
            };

            types = mkOption {
              type = types.listOf (types.enum [ "like" "repost" "follow" "mention" "reply" "gallery_like" "gallery_comment" ]);
              default = [ "like" "repost" "follow" "mention" "reply" "gallery_like" "gallery_comment" ];
              description = "Types of notifications to process.";
            };
          };

          websocket = {
            enable = mkEnableOption "WebSocket support for real-time notifications";

            maxConnections = mkOption {
              type = types.int;
              default = 1000;
              description = "Maximum number of WebSocket connections.";
            };

            pingInterval = mkOption {
              type = types.int;
              default = 30;
              description = "WebSocket ping interval in seconds.";
            };
          };

          email = {
            enable = mkEnableOption "email notifications";

            smtp = {
              host = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "SMTP server hostname.";
              };

              port = mkOption {
                type = types.port;
                default = 587;
                description = "SMTP server port.";
              };

              username = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "SMTP username.";
              };

              passwordFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "File containing SMTP password.";
              };

              fromAddress = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "From email address.";
                example = "notifications@grain.example.com";
              };

              tls = mkEnableOption "TLS encryption for SMTP";
            };

            templates = {
              directory = mkOption {
                type = types.path;
                default = "${cfg.dataDir}/templates";
                description = "Directory containing email templates.";
              };
            };
          };

          plcHost = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "PLC directory host URL.";
          };

          logLevel = mkOption {
            type = types.enum [ "DEBUG" "INFO" "WARN" "ERROR" ];
            default = "INFO";
            description = "Logging level.";
          };

          metrics = {
            enable = mkEnableOption "Prometheus metrics endpoint";
            
            port = mkOption {
              type = types.port;
              default = 3012;
              description = "Port for metrics endpoint.";
            };
          };
        };
      };
      default = {};
      description = "Grain Notifications service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.firehoseHost != "";
        message = "services.grain-notifications: firehoseHost must be specified";
      }
      {
        assertion = cfg.settings.database.url != "";
        message = "services.grain-notifications: database URL must be specified";
      }
      {
        assertion = cfg.settings.email.enable -> (
          cfg.settings.email.smtp.host != null &&
          cfg.settings.email.smtp.username != null &&
          cfg.settings.email.smtp.passwordFile != null &&
          cfg.settings.email.smtp.fromAddress != null
        );
        message = "services.grain-notifications: complete SMTP configuration required when email is enabled";
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
    ] ++ lib.optional (cfg.settings.email.enable) [
      "d '${cfg.settings.email.templates.directory}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # systemd service
    systemd.services.grain-notifications = {
      description = "Grain Notifications service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" ] 
        ++ lib.optional (cfg.settings.redis.url != null) [ "redis.service" ];
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
        ReadWritePaths = [ cfg.dataDir ] 
          ++ lib.optional (cfg.settings.email.enable) cfg.settings.email.templates.directory;
        ReadOnlyPaths = [ "/nix/store" ];
      };

      environment = {
        LOG_LEVEL = cfg.settings.logLevel;
        NOTIFICATIONS_HOSTNAME = cfg.settings.hostname;
        NOTIFICATIONS_PORT = toString cfg.settings.port;
        NOTIFICATIONS_FIREHOSE_HOST = cfg.settings.firehoseHost;
        NOTIFICATIONS_PLC_HOST = cfg.settings.plcHost;
        NOTIFICATIONS_DATABASE_URL = cfg.settings.database.url;
        NOTIFICATIONS_BATCH_SIZE = toString cfg.settings.notifications.batchSize;
        NOTIFICATIONS_WORKERS = toString cfg.settings.notifications.workers;
        NOTIFICATIONS_RETENTION_DAYS = toString cfg.settings.notifications.retentionDays;
        NOTIFICATIONS_TYPES = concatStringsSep "," cfg.settings.notifications.types;
      } // lib.optionalAttrs (cfg.settings.redis.url != null) {
        NOTIFICATIONS_REDIS_URL = cfg.settings.redis.url;
      } // lib.optionalAttrs (cfg.settings.websocket.enable) {
        NOTIFICATIONS_WEBSOCKET_ENABLED = "true";
        NOTIFICATIONS_WEBSOCKET_MAX_CONNECTIONS = toString cfg.settings.websocket.maxConnections;
        NOTIFICATIONS_WEBSOCKET_PING_INTERVAL = toString cfg.settings.websocket.pingInterval;
      } // lib.optionalAttrs (cfg.settings.email.enable) {
        NOTIFICATIONS_EMAIL_ENABLED = "true";
        NOTIFICATIONS_SMTP_HOST = cfg.settings.email.smtp.host;
        NOTIFICATIONS_SMTP_PORT = toString cfg.settings.email.smtp.port;
        NOTIFICATIONS_SMTP_USERNAME = cfg.settings.email.smtp.username;
        NOTIFICATIONS_SMTP_FROM_ADDRESS = cfg.settings.email.smtp.fromAddress;
        NOTIFICATIONS_EMAIL_TEMPLATES_DIR = cfg.settings.email.templates.directory;
      } // lib.optionalAttrs (cfg.settings.email.enable && cfg.settings.email.smtp.tls) {
        NOTIFICATIONS_SMTP_TLS = "true";
      } // lib.optionalAttrs (cfg.settings.metrics.enable) {
        NOTIFICATIONS_METRICS_PORT = toString cfg.settings.metrics.port;
      };

      script = 
        let
          dbPasswordEnv = if cfg.settings.database.passwordFile != null
            then "NOTIFICATIONS_DATABASE_URL=$(sed \"s/:pass@/:$(cat ${cfg.settings.database.passwordFile})@/\" <<< \"${cfg.settings.database.url}\")"
            else "";
          
          redisPasswordEnv = if cfg.settings.redis.url != null && cfg.settings.redis.passwordFile != null
            then "NOTIFICATIONS_REDIS_URL=$(sed \"s/:@/:$(cat ${cfg.settings.redis.passwordFile})@/\" <<< \"${cfg.settings.redis.url}\")"
            else "";
          
          smtpPasswordEnv = if cfg.settings.email.enable && cfg.settings.email.smtp.passwordFile != null
            then "NOTIFICATIONS_SMTP_PASSWORD=$(cat ${cfg.settings.email.smtp.passwordFile})"
            else "";
        in
        ''
          ${lib.optionalString (cfg.settings.database.passwordFile != null) dbPasswordEnv}
          ${lib.optionalString (cfg.settings.redis.url != null && cfg.settings.redis.passwordFile != null) redisPasswordEnv}
          ${lib.optionalString (cfg.settings.email.enable && cfg.settings.email.smtp.passwordFile != null) smtpPasswordEnv}
          ${lib.optionalString (cfg.settings.database.passwordFile != null) "export NOTIFICATIONS_DATABASE_URL"}
          ${lib.optionalString (cfg.settings.redis.url != null && cfg.settings.redis.passwordFile != null) "export NOTIFICATIONS_REDIS_URL"}
          ${lib.optionalString (cfg.settings.email.enable && cfg.settings.email.smtp.passwordFile != null) "export NOTIFICATIONS_SMTP_PASSWORD"}
          
          exec ${cfg.package}/bin/grain-notifications
        '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.port ] 
      ++ lib.optional cfg.settings.metrics.enable cfg.settings.metrics.port;
  };
}