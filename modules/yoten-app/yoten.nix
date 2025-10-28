# Defines the NixOS module for Yoten language learning social platform
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.yoten-app-yoten;
in
{
  options.services.yoten-app-yoten = {
    enable = mkEnableOption "Yoten language learning social platform";

    package = mkOption {
      type = types.package;
      default = pkgs.yoten-app-yoten or pkgs.yoten;
      description = "The Yoten package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/atproto-yoten";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "atproto-yoten";
      description = "User account for Yoten service.";
    };

    group = mkOption {
      type = types.str;
      default = "atproto-yoten";
      description = "Group for Yoten service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          server = {
            port = mkOption {
              type = types.port;
              default = 8080;
              description = "Port for the Yoten web server.";
            };

            hostname = mkOption {
              type = types.str;
              default = "localhost";
              description = "Hostname for the Yoten service.";
              example = "yoten.example.com";
            };

            publicUrl = mkOption {
              type = types.str;
              description = "Public URL for the Yoten service.";
              example = "https://yoten.example.com";
            };

            environment = mkOption {
              type = types.enum [ "development" "production" ];
              default = "production";
              description = "Application environment mode.";
            };
          };

          database = {
            type = mkOption {
              type = types.enum [ "sqlite" "postgres" ];
              default = "sqlite";
              description = "Database backend type.";
            };

            url = mkOption {
              type = types.str;
              default = "sqlite:///var/lib/atproto-yoten/yoten.db";
              description = "Database connection URL.";
              example = "postgresql://user:pass@localhost:5432/yoten";
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

          atproto = {
            pdsUrl = mkOption {
              type = types.str;
              default = "https://bsky.social";
              description = "AT Protocol PDS URL.";
            };

            handle = mkOption {
              type = types.str;
              description = "AT Protocol handle for the service.";
              example = "yoten.example.com";
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

            jetstream = {
              url = mkOption {
                type = types.str;
                default = "wss://jetstream.atproto.tools/subscribe";
                description = "Jetstream WebSocket URL for real-time updates.";
              };

              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Enable Jetstream integration for real-time updates.";
              };
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
              example = "https://yoten.example.com/auth/callback";
            };

            issuer = mkOption {
              type = types.str;
              default = "https://bsky.social";
              description = "OAuth issuer URL.";
            };
          };

          session = {
            secretFile = mkOption {
              type = types.path;
              description = "File containing session secret key.";
            };

            maxAge = mkOption {
              type = types.int;
              default = 86400; # 24 hours
              description = "Session maximum age in seconds.";
            };
          };

          redis = {
            url = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Redis connection URL for caching (optional).";
              example = "redis://localhost:6379";
            };
          };

          analytics = {
            posthog = {
              enable = mkEnableOption "PostHog analytics integration";

              apiKey = mkOption {
                type = types.str;
                default = "";
                description = "PostHog API key.";
              };

              host = mkOption {
                type = types.str;
                default = "https://app.posthog.com";
                description = "PostHog host URL.";
              };
            };
          };

          features = {
            registration = mkOption {
              type = types.bool;
              default = true;
              description = "Enable user registration.";
            };

            publicProfiles = mkOption {
              type = types.bool;
              default = true;
              description = "Enable public user profiles.";
            };

            socialFeatures = mkOption {
              type = types.bool;
              default = true;
              description = "Enable social features (following, sharing).";
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
      description = "Yoten service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.server.publicUrl != "";
        message = "services.yoten-app-yoten: public URL must be specified";
      }
      {
        assertion = cfg.settings.atproto.handle != "";
        message = "services.yoten-app-yoten: AT Protocol handle must be specified";
      }
      {
        assertion = cfg.settings.oauth.clientId != "";
        message = "services.yoten-app-yoten: OAuth client ID must be specified";
      }
      {
        assertion = cfg.settings.database.type == "postgres" -> (hasInfix "postgresql://" cfg.settings.database.url);
        message = "services.yoten-app-yoten: PostgreSQL URL must start with 'postgresql://' when using postgres database type";
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
      "d '${cfg.dataDir}/static' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # Yoten web application service
    systemd.services.yoten-app-yoten = {
      description = "Yoten language learning social platform";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] 
        ++ optional (cfg.settings.database.type == "postgres") [ "postgresql.service" ]
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
        # Server configuration
        PORT = toString cfg.settings.server.port;
        HOSTNAME = cfg.settings.server.hostname;
        PUBLIC_URL = cfg.settings.server.publicUrl;
        ENVIRONMENT = cfg.settings.server.environment;
        
        # Database configuration
        DATABASE_URL = cfg.settings.database.url;
        
        # AT Protocol configuration
        ATPROTO_PDS_URL = cfg.settings.atproto.pdsUrl;
        ATPROTO_HANDLE = cfg.settings.atproto.handle;
        ATPROTO_DID = cfg.settings.atproto.did;
        JETSTREAM_URL = cfg.settings.atproto.jetstream.url;
        JETSTREAM_ENABLED = if cfg.settings.atproto.jetstream.enable then "true" else "false";
        
        # OAuth configuration
        OAUTH_CLIENT_ID = cfg.settings.oauth.clientId;
        OAUTH_REDIRECT_URI = cfg.settings.oauth.redirectUri;
        OAUTH_ISSUER = cfg.settings.oauth.issuer;
        
        # Session configuration
        SESSION_MAX_AGE = toString cfg.settings.session.maxAge;
        
        # Feature flags
        REGISTRATION_ENABLED = if cfg.settings.features.registration then "true" else "false";
        PUBLIC_PROFILES_ENABLED = if cfg.settings.features.publicProfiles then "true" else "false";
        SOCIAL_FEATURES_ENABLED = if cfg.settings.features.socialFeatures then "true" else "false";
        
        # Logging
        LOG_LEVEL = cfg.settings.logLevel;
      } // optionalAttrs (cfg.settings.redis.url != null) {
        REDIS_URL = cfg.settings.redis.url;
      } // optionalAttrs cfg.settings.analytics.posthog.enable {
        POSTHOG_API_KEY = cfg.settings.analytics.posthog.apiKey;
        POSTHOG_HOST = cfg.settings.analytics.posthog.host;
      } // optionalAttrs cfg.settings.monitoring.enable {
        METRICS_PORT = toString cfg.settings.monitoring.port;
      };

      script = ''
        # Load secrets from files
        export ATPROTO_SIGNING_KEY="$(cat ${cfg.settings.atproto.signingKeyFile})"
        export OAUTH_CLIENT_SECRET="$(cat ${cfg.settings.oauth.clientSecretFile})"
        export SESSION_SECRET="$(cat ${cfg.settings.session.secretFile})"
        
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}

        # Run database migrations if enabled
        ${optionalString cfg.settings.database.migrate ''
          ${cfg.package}/bin/yoten migrate
        ''}

        exec ${cfg.package}/bin/yoten
      '';
    };

    # Enable required system services based on configuration
    services.postgresql.enable = mkIf (cfg.settings.database.type == "postgres") (mkDefault true);
    services.redis.servers.yoten.enable = mkIf (cfg.settings.redis.url != null) (mkDefault true);
  };
}