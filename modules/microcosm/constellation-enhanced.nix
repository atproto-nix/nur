# Enhanced Constellation service with NixOS ecosystem integration
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-constellation;
  microcosmLib = import ../../lib/microcosm.nix { inherit lib; };
  nixosIntegration = import ../../lib/nixos-integration.nix { inherit lib config; };
in
{
  imports = [
    ../common/nixos-integration.nix
  ];

  options.services.microcosm-constellation = microcosmLib.mkMicrocosmServiceOptions "Constellation" {
    package = mkOption {
      type = types.package;
      default = pkgs.microcosm.constellation;
      description = "The Constellation package to use.";
    };

    backend = mkOption {
      type = types.enum [ "memory" "rocks" "postgres" ];
      default = "rocks";
      description = "The storage backend to use.";
    };

    jetstream = mkOption {
      type = types.str;
      description = "The Jetstream server to connect to.";
      example = "wss://jetstream1.us-east.bsky.network/subscribe";
    };

    # Database configuration for postgres backend
    database = mkOption {
      type = types.submodule {
        options = {
          type = mkOption {
            type = types.enum [ "postgres" "sqlite" ];
            default = "sqlite";
            description = "Database type to use";
          };
          
          url = mkOption {
            type = types.str;
            default = "sqlite://${cfg.dataDir}/constellation.db";
            description = "Database connection URL";
            example = "postgresql://constellation:password@localhost/constellation";
          };
          
          createDatabase = mkOption {
            type = types.bool;
            default = true;
            description = "Automatically create database and user for local PostgreSQL";
          };
          
          passwordFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "File containing database password";
          };
        };
      };
      default = {};
      description = "Database configuration";
    };

    # Metrics and monitoring
    metrics = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Prometheus metrics endpoint";
          
          port = mkOption {
            type = types.port;
            default = 9090;
            description = "Metrics endpoint port";
          };
          
          path = mkOption {
            type = types.str;
            default = "/metrics";
            description = "Metrics endpoint path";
          };
        };
      };
      default = {};
      description = "Metrics configuration";
    };

    # Nginx reverse proxy configuration
    nginx = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Nginx reverse proxy";
          
          serverName = mkOption {
            type = types.str;
            description = "Server name for nginx virtual host";
            example = "constellation.example.com";
          };
          
          port = mkOption {
            type = types.port;
            default = cfg.port;
            description = "Upstream port for nginx proxy";
          };
          
          ssl = {
            enable = mkEnableOption "SSL/TLS via ACME";
            force = mkOption {
              type = types.bool;
              default = true;
              description = "Force HTTPS redirects";
            };
          };
        };
      };
      default = {};
      description = "Nginx reverse proxy configuration";
    };

    # Backup configuration
    backup = {
      enable = mkEnableOption "database backups";

      directory = mkOption {
        type = types.path;
        default = "${cfg.dataDir}/backups";
        description = "Directory to store backups.";
      };

      interval = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Take backups every N hours. If null, no automatic backups.";
        example = 24;
      };

      maxOldBackups = mkOption {
        type = types.nullOr types.int;
        default = 7;
        description = "Keep at most this many backups, purging oldest first. Only used with interval.";
      };
      
      # Enhanced backup options using NixOS ecosystem
      restic = {
        enable = mkEnableOption "Restic backup integration";
        
        repository = mkOption {
          type = types.str;
          description = "Restic repository URL";
          example = "s3:s3.amazonaws.com/my-backup-bucket/constellation";
        };
        
        passwordFile = mkOption {
          type = types.path;
          description = "File containing restic repository password";
        };
      };
    };

    # Security configuration
    security = mkOption {
      type = types.submodule {
        options = {
          apparmor = {
            enable = mkEnableOption "AppArmor profile";
            enforce = mkOption {
              type = types.bool;
              default = true;
              description = "Enforce AppArmor profile (vs complain mode)";
            };
          };
          
          firewall = {
            enable = mkEnableOption "automatic firewall rules";
            allowedPorts = mkOption {
              type = types.listOf types.port;
              default = [];
              description = "Additional ports to allow through firewall";
            };
          };
        };
      };
      default = {};
      description = "Security configuration";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Configuration validation
    (microcosmLib.mkConfigValidation cfg "Constellation" (
      microcosmLib.mkJetstreamValidation cfg.jetstream ++
      [
        {
          assertion = cfg.backup.enable -> cfg.backup.directory != "";
          message = "Backup directory cannot be empty when backups are enabled.";
        }
        {
          assertion = cfg.backup.enable && cfg.backup.interval != null -> cfg.backup.interval > 0;
          message = "Backup interval must be greater than 0 when specified.";
        }
        {
          assertion = cfg.backup.enable && cfg.backup.maxOldBackups != null -> cfg.backup.maxOldBackups > 0;
          message = "Maximum old backups must be greater than 0 when specified.";
        }
        {
          assertion = cfg.nginx.enable -> cfg.nginx.serverName != "";
          message = "Nginx server name must be specified when nginx is enabled.";
        }
        {
          assertion = cfg.database.type == "postgres" -> (hasInfix "postgresql://" cfg.database.url);
          message = "PostgreSQL URL must start with 'postgresql://' when using postgres database type";
        }
      ]
    ))

    # User and group management
    (microcosmLib.mkUserConfig cfg)

    # Directory management
    (microcosmLib.mkDirectoryConfig cfg (optional cfg.backup.enable cfg.backup.directory))

    # Database integration
    (nixosIntegration.mkDatabaseIntegration "microcosm-constellation" cfg {
      type = cfg.database.type;
      url = cfg.database.url;
      createDatabase = cfg.database.createDatabase;
      database = "constellation";
      user = "constellation";
    })

    # Nginx integration
    (nixosIntegration.mkNginxIntegration "microcosm-constellation" cfg cfg.nginx)

    # Prometheus metrics integration
    (nixosIntegration.mkPrometheusIntegration "microcosm-constellation" cfg cfg.metrics)

    # Logging integration
    (nixosIntegration.mkLoggingIntegration "microcosm-constellation" cfg {
      level = cfg.logLevel;
      format = "json";
      files = optional cfg.backup.enable [ "${cfg.backup.directory}/*.log" ];
    })

    # Security integration
    (nixosIntegration.mkSecurityIntegration "microcosm-constellation" cfg cfg.security)

    # Backup integration
    (nixosIntegration.mkBackupIntegration "microcosm-constellation" cfg (cfg.backup // {
      extraPaths = optional (cfg.backend == "rocks") [ "${cfg.dataDir}/db" ];
    }))

    # Service dependencies
    (nixosIntegration.mkServiceDependencies "microcosm-constellation" 
      nixosIntegration.atprotoServiceDependencies.indexer)

    # systemd service with enhanced configuration
    (microcosmLib.mkSystemdService cfg "Constellation" {
      description = "Global backlink index for AT Protocol";
      extraReadWritePaths = optional cfg.backup.enable cfg.backup.directory;
      
      # Enhanced service dependencies
      after = [ "network.target" ] 
        ++ optional (cfg.database.type == "postgres") [ "postgresql.service" ]
        ++ optional cfg.nginx.enable [ "nginx.service" ];
      
      wants = [ "network.target" ]
        ++ optional (cfg.database.type == "postgres") [ "postgresql.service" ];
      
      serviceConfig = {
        ExecStart = 
          let
            args = flatten [
              [
                "--jetstream"
                (escapeShellArg cfg.jetstream)
                "--backend"
                (escapeShellArg cfg.backend)
              ]
              (optional (cfg.backend == "rocks") [
                "--data"
                (escapeShellArg "${cfg.dataDir}/db")
              ])
              (optional (cfg.backend == "postgres") [
                "--database-url"
                (escapeShellArg cfg.database.url)
              ])
              (optional cfg.metrics.enable [
                "--metrics-port"
                (escapeShellArg (toString cfg.metrics.port))
                "--metrics-path"
                (escapeShellArg cfg.metrics.path)
              ])
              (optional cfg.backup.enable [
                "--backup"
                (escapeShellArg cfg.backup.directory)
              ])
              (optional (cfg.backup.enable && cfg.backup.interval != null) [
                "--backup-interval"
                (escapeShellArg (toString cfg.backup.interval))
              ])
              (optional (cfg.backup.enable && cfg.backup.interval != null && cfg.backup.maxOldBackups != null) [
                "--max-old-backups"
                (escapeShellArg (toString cfg.backup.maxOldBackups))
              ])
            ];
          in
          "${cfg.package}/bin/main ${concatStringsSep " " args}";
        
        # Enhanced environment variables
        Environment = [
          "RUST_LOG=${cfg.logLevel}"
          "LOG_FORMAT=json"
        ] ++ optional (cfg.database.passwordFile != null) 
          "DATABASE_PASSWORD_FILE=${cfg.database.passwordFile}";
        
        # Health check configuration
        ExecStartPre = mkIf (cfg.database.type == "postgres") 
          "${pkgs.postgresql}/bin/pg_isready -h localhost -p 5432";
        
        # Restart policy for better reliability
        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitBurst = 3;
        StartLimitIntervalSec = "60s";
      };
    })

    # Enable global integration features based on service configuration
    {
      atproto.integration = {
        database.postgresql.enable = mkIf (cfg.database.type == "postgres") true;
        nginx.enable = mkIf cfg.nginx.enable true;
        monitoring.prometheus.enable = mkIf cfg.metrics.enable true;
        logging.enable = true;
        security.enable = mkIf (cfg.security.apparmor.enable || cfg.security.firewall.enable) true;
        backup.enable = mkIf cfg.backup.enable true;
      };
    }

    # Firewall rules
    {
      networking.firewall.allowedTCPPorts = mkIf cfg.security.firewall.enable (
        [ cfg.port ] 
        ++ optional cfg.metrics.enable cfg.metrics.port
        ++ cfg.security.firewall.allowedPorts
      );
    }
  ]);
}