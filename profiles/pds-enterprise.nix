# Enterprise PDS deployment profile
# Comprehensive PDS setup with backup, monitoring, and management tools
{ config, lib, pkgs, ... }:

with lib;

{
  options.profiles.pds-enterprise = {
    enable = mkEnableOption "Enterprise PDS deployment profile with full management suite";
    
    hostname = mkOption {
      type = types.str;
      example = "pds.example.com";
      description = "Hostname for the PDS service";
    };
    
    dataDirectory = mkOption {
      type = types.path;
      default = "/var/lib/pds";
      description = "Data directory for PDS storage";
    };
    
    database = {
      type = mkOption {
        type = types.enum [ "sqlite" "postgres" ];
        default = "postgres";
        description = "Database backend for production use";
      };
      
      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "Database host";
      };
      
      port = mkOption {
        type = types.port;
        default = 5432;
        description = "Database port";
      };
      
      name = mkOption {
        type = types.str;
        default = "atproto";
        description = "Database name";
      };
      
      user = mkOption {
        type = types.str;
        default = "atproto";
        description = "Database user";
      };
    };
    
    dashboard = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable the PDS dashboard";
      };
      
      port = mkOption {
        type = types.port;
        default = 3001;
        description = "Port for the PDS dashboard";
      };
      
      theme = mkOption {
        type = types.str;
        default = "default";
        description = "Dashboard theme to use";
      };
      
      subdomain = mkOption {
        type = types.str;
        default = "dashboard";
        description = "Subdomain for dashboard access";
      };
    };
    
    gatekeeper = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable PDS Gatekeeper for enhanced security";
      };
      
      port = mkOption {
        type = types.port;
        default = 8080;
        description = "Port for PDS Gatekeeper";
      };
      
      rateLimiting = {
        createAccountPerSecond = mkOption {
          type = types.ints.positive;
          default = 300; # More restrictive for enterprise
          description = "Seconds between account creation attempts";
        };
        
        createAccountBurst = mkOption {
          type = types.ints.positive;
          default = 3; # Lower burst for enterprise
          description = "Maximum burst of account creation requests";
        };
      };
      
      twoFactorEmailSubject = mkOption {
        type = types.str;
        default = "Two-Factor Authentication - ${config.profiles.pds-enterprise.hostname}";
        description = "Subject line for 2FA emails";
      };
    };
    
    monitoring = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable monitoring and metrics";
      };
      
      prometheus = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable Prometheus metrics collection";
        };
        
        port = mkOption {
          type = types.port;
          default = 9090;
          description = "Port for Prometheus metrics";
        };
      };
      
      grafana = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable Grafana dashboards";
        };
        
        port = mkOption {
          type = types.port;
          default = 3000;
          description = "Port for Grafana interface";
        };
      };
    };
    
    backup = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable automated backups";
      };
      
      schedule = mkOption {
        type = types.str;
        default = "daily";
        description = "Backup schedule (systemd timer format)";
      };
      
      retention = mkOption {
        type = types.ints.positive;
        default = 30;
        description = "Number of days to retain backups";
      };
      
      destination = mkOption {
        type = types.path;
        default = "/var/backups/pds";
        description = "Backup destination directory";
      };
    };
    
    ssl = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable SSL/TLS";
      };
      
      acme = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to use ACME for automatic certificate management";
        };
        
        email = mkOption {
          type = types.str;
          example = "admin@example.com";
          description = "Email for ACME certificate registration";
        };
      };
    };
  };
  
  config = mkIf config.profiles.pds-enterprise.enable {
    # PDS Dashboard configuration
    services.witchcraft-systems-pds-dash = mkIf config.profiles.pds-enterprise.dashboard.enable {
      enable = true;
      settings = {
        pdsUrl = "https://${config.profiles.pds-enterprise.hostname}";
        host = "127.0.0.1";
        port = config.profiles.pds-enterprise.dashboard.port;
        theme = config.profiles.pds-enterprise.dashboard.theme;
        frontendUrl = "https://bsky.app";
        maxPosts = 50; # Higher for enterprise monitoring
        footerText = "<a href='https://github.com/witchcraft-systems/pds-dash' target='_blank'>PDS Dashboard</a> | Enterprise Instance";
        showFuturePosts = false;
        openFirewall = false;
      };
    };
    
    # PDS Gatekeeper configuration with enterprise security
    services.bluesky.pds-gatekeeper = mkIf config.profiles.pds-enterprise.gatekeeper.enable {
      enable = true;
      settings = {
        pdsDataDirectory = config.profiles.pds-enterprise.dataDirectory;
        pdsEnvLocation = "${config.profiles.pds-enterprise.dataDirectory}/pds.env";
        pdsBaseUrl = "http://localhost:3000";
        host = "127.0.0.1";
        port = config.profiles.pds-enterprise.gatekeeper.port;
        twoFactorEmailSubject = config.profiles.pds-enterprise.gatekeeper.twoFactorEmailSubject;
        createAccountPerSecond = config.profiles.pds-enterprise.gatekeeper.rateLimiting.createAccountPerSecond;
        createAccountBurst = config.profiles.pds-enterprise.gatekeeper.rateLimiting.createAccountBurst;
        openFirewall = false;
      };
    };
    
    # PostgreSQL configuration for enterprise deployment
    services.postgresql = mkIf (config.profiles.pds-enterprise.database.type == "postgres") {
      enable = true;
      package = pkgs.postgresql_15;
      
      ensureDatabases = [ config.profiles.pds-enterprise.database.name ];
      ensureUsers = [
        {
          name = config.profiles.pds-enterprise.database.user;
          ensureDBOwnership = true;
        }
      ];
      
      settings = {
        # Enterprise PostgreSQL tuning
        shared_buffers = "256MB";
        effective_cache_size = "1GB";
        maintenance_work_mem = "64MB";
        checkpoint_completion_target = 0.9;
        wal_buffers = "16MB";
        default_statistics_target = 100;
        random_page_cost = 1.1;
        effective_io_concurrency = 200;
      };
    };
    
    # Prometheus monitoring
    services.prometheus = mkIf (config.profiles.pds-enterprise.monitoring.enable && config.profiles.pds-enterprise.monitoring.prometheus.enable) {
      enable = true;
      port = config.profiles.pds-enterprise.monitoring.prometheus.port;
      
      scrapeConfigs = [
        {
          job_name = "pds-gatekeeper";
          static_configs = [{
            targets = [ "localhost:${toString config.profiles.pds-enterprise.gatekeeper.port}" ];
          }];
        }
        {
          job_name = "pds-dashboard";
          static_configs = [{
            targets = [ "localhost:${toString config.profiles.pds-enterprise.dashboard.port}" ];
          }];
        }
        {
          job_name = "postgresql";
          static_configs = [{
            targets = [ "localhost:${toString config.profiles.pds-enterprise.database.port}" ];
          }];
        }
      ];
    };
    
    # Grafana dashboards
    services.grafana = mkIf (config.profiles.pds-enterprise.monitoring.enable && config.profiles.pds-enterprise.monitoring.grafana.enable) {
      enable = true;
      settings = {
        server = {
          http_port = config.profiles.pds-enterprise.monitoring.grafana.port;
          domain = "${config.profiles.pds-enterprise.hostname}";
          root_url = "https://${config.profiles.pds-enterprise.hostname}/grafana/";
        };
        
        security = {
          admin_user = "admin";
          admin_password = "$__file{/run/secrets/grafana-admin-password}";
        };
      };
      
      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://localhost:${toString config.profiles.pds-enterprise.monitoring.prometheus.port}";
            isDefault = true;
          }
        ];
      };
    };
    
    # Automated backup system
    systemd.services.pds-backup = mkIf config.profiles.pds-enterprise.backup.enable {
      description = "PDS Enterprise Backup Service";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = pkgs.writeShellScript "pds-backup" ''
          set -euo pipefail
          
          BACKUP_DIR="${config.profiles.pds-enterprise.backup.destination}"
          TIMESTAMP=$(date +%Y%m%d_%H%M%S)
          BACKUP_PATH="$BACKUP_DIR/pds_backup_$TIMESTAMP"
          
          # Create backup directory
          mkdir -p "$BACKUP_PATH"
          
          # Backup PDS data directory
          echo "Backing up PDS data..."
          tar -czf "$BACKUP_PATH/pds_data.tar.gz" -C "${config.profiles.pds-enterprise.dataDirectory}" .
          
          # Backup database
          ${optionalString (config.profiles.pds-enterprise.database.type == "postgres") ''
            echo "Backing up PostgreSQL database..."
            ${pkgs.postgresql}/bin/pg_dump -h ${config.profiles.pds-enterprise.database.host} \
              -p ${toString config.profiles.pds-enterprise.database.port} \
              -U ${config.profiles.pds-enterprise.database.user} \
              -d ${config.profiles.pds-enterprise.database.name} \
              --no-password > "$BACKUP_PATH/database.sql"
          ''}
          
          # Cleanup old backups
          echo "Cleaning up old backups..."
          find "$BACKUP_DIR" -name "pds_backup_*" -type d -mtime +${toString config.profiles.pds-enterprise.backup.retention} -exec rm -rf {} \;
          
          echo "Backup completed: $BACKUP_PATH"
        '';
      };
    };
    
    systemd.timers.pds-backup = mkIf config.profiles.pds-enterprise.backup.enable {
      description = "PDS Enterprise Backup Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = config.profiles.pds-enterprise.backup.schedule;
        Persistent = true;
      };
    };
    
    # ACME SSL certificates
    security.acme = mkIf (config.profiles.pds-enterprise.ssl.enable && config.profiles.pds-enterprise.ssl.acme.enable) {
      acceptTerms = true;
      defaults.email = config.profiles.pds-enterprise.ssl.acme.email;
      
      certs."${config.profiles.pds-enterprise.hostname}" = {
        domain = config.profiles.pds-enterprise.hostname;
        extraDomainNames = [ 
          "${config.profiles.pds-enterprise.dashboard.subdomain}.${config.profiles.pds-enterprise.hostname}"
        ];
      };
    };
    
    # Ensure directories exist
    systemd.tmpfiles.rules = [
      "d '${config.profiles.pds-enterprise.dataDirectory}' 0755 - - - -"
      "d '${config.profiles.pds-enterprise.backup.destination}' 0755 - - - -"
    ];
    
    # Service dependencies
    systemd.services.pds-gatekeeper = mkIf config.profiles.pds-enterprise.gatekeeper.enable {
      after = [ "pds.service" "postgresql.service" ];
      wants = [ "pds.service" ];
    };
    
    systemd.services.pds-dash = mkIf config.profiles.pds-enterprise.dashboard.enable {
      after = [ "pds.service" ];
      wants = [ "pds.service" ];
    };
    
    # Generate comprehensive reverse proxy configuration
    environment.etc."pds-enterprise/caddy-config.txt" = {
      text = ''
        # Enterprise Caddy configuration for PDS
        
        ${config.profiles.pds-enterprise.hostname} {
            # ACME TLS
            ${optionalString config.profiles.pds-enterprise.ssl.acme.enable "tls ${config.profiles.pds-enterprise.ssl.acme.email}"}
            
            # Security headers
            header {
                Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
                X-Content-Type-Options "nosniff"
                X-Frame-Options "DENY"
                X-XSS-Protection "1; mode=block"
                Referrer-Policy "strict-origin-when-cross-origin"
            }
            
            # Gatekeeper paths
            @gatekeeper {
                path /xrpc/com.atproto.server.getSession
                path /xrpc/com.atproto.server.updateEmail
                path /xrpc/com.atproto.server.createSession
                path /xrpc/com.atproto.server.createAccount
                path /@atproto/oauth-provider/~api/sign-in
            }
            
            handle @gatekeeper {
                reverse_proxy http://localhost:${toString config.profiles.pds-enterprise.gatekeeper.port} {
                    header_up X-Forwarded-For {remote_host}
                    header_up X-Forwarded-Proto {scheme}
                }
            }
            
            # Monitoring endpoints (protected)
            handle /grafana* {
                reverse_proxy http://localhost:${toString config.profiles.pds-enterprise.monitoring.grafana.port}
            }
            
            handle /prometheus* {
                reverse_proxy http://localhost:${toString config.profiles.pds-enterprise.monitoring.prometheus.port}
            }
            
            # Main PDS
            reverse_proxy http://localhost:3000 {
                header_up X-Forwarded-For {remote_host}
                header_up X-Forwarded-Proto {scheme}
            }
        }
        
        # Dashboard subdomain
        ${config.profiles.pds-enterprise.dashboard.subdomain}.${config.profiles.pds-enterprise.hostname} {
            ${optionalString config.profiles.pds-enterprise.ssl.acme.enable "tls ${config.profiles.pds-enterprise.ssl.acme.email}"}
            
            reverse_proxy http://localhost:${toString config.profiles.pds-enterprise.dashboard.port} {
                header_up X-Forwarded-For {remote_host}
                header_up X-Forwarded-Proto {scheme}
            }
        }
      '';
    };
  };
}