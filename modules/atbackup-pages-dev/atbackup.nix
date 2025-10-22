# Defines the NixOS module for the ATBackup service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.atbackup-pages-dev-atbackup;
in
{
  options.services.atbackup-pages-dev-atbackup = {
    enable = mkEnableOption "ATBackup AT Protocol backup service";

    package = mkOption {
      type = types.package;
      default = pkgs.atbackup-pages-dev-atbackup or pkgs.atbackup;
      description = "The ATBackup package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/atbackup";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "atbackup";
      description = "User account for ATBackup service.";
    };

    group = mkOption {
      type = types.str;
      default = "atbackup";
      description = "Group for ATBackup service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 3004;
            description = "Port for the ATBackup web interface.";
          };

          hostname = mkOption {
            type = types.str;
            default = "localhost";
            description = "Hostname for the ATBackup service.";
          };

          backups = {
            directory = mkOption {
              type = types.path;
              default = "${cfg.dataDir}/backups";
              description = "Directory to store backup files.";
            };

            schedule = {
              enable = mkEnableOption "automatic backup scheduling";

              interval = mkOption {
                type = types.str;
                default = "daily";
                description = "Backup interval (systemd timer format).";
                example = "hourly";
              };

              accounts = mkOption {
                type = types.listOf (types.submodule {
                  options = {
                    handle = mkOption {
                      type = types.str;
                      description = "AT Protocol handle to backup.";
                      example = "user.bsky.social";
                    };

                    pds = mkOption {
                      type = types.nullOr types.str;
                      default = null;
                      description = "PDS URL for this account.";
                      example = "https://bsky.social";
                    };

                    authFile = mkOption {
                      type = types.path;
                      description = "File containing authentication credentials.";
                    };

                    compression = mkOption {
                      type = types.bool;
                      default = true;
                      description = "Enable compression for backup files.";
                    };

                    retention = mkOption {
                      type = types.int;
                      default = 30;
                      description = "Number of days to retain backups.";
                    };
                  };
                });
                default = [];
                description = "Accounts to backup automatically.";
              };
            };

            format = mkOption {
              type = types.enum [ "car" "json" "both" ];
              default = "car";
              description = "Backup file format.";
            };

            compression = mkOption {
              type = types.bool;
              default = true;
              description = "Enable compression for backup files.";
            };

            verification = mkOption {
              type = types.bool;
              default = true;
              description = "Enable backup verification after creation.";
            };
          };

          webInterface = {
            enable = mkEnableOption "web interface for backup management";

            auth = {
              enable = mkEnableOption "authentication for web interface";

              username = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Username for web interface authentication.";
              };

              passwordFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "File containing password for web interface.";
              };
            };

            maxUploadSize = mkOption {
              type = types.str;
              default = "100MB";
              description = "Maximum upload size for restore operations.";
            };
          };

          storage = {
            type = mkOption {
              type = types.enum [ "local" "s3" ];
              default = "local";
              description = "Storage backend for backups.";
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

          logLevel = mkOption {
            type = types.enum [ "DEBUG" "INFO" "WARN" "ERROR" ];
            default = "INFO";
            description = "Logging level.";
          };

          metrics = {
            enable = mkEnableOption "Prometheus metrics endpoint";
            
            port = mkOption {
              type = types.port;
              default = 3014;
              description = "Port for metrics endpoint.";
            };
          };
        };
      };
      default = {};
      description = "ATBackup service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.storage.type == "s3" -> (
          cfg.settings.storage.s3.bucket != null && 
          cfg.settings.storage.s3.region != null &&
          cfg.settings.storage.s3.accessKeyId != null &&
          cfg.settings.storage.s3.secretAccessKeyFile != null
        );
        message = "services.atbackup-pages-dev-atbackup: S3 configuration must be complete when using S3 storage";
      }
      {
        assertion = cfg.settings.webInterface.enable && cfg.settings.webInterface.auth.enable -> (
          cfg.settings.webInterface.auth.username != null &&
          cfg.settings.webInterface.auth.passwordFile != null
        );
        message = "services.atbackup-pages-dev-atbackup: web interface authentication requires username and passwordFile";
      }
      {
        assertion = cfg.settings.backups.schedule.enable -> (cfg.settings.backups.schedule.accounts != []);
        message = "services.atbackup-pages-dev-atbackup: scheduled backups require at least one account to be configured";
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
      "d '${cfg.settings.backups.directory}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # Generate backup configuration file
    environment.etc."atbackup/config.json" = {
      text = builtins.toJSON {
        backups = cfg.settings.backups.schedule.accounts;
        storage = cfg.settings.storage;
        format = cfg.settings.backups.format;
        compression = cfg.settings.backups.compression;
        verification = cfg.settings.backups.verification;
      };
      mode = "0640";
      user = cfg.user;
      group = cfg.group;
    };

    # Main ATBackup service
    systemd.services.atbackup-pages-dev-atbackup = mkIf cfg.settings.webInterface.enable {
      description = "ATBackup AT Protocol backup service";
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
        ReadWritePaths = [ cfg.dataDir cfg.settings.backups.directory ];
        ReadOnlyPaths = [ "/nix/store" "/etc/atbackup" ];
      };

      environment = {
        LOG_LEVEL = cfg.settings.logLevel;
        ATBACKUP_HOSTNAME = cfg.settings.hostname;
        ATBACKUP_PORT = toString cfg.settings.port;
        ATBACKUP_DATA_DIR = cfg.dataDir;
        ATBACKUP_BACKUPS_DIR = cfg.settings.backups.directory;
        ATBACKUP_CONFIG_FILE = "/etc/atbackup/config.json";
        ATBACKUP_STORAGE_TYPE = cfg.settings.storage.type;
        ATBACKUP_MAX_UPLOAD_SIZE = cfg.settings.webInterface.maxUploadSize;
      } // lib.optionalAttrs (cfg.settings.storage.type == "s3") {
        ATBACKUP_S3_BUCKET = cfg.settings.storage.s3.bucket;
        ATBACKUP_S3_REGION = cfg.settings.storage.s3.region;
        ATBACKUP_S3_ACCESS_KEY_ID = cfg.settings.storage.s3.accessKeyId;
      } // lib.optionalAttrs (cfg.settings.storage.s3.endpoint != null) {
        ATBACKUP_S3_ENDPOINT = cfg.settings.storage.s3.endpoint;
      } // lib.optionalAttrs (cfg.settings.webInterface.auth.enable) {
        ATBACKUP_AUTH_ENABLED = "true";
        ATBACKUP_AUTH_USERNAME = cfg.settings.webInterface.auth.username;
      } // lib.optionalAttrs (cfg.settings.metrics.enable) {
        ATBACKUP_METRICS_PORT = toString cfg.settings.metrics.port;
      };

      script = 
        let
          s3SecretEnv = if cfg.settings.storage.type == "s3" && cfg.settings.storage.s3.secretAccessKeyFile != null
            then "ATBACKUP_S3_SECRET_ACCESS_KEY=$(cat ${cfg.settings.storage.s3.secretAccessKeyFile})"
            else "";
          
          authPasswordEnv = if cfg.settings.webInterface.auth.enable && cfg.settings.webInterface.auth.passwordFile != null
            then "ATBACKUP_AUTH_PASSWORD=$(cat ${cfg.settings.webInterface.auth.passwordFile})"
            else "";
        in
        ''
          ${lib.optionalString (cfg.settings.storage.type == "s3" && cfg.settings.storage.s3.secretAccessKeyFile != null) s3SecretEnv}
          ${lib.optionalString (cfg.settings.webInterface.auth.enable && cfg.settings.webInterface.auth.passwordFile != null) authPasswordEnv}
          ${lib.optionalString (cfg.settings.storage.type == "s3" && cfg.settings.storage.s3.secretAccessKeyFile != null) "export ATBACKUP_S3_SECRET_ACCESS_KEY"}
          ${lib.optionalString (cfg.settings.webInterface.auth.enable && cfg.settings.webInterface.auth.passwordFile != null) "export ATBACKUP_AUTH_PASSWORD"}
          
          exec ${cfg.package}/bin/atbackup-server
        '';
    };

    # Scheduled backup service
    systemd.services.atbackup-pages-dev-atbackup-scheduler = mkIf cfg.settings.backups.schedule.enable {
      description = "ATBackup scheduled backup service";
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;

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
        ReadWritePaths = [ cfg.dataDir cfg.settings.backups.directory ];
        ReadOnlyPaths = [ "/nix/store" "/etc/atbackup" ];
      };

      script = ''
        exec ${cfg.package}/bin/atbackup-cli backup --config /etc/atbackup/config.json
      '';
    };

    # Scheduled backup timer
    systemd.timers.atbackup-scheduler = mkIf cfg.settings.backups.schedule.enable {
      description = "ATBackup scheduled backup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.settings.backups.schedule.interval;
        Persistent = true;
        RandomizedDelaySec = "300";
      };
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = lib.optional cfg.settings.webInterface.enable cfg.settings.port
      ++ lib.optional cfg.settings.metrics.enable cfg.settings.metrics.port;
  };
}