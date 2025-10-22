# Defines the NixOS module for the Parakeet ATProto AppView
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.parakeet-social-parakeet;
in
{
  options.services.parakeet-social-parakeet = {
    enable = mkEnableOption "Parakeet ATProto AppView";

    package = mkOption {
      type = types.package;
      default = pkgs.parakeet-social-parakeet or pkgs.parakeet;
      description = "The Parakeet package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/atproto-parakeet";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "atproto-parakeet";
      description = "User account for Parakeet service.";
    };

    group = mkOption {
      type = types.str;
      default = "atproto-parakeet";
      description = "Group for Parakeet service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          appview = {
            port = mkOption {
              type = types.port;
              default = 6000;
              description = "Port for the Parakeet AppView server.";
            };

            bindAddress = mkOption {
              type = types.str;
              default = "0.0.0.0";
              description = "Address for the AppView server to bind to.";
            };

            did = mkOption {
              type = types.str;
              description = "DID for the AppView (did:web format).";
              example = "did:web:parakeet.example.com";
            };

            publicKey = mkOption {
              type = types.str;
              description = "Public key for the AppView.";
            };

            endpoint = mkOption {
              type = types.str;
              description = "HTTPS publicly accessible endpoint for the AppView.";
              example = "https://parakeet.example.com";
            };
          };

          consumer = {
            enable = mkEnableOption "Parakeet consumer service";

            indexer = {
              relaySource = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Relay to consume from.";
                example = "wss://bsky.network";
              };

              historyMode = mkOption {
                type = types.enum [ "backfill_history" "realtime" ];
                default = "realtime";
                description = "History mode for indexing.";
              };

              workers = mkOption {
                type = types.int;
                default = 4;
                description = "Number of indexer workers.";
              };

              startCommitSeq = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Relay sequence to start consuming from.";
              };

              skipHandleValidation = mkOption {
                type = types.bool;
                default = false;
                description = "Skip validating handles from identity events.";
              };

              requestBackfill = mkOption {
                type = types.bool;
                default = false;
                description = "Request backfill when relevant.";
              };
            };

            backfill = {
              workers = mkOption {
                type = types.int;
                default = 4;
                description = "Number of backfill workers.";
              };

              skipAggregation = mkOption {
                type = types.bool;
                default = false;
                description = "Skip sending aggregation to parakeet-index.";
              };

              downloadWorkers = mkOption {
                type = types.int;
                default = 25;
                description = "Number of download workers for backfilling.";
              };

              downloadBuffer = mkOption {
                type = types.int;
                default = 25000;
                description = "Number of repos to download and queue.";
              };

              downloadTmpDir = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "Directory to download repos to.";
              };
            };

            labelSource = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Labeler or label relay to consume.";
              example = "did:plc:ar7c4by46qjdydhdevvrndac";
            };

            resumePath = mkOption {
              type = types.path;
              default = "${cfg.dataDir}/cursor";
              description = "Where to store cursor data.";
            };

            userAgent = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Contact details to add to User-Agent.";
              example = "contact@example.com";
            };
          };

          index = {
            enable = mkEnableOption "Parakeet index service";

            port = mkOption {
              type = types.port;
              default = 6001;
              description = "Port for the index service.";
            };

            bindAddress = mkOption {
              type = types.str;
              default = "0.0.0.0";
              description = "Address for the index server to bind to.";
            };

            dbPath = mkOption {
              type = types.path;
              default = "${cfg.dataDir}/index";
              description = "Location to store the index database.";
            };
          };

          database = {
            url = mkOption {
              type = types.str;
              description = "PostgreSQL database URL.";
              example = "postgres://user:pass@localhost:5432/parakeet";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing database password.";
            };
          };

          redis = {
            url = mkOption {
              type = types.str;
              description = "Redis connection URL.";
              example = "redis://localhost:6379";
            };
          };

          plcDirectory = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "PLC directory URL.";
          };

          trustedVerifiers = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "List of trusted verifiers.";
            example = [ "did:plc:example1" "did:plc:example2" ];
          };

          cdn = {
            base = mkOption {
              type = types.str;
              default = "https://cdn.bsky.app";
              description = "Base URL for Bluesky compatible CDN.";
            };

            videoBase = mkOption {
              type = types.str;
              default = "https://video.bsky.app";
              description = "Base URL for Bluesky compatible video CDN.";
            };
          };

          didAllowlist = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "List of DIDs allowed to access the AppView.";
            example = [ "did:plc:example1" "did:plc:example2" ];
          };

          migrate = mkOption {
            type = types.bool;
            default = true;
            description = "Run database migrations automatically on start.";
          };

          logLevel = mkOption {
            type = types.enum [ "trace" "debug" "info" "warn" "error" ];
            default = "info";
            description = "Logging level.";
          };
        };
      };
      default = {};
      description = "Parakeet service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.database.url != "";
        message = "services.parakeet-social-parakeet: database URL must be specified";
      }
      {
        assertion = cfg.settings.redis.url != "";
        message = "services.parakeet-social-parakeet: Redis URL must be specified";
      }
      {
        assertion = cfg.settings.appview.did != "";
        message = "services.parakeet-social-parakeet: AppView DID must be specified";
      }
      {
        assertion = cfg.settings.consumer.enable -> (cfg.settings.consumer.indexer.relaySource != null);
        message = "services.parakeet-social-parakeet: relay source must be specified when consumer is enabled";
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
      "d '${cfg.dataDir}/logs' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${toString cfg.settings.consumer.resumePath}' 0750 ${cfg.user} ${cfg.group} - -"
    ] ++ optional cfg.settings.index.enable [
      "d '${toString cfg.settings.index.dbPath}' 0750 ${cfg.user} ${cfg.group} - -"
    ] ++ optional (cfg.settings.consumer.backfill.downloadTmpDir != null) [
      "d '${toString cfg.settings.consumer.backfill.downloadTmpDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # Parakeet AppView service
    systemd.services.parakeet-social-parakeet = {
      description = "Parakeet ATProto AppView";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" "redis.service" ] 
        ++ optional cfg.settings.index.enable [ "atproto-parakeet-index.service" ];
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
        PK_DATABASE_URL = cfg.settings.database.url;
        PK_REDIS_URI = cfg.settings.redis.url;
        PK_INDEX_URI = "localhost:${toString cfg.settings.index.port}";
        PK_PLC_DIRECTORY = cfg.settings.plcDirectory;
        PK_SERVER__BIND_ADDRESS = cfg.settings.appview.bindAddress;
        PK_SERVER__PORT = toString cfg.settings.appview.port;
        PK_SERVICE__DID = cfg.settings.appview.did;
        PK_SERVICE__PUBLIC_KEY = cfg.settings.appview.publicKey;
        PK_SERVICE__ENDPOINT = cfg.settings.appview.endpoint;
        PK_CDN__BASE = cfg.settings.cdn.base;
        PK_CDN__VIDEO_BASE = cfg.settings.cdn.videoBase;
        PK_MIGRATE = if cfg.settings.migrate then "true" else "false";
        RUST_LOG = cfg.settings.logLevel;
      } // optionalAttrs (cfg.settings.trustedVerifiers != []) {
        PK_TRUSTED_VERIFIERS = concatStringsSep "," cfg.settings.trustedVerifiers;
      } // optionalAttrs (cfg.settings.didAllowlist != []) {
        PK_DID_ALLOWLIST = concatStringsSep "," cfg.settings.didAllowlist;
      };

      script = ''
        # Load secrets from files
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export PK_DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}

        exec ${cfg.package}/bin/parakeet
      '';
    };

    # Optional Parakeet consumer service
    systemd.services.parakeet-social-parakeet-consumer = mkIf cfg.settings.consumer.enable {
      description = "Parakeet consumer service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" "redis.service" ]
        ++ optional cfg.settings.index.enable [ "atproto-parakeet-index.service" ];
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
        ReadWritePaths = [ cfg.dataDir (toString cfg.settings.consumer.resumePath) ]
          ++ optional (cfg.settings.consumer.backfill.downloadTmpDir != null) 
             (toString cfg.settings.consumer.backfill.downloadTmpDir);
        ReadOnlyPaths = [ "/nix/store" ];
      };

      environment = {
        PKC_DATABASE__URL = cfg.settings.database.url;
        PKC_REDIS_URI = cfg.settings.redis.url;
        PKC_INDEX_URI = "localhost:${toString cfg.settings.index.port}";
        PKC_PLC_DIRECTORY = cfg.settings.plcDirectory;
        PKC_RESUME_PATH = toString cfg.settings.consumer.resumePath;
        PKC_INDEXER__INDEXER_WORKERS = toString cfg.settings.consumer.indexer.workers;
        PKC_INDEXER__HISTORY_MODE = cfg.settings.consumer.indexer.historyMode;
        PKC_INDEXER__SKIP_HANDLE_VALIDATION = if cfg.settings.consumer.indexer.skipHandleValidation then "true" else "false";
        PKC_INDEXER__REQUEST_BACKFILL = if cfg.settings.consumer.indexer.requestBackfill then "true" else "false";
        PKC_BACKFILL__WORKERS = toString cfg.settings.consumer.backfill.workers;
        PKC_BACKFILL__SKIP_AGGREGATION = if cfg.settings.consumer.backfill.skipAggregation then "true" else "false";
        PKC_BACKFILL__DOWNLOAD_WORKERS = toString cfg.settings.consumer.backfill.downloadWorkers;
        PKC_BACKFILL__DOWNLOAD_BUFFER = toString cfg.settings.consumer.backfill.downloadBuffer;
        RUST_LOG = cfg.settings.logLevel;
      } // optionalAttrs (cfg.settings.consumer.indexer.relaySource != null) {
        PKC_INDEXER__RELAY_SOURCE = cfg.settings.consumer.indexer.relaySource;
      } // optionalAttrs (cfg.settings.consumer.indexer.startCommitSeq != null) {
        PKC_INDEXER__START_COMMIT_SEQ = toString cfg.settings.consumer.indexer.startCommitSeq;
      } // optionalAttrs (cfg.settings.consumer.labelSource != null) {
        PKC_LABEL_SOURCE = cfg.settings.consumer.labelSource;
      } // optionalAttrs (cfg.settings.consumer.userAgent != null) {
        PKC_UA_CONTACT = cfg.settings.consumer.userAgent;
      } // optionalAttrs (cfg.settings.consumer.backfill.downloadTmpDir != null) {
        PKC_BACKFILL__DOWNLOAD_TMP_DIR = toString cfg.settings.consumer.backfill.downloadTmpDir;
      };

      script = ''
        # Load secrets from files
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export PKC_DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}

        exec ${cfg.package}/bin/consumer
      '';
    };

    # Optional Parakeet index service
    systemd.services.parakeet-social-parakeet-index = mkIf cfg.settings.index.enable {
      description = "Parakeet index service";
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
        ReadWritePaths = [ cfg.dataDir (toString cfg.settings.index.dbPath) ];
        ReadOnlyPaths = [ "/nix/store" ];
      };

      environment = {
        PKI_DATABASE_URL = cfg.settings.database.url;
        PKI_SERVER__BIND_ADDRESS = cfg.settings.index.bindAddress;
        PKI_SERVER__PORT = toString cfg.settings.index.port;
        PKI_INDEX_DB_PATH = toString cfg.settings.index.dbPath;
        RUST_LOG = cfg.settings.logLevel;
      };

      script = ''
        # Load secrets from files
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export PKI_DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}

        exec ${cfg.package}/bin/parakeet-index
      '';
    };
  };
}