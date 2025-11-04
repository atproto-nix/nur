# NixOS service module for Lycan - Custom feed generator for AT Protocol
# A Ruby/Sinatra application for creating custom feeds on Bluesky
#
# Configuration example:
#
# services.lycan = {
#   enable = true;
#   hostname = "feeds.example.com";
#   port = 3000;
#   database = {
#     host = "localhost";
#     name = "lycan";
#     user = "lycan";
#     passwordFile = "/run/secrets/lycan-db-password";
#   };
#   environment = {
#     RELAY_HOST = "bsky.network";
#     APPVIEW_HOST = "public.api.bsky.app";
#   };
# };

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.lycan;
  lycanPkg = pkgs.mackuba-lycan or pkgs.callPackage ../../pkgs/mackuba { inherit lib; };
in
{
  options.services.lycan = with types; {
    enable = mkEnableOption "Lycan feed generator service for AT Protocol";

    package = mkOption {
      type = package;
      default = lycanPkg;
      description = "The lycan package to use.";
    };

    user = mkOption {
      type = str;
      default = "lycan";
      description = "User account for lycan service.";
    };

    group = mkOption {
      type = str;
      default = "lycan";
      description = "Group for lycan service.";
    };

    dataDir = mkOption {
      type = path;
      default = "/var/lib/lycan";
      description = "Data directory for lycan service (logs, cache, etc).";
    };

    hostname = mkOption {
      type = str;
      default = "localhost";
      description = ''
        Hostname for the Lycan feed generator server.
        This is used to construct feed URIs and identify the server.
      '';
      example = "feeds.example.com";
    };

    port = mkOption {
      type = int;
      default = 3000;
      description = "Port to bind the Lycan web server to.";
    };

    bindAddress = mkOption {
      type = str;
      default = "127.0.0.1";
      description = "Address to bind the Lycan web server to.";
    };

    database = {
      host = mkOption {
        type = str;
        default = "localhost";
        description = "PostgreSQL database host.";
      };

      port = mkOption {
        type = int;
        default = 5432;
        description = "PostgreSQL database port.";
      };

      name = mkOption {
        type = str;
        default = "lycan";
        description = "PostgreSQL database name.";
      };

      user = mkOption {
        type = str;
        default = "lycan";
        description = "PostgreSQL database user.";
      };

      passwordFile = mkOption {
        type = nullOr path;
        default = null;
        description = ''
          Path to file containing PostgreSQL password.
          If null, password authentication is disabled.
        '';
      };

      createLocally = mkOption {
        type = bool;
        default = true;
        description = "Create PostgreSQL database and user locally.";
      };
    };

    relayHost = mkOption {
      type = str;
      default = "bsky.network";
      description = "ATProto relay host for firehose connections.";
    };

    appviewHost = mkOption {
      type = str;
      default = "public.api.bsky.app";
      description = "AppView host for service discovery.";
    };

    logLevel = mkOption {
      type = enum [ "debug" "info" "warn" "error" ];
      default = "info";
      description = "Logging level for the Lycan service.";
    };

    environment = mkOption {
      type = attrsOf str;
      default = {};
      description = ''
        Additional environment variables to pass to the Lycan service.
        Useful for customizing behavior without rewriting configuration.
      '';
      example = {
        FIREHOSE_USER_AGENT = "MyFeedGenerator/1.0";
        CUSTOM_LEXICON_URL = "https://example.com/lexicon.json";
      };
    };

    openFirewall = mkOption {
      type = bool;
      default = false;
      description = "Whether to open the firewall port for Lycan.";
    };

    workingDirectory = mkOption {
      type = path;
      default = "/var/lib/lycan";
      description = "Working directory for Lycan process.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Configuration validation
    {
      assertions = [
        {
          assertion = cfg.package != null;
          message = "services.lycan.package must be set to a valid package.";
        }
        {
          assertion = cfg.hostname != "";
          message = "services.lycan.hostname cannot be empty.";
        }
        {
          assertion = cfg.port > 0 && cfg.port < 65536;
          message = "services.lycan.port must be a valid port number (1-65535).";
        }
        {
          assertion = cfg.database.name != "";
          message = "services.lycan.database.name cannot be empty.";
        }
      ];

      warnings = lib.optionals (cfg.logLevel == "debug") [
        "Lycan debug logging enabled - performance may be impacted in production"
      ];
    }

    # User and group management
    {
      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
        createHome = false;
        description = "Lycan feed generator service user";
      };

      users.groups.${cfg.group} = {};
    }

    # Directory and tmpfiles management
    {
      systemd.tmpfiles.rules = [
        "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
        "d '${cfg.dataDir}/logs' 0750 ${cfg.user} ${cfg.group} - -"
        "d '${cfg.dataDir}/cache' 0750 ${cfg.user} ${cfg.group} - -"
      ];
    }

    # PostgreSQL database setup (optional local database)
    (mkIf cfg.database.createLocally {
      services.postgresql = {
        enable = true;
        ensureUsers = [
          {
            name = cfg.database.user;
            ensureDBOwnership = true;
          }
        ];
        ensureDatabases = [ cfg.database.name ];
      };
    })

    # systemd service configuration
    {
      systemd.services.lycan = {
        description = "Lycan - Custom feed generator for AT Protocol";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ] ++ (lib.optionals cfg.database.createLocally [ "postgresql.service" ]);
        wants = [ "network-online.target" ];

        path = with pkgs; [ ruby_3_3 ];

        environment = {
          # Server configuration
          SERVER_HOSTNAME = cfg.hostname;
          BIND_ADDRESS = cfg.bindAddress;
          PORT = toString cfg.port;

          # Database configuration
          DATABASE_URL =
            if cfg.database.passwordFile != null
            then "postgresql://${cfg.database.user}:$(cat ${cfg.database.passwordFile})@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}"
            else "postgresql://${cfg.database.user}@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}";

          # ATProto configuration
          RELAY_HOST = cfg.relayHost;
          APPVIEW_HOST = cfg.appviewHost;

          # Logging
          RACK_ENV = "production";
          RAILS_ENV = "production";
          LOG_LEVEL = lib.toUpper cfg.logLevel;

          # Ruby/Sinatra specific
          BUNDLE_GEMFILE = "${cfg.package}/Gemfile";
          BUNDLE_APP_CONFIG = "${cfg.dataDir}/.bundle";
        } // cfg.environment;

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.workingDirectory;
          StateDirectory = "lycan";
          CacheDirectory = "lycan";
          LogsDirectory = "lycan";

          # Security hardening
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          ProtectClock = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          RestrictNamespaces = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          RemoveIPC = true;
          PrivateMounts = true;
          PrivateDevices = true;
          RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
          SystemCallArchitectures = "native";
          UMask = "0077";

          # Restart policy
          Restart = "on-failure";
          RestartSec = "5s";
          StartLimitBurst = 5;
          StartLimitIntervalSec = "60s";

          # File access
          ReadWritePaths = [ cfg.dataDir ];
          ReadOnlyPaths = [ "${cfg.package}" ];

          # Execute start command
          ExecStart = ''
            ${pkgs.ruby_3_3}/bin/bundle exec \
            ${cfg.package}/bin/lycan
          '';

          # Graceful shutdown
          ExecStop = "${pkgs.coreutils}/bin/kill -TERM $MAINPID";
          TimeoutStopSec = 30;
        };

        preStart = mkIf cfg.database.createLocally ''
          # Run database migrations on startup
          ${pkgs.ruby_3_3}/bin/bundle exec ${cfg.package}/bin/lycan-rake db:migrate || true
        '';
      };
    }

    # Firewall configuration
    (mkIf cfg.openFirewall {
      networking.firewall = {
        allowedTCPPorts = [ cfg.port ];
      };
    })

    # Optional: Add nginx reverse proxy example
    # services.nginx.virtualHosts.${cfg.hostname} = {
    #   enableACME = true;
    #   forceSSL = true;
    #   locations."/" = {
    #     proxyPass = "http://${cfg.bindAddress}:${toString cfg.port}";
    #     proxyWebsockets = true;
    #   };
    # };
  ]);
}
