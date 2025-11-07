{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.whyrusleeping.konbini;

  # Sync configuration file
  syncConfigFile = pkgs.writeText "sync-config.json" (builtins.toJSON cfg.syncConfig);

in
{
  options.services.whyrusleeping.konbini = {
    enable = mkEnableOption "Konbini - Friends of Friends Bluesky AppView with multi-service support (API, XRPC, pprof)";

    package = mkOption {
      type = types.package;
      default = pkgs.whyrusleeping-konbini;
      defaultText = literalExpression "pkgs.whyrusleeping-konbini";
      description = "The Konbini package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "konbini";
      description = "User account under which Konbini runs.";
    };

    group = mkOption {
      type = types.str;
      default = "konbini";
      description = "Group under which Konbini runs.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/konbini";
      description = "Directory where Konbini stores its data.";
    };

    apiPort = mkOption {
      type = types.port;
      default = 4444;
      description = ''
        Port for the Konbini API server (custom JSON API for frontend).
        NOTE: This port is hardcoded in the konbini application.
        This option controls firewall rules and reverse proxy configuration.
      '';
    };

    xrpcPort = mkOption {
      type = types.port;
      default = 4446;
      description = ''
        Port for the XRPC server (ATProto/Bluesky AppView compatibility).
        Allows the official Bluesky app to use Konbini as an AppView.
        NOTE: This port is hardcoded in the konbini application.
        This option controls firewall rules and reverse proxy configuration.
      '';
    };

    pprofPort = mkOption {
      type = types.port;
      default = 4445;
      description = ''
        Port for the pprof debugging server (Go profiling endpoints).
        NOTE: This port is hardcoded in the konbini application.
        This option controls firewall rules and reverse proxy configuration.
      '';
    };

    pprofEnable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the pprof debugging server. Disabled by default for security.";
    };

    hostname = mkOption {
      type = types.str;
      default = "localhost";
      example = "konbini.example.com";
      description = "Hostname for the Konbini AppView.";
    };

    database = {
      url = mkOption {
        type = types.str;
        description = "PostgreSQL database URL.";
        example = "postgresql://konbini:password@localhost:5432/konbini";
      };

      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = "Create a local PostgreSQL database for Konbini.";
      };
    };

    bluesky = {
      handleFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/konbini-handle";
        description = ''
          Path to file containing Bluesky handle (e.g., user.bsky.social).
          Used for authenticating with Bluesky to access the firehose.
        '';
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/konbini-password";
        description = ''
          Path to file containing Bluesky app password.
          Create an app password at https://bsky.app/settings/app-passwords
        '';
      };
    };

    syncConfig = mkOption {
      type = types.attrs;
      default = {
        backends = [
          {
            type = "firehose";
            host = "bsky.network";
          }
        ];
      };
      description = ''
        Sync backend configuration. Supports multiple backends including
        firehose and jetstream endpoints.
      '';
      example = literalExpression ''
        {
          backends = [
            {
              type = "jetstream";
              host = "jetstream1.us-west.bsky.network";
            }
          ];
        }
      '';
    };

    maxDatabaseConnections = mkOption {
      type = types.int;
      default = 0;
      description = ''
        Maximum number of database connections. Set to 0 for automatic (CPU count).
        Passed to konbini via --max-db-connections flag.
      '';
    };

    redis = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable Redis for identity caching, improving performance.
        '';
      };

      url = mkOption {
        type = types.str;
        example = "redis://localhost:6379";
        description = ''
          Redis connection URL. Only used if redis.enable is true.
        '';
      };
    };

    observability = {
      jaeger = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable Jaeger tracing for observability and debugging.
        '';
      };

      environment = mkOption {
        type = types.str;
        default = "production";
        example = "development";
        description = ''
          Environment name for tracing. Set to "development" for development deployments.
        '';
      };
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/konbini-env";
      description = ''
        Path to environment file containing additional configuration.
        This file can contain DATABASE_URL, BSKY_HANDLE, BSKY_PASSWORD, etc.
        Format: KEY=value (one per line).
      '';
    };

    extraEnv = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          LOG_LEVEL = "debug";
        }
      '';
      description = "Additional environment variables to set.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the firewall for Konbini service ports (API, XRPC, pprof).";
    };
  };

  config = mkIf cfg.enable {
    # Assertions
    assertions = [
      {
        assertion = cfg.bluesky.handleFile != null || cfg.environmentFile != null;
        message = "services.whyrusleeping.konbini: either bluesky.handleFile or environmentFile must be set";
      }
      {
        assertion = cfg.bluesky.passwordFile != null || cfg.environmentFile != null;
        message = "services.whyrusleeping.konbini: either bluesky.passwordFile or environmentFile must be set";
      }
      {
        assertion = cfg.database.createLocally -> (cfg.database.url == "postgresql://konbini@localhost/konbini" || cfg.database.url == "postgresql://${cfg.user}@localhost/${cfg.user}");
        message = "services.whyrusleeping.konbini: database.createLocally requires database.url to use local socket authentication";
      }
    ];

    # User and group configuration
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      description = "Konbini service user";
    };

    users.groups.${cfg.group} = {};

    # PostgreSQL database
    services.postgresql = mkIf cfg.database.createLocally {
      enable = true;
      ensureDatabases = [ "konbini" ];
      ensureUsers = [
        {
          name = cfg.user;
          ensureDBOwnership = true;
        }
      ];
    };

    # systemd service
    systemd.services.konbini = {
      description = "Konbini - Friends of Friends Bluesky AppView (multi-service: API, XRPC, pprof)";
      documentation = [ "https://github.com/whyrusleeping/konbini" ];
      after = [ "network.target" ] ++ optional cfg.database.createLocally "postgresql.service";
      requires = optional cfg.database.createLocally "postgresql.service";
      wantedBy = [ "multi-user.target" ];

      environment = {
        # Database URL (can be overridden by environmentFile)
        DATABASE_URL = if cfg.database.createLocally
          then "postgresql:///${cfg.user}?host=/run/postgresql"
          else cfg.database.url;

        # Hostname
        KONBINI_HOSTNAME = cfg.hostname;

        # Observability
        ENV = cfg.observability.environment;
      } // (optionalAttrs cfg.observability.jaeger {
        OTEL_ENABLED = "true";
      }) // cfg.extraEnv;

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;

        # Build command line with all flags
        ExecStart = let
          baseCmd = "${cfg.package}/bin/konbini";
          syncConfigFlag = "--sync-config ${syncConfigFile}";
          maxDbConnFlag = optionalString (cfg.maxDatabaseConnections > 0)
            "--max-db-connections ${toString cfg.maxDatabaseConnections}";
          redisFlag = optionalString cfg.redis.enable "--redis-url ${cfg.redis.url}";
          jaegerFlag = optionalString cfg.observability.jaeger "--jaeger";
        in "${baseCmd} ${syncConfigFlag} ${maxDbConnFlag} ${redisFlag} ${jaegerFlag}";

        Restart = "on-failure";
        RestartSec = "10s";

        # Load credentials from files
        LoadCredential = flatten [
          (optional (cfg.bluesky.handleFile != null) "bsky-handle:${cfg.bluesky.handleFile}")
          (optional (cfg.bluesky.passwordFile != null) "bsky-password:${cfg.bluesky.passwordFile}")
        ];

        # Environment file for secrets
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        SystemCallFilter = [ "@system-service" "~@privileged" ];
        PrivateNetwork = false;

        # Working directory
        WorkingDirectory = "/var/lib/konbini";
        StateDirectory = "konbini";
        StateDirectoryMode = "0750";

        # Resource limits
        LimitNOFILE = 65536;
      };

      # Set credentials as environment variables if provided
      script = mkIf (cfg.bluesky.handleFile != null || cfg.bluesky.passwordFile != null) ''
        ${optionalString (cfg.bluesky.handleFile != null) ''
          export BSKY_HANDLE="$(cat $CREDENTIALS_DIRECTORY/bsky-handle)"
        ''}
        ${optionalString (cfg.bluesky.passwordFile != null) ''
          export BSKY_PASSWORD="$(cat $CREDENTIALS_DIRECTORY/bsky-password)"
        ''}
        exec systemctl start konbini.service
      '';
    };

    # Firewall
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall (
      [ cfg.apiPort cfg.xrpcPort ]
      ++ optional cfg.pprofEnable cfg.pprofPort
    );
  };
}
