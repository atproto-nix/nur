# Defines the NixOS module for the Leaflet collaborative writing platform
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.atproto-leaflet;
in
{
  options.services.atproto-leaflet = {
    enable = mkEnableOption "Leaflet collaborative writing platform";

    package = mkOption {
      type = types.package;
      default = pkgs.hyperlink-academy-leaflet or pkgs.leaflet;
      description = "The Leaflet package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/atproto-leaflet";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "atproto-leaflet";
      description = "User account for Leaflet service.";
    };

    group = mkOption {
      type = types.str;
      default = "atproto-leaflet";
      description = "Group for Leaflet service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 3000;
            description = "Port for the Leaflet web server.";
          };

          hostname = mkOption {
            type = types.str;
            default = "localhost";
            description = "Hostname for the Leaflet service.";
            example = "leaflet.example.com";
          };

          nodeEnv = mkOption {
            type = types.enum [ "development" "production" ];
            default = "production";
            description = "Node.js environment mode.";
          };

          database = {
            url = mkOption {
              type = types.str;
              description = "Supabase database URL.";
              example = "postgresql://user:pass@localhost:5432/leaflet";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing database password.";
            };
          };

          supabase = {
            url = mkOption {
              type = types.str;
              description = "Supabase project URL.";
              example = "https://your-project.supabase.co";
            };

            anonKey = mkOption {
              type = types.str;
              description = "Supabase anonymous key.";
            };

            serviceRoleKeyFile = mkOption {
              type = types.path;
              description = "File containing Supabase service role key.";
            };
          };

          replicache = {
            licenseKeyFile = mkOption {
              type = types.path;
              description = "File containing Replicache license key.";
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
              example = "https://leaflet.example.com/api/auth/callback";
            };
          };

          appview = {
            enable = mkEnableOption "Leaflet AppView service";

            port = mkOption {
              type = types.port;
              default = 8080;
              description = "Port for the AppView service.";
            };
          };

          feedService = {
            enable = mkEnableOption "Leaflet feed service";

            port = mkOption {
              type = types.port;
              default = 8081;
              description = "Port for the feed service.";
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
      description = "Leaflet service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.database.url != "";
        message = "services.atproto-leaflet: database URL must be specified";
      }
      {
        assertion = cfg.settings.supabase.url != "";
        message = "services.atproto-leaflet: Supabase URL must be specified";
      }
      {
        assertion = cfg.settings.oauth.clientId != "";
        message = "services.atproto-leaflet: OAuth client ID must be specified";
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

    # Main Leaflet web application service
    systemd.services.atproto-leaflet = {
      description = "Leaflet collaborative writing platform";
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
        NODE_ENV = cfg.settings.nodeEnv;
        PORT = toString cfg.settings.port;
        HOSTNAME = cfg.settings.hostname;
        DATABASE_URL = cfg.settings.database.url;
        SUPABASE_URL = cfg.settings.supabase.url;
        SUPABASE_ANON_KEY = cfg.settings.supabase.anonKey;
        OAUTH_CLIENT_ID = cfg.settings.oauth.clientId;
        OAUTH_REDIRECT_URI = cfg.settings.oauth.redirectUri;
        LOG_LEVEL = cfg.settings.logLevel;
      };

      script = ''
        # Load secrets from files
        export SUPABASE_SERVICE_ROLE_KEY="$(cat ${cfg.settings.supabase.serviceRoleKeyFile})"
        export REPLICACHE_LICENSE_KEY="$(cat ${cfg.settings.replicache.licenseKeyFile})"
        export OAUTH_CLIENT_SECRET="$(cat ${cfg.settings.oauth.clientSecretFile})"
        
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}

        exec ${cfg.package}/bin/leaflet
      '';
    };

    # Optional AppView service
    systemd.services.atproto-leaflet-appview = mkIf cfg.settings.appview.enable {
      description = "Leaflet AppView service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "atproto-leaflet.service" ];
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
        NODE_ENV = cfg.settings.nodeEnv;
        PORT = toString cfg.settings.appview.port;
        DATABASE_URL = cfg.settings.database.url;
        LOG_LEVEL = cfg.settings.logLevel;
      };

      script = ''
        # Load secrets from files
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}

        exec ${cfg.package}/bin/leaflet-appview
      '';
    };

    # Optional feed service
    systemd.services.atproto-leaflet-feedservice = mkIf cfg.settings.feedService.enable {
      description = "Leaflet feed service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "atproto-leaflet.service" ];
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
        NODE_ENV = cfg.settings.nodeEnv;
        PORT = toString cfg.settings.feedService.port;
        DATABASE_URL = cfg.settings.database.url;
        LOG_LEVEL = cfg.settings.logLevel;
      };

      script = ''
        # Load secrets from files
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}

        exec ${cfg.package}/bin/leaflet-feedservice
      '';
    };
  };
}