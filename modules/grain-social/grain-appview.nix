# Grain AppView Service Module
#
# STATUS: Experimental - Awaiting package implementation
#
# This module defines comprehensive configuration options for the Grain AppView service
# (photo-sharing web application), but the actual package is not yet implemented.
#
# TO IMPLEMENT:
# - Create /Users/jack/Software/nur-vps/pkgs/grain-social/appview.nix
# - Build with Deno runtime (buildDeno or buildNpmPackage)
# - Source: @grain.social/grain monorepo from Tangled.org
# - Requires: PostgreSQL client libs, image processing deps
#
# CONFIGURATION:
# services.grain-appview = {
#   enable = true;  # Will fail until package is implemented
#   settings = {
#     hostname = "grain.example.com";
#     firehoseHost = "bsky.network";
#     database.url = "postgres://...";
#     storage.type = "local";
#   };
# };
#
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.grain-appview;
in
{
  options.services.grain-appview = {
    enable = mkEnableOption "Grain AppView photo-sharing service";

    package = mkOption {
      type = types.package;
      default = pkgs.grain-social-appview or (throw "grain-social-appview package not found in pkgs");
      description = "The Grain AppView package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/grain-appview";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "grain-appview";
      description = "User account for Grain AppView service.";
    };

    group = mkOption {
      type = types.str;
      default = "grain-appview";
      description = "Group for Grain AppView service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 3000;
            description = "Port for the appview service to listen on.";
          };

          hostname = mkOption {
            type = types.str;
            description = "Hostname for the appview service.";
            example = "grain.example.com";
          };

          firehoseHost = mkOption {
            type = types.str;
            description = "Firehose host to connect to for data synchronization.";
            example = "bsky.network";
          };

          database = {
            url = mkOption {
              type = types.str;
              description = "Database connection URL.";
              example = "postgres://user:pass@localhost/grain";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing database password.";
            };
          };

          storage = {
            type = mkOption {
              type = types.enum [ "local" "s3" ];
              default = "local";
              description = "Storage backend for photos.";
            };

            localPath = mkOption {
              type = types.path;
              default = "${cfg.dataDir}/uploads";
              description = "Local storage path for photos.";
            };

            s3 = {
              bucket = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "S3 bucket name.";
              };

              region = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "S3 region.";
              };

              accessKeyId = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "S3 access key ID.";
              };

              secretAccessKeyFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "File containing S3 secret access key.";
              };

              endpoint = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Custom S3 endpoint URL.";
              };
            };
          };

          darkroom = {
            enable = mkEnableOption "integration with Darkroom service";

            url = mkOption {
              type = types.str;
              default = "http://localhost:3001";
              description = "Darkroom service URL for image processing.";
            };
          };

          notifications = {
            enable = mkEnableOption "integration with notifications service";

            url = mkOption {
              type = types.str;
              default = "http://localhost:3002";
              description = "Notifications service URL.";
            };
          };

          plcHost = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "PLC directory host URL.";
          };

          maxUploadSize = mkOption {
            type = types.str;
            default = "10MB";
            description = "Maximum upload size for photos.";
          };

          logLevel = mkOption {
            type = types.enum [ "DEBUG" "INFO" "WARN" "ERROR" ];
            default = "INFO";
            description = "Logging level.";
          };

          auth = {
            jwtSecret = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "JWT secret for session management.";
            };

            jwtSecretFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing JWT secret.";
            };
          };
        };
      };
      default = {};
      description = "Grain AppView service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.hostname != "";
        message = "services.grain-appview: hostname must be specified";
      }
      {
        assertion = cfg.settings.firehoseHost != "";
        message = "services.grain-appview: firehoseHost must be specified";
      }
      {
        assertion = cfg.settings.database.url != "";
        message = "services.grain-appview: database URL must be specified";
      }
      {
        assertion = cfg.settings.storage.type == "s3" -> (
          cfg.settings.storage.s3.bucket != null && 
          cfg.settings.storage.s3.region != null &&
          cfg.settings.storage.s3.accessKeyId != null &&
          cfg.settings.storage.s3.secretAccessKeyFile != null
        );
        message = "services.grain-appview: S3 configuration must be complete when using S3 storage";
      }
      {
        assertion = (cfg.settings.auth.jwtSecret != null) != (cfg.settings.auth.jwtSecretFile != null);
        message = "services.grain-appview: exactly one of jwtSecret or jwtSecretFile must be specified";
      }
    ];

    warnings = lib.optionals (cfg.settings.auth.jwtSecret != null) [
      "Grain AppView JWT secret is specified in plain text - consider using jwtSecretFile instead"
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
    ] ++ lib.optional (cfg.settings.storage.type == "local") [
      "d '${cfg.settings.storage.localPath}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # systemd service
    systemd.services.grain-appview = {
      description = "Grain AppView photo-sharing service";
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
        ReadWritePaths = [ cfg.dataDir ] 
          ++ lib.optional (cfg.settings.storage.type == "local") cfg.settings.storage.localPath;
        ReadOnlyPaths = [ "/nix/store" ];
      };

      environment = {
        LOG_LEVEL = cfg.settings.logLevel;
        GRAIN_HOSTNAME = cfg.settings.hostname;
        GRAIN_PORT = toString cfg.settings.port;
        GRAIN_FIREHOSE_HOST = cfg.settings.firehoseHost;
        GRAIN_PLC_HOST = cfg.settings.plcHost;
        GRAIN_DATABASE_URL = cfg.settings.database.url;
        GRAIN_STORAGE_TYPE = cfg.settings.storage.type;
        GRAIN_MAX_UPLOAD_SIZE = cfg.settings.maxUploadSize;
      } // lib.optionalAttrs (cfg.settings.storage.type == "local") {
        GRAIN_STORAGE_LOCAL_PATH = cfg.settings.storage.localPath;
      } // lib.optionalAttrs (cfg.settings.storage.type == "s3") {
        GRAIN_S3_BUCKET = cfg.settings.storage.s3.bucket;
        GRAIN_S3_REGION = cfg.settings.storage.s3.region;
        GRAIN_S3_ACCESS_KEY_ID = cfg.settings.storage.s3.accessKeyId;
      } // lib.optionalAttrs (cfg.settings.storage.s3.endpoint != null) {
        GRAIN_S3_ENDPOINT = cfg.settings.storage.s3.endpoint;
      } // lib.optionalAttrs (cfg.settings.darkroom.enable) {
        GRAIN_DARKROOM_URL = cfg.settings.darkroom.url;
      } // lib.optionalAttrs (cfg.settings.notifications.enable) {
        GRAIN_NOTIFICATIONS_URL = cfg.settings.notifications.url;
      };

      script = 
        let
          dbPasswordEnv = if cfg.settings.database.passwordFile != null
            then "GRAIN_DATABASE_URL=$(sed \"s/:pass@/:$(cat ${cfg.settings.database.passwordFile})@/\" <<< \"${cfg.settings.database.url}\")"
            else "";
          
          s3SecretEnv = if cfg.settings.storage.type == "s3" && cfg.settings.storage.s3.secretAccessKeyFile != null
            then "GRAIN_S3_SECRET_ACCESS_KEY=$(cat ${cfg.settings.storage.s3.secretAccessKeyFile})"
            else "";
          
          jwtSecretEnv = if cfg.settings.auth.jwtSecretFile != null
            then "GRAIN_JWT_SECRET=$(cat ${cfg.settings.auth.jwtSecretFile})"
            else if cfg.settings.auth.jwtSecret != null
            then "GRAIN_JWT_SECRET=${cfg.settings.auth.jwtSecret}"
            else "";
        in
        ''
          ${lib.optionalString (cfg.settings.database.passwordFile != null) dbPasswordEnv}
          ${lib.optionalString (cfg.settings.storage.type == "s3" && cfg.settings.storage.s3.secretAccessKeyFile != null) s3SecretEnv}
          ${jwtSecretEnv}
          ${lib.optionalString (cfg.settings.database.passwordFile != null) "export GRAIN_DATABASE_URL"}
          ${lib.optionalString (cfg.settings.storage.type == "s3" && cfg.settings.storage.s3.secretAccessKeyFile != null) "export GRAIN_S3_SECRET_ACCESS_KEY"}
          ${lib.optionalString (cfg.settings.auth.jwtSecret != null || cfg.settings.auth.jwtSecretFile != null) "export GRAIN_JWT_SECRET"}
          
          exec ${cfg.package}/bin/grain-appview
        '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.port ];
  };
}