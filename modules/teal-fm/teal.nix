# Defines the NixOS module for the Teal ATProto platform
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.atproto-teal;
in
{
  options.services.atproto-teal = {
    enable = mkEnableOption "Teal ATProto platform";

    package = mkOption {
      type = types.package;
      default = pkgs.teal-fm-teal or pkgs.teal;
      description = "The Teal package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/atproto-teal";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "atproto-teal";
      description = "User account for Teal service.";
    };

    group = mkOption {
      type = types.str;
      default = "atproto-teal";
      description = "Group for Teal service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          aqua = {
            enable = mkEnableOption "Teal Aqua web application";

            port = mkOption {
              type = types.port;
              default = 3000;
              description = "Port for the Aqua web server.";
            };

            hostname = mkOption {
              type = types.str;
              default = "localhost";
              description = "Hostname for the Aqua service.";
              example = "teal.example.com";
            };

            nodeEnv = mkOption {
              type = types.enum [ "development" "production" ];
              default = "production";
              description = "Node.js environment mode.";
            };
          };

          services = {
            garnet = {
              enable = mkEnableOption "Teal Garnet service";

              port = mkOption {
                type = types.port;
                default = 8080;
                description = "Port for the Garnet service.";
              };
            };

            amethyst = {
              enable = mkEnableOption "Teal Amethyst service";

              port = mkOption {
                type = types.port;
                default = 8081;
                description = "Port for the Amethyst service.";
              };
            };

            piper = {
              enable = mkEnableOption "Teal Piper music scraper service";

              port = mkOption {
                type = types.port;
                default = 8082;
                description = "Port for the Piper service.";
              };
            };
          };

          database = {
            url = mkOption {
              type = types.str;
              description = "PostgreSQL database URL.";
              example = "postgresql://user:pass@localhost:5432/teal";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing database password.";
            };

            migrate = mkOption {
              type = types.bool;
              default = true;
              description = "Run database migrations automatically on start.";
            };
          };

          oauth = {
            clientId = mkOption {
              type = types.str;
              description = "AT Protocol OAuth client ID.";
            };

            clientSecretFile = mkOption {
              type = types.path;
              description = "File containing AT Protocol OAuth client secret.";
            };

            redirectUri = mkOption {
              type = types.str;
              description = "OAuth redirect URI.";
              example = "https://teal.example.com/api/auth/callback";
            };

            issuer = mkOption {
              type = types.str;
              default = "https://bsky.social";
              description = "OAuth issuer URL.";
            };
          };

          atproto = {
            pdsUrl = mkOption {
              type = types.str;
              default = "https://bsky.social";
              description = "AT Protocol PDS URL.";
            };

            handle = mkOption {
              type = types.str;
              description = "AT Protocol handle for the service.";
              example = "teal.example.com";
            };

            did = mkOption {
              type = types.str;
              description = "AT Protocol DID for the service.";
              example = "did:plc:example123";
            };

            signingKeyFile = mkOption {
              type = types.path;
              description = "File containing AT Protocol signing key.";
            };
          };

          cdn = {
            baseUrl = mkOption {
              type = types.str;
              default = "https://cdn.bsky.app";
              description = "Base URL for CDN resources.";
            };
          };

          redis = {
            url = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Redis connection URL (optional).";
              example = "redis://localhost:6379";
            };
          };

          s3 = {
            enable = mkEnableOption "S3 storage configuration";

            bucket = mkOption {
              type = types.str;
              default = "";
              description = "S3 bucket name.";
            };

            region = mkOption {
              type = types.str;
              default = "us-east-1";
              description = "S3 region.";
            };

            accessKeyFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing S3 access key.";
            };

            secretKeyFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing S3 secret key.";
            };
          };

          monitoring = {
            enable = mkEnableOption "monitoring and metrics";

            port = mkOption {
              type = types.port;
              default = 9090;
              description = "Port for metrics endpoint.";
            };
          };

          logLevel = mkOption {
            type = types.enum [ "trace" "debug" "info" "warn" "error" ];
            default = "info";
            description = "Logging level.";
          };
        };
      };
      default = {};
      description = "Teal service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.database.url != "";
        message = "services.atproto-teal: database URL must be specified";
      }
      {
        assertion = cfg.settings.oauth.clientId != "";
        message = "services.atproto-teal: OAuth client ID must be specified";
      }
      {
        assertion = cfg.settings.atproto.handle != "";
        message = "services.atproto-teal: AT Protocol handle must be specified";
      }
      {
        assertion = cfg.settings.s3.enable -> (cfg.settings.s3.bucket != "");
        message = "services.atproto-teal: S3 bucket must be specified when S3 is enabled";
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

    # Teal Aqua web application service
    systemd.services.atproto-teal-aqua = mkIf cfg.settings.aqua.enable {
      description = "Teal Aqua web application";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" ] 
        ++ optional (cfg.settings.redis.url != null) [ "redis.service" ];
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
        NODE_ENV = cfg.settings.aqua.nodeEnv;
        PORT = toString cfg.settings.aqua.port;
        HOSTNAME = cfg.settings.aqua.hostname;
        DATABASE_URL = cfg.settings.database.url;
        OAUTH_CLIENT_ID = cfg.settings.oauth.clientId;
        OAUTH_REDIRECT_URI = cfg.settings.oauth.redirectUri;
        OAUTH_ISSUER = cfg.settings.oauth.issuer;
        ATPROTO_PDS_URL = cfg.settings.atproto.pdsUrl;
        ATPROTO_HANDLE = cfg.settings.atproto.handle;
        ATPROTO_DID = cfg.settings.atproto.did;
        CDN_BASE_URL = cfg.settings.cdn.baseUrl;
        LOG_LEVEL = cfg.settings.logLevel;
      } // optionalAttrs (cfg.settings.redis.url != null) {
        REDIS_URL = cfg.settings.redis.url;
      } // optionalAttrs cfg.settings.s3.enable {
        S3_BUCKET = cfg.settings.s3.bucket;
        S3_REGION = cfg.settings.s3.region;
      } // optionalAttrs cfg.settings.monitoring.enable {
        METRICS_PORT = toString cfg.settings.monitoring.port;
      };

      script = ''
        # Load secrets from files
        export OAUTH_CLIENT_SECRET="$(cat ${cfg.settings.oauth.clientSecretFile})"
        export ATPROTO_SIGNING_KEY="$(cat ${cfg.settings.atproto.signingKeyFile})"
        
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}
        
        ${optionalString (cfg.settings.s3.enable && cfg.settings.s3.accessKeyFile != null) ''
          export S3_ACCESS_KEY="$(cat ${cfg.settings.s3.accessKeyFile})"
        ''}
        
        ${optionalString (cfg.settings.s3.enable && cfg.settings.s3.secretKeyFile != null) ''
          export S3_SECRET_KEY="$(cat ${cfg.settings.s3.secretKeyFile})"
        ''}

        # Run database migrations if enabled
        ${optionalString cfg.settings.database.migrate ''
          ${cfg.package}/bin/teal-migrate
        ''}

        exec ${cfg.package}/bin/teal-aqua
      '';
    };

    # Teal Garnet service
    systemd.services.atproto-teal-garnet = mkIf cfg.settings.services.garnet.enable {
      description = "Teal Garnet service";
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
        ReadWritePaths = [ cfg.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };

      environment = {
        PORT = toString cfg.settings.services.garnet.port;
        DATABASE_URL = cfg.settings.database.url;
        RUST_LOG = cfg.settings.logLevel;
      };

      script = ''
        # Load secrets from files
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}

        exec ${cfg.package}/bin/teal-garnet
      '';
    };

    # Teal Amethyst service
    systemd.services.atproto-teal-amethyst = mkIf cfg.settings.services.amethyst.enable {
      description = "Teal Amethyst service";
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
        ReadWritePaths = [ cfg.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };

      environment = {
        PORT = toString cfg.settings.services.amethyst.port;
        DATABASE_URL = cfg.settings.database.url;
        RUST_LOG = cfg.settings.logLevel;
      };

      script = ''
        # Load secrets from files
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}

        exec ${cfg.package}/bin/teal-amethyst
      '';
    };

    # Teal Piper music scraper service
    systemd.services.atproto-teal-piper = mkIf cfg.settings.services.piper.enable {
      description = "Teal Piper music scraper service";
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
        ReadWritePaths = [ cfg.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };

      environment = {
        PORT = toString cfg.settings.services.piper.port;
        DATABASE_URL = cfg.settings.database.url;
        RUST_LOG = cfg.settings.logLevel;
      };

      script = ''
        # Load secrets from files
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}

        exec ${cfg.package}/bin/teal-piper
      '';
    };
  };
}