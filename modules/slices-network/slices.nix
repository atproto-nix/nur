# Defines the NixOS module for the Slices custom AppView platform
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.atproto-slices;
in
{
  options.services.atproto-slices = {
    enable = mkEnableOption "Slices custom AppView platform";

    package = mkOption {
      type = types.package;
      default = pkgs.slices-network-slices or pkgs.slices;
      description = "The Slices package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/atproto-slices";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "atproto-slices";
      description = "User account for Slices service.";
    };

    group = mkOption {
      type = types.str;
      default = "atproto-slices";
      description = "Group for Slices service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          api = {
            port = mkOption {
              type = types.port;
              default = 3000;
              description = "Port for the Slices API server.";
            };

            processType = mkOption {
              type = types.enum [ "all" "app" "worker" ];
              default = "all";
              description = "Process type: all (HTTP + Jetstream), app, or worker.";
            };

            maxSyncRepos = mkOption {
              type = types.int;
              default = 5000;
              description = "Maximum repositories per sync operation.";
            };
          };

          frontend = {
            enable = mkEnableOption "Slices frontend service";

            port = mkOption {
              type = types.port;
              default = 8080;
              description = "Port for the Slices frontend server.";
            };
          };

          database = {
            url = mkOption {
              type = types.str;
              description = "PostgreSQL database URL.";
              example = "postgresql://user:pass@localhost:5432/slices";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing database password.";
            };
          };

          oauth = {
            clientId = mkOption {
              type = types.str;
              description = "OAuth application client ID.";
            };

            clientSecretFile = mkOption {
              type = types.path;
              description = "File containing OAuth client secret.";
            };

            redirectUri = mkOption {
              type = types.str;
              description = "OAuth callback URL.";
              example = "https://slices.example.com/auth/callback";
            };

            aipBaseUrl = mkOption {
              type = types.str;
              description = "AIP OAuth service URL.";
              example = "https://auth.slices.example.com";
            };
          };

          atproto = {
            relayEndpoint = mkOption {
              type = types.str;
              default = "https://relay1.us-west.bsky.network";
              description = "AT Protocol relay endpoint for backfill.";
            };

            jetstreamHostname = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "AT Protocol Jetstream hostname.";
              example = "jetstream1.us-east.bsky.network";
            };

            systemSliceUri = mkOption {
              type = types.str;
              description = "System slice URI.";
              example = "at://did:plc:example/network.slices.slice/example";
            };

            sliceUri = mkOption {
              type = types.str;
              description = "Default slice URI for queries.";
              example = "at://did:plc:example/network.slices.slice/example";
            };
          };

          redis = {
            url = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Redis connection URL (optional, falls back to in-memory cache).";
              example = "redis://localhost:6379";
            };

            ttlSeconds = mkOption {
              type = types.int;
              default = 3600;
              description = "Redis cache TTL in seconds.";
            };
          };

          jetstream = {
            cursorWriteIntervalSecs = mkOption {
              type = types.int;
              default = 30;
              description = "Interval for writing Jetstream cursor position.";
            };
          };

          adminDid = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Admin DID for privileged operations.";
            example = "did:plc:example123";
          };

          logLevel = mkOption {
            type = types.enum [ "trace" "debug" "info" "warn" "error" ];
            default = "info";
            description = "Logging level.";
          };
        };
      };
      default = {};
      description = "Slices service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.database.url != "";
        message = "services.atproto-slices: database URL must be specified";
      }
      {
        assertion = cfg.settings.oauth.clientId != "";
        message = "services.atproto-slices: OAuth client ID must be specified";
      }
      {
        assertion = cfg.settings.atproto.systemSliceUri != "";
        message = "services.atproto-slices: system slice URI must be specified";
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
    ];

    # Slices API service
    systemd.services.atproto-slices-api = {
      description = "Slices API server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" ] ++ optional (cfg.settings.redis.url != null) [ "redis.service" ];
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
        DATABASE_URL = cfg.settings.database.url;
        PORT = toString cfg.settings.api.port;
        PROCESS_TYPE = cfg.settings.api.processType;
        RELAY_ENDPOINT = cfg.settings.atproto.relayEndpoint;
        SYSTEM_SLICE_URI = cfg.settings.atproto.systemSliceUri;
        DEFAULT_MAX_SYNC_REPOS = toString cfg.settings.api.maxSyncRepos;
        JETSTREAM_CURSOR_WRITE_INTERVAL_SECS = toString cfg.settings.jetstream.cursorWriteIntervalSecs;
        RUST_LOG = cfg.settings.logLevel;
      } // optionalAttrs (cfg.settings.atproto.jetstreamHostname != null) {
        JETSTREAM_HOSTNAME = cfg.settings.atproto.jetstreamHostname;
      } // optionalAttrs (cfg.settings.redis.url != null) {
        REDIS_URL = cfg.settings.redis.url;
        REDIS_TTL_SECONDS = toString cfg.settings.redis.ttlSeconds;
      } // optionalAttrs (cfg.settings.adminDid != null) {
        ADMIN_DID = cfg.settings.adminDid;
      };

      script = ''
        # Load secrets from files
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}

        exec ${cfg.package}/bin/slices-api
      '';
    };

    # Optional Slices frontend service
    systemd.services.atproto-slices-frontend = mkIf cfg.settings.frontend.enable {
      description = "Slices frontend server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "atproto-slices-api.service" ];
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
        OAUTH_CLIENT_ID = cfg.settings.oauth.clientId;
        OAUTH_REDIRECT_URI = cfg.settings.oauth.redirectUri;
        OAUTH_AIP_BASE_URL = cfg.settings.oauth.aipBaseUrl;
        API_URL = "http://localhost:${toString cfg.settings.api.port}";
        SLICE_URI = cfg.settings.atproto.sliceUri;
        DATABASE_URL = "${cfg.dataDir}/slices-frontend.db";  # SQLite for frontend sessions
        PORT = toString cfg.settings.frontend.port;
      } // optionalAttrs (cfg.settings.adminDid != null) {
        ADMIN_DID = cfg.settings.adminDid;
      };

      script = ''
        # Load secrets from files
        export OAUTH_CLIENT_SECRET="$(cat ${cfg.settings.oauth.clientSecretFile})"

        exec ${cfg.package}/bin/slices-frontend
      '';
    };
  };
}