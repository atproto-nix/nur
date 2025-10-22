# Complete ATproto Deployment Examples
# 
# This file contains comprehensive deployment examples for various ATproto scenarios.
# Each example is a complete, working NixOS configuration that can be used as-is
# or adapted for specific needs.

{
  # Simple Personal PDS
  # A basic setup for running your own Personal Data Server
  personal-pds = { config, lib, pkgs, ... }: {
    imports = [
      # ATproto NUR modules
      inputs.atproto-nur.nixosModules.default
    ];

    # Network configuration
    networking = {
      hostName = "my-pds";
      domain = "example.com";
      firewall = {
        enable = true;
        allowedTCPPorts = [ 80 443 ];
      };
    };

    # SSL certificates
    security.acme = {
      acceptTerms = true;
      defaults.email = "admin@example.com";
      certs."pds.example.com" = {
        domain = "pds.example.com";
        extraDomainNames = [ "dash.pds.example.com" ];
      };
    };

    # Core PDS service
    services.bluesky-social-frontpage = {
      enable = true;
      settings = {
        hostname = "pds.example.com";
        port = 3000;
        
        database = {
          type = "postgresql";
          url = "postgresql://pds@localhost/pds";
        };
        
        storage = {
          type = "local";
          path = "/var/lib/pds/storage";
        };
        
        identity = {
          plcUrl = "https://plc.directory";
          didMethod = "plc";
        };
      };
    };

    # PDS management dashboard
    services.witchcraft-systems-pds-dash = {
      enable = true;
      settings = {
        pdsUrl = "https://pds.example.com";
        port = 3001;
        theme = "default";
        frontendUrl = "https://bsky.app";
      };
    };

    # Identity resolution service
    services.smokesignal-events-quickdid = {
      enable = true;
      settings = {
        port = 8080;
        hostname = "did.example.com";
        database = {
          url = "postgresql://quickdid@localhost/quickdid";
        };
        plc = {
          endpoint = "https://plc.directory";
        };
      };
    };

    # Database setup
    services.postgresql = {
      enable = true;
      ensureDatabases = [ "pds" "quickdid" ];
      ensureUsers = [
        {
          name = "pds";
          ensurePermissions = {
            "DATABASE pds" = "ALL PRIVILEGES";
          };
        }
        {
          name = "quickdid";
          ensurePermissions = {
            "DATABASE quickdid" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    # Reverse proxy
    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      virtualHosts = {
        "pds.example.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
            proxyWebsockets = true;
          };
        };
        
        "dash.pds.example.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3001";
          };
        };
        
        "did.example.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8080";
            extraConfig = ''
              proxy_cache_valid 200 1h;
              proxy_cache_key "$scheme$request_method$host$request_uri";
            '';
          };
        };
      };
    };

    # Backup configuration
    services.restic.backups.pds = {
      repository = "local:/backup/pds";
      passwordFile = "/run/secrets/restic-password";
      paths = [
        "/var/lib/pds"
        "/var/lib/quickdid"
      ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };

  # Development Environment
  # Complete development setup with hot reload and debugging
  development-environment = { config, lib, pkgs, ... }: {
    imports = [
      inputs.atproto-nur.nixosModules.default
    ];

    # Development-friendly network setup
    networking = {
      hostName = "atproto-dev";
      firewall.enable = false; # Disabled for development
    };

    # Development services with relaxed security
    services.smokesignal-events-quickdid = {
      enable = true;
      settings = {
        port = 8080;
        hostname = "localhost";
        database = {
          type = "sqlite";
          url = "sqlite:///var/lib/quickdid/dev.db";
        };
        development = {
          hotReload = true;
          debugLogs = true;
          corsAllowAll = true;
        };
      };
    };

    services.witchcraft-systems-pds-dash = {
      enable = true;
      settings = {
        pdsUrl = "http://localhost:3000";
        port = 3001;
        development = {
          hotReload = true;
          debugMode = true;
        };
      };
    };

    # Development tools
    environment.systemPackages = with pkgs; [
      # ATproto tools
      atproto-nur.packages.${system}.tangled-dev-lexgen
      atproto-nur.packages.${system}.tangled-dev-genjwks
      
      # Development utilities
      curl
      jq
      websocat
      httpie
      
      # Database tools
      sqlite
      postgresql
      
      # Monitoring
      prometheus
      grafana
    ];

    # Fast development database
    services.postgresql = {
      enable = true;
      settings = {
        # Development optimizations (not for production!)
        fsync = "off";
        synchronous_commit = "off";
        full_page_writes = "off";
      };
    };

    # Development shell environment
    programs.bash.shellInit = ''
      # ATproto development aliases
      alias pds-logs="journalctl -u bluesky-social-frontpage -f"
      alias quickdid-logs="journalctl -u smokesignal-events-quickdid -f"
      alias dash-logs="journalctl -u witchcraft-systems-pds-dash -f"
      
      # Development helpers
      alias dev-reset="sudo systemctl restart postgresql && sleep 2 && sudo systemctl restart smokesignal-events-quickdid"
      alias dev-status="systemctl status smokesignal-events-quickdid witchcraft-systems-pds-dash"
      
      echo "🚀 ATproto Development Environment Ready"
      echo "Services: QuickDID (8080), PDS Dashboard (3001)"
      echo "Use 'dev-status' to check services, 'dev-reset' to restart"
    '';
  };

  # Content Creator Platform
  # Specialized setup for content creation and collaboration
  content-platform = { config, lib, pkgs, ... }: {
    imports = [
      inputs.atproto-nur.nixosModules.default
    ];

    networking = {
      hostName = "content-platform";
      domain = "creator.example.com";
      firewall = {
        enable = true;
        allowedTCPPorts = [ 80 443 ];
      };
    };

    # SSL configuration
    security.acme = {
      acceptTerms = true;
      defaults.email = "admin@creator.example.com";
      certs."creator.example.com" = {
        domain = "creator.example.com";
        extraDomainNames = [
          "app.creator.example.com"
          "api.creator.example.com"
          "media.creator.example.com"
        ];
      };
    };

    # Collaborative writing platform
    services.hyperlink-academy-leaflet = {
      enable = true;
      settings = {
        hostname = "app.creator.example.com";
        port = 3000;
        
        database = {
          url = "postgresql://leaflet@localhost/leaflet";
        };
        
        # Content creation features
        collaboration = {
          enable = true;
          realtime = true;
          maxCollaborators = 10;
        };
        
        publishing = {
          enable = true;
          socialFeatures = true;
          crossPosting = [ "bluesky" "mastodon" ];
        };
        
        # Supabase integration for real-time features
        supabase = {
          url = "https://your-project.supabase.co";
          anonKey = "your-anon-key";
          serviceRoleKeyFile = "/run/secrets/supabase-service-key";
        };
        
        # OAuth for social login
        oauth = {
          providers = [ "github" "google" "bluesky" ];
          clientIdFile = "/run/secrets/oauth-client-id";
          clientSecretFile = "/run/secrets/oauth-client-secret";
        };
      };
    };

    # Media processing service (if needed)
    services.stream-place-streamplace = {
      enable = true;
      settings = {
        hostname = "media.creator.example.com";
        port = 3002;
        
        # Video processing
        video = {
          processing = true;
          formats = [ "mp4" "webm" "hls" ];
          resolutions = [ "720p" "1080p" "4k" ];
        };
        
        # Live streaming
        streaming = {
          enable = true;
          rtmp = {
            port = 1935;
            enable = true;
          };
          webrtc = {
            enable = true;
            stunServers = [ "stun:stun.l.google.com:19302" ];
          };
        };
        
        # Storage configuration
        storage = {
          type = "s3";
          bucket = "creator-media";
          region = "us-east-1";
        };
      };
    };

    # Supporting services
    services.smokesignal-events-quickdid = {
      enable = true;
      settings = {
        port = 8080;
        database = {
          url = "postgresql://quickdid@localhost/quickdid";
        };
      };
    };

    services.microcosm-constellation = {
      enable = true;
      settings = {
        jetstream = "wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos";
        backend = "rocks";
        port = 3003;
      };
    };

    # Database cluster
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      ensureDatabases = [ "leaflet" "quickdid" ];
      ensureUsers = [
        {
          name = "leaflet";
          ensurePermissions = {
            "DATABASE leaflet" = "ALL PRIVILEGES";
          };
        }
        {
          name = "quickdid";
          ensurePermissions = {
            "DATABASE quickdid" = "ALL PRIVILEGES";
          };
        }
      ];
      
      # Performance tuning for content workloads
      settings = {
        shared_buffers = "256MB";
        effective_cache_size = "1GB";
        maintenance_work_mem = "64MB";
        checkpoint_completion_target = "0.9";
        wal_buffers = "16MB";
        default_statistics_target = "100";
        random_page_cost = "1.1"; # SSD optimized
        effective_io_concurrency = "200";
      };
    };

    # Redis for caching and sessions
    services.redis.servers.content = {
      enable = true;
      port = 6379;
      bind = "127.0.0.1";
      settings = {
        maxmemory = "512mb";
        maxmemory-policy = "allkeys-lru";
      };
    };

    # Load balancer and reverse proxy
    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      # Enable upload progress for large media files
      appendConfig = ''
        upload_progress proxied 1m;
      '';

      virtualHosts = {
        "creator.example.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            return = "301 https://app.creator.example.com$request_uri";
          };
        };
        
        "app.creator.example.com" = {
          enableACME = true;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:3000";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_read_timeout 300s;
                proxy_connect_timeout 75s;
              '';
            };
            
            "/api/" = {
              proxyPass = "http://127.0.0.1:3000/api/";
              extraConfig = ''
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              '';
            };
          };
        };
        
        "media.creator.example.com" = {
          enableACME = true;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:3002";
            };
            
            "/upload" = {
              proxyPass = "http://127.0.0.1:3002/upload";
              extraConfig = ''
                client_max_body_size 1G;
                proxy_request_buffering off;
                proxy_read_timeout 300s;
                proxy_connect_timeout 75s;
                proxy_send_timeout 300s;
                
                # Upload progress tracking
                track_uploads proxied 30s;
              '';
            };
            
            "/hls/" = {
              proxyPass = "http://127.0.0.1:3002/hls/";
              extraConfig = ''
                add_header Cache-Control "max-age=3600";
                add_header Access-Control-Allow-Origin "*";
              '';
            };
          };
        };
      };
    };

    # Monitoring for content platform
    services.prometheus = {
      enable = true;
      scrapeConfigs = [
        {
          job_name = "content-services";
          static_configs = [{
            targets = [
              "localhost:3000" # Leaflet
              "localhost:3002" # Streamplace
              "localhost:3003" # Constellation
              "localhost:8080" # QuickDID
            ];
          }];
        }
      ];
    };

    # Backup strategy for content
    services.restic.backups = {
      content-data = {
        repository = "s3:backup-bucket/content-data";
        passwordFile = "/run/secrets/restic-password";
        environmentFile = "/run/secrets/restic-env";
        paths = [
          "/var/lib/leaflet"
          "/var/lib/quickdid"
          "/var/lib/constellation"
        ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
      
      media-files = {
        repository = "s3:backup-bucket/media-files";
        passwordFile = "/run/secrets/restic-password";
        environmentFile = "/run/secrets/restic-env";
        paths = [
          "/var/lib/streamplace/media"
        ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
        };
      };
    };
  };

  # Enterprise ATproto Network
  # Production-ready, scalable ATproto infrastructure
  enterprise-network = { config, lib, pkgs, ... }: {
    imports = [
      inputs.atproto-nur.nixosModules.default
    ];

    networking = {
      hostName = "atproto-enterprise";
      domain = "atproto.corp.example.com";
      firewall = {
        enable = true;
        allowedTCPPorts = [ 80 443 8500 ]; # Include Consul UI
      };
    };

    # Enterprise SSL with multiple domains
    security.acme = {
      acceptTerms = true;
      defaults.email = "devops@corp.example.com";
      certs."atproto.corp.example.com" = {
        domain = "atproto.corp.example.com";
        extraDomainNames = [
          "pds.corp.example.com"
          "relay.corp.example.com"
          "app.corp.example.com"
          "api.corp.example.com"
          "admin.corp.example.com"
          "monitor.corp.example.com"
        ];
      };
    };

    # Use production ATproto stack profile
    services.atproto-stacks = {
      profile = "prod-cluster";
      domain = "atproto.corp.example.com";
      
      discovery = {
        backend = "consul";
        consulAddress = "127.0.0.1:8500";
      };
      
      coordination = {
        strategy = "leader-follower";
        enableHealthChecks = true;
        dependencyTimeout = 120;
      };
    };

    # Core PDS service
    services.bluesky-social-frontpage = {
      enable = true;
      settings = {
        hostname = "pds.corp.example.com";
        port = 3000;
        
        database = {
          url = "postgresql://pds@db-cluster.internal/pds";
          maxConnections = 100;
          connectionTimeout = 30;
        };
        
        storage = {
          type = "s3";
          bucket = "corp-atproto-storage";
          region = "us-east-1";
        };
        
        # Enterprise features
        enterprise = {
          sso = {
            enable = true;
            provider = "saml";
            entityId = "corp-atproto";
          };
          
          audit = {
            enable = true;
            destination = "syslog";
          };
          
          rateLimit = {
            requests = 10000;
            window = 3600;
            burst = 100;
          };
        };
      };
    };

    # Relay service (Indigo)
    services.bluesky-social-indigo = {
      enable = true;
      services = [ "relay" "palomar" "rainbow" ];
      
      settings = {
        relay = {
          hostname = "relay.corp.example.com";
          port = 3001;
          
          database = {
            url = "postgresql://relay@db-cluster.internal/relay";
            maxConnections = 200;
          };
          
          # High-performance settings
          firehose = {
            maxConnections = 10000;
            bufferSize = "10MB";
            compression = true;
          };
          
          # Enterprise networking
          clustering = {
            enable = true;
            peers = [
              "relay-2.internal:3001"
              "relay-3.internal:3001"
            ];
          };
        };
        
        palomar = {
          port = 3002;
          jetstream = {
            endpoint = "wss://relay.corp.example.com/jetstream";
            maxConnections = 5000;
          };
        };
        
        rainbow = {
          port = 3003;
          # Content delivery optimization
          cdn = {
            enable = true;
            provider = "cloudfront";
          };
        };
      };
    };

    # Enterprise AppView
    services.parakeet-social-parakeet = {
      enable = true;
      settings = {
        hostname = "app.corp.example.com";
        port = 3004;
        
        database = {
          url = "postgresql://parakeet@db-cluster.internal/parakeet";
          readReplicas = [
            "postgresql://parakeet@db-replica-1.internal/parakeet"
            "postgresql://parakeet@db-replica-2.internal/parakeet"
          ];
        };
        
        # Enterprise features
        enterprise = {
          multiTenant = true;
          customBranding = true;
          advancedAnalytics = true;
        };
        
        # Performance optimization
        performance = {
          workers = 16;
          cacheSize = "2GB";
          indexing = {
            workers = 8;
            batchSize = 1000;
          };
        };
      };
    };

    # Identity services cluster
    services.smokesignal-events-quickdid = {
      enable = true;
      settings = {
        port = 8080;
        hostname = "did.corp.example.com";
        
        database = {
          url = "postgresql://quickdid@db-cluster.internal/quickdid";
          maxConnections = 50;
        };
        
        # High-performance caching
        performance = {
          workers = 8;
          cacheSize = 50000;
          cacheTtl = 3600;
        };
        
        # Enterprise integration
        enterprise = {
          metrics = {
            enable = true;
            endpoint = "/metrics";
          };
          
          logging = {
            level = "info";
            format = "json";
            destination = "syslog";
          };
        };
      };
    };

    services.microcosm-blue-allegedly = {
      enable = true;
      settings = {
        port = 8081;
        hostname = "plc.corp.example.com";
        
        database = {
          url = "postgresql://allegedly@db-cluster.internal/allegedly";
        };
        
        # PLC operations security
        plc = {
          signingKeyFile = "/run/secrets/plc-signing-key";
          rotationKeys = [
            "/run/secrets/plc-rotation-key-1"
            "/run/secrets/plc-rotation-key-2"
            "/run/secrets/plc-rotation-key-3"
          ];
          
          # Enterprise key management
          hsm = {
            enable = true;
            provider = "aws-cloudhsm";
          };
        };
      };
    };

    # Supporting services
    services.microcosm-constellation = {
      enable = true;
      settings = {
        jetstream = "wss://relay.corp.example.com/jetstream";
        backend = "rocks";
        port = 3005;
        
        # Enterprise performance
        performance = {
          workers = 12;
          batchSize = 5000;
          indexingThreads = 8;
        };
        
        clustering = {
          enable = true;
          role = "primary";
          peers = [
            "constellation-2.internal:3005"
            "constellation-3.internal:3005"
          ];
        };
      };
    };

    # Service discovery and coordination
    services.consul = {
      enable = true;
      webUi = true;
      
      extraConfig = {
        datacenter = "corp-atproto";
        data_dir = "/var/lib/consul";
        log_level = "INFO";
        
        # Production cluster configuration
        server = true;
        bootstrap_expect = 3;
        
        bind_addr = "{{ GetInterfaceIP \"eth0\" }}";
        client_addr = "0.0.0.0";
        
        retry_join = [
          "consul-1.internal"
          "consul-2.internal"
          "consul-3.internal"
        ];
        
        # Enterprise features
        enterprise = {
          license_path = "/run/secrets/consul-license";
        };
        
        # Security
        encrypt = "base64-encoded-key";
        ca_file = "/run/secrets/consul-ca.pem";
        cert_file = "/run/secrets/consul-cert.pem";
        key_file = "/run/secrets/consul-key.pem";
        
        # Performance
        performance = {
          raft_multiplier = 1;
        };
      };
    };

    # Enterprise monitoring stack
    services.prometheus = {
      enable = true;
      port = 9090;
      
      scrapeConfigs = [
        {
          job_name = "consul";
          consul_sd_configs = [{
            server = "127.0.0.1:8500";
            services = [ "atproto-services" ];
          }];
        }
        
        {
          job_name = "atproto-core";
          static_configs = [{
            targets = [
              "localhost:3000" # PDS
              "localhost:3001" # Relay
              "localhost:3004" # AppView
              "localhost:8080" # QuickDID
              "localhost:8081" # Allegedly
              "localhost:3005" # Constellation
            ];
          }];
        }
      ];
      
      rules = [
        ''
          groups:
          - name: atproto-enterprise
            rules:
            - alert: ServiceDown
              expr: up == 0
              for: 2m
              labels:
                severity: critical
              annotations:
                summary: "ATproto service {{ $labels.instance }} is down"
                
            - alert: HighErrorRate
              expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "High error rate on {{ $labels.instance }}"
                
            - alert: DatabaseConnections
              expr: postgresql_connections_active / postgresql_connections_max > 0.8
              for: 10m
              labels:
                severity: warning
              annotations:
                summary: "High database connection usage"
        ''
      ];
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_port = 3010;
          domain = "monitor.corp.example.com";
          root_url = "https://monitor.corp.example.com";
        };
        
        security = {
          admin_user = "admin";
          admin_password = "$__file{/run/secrets/grafana-password}";
          secret_key = "$__file{/run/secrets/grafana-secret}";
        };
        
        database = {
          type = "postgres";
          host = "db-cluster.internal:5432";
          name = "grafana";
          user = "grafana";
          password = "$__file{/run/secrets/grafana-db-password}";
        };
        
        # Enterprise features
        enterprise = {
          license_path = "/run/secrets/grafana-license";
        };
        
        # LDAP integration
        "auth.ldap" = {
          enabled = true;
          config_file = "/run/secrets/grafana-ldap.toml";
        };
      };
    };

    # Enterprise load balancer (HAProxy)
    services.haproxy = {
      enable = true;
      config = ''
        global
          daemon
          maxconn 10000
          log stdout local0
          ssl-default-bind-ciphers ECDHE+AESGCM:ECDHE+CHACHA20:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
          ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets
          
        defaults
          mode http
          timeout connect 5000ms
          timeout client 50000ms
          timeout server 50000ms
          option httplog
          option dontlognull
          option http-server-close
          option forwardfor except 127.0.0.0/8
          option redispatch
          retries 3
          
        frontend atproto_frontend
          bind *:80
          bind *:443 ssl crt /var/lib/acme/atproto.corp.example.com/full.pem
          redirect scheme https if !{ ssl_fc }
          
          # Security headers
          http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains"
          http-response set-header X-Frame-Options "DENY"
          http-response set-header X-Content-Type-Options "nosniff"
          
          # Route based on host
          acl is_pds hdr(host) -i pds.corp.example.com
          acl is_relay hdr(host) -i relay.corp.example.com
          acl is_app hdr(host) -i app.corp.example.com
          acl is_admin hdr(host) -i admin.corp.example.com
          acl is_monitor hdr(host) -i monitor.corp.example.com
          
          use_backend pds_backend if is_pds
          use_backend relay_backend if is_relay
          use_backend app_backend if is_app
          use_backend admin_backend if is_admin
          use_backend monitor_backend if is_monitor
          
        backend pds_backend
          balance roundrobin
          option httpchk GET /xrpc/_health
          http-check expect status 200
          server pds1 localhost:3000 check inter 5s
          
        backend relay_backend
          balance roundrobin
          option httpchk GET /xrpc/_health
          http-check expect status 200
          server relay1 localhost:3001 check inter 5s
          
        backend app_backend
          balance roundrobin
          option httpchk GET /api/health
          http-check expect status 200
          server app1 localhost:3004 check inter 5s
          
        backend admin_backend
          balance roundrobin
          server admin1 localhost:3001 check inter 5s
          
        backend monitor_backend
          balance roundrobin
          server monitor1 localhost:3010 check inter 5s
      '';
    };

    # Enterprise backup strategy
    services.restic.backups = {
      atproto-data = {
        repository = "s3:enterprise-backup/atproto-data";
        passwordFile = "/run/secrets/restic-password";
        environmentFile = "/run/secrets/restic-env";
        paths = [
          "/var/lib/pds"
          "/var/lib/relay"
          "/var/lib/parakeet"
          "/var/lib/quickdid"
          "/var/lib/allegedly"
          "/var/lib/constellation"
        ];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
        exclude = [
          "*.tmp"
          "*/cache/*"
          "*/logs/*"
        ];
      };
      
      system-config = {
        repository = "s3:enterprise-backup/system-config";
        passwordFile = "/run/secrets/restic-password";
        environmentFile = "/run/secrets/restic-env";
        paths = [
          "/etc/nixos"
          "/var/lib/consul"
          "/run/secrets"
        ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    };

    # Security hardening
    security = {
      apparmor.enable = true;
      auditd.enable = true;
      
      fail2ban = {
        enable = true;
        jails.atproto = {
          filter = "atproto";
          logpath = "/var/log/atproto/*.log";
          maxretry = 5;
          bantime = 3600;
        };
      };
    };

    # System optimization for enterprise workload
    boot.kernel.sysctl = {
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_max" = 134217728;
      "net.ipv4.tcp_rmem" = "4096 87380 134217728";
      "net.ipv4.tcp_wmem" = "4096 65536 134217728";
      "net.core.netdev_max_backlog" = 5000;
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  # Custom Algorithm Platform
  # Specialized setup for custom feed algorithms and content discovery
  algorithm-platform = { config, lib, pkgs, ... }: {
    imports = [
      inputs.atproto-nur.nixosModules.default
    ];

    networking = {
      hostName = "algorithm-platform";
      domain = "feeds.example.com";
      firewall = {
        enable = true;
        allowedTCPPorts = [ 80 443 ];
      };
    };

    # SSL configuration
    security.acme = {
      acceptTerms = true;
      defaults.email = "admin@feeds.example.com";
      certs."feeds.example.com" = {
        domain = "feeds.example.com";
        extraDomainNames = [
          "api.feeds.example.com"
          "admin.feeds.example.com"
        ];
      };
    };

    # Custom AppView with algorithm engine
    services.slices-network-slices = {
      enable = true;
      settings = {
        hostname = "feeds.example.com";
        port = 3000;
        
        database = {
          url = "postgresql://slices@localhost/slices";
          maxConnections = 100;
        };
        
        # ATproto configuration
        atproto = {
          pds = "https://bsky.social";
          handle = "feeds.example.com";
          passwordFile = "/run/secrets/atproto-password";
        };
        
        # Custom feed algorithms
        algorithms = {
          trending = {
            type = "engagement";
            window = "24h";
            weights = {
              likes = 1.0;
              reposts = 2.0;
              replies = 1.5;
              follows = 3.0;
            };
            filters = {
              minEngagement = 10;
              languages = [ "en" "es" "fr" ];
              contentTypes = [ "text" "image" ];
            };
          };
          
          discovery = {
            type = "collaborative_filtering";
            similarityThreshold = 0.7;
            maxRecommendations = 50;
            diversityFactor = 0.3;
          };
          
          local = {
            type = "geographic";
            radius = "50km";
            boostLocal = 2.0;
            timeDecay = 0.9;
          };
          
          topical = {
            type = "topic_modeling";
            topics = [ "technology" "science" "art" "music" ];
            modelPath = "/var/lib/slices/models/topics.bin";
            updateInterval = "6h";
          };
        };
        
        # API configuration
        api = {
          rateLimit = {
            requests = 5000;
            window = 3600;
            burst = 100;
          };
          
          cors = {
            origins = [ "https://feeds.example.com" "https://bsky.app" ];
            methods = [ "GET" "POST" "OPTIONS" ];
          };
          
          authentication = {
            required = false;
            optional = true;
            methods = [ "bearer" "oauth" ];
          };
        };
        
        # Performance optimization
        performance = {
          workers = 8;
          cacheSize = "1GB";
          
          indexing = {
            batchSize = 1000;
            workers = 4;
            interval = "5m";
          };
          
          algorithms = {
            parallelism = 4;
            timeout = "30s";
            cacheResults = true;
            cacheTtl = "15m";
          };
        };
      };
    };

    # Machine learning backend (Python service)
    systemd.services.ml-backend = {
      description = "Machine Learning Backend for Feed Algorithms";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" ];
      
      serviceConfig = {
        Type = "simple";
        User = "ml-backend";
        Group = "ml-backend";
        WorkingDirectory = "/var/lib/ml-backend";
        
        ExecStart = "${pkgs.python3.withPackages (ps: with ps; [
          scikit-learn
          numpy
          pandas
          redis
          psycopg2
          fastapi
          uvicorn
        ])}/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000";
        
        Restart = "always";
        RestartSec = "10s";
        
        # Security
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/ml-backend" ];
      };
    };

    # Real-time processing with Redis
    services.redis.servers.algorithms = {
      enable = true;
      port = 6379;
      bind = "127.0.0.1";
      settings = {
        maxmemory = "2gb";
        maxmemory-policy = "allkeys-lru";
        
        # Persistence for algorithm state
        save = "900 1 300 10 60 10000";
        
        # Performance
        tcp-keepalive = 300;
        timeout = 0;
      };
    };

    # Time-series database for metrics
    services.influxdb2 = {
      enable = true;
      settings = {
        http-bind-address = "127.0.0.1:8086";
        
        # Performance tuning
        storage-cache-max-memory-size = "1g";
        storage-cache-snapshot-memory-size = "25m";
        storage-wal-fsync-delay = "0s";
      };
    };

    # Algorithm performance monitoring
    services.prometheus = {
      enable = true;
      scrapeConfigs = [
        {
          job_name = "algorithm-platform";
          static_configs = [{
            targets = [
              "localhost:3000" # Slices
              "localhost:8000" # ML Backend
              "localhost:6379" # Redis
              "localhost:8086" # InfluxDB
            ];
          }];
        }
      ];
    };

    # Database with time-series extensions
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      
      extraPlugins = with pkgs.postgresql15Packages; [
        timescaledb
        pg_stat_statements
      ];
      
      settings = {
        shared_preload_libraries = "timescaledb,pg_stat_statements";
        
        # Performance for analytics workload
        shared_buffers = "512MB";
        effective_cache_size = "2GB";
        maintenance_work_mem = "128MB";
        
        # Time-series optimization
        timescaledb.max_background_workers = 8;
        
        # Analytics optimization
        work_mem = "32MB";
        hash_mem_multiplier = 2.0;
        
        # Parallel processing
        max_parallel_workers_per_gather = 4;
        max_parallel_workers = 8;
        max_parallel_maintenance_workers = 4;
      };
      
      ensureDatabases = [ "slices" "analytics" ];
      ensureUsers = [
        {
          name = "slices";
          ensurePermissions = {
            "DATABASE slices" = "ALL PRIVILEGES";
            "DATABASE analytics" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    # Load balancer with algorithm-specific routing
    services.nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      # Rate limiting for API endpoints
      appendConfig = ''
        limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;
        limit_req_zone $binary_remote_addr zone=feeds:10m rate=1000r/m;
      '';

      virtualHosts = {
        "feeds.example.com" = {
          enableACME = true;
          forceSSL = true;
          
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:3000";
              extraConfig = ''
                # Caching for feed results
                proxy_cache_valid 200 5m;
                proxy_cache_key "$scheme$request_method$host$request_uri$args";
                add_header X-Cache-Status $upstream_cache_status;
              '';
            };
            
            "/api/feeds/" = {
              proxyPass = "http://127.0.0.1:3000/api/feeds/";
              extraConfig = ''
                limit_req zone=feeds burst=50 nodelay;
                
                # CORS for feed API
                add_header Access-Control-Allow-Origin "*";
                add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
                add_header Access-Control-Allow-Headers "Content-Type, Authorization";
              '';
            };
            
            "/api/admin/" = {
              proxyPass = "http://127.0.0.1:3000/api/admin/";
              extraConfig = ''
                limit_req zone=api burst=10 nodelay;
                
                # Admin API requires authentication
                auth_basic "Algorithm Platform Admin";
                auth_basic_user_file /run/secrets/nginx-htpasswd;
              '';
            };
            
            "/ml/" = {
              proxyPass = "http://127.0.0.1:8000/";
              extraConfig = ''
                # ML API with longer timeouts
                proxy_read_timeout 120s;
                proxy_connect_timeout 30s;
              '';
            };
          };
        };
      };
    };

    # Users for services
    users.users = {
      ml-backend = {
        isSystemUser = true;
        group = "ml-backend";
        home = "/var/lib/ml-backend";
        createHome = true;
      };
    };
    
    users.groups.ml-backend = {};

    # Directory setup
    systemd.tmpfiles.rules = [
      "d /var/lib/ml-backend 0755 ml-backend ml-backend - -"
      "d /var/lib/ml-backend/models 0755 ml-backend ml-backend - -"
      "d /var/lib/ml-backend/cache 0755 ml-backend ml-backend - -"
    ];
  };
}