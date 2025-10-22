# Example patch showing how to add NixOS ecosystem integration to existing service
# This shows the changes needed to update modules/atproto/yoten.nix

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.yoten-app-yoten;
  # Add integration library import
  nixosIntegration = import ../../lib/nixos-integration.nix { inherit lib config; };
in
{
  # Add integration module import
  imports = [
    ../common/nixos-integration.nix
  ];

  options.services.yoten-app-yoten = {
    enable = mkEnableOption "Yoten language learning social platform";

    package = mkOption {
      type = types.package;
      default = pkgs.yoten-app-yoten or pkgs.yoten;
      description = "The Yoten package to use.";
    };

    # ... existing options ...

    # ADD: Enhanced database configuration with integration
    database = mkOption {
      type = types.submodule {
        options = {
          type = mkOption {
            type = types.enum [ "sqlite" "postgres" "mysql" ];
            default = "sqlite";
            description = "Database type to use";
          };
          
          url = mkOption {
            type = types.str;
            default = "sqlite:///var/lib/atproto-yoten/yoten.db";
            description = "Database connection URL";
            example = "postgresql://yoten:password@localhost/yoten";
          };
          
          # ADD: Auto-creation support
          createDatabase = mkOption {
            type = types.bool;
            default = true;
            description = "Automatically create database and user for local databases";
          };
          
          passwordFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "File containing database password";
          };
        };
      };
      default = {};
      description = "Database configuration with NixOS integration";
    };

    # ADD: Nginx integration options
    nginx = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Nginx reverse proxy";
          
          serverName = mkOption {
            type = types.str;
            description = "Server name for nginx virtual host";
            example = "yoten.example.com";
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

    # ADD: Metrics configuration
    metrics = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Prometheus metrics endpoint";
          
          port = mkOption {
            type = types.port;
            default = 9091;
            description = "Metrics endpoint port";
          };
        };
      };
      default = {};
      description = "Metrics configuration";
    };

    # ... existing redis and other options ...
  };

  config = mkIf cfg.enable (mkMerge [
    # Existing configuration validation
    {
      assertions = [
        # ... existing assertions ...
        
        # ADD: Integration-specific validations
        {
          assertion = cfg.nginx.enable -> cfg.nginx.serverName != "";
          message = "services.yoten-app-yoten: Nginx server name must be specified when nginx is enabled";
        }
        {
          assertion = cfg.database.type == "postgres" -> (hasInfix "postgresql://" cfg.database.url);
          message = "services.yoten-app-yoten: PostgreSQL URL must start with 'postgresql://' when using postgres database type";
        }
      ];
    }

    # ... existing user, group, directory management ...

    # ADD: Database integration
    (nixosIntegration.mkDatabaseIntegration "atproto-yoten" cfg {
      type = cfg.database.type;
      url = cfg.database.url;
      createDatabase = cfg.database.createDatabase;
      database = "yoten";
      user = "yoten";
    })

    # ADD: Nginx integration
    (nixosIntegration.mkNginxIntegration "atproto-yoten" cfg cfg.nginx)

    # ADD: Prometheus metrics integration
    (nixosIntegration.mkPrometheusIntegration "atproto-yoten" cfg cfg.metrics)

    # ADD: Enhanced logging integration
    (nixosIntegration.mkLoggingIntegration "atproto-yoten" cfg {
      level = cfg.settings.logLevel;
      format = "json";
    })

    # ADD: Service dependencies
    (nixosIntegration.mkServiceDependencies "atproto-yoten" {
      after = [ "network.target" ] 
        ++ optional (cfg.database.type == "postgres") [ "postgresql.service" ]
        ++ optional (cfg.database.type == "mysql") [ "mysql.service" ]
        ++ optional (cfg.settings.redis.url != null) [ "redis.service" ];
      
      wants = [ "network.target" ]
        ++ optional (cfg.database.type == "postgres") [ "postgresql.service" ]
        ++ optional (cfg.database.type == "mysql") [ "mysql.service" ];
    })

    # MODIFY: Enhanced systemd service configuration
    {
      systemd.services.yoten-app-yoten = {
        description = "Yoten language learning social platform";
        wantedBy = [ "multi-user.target" ];
        
        # Enhanced dependencies (automatically managed by integration)
        after = [ "network.target" ] 
          ++ optional (cfg.database.type == "postgres") [ "postgresql.service" ]
          ++ optional (cfg.settings.redis.url != null) [ "redis.service" ];
        
        wants = [ "network.target" ];

        # ADD: Pre-start health checks
        preStart = mkMerge [
          (mkIf (cfg.database.type == "postgres") ''
            ${pkgs.postgresql}/bin/pg_isready -h localhost -p 5432
          '')
          (mkIf (cfg.settings.redis.url != null) ''
            ${pkgs.redis}/bin/redis-cli ping
          '')
        ];

        serviceConfig = {
          Type = "exec";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.dataDir;
          
          # Enhanced environment with integration support
          Environment = [
            "YOTEN_PORT=${toString cfg.settings.server.port}"
            "YOTEN_HOSTNAME=${cfg.settings.server.hostname}"
            "YOTEN_DATABASE_URL=${cfg.database.url}"
            "LOG_LEVEL=${cfg.settings.logLevel}"
            "LOG_FORMAT=json"  # Structured logging
          ] ++ optional cfg.metrics.enable [
            "YOTEN_METRICS_PORT=${toString cfg.metrics.port}"
          ] ++ optional (cfg.settings.redis.url != null) [
            "YOTEN_REDIS_URL=${cfg.settings.redis.url}"
          ];

          # ADD: Enhanced security hardening
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

          # ADD: Enhanced restart and health monitoring
          Restart = "on-failure";
          RestartSec = "5s";
          StartLimitBurst = 3;
          StartLimitIntervalSec = "60s";
          
          # Health monitoring
          WatchdogSec = "30s";
          NotifyAccess = "main";

          ExecStart = "${cfg.package}/bin/yoten";
        };
      };
    }

    # ADD: Enable global integration features based on service configuration
    {
      atproto.integration = {
        database = mkMerge [
          (mkIf (cfg.database.type == "postgres") { postgresql.enable = true; })
          (mkIf (cfg.database.type == "mysql") { mysql.enable = true; })
        ];
        redis.enable = mkIf (cfg.settings.redis.url != null) true;
        nginx.enable = mkIf cfg.nginx.enable true;
        monitoring.prometheus.enable = mkIf cfg.metrics.enable true;
        logging.enable = true;
        security.firewall.enable = true;
      };
    }

    # ADD: Automatic firewall configuration
    {
      networking.firewall.allowedTCPPorts = mkIf config.atproto.integration.security.firewall.enable (
        [ cfg.settings.server.port ]
        ++ optional cfg.metrics.enable cfg.metrics.port
      );
    }
  ]);
}

# Summary of changes needed:
# 1. Add imports for integration modules
# 2. Import nixosIntegration library
# 3. Add integration-specific options (nginx, metrics, enhanced database)
# 4. Add integration assertions for validation
# 5. Use integration helpers (mkDatabaseIntegration, mkNginxIntegration, etc.)
# 6. Enhance systemd service with better dependencies and health checks
# 7. Enable global integration features based on service config
# 8. Add automatic firewall configuration