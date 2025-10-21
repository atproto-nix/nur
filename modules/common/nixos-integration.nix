# Common NixOS ecosystem integration module for ATProto services
{ config, lib, pkgs, ... }:

with lib;

let
  nixosIntegration = import ../../lib/nixos-integration.nix { inherit lib config; };
in

{
  # Common integration options that all ATProto services can use
  options = {
    atproto.integration = {
      # Database integration options
      database = {
        enable = mkEnableOption "automatic database service integration";
        
        autoCreate = mkOption {
          type = types.bool;
          default = true;
          description = "Automatically create database and user when using local database services";
        };
        
        postgresql = {
          enable = mkEnableOption "PostgreSQL integration";
          
          package = mkOption {
            type = types.package;
            default = pkgs.postgresql;
            description = "PostgreSQL package to use";
          };
          
          settings = mkOption {
            type = types.attrs;
            default = {};
            description = "Additional PostgreSQL configuration";
          };
        };
        
        mysql = {
          enable = mkEnableOption "MySQL integration";
          
          package = mkOption {
            type = types.package;
            default = pkgs.mysql80;
            description = "MySQL package to use";
          };
        };
      };
      
      # Redis integration options
      redis = {
        enable = mkEnableOption "Redis integration";
        
        package = mkOption {
          type = types.package;
          default = pkgs.redis;
          description = "Redis package to use";
        };
        
        settings = mkOption {
          type = types.attrs;
          default = {};
          description = "Additional Redis configuration";
        };
      };
      
      # Nginx reverse proxy integration
      nginx = {
        enable = mkEnableOption "Nginx reverse proxy integration";
        
        package = mkOption {
          type = types.package;
          default = pkgs.nginx;
          description = "Nginx package to use";
        };
        
        defaultVirtualHost = mkOption {
          type = types.bool;
          default = false;
          description = "Make this the default virtual host";
        };
        
        ssl = {
          enable = mkEnableOption "SSL/TLS support via ACME";
          
          email = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Email for ACME certificate registration";
          };
          
          staging = mkOption {
            type = types.bool;
            default = false;
            description = "Use ACME staging environment for testing";
          };
        };
      };
      
      # Monitoring and metrics integration
      monitoring = {
        enable = mkEnableOption "monitoring integration";
        
        prometheus = {
          enable = mkEnableOption "Prometheus metrics collection";
          
          package = mkOption {
            type = types.package;
            default = pkgs.prometheus;
            description = "Prometheus package to use";
          };
          
          scrapeInterval = mkOption {
            type = types.str;
            default = "15s";
            description = "Metrics scrape interval";
          };
          
          retentionTime = mkOption {
            type = types.str;
            default = "15d";
            description = "Metrics retention time";
          };
        };
        
        grafana = {
          enable = mkEnableOption "Grafana dashboard integration";
          
          package = mkOption {
            type = types.package;
            default = pkgs.grafana;
            description = "Grafana package to use";
          };
          
          dashboards = mkOption {
            type = types.listOf types.path;
            default = [];
            description = "Additional dashboard files to provision";
          };
        };
        
        alertmanager = {
          enable = mkEnableOption "Alertmanager integration";
          
          package = mkOption {
            type = types.package;
            default = pkgs.alertmanager;
            description = "Alertmanager package to use";
          };
        };
      };
      
      # Logging integration
      logging = {
        enable = mkEnableOption "enhanced logging integration";
        
        structured = mkOption {
          type = types.bool;
          default = true;
          description = "Enable structured JSON logging";
        };
        
        retention = mkOption {
          type = types.str;
          default = "30d";
          description = "Log retention period";
        };
        
        maxSize = mkOption {
          type = types.str;
          default = "1G";
          description = "Maximum disk usage for logs";
        };
        
        loki = {
          enable = mkEnableOption "Loki log aggregation";
          
          package = mkOption {
            type = types.package;
            default = pkgs.grafana-loki;
            description = "Loki package to use";
          };
          
          url = mkOption {
            type = types.str;
            default = "http://localhost:3100";
            description = "Loki server URL";
          };
        };
      };
      
      # Security integration
      security = {
        enable = mkEnableOption "enhanced security integration";
        
        fail2ban = {
          enable = mkEnableOption "Fail2ban intrusion prevention";
          
          maxRetry = mkOption {
            type = types.int;
            default = 5;
            description = "Maximum retry attempts before ban";
          };
          
          banTime = mkOption {
            type = types.int;
            default = 3600;
            description = "Ban duration in seconds";
          };
        };
        
        apparmor = {
          enable = mkEnableOption "AppArmor mandatory access control";
          
          enforce = mkOption {
            type = types.bool;
            default = true;
            description = "Enforce AppArmor profiles (vs. complain mode)";
          };
        };
        
        firewall = {
          enable = mkEnableOption "automatic firewall rule management";
          
          allowedPorts = mkOption {
            type = types.listOf types.port;
            default = [];
            description = "Additional ports to open in firewall";
          };
        };
      };
      
      # Backup integration
      backup = {
        enable = mkEnableOption "backup integration";
        
        schedule = mkOption {
          type = types.str;
          default = "daily";
          description = "Backup schedule (systemd timer format)";
        };
        
        retention = {
          daily = mkOption {
            type = types.int;
            default = 7;
            description = "Number of daily backups to keep";
          };
          
          weekly = mkOption {
            type = types.int;
            default = 4;
            description = "Number of weekly backups to keep";
          };
          
          monthly = mkOption {
            type = types.int;
            default = 12;
            description = "Number of monthly backups to keep";
          };
        };
        
        restic = {
          enable = mkEnableOption "Restic backup integration";
          
          repository = mkOption {
            type = types.str;
            description = "Restic repository URL";
            example = "s3:s3.amazonaws.com/my-backup-bucket";
          };
          
          passwordFile = mkOption {
            type = types.path;
            description = "File containing restic repository password";
          };
        };
        
        borg = {
          enable = mkEnableOption "BorgBackup integration";
          
          repository = mkOption {
            type = types.str;
            description = "Borg repository path";
            example = "/backup/borg-repo";
          };
          
          passwordFile = mkOption {
            type = types.path;
            description = "File containing borg repository password";
          };
        };
      };
    };
  };

  config = {
    # Global ATProto integration settings
    services = {
      # Enable PostgreSQL if any service requests it
      postgresql = mkIf config.atproto.integration.database.postgresql.enable {
        enable = mkDefault true;
        package = config.atproto.integration.database.postgresql.package;
        settings = config.atproto.integration.database.postgresql.settings;
        
        # Performance tuning for ATProto workloads
        settings = {
          shared_buffers = mkDefault "256MB";
          effective_cache_size = mkDefault "1GB";
          maintenance_work_mem = mkDefault "64MB";
          checkpoint_completion_target = mkDefault 0.9;
          wal_buffers = mkDefault "16MB";
          default_statistics_target = mkDefault 100;
          random_page_cost = mkDefault 1.1;
          effective_io_concurrency = mkDefault 200;
        } // config.atproto.integration.database.postgresql.settings;
      };
      
      # Enable MySQL if any service requests it
      mysql = mkIf config.atproto.integration.database.mysql.enable {
        enable = mkDefault true;
        package = config.atproto.integration.database.mysql.package;
        
        # Performance tuning for ATProto workloads
        settings = {
          mysqld = {
            innodb_buffer_pool_size = mkDefault "256M";
            innodb_log_file_size = mkDefault "64M";
            max_connections = mkDefault 200;
            query_cache_size = mkDefault "32M";
            query_cache_type = mkDefault 1;
          };
        };
      };
      
      # Enable Redis if any service requests it
      redis = mkIf config.atproto.integration.redis.enable {
        servers.default = {
          enable = mkDefault true;
          package = config.atproto.integration.redis.package;
          settings = {
            maxmemory = mkDefault "256mb";
            maxmemory-policy = mkDefault "allkeys-lru";
            save = mkDefault [ "900 1" "300 10" "60 10000" ];
          } // config.atproto.integration.redis.settings;
        };
      };
      
      # Enable Nginx if any service requests it
      nginx = mkIf config.atproto.integration.nginx.enable {
        enable = mkDefault true;
        package = config.atproto.integration.nginx.package;
        
        # Performance and security settings for ATProto services
        appendHttpConfig = ''
          # Security headers
          add_header X-Frame-Options DENY;
          add_header X-Content-Type-Options nosniff;
          add_header X-XSS-Protection "1; mode=block";
          add_header Referrer-Policy strict-origin-when-cross-origin;
          
          # Performance settings
          gzip on;
          gzip_vary on;
          gzip_min_length 1024;
          gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
          
          # Rate limiting
          limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
          limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
        '';
      };
      
      # Enable Prometheus if monitoring is requested
      prometheus = mkIf config.atproto.integration.monitoring.prometheus.enable {
        enable = mkDefault true;
        package = config.atproto.integration.monitoring.prometheus.package;
        
        globalConfig = {
          scrape_interval = config.atproto.integration.monitoring.prometheus.scrapeInterval;
        };
        
        retentionTime = config.atproto.integration.monitoring.prometheus.retentionTime;
        
        # Default rules for ATProto services
        rules = [
          (builtins.toJSON {
            groups = [{
              name = "atproto";
              rules = [
                {
                  alert = "ATProtoServiceDown";
                  expr = "up{job=~\".*atproto.*\"} == 0";
                  for = "5m";
                  labels.severity = "critical";
                  annotations = {
                    summary = "ATProto service {{ $labels.job }} is down";
                    description = "ATProto service {{ $labels.job }} has been down for more than 5 minutes.";
                  };
                }
                {
                  alert = "ATProtoHighErrorRate";
                  expr = "rate(http_requests_total{job=~\".*atproto.*\",status=~\"5..\"}[5m]) > 0.1";
                  for = "5m";
                  labels.severity = "warning";
                  annotations = {
                    summary = "High error rate in ATProto service {{ $labels.job }}";
                    description = "ATProto service {{ $labels.job }} has error rate above 10% for more than 5 minutes.";
                  };
                }
              ];
            }];
          })
        ];
      };
      
      # Enable Grafana if requested
      grafana = mkIf config.atproto.integration.monitoring.grafana.enable {
        enable = mkDefault true;
        package = config.atproto.integration.monitoring.grafana.package;
        
        settings = {
          server = {
            http_port = mkDefault 3001;
            domain = mkDefault "localhost";
          };
          
          security = {
            admin_user = mkDefault "admin";
            admin_password = mkDefault "$__file{/etc/grafana/admin-password}";
          };
        };
        
        provision = {
          enable = mkDefault true;
          
          datasources.settings.datasources = [{
            name = "Prometheus";
            type = "prometheus";
            url = "http://localhost:9090";
            isDefault = true;
          }] ++ optional config.atproto.integration.logging.loki.enable {
            name = "Loki";
            type = "loki";
            url = config.atproto.integration.logging.loki.url;
          };
          
          dashboards.settings.providers = [{
            name = "ATProto";
            type = "file";
            options.path = "/etc/grafana/dashboards";
          }];
        };
      };
      
      # Enable Loki if log aggregation is requested
      loki = mkIf config.atproto.integration.logging.loki.enable {
        enable = mkDefault true;
        package = config.atproto.integration.logging.loki.package;
        
        configuration = {
          server.http_listen_port = 3100;
          
          ingester = {
            lifecycler = {
              address = "127.0.0.1";
              ring = {
                kvstore.store = "inmemory";
                replication_factor = 1;
              };
            };
            chunk_idle_period = "1h";
            max_chunk_age = "1h";
            chunk_target_size = 1048576;
            chunk_retain_period = "30s";
          };
          
          schema_config.configs = [{
            from = "2020-10-24";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v11";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];
          
          storage_config = {
            boltdb_shipper = {
              active_index_directory = "/var/lib/loki/boltdb-shipper-active";
              cache_location = "/var/lib/loki/boltdb-shipper-cache";
              shared_store = "filesystem";
            };
            
            filesystem.directory = "/var/lib/loki/chunks";
          };
          
          limits_config = {
            reject_old_samples = true;
            reject_old_samples_max_age = "168h";
          };
        };
      };
      
      # Enable Fail2ban if security integration is requested
      fail2ban = mkIf config.atproto.integration.security.fail2ban.enable {
        enable = mkDefault true;
        
        # Default jail configuration for ATProto services
        jails = {
          DEFAULT = {
            settings = {
              bantime = toString config.atproto.integration.security.fail2ban.banTime;
              findtime = "600";
              maxretry = toString config.atproto.integration.security.fail2ban.maxRetry;
            };
          };
        };
      };
    };
    
    # Security configuration
    security = {
      # Enable AppArmor if requested
      apparmor = mkIf config.atproto.integration.security.apparmor.enable {
        enable = mkDefault true;
      };
    };
    
    # Firewall configuration
    networking.firewall = mkIf config.atproto.integration.security.firewall.enable {
      allowedTCPPorts = config.atproto.integration.security.firewall.allowedPorts;
    };
    
    # System-wide logging configuration
    services.journald = mkIf config.atproto.integration.logging.enable {
      extraConfig = ''
        SystemMaxUse=${config.atproto.integration.logging.maxSize}
        MaxRetentionSec=${config.atproto.integration.logging.retention}
        Compress=yes
        ForwardToSyslog=no
      '';
    };
    
    # Systemd timer for log cleanup
    systemd.timers.atproto-log-cleanup = mkIf config.atproto.integration.logging.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
    
    systemd.services.atproto-log-cleanup = mkIf config.atproto.integration.logging.enable {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-time=${config.atproto.integration.logging.retention}";
      };
    };
  };
}