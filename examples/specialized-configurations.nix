# Specialized ATproto Configuration Examples
#
# This file contains specialized configuration examples for specific use cases,
# advanced features, and integration scenarios.

{
  # High-Availability Multi-Region Setup
  # Distributed ATproto infrastructure across multiple regions
  multi-region-ha = {
    # Primary region (US East)
    primary-region = { config, lib, pkgs, ... }: {
      imports = [
        inputs.atproto-nur.nixosModules.default
      ];

      networking = {
        hostName = "atproto-primary-us-east";
        domain = "us-east.atproto.example.com";
      };

      # Regional service configuration
      services.atproto-stacks = {
        profile = "prod-cluster";
        domain = "atproto.example.com";
        
        discovery = {
          backend = "consul";
          consulAddress = "consul-us-east.internal:8500";
        };
        
        coordination = {
          strategy = "leader-follower";
          enableHealthChecks = true;
          
          # Multi-region coordination
          regions = {
            primary = "us-east";
            replicas = [ "us-west" "eu-west" "ap-southeast" ];
          };
        };
      };

      # Primary PDS with cross-region replication
      services.bluesky-social-frontpage = {
        enable = true;
        settings = {
          hostname = "pds.atproto.example.com";
          port = 3000;
          
          database = {
            url = "postgresql://pds@db-primary-us-east.internal/pds";
            
            # Cross-region replication
            replication = {
              enable = true;
              replicas = [
                "postgresql://pds@db-replica-us-west.internal/pds"
                "postgresql://pds@db-replica-eu-west.internal/pds"
              ];
              syncMode = "async";
            };
          };
          
          # Global storage with regional caching
          storage = {
            type = "s3";
            bucket = "atproto-global-storage";
            region = "us-east-1";
            
            # Regional CDN endpoints
            cdn = {
              enable = true;
              endpoints = {
                "us-east" = "https://cdn-us-east.atproto.example.com";
                "us-west" = "https://cdn-us-west.atproto.example.com";
                "eu-west" = "https://cdn-eu-west.atproto.example.com";
                "ap-southeast" = "https://cdn-ap-southeast.atproto.example.com";
              };
            };
          };
          
          # Global identity coordination
          identity = {
            plcUrl = "https://plc.atproto.example.com";
            
            # Cross-region DID resolution
            didResolvers = [
              "https://did-us-east.atproto.example.com"
              "https://did-us-west.atproto.example.com"
              "https://did-eu-west.atproto.example.com"
            ];
          };
        };
      };

      # Global relay with regional distribution
      services.bluesky-social-indigo = {
        enable = true;
        services = [ "relay" "palomar" ];
        
        settings = {
          relay = {
            hostname = "relay.atproto.example.com";
            port = 3001;
            
            # Global firehose distribution
            firehose = {
              distribution = {
                enable = true;
                regions = [
                  {
                    name = "us-west";
                    endpoint = "wss://relay-us-west.internal:3001";
                    weight = 100;
                  }
                  {
                    name = "eu-west";
                    endpoint = "wss://relay-eu-west.internal:3001";
                    weight = 100;
                  }
                  {
                    name = "ap-southeast";
                    endpoint = "wss://relay-ap-southeast.internal:3001";
                    weight = 50;
                  }
                ];
              };
            };
          };
        };
      };

      # Global load balancer configuration
      services.haproxy = {
        enable = true;
        config = ''
          global
            daemon
            maxconn 50000
            
          defaults
            mode http
            timeout connect 5000ms
            timeout client 50000ms
            timeout server 50000ms
            
          # Global frontend with geographic routing
          frontend global_frontend
            bind *:443 ssl crt /var/lib/acme/atproto.example.com/full.pem
            
            # Geographic routing based on client IP
            acl is_us_west src -f /etc/haproxy/geoip/us-west.lst
            acl is_eu_west src -f /etc/haproxy/geoip/eu-west.lst
            acl is_ap_southeast src -f /etc/haproxy/geoip/ap-southeast.lst
            
            use_backend us_west_backend if is_us_west
            use_backend eu_west_backend if is_eu_west
            use_backend ap_southeast_backend if is_ap_southeast
            default_backend us_east_backend
            
          backend us_east_backend
            balance roundrobin
            server primary localhost:3000 check
            
          backend us_west_backend
            balance roundrobin
            server replica1 us-west-1.internal:3000 check
            server replica2 us-west-2.internal:3000 check backup
            
          backend eu_west_backend
            balance roundrobin
            server replica1 eu-west-1.internal:3000 check
            server replica2 eu-west-2.internal:3000 check backup
            
          backend ap_southeast_backend
            balance roundrobin
            server replica1 ap-southeast-1.internal:3000 check
        '';
      };
    };

    # Replica region configuration (similar structure for other regions)
    replica-region = { config, lib, pkgs, ... }: {
      # Similar configuration but with replica-specific settings
      services.bluesky-social-frontpage.settings = {
        # Read-only replica configuration
        database = {
          url = "postgresql://pds@db-replica-local.internal/pds";
          readOnly = true;
        };
        
        # Regional storage caching
        storage = {
          type = "s3";
          bucket = "atproto-global-storage";
          region = "local-region";
          
          cache = {
            enable = true;
            size = "100GB";
            ttl = "24h";
          };
        };
      };
    };
  };

  # Identity Provider Integration
  # Enterprise SSO and identity management integration
  enterprise-identity = { config, lib, pkgs, ... }: {
    imports = [
      inputs.atproto-nur.nixosModules.default
    ];

    # SAML/OIDC identity provider integration
    services.bluesky-social-frontpage = {
      enable = true;
      settings = {
        # Enterprise authentication
        authentication = {
          providers = [
            {
              type = "saml";
              name = "corporate-sso";
              entityId = "https://sso.corp.example.com";
              ssoUrl = "https://sso.corp.example.com/saml/sso";
              x509cert = "/run/secrets/saml-cert.pem";
              
              # Attribute mapping
              attributes = {
                email = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress";
                name = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name";
                groups = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/groups";
              };
            }
            
            {
              type = "oidc";
              name = "azure-ad";
              clientId = "azure-client-id";
              clientSecretFile = "/run/secrets/azure-client-secret";
              discoveryUrl = "https://login.microsoftonline.com/tenant-id/v2.0/.well-known/openid_configuration";
              
              # Scope and claims
              scopes = [ "openid" "profile" "email" "groups" ];
              claimsMapping = {
                email = "email";
                name = "name";
                groups = "groups";
              };
            }
          ];
          
          # Authorization policies
          authorization = {
            defaultRole = "user";
            
            roles = {
              admin = {
                permissions = [ "manage_users" "manage_content" "system_admin" ];
                groups = [ "ATProto Admins" "IT Administrators" ];
              };
              
              moderator = {
                permissions = [ "moderate_content" "manage_reports" ];
                groups = [ "Content Moderators" ];
              };
              
              user = {
                permissions = [ "create_content" "interact" ];
                groups = [ "All Users" ];
              };
            };
          };
        };
        
        # User provisioning
        provisioning = {
          autoCreate = true;
          autoUpdate = true;
          
          # Handle mapping
          handleGeneration = {
            strategy = "email"; # or "username", "custom"
            domain = "corp.atproto.example.com";
            
            # Custom handle generation
            template = "{username}.corp.atproto.example.com";
            
            # Handle conflicts
            conflictResolution = "append_number";
          };
          
          # Profile synchronization
          profileSync = {
            enable = true;
            fields = [ "displayName" "avatar" "description" ];
            frequency = "daily";
          };
        };
      };
    };

    # LDAP integration for user lookup
    services.smokesignal-events-quickdid = {
      enable = true;
      settings = {
        # LDAP directory integration
        ldap = {
          enable = true;
          servers = [
            "ldap://ldap1.corp.example.com:389"
            "ldap://ldap2.corp.example.com:389"
          ];
          
          bindDn = "cn=atproto-service,ou=services,dc=corp,dc=example,dc=com";
          bindPasswordFile = "/run/secrets/ldap-password";
          
          # Search configuration
          baseDn = "ou=users,dc=corp,dc=example,dc=com";
          userFilter = "(&(objectClass=person)(mail={email}))";
          
          # Attribute mapping
          attributes = {
            email = "mail";
            username = "sAMAccountName";
            displayName = "displayName";
            groups = "memberOf";
          };
          
          # Caching
          cache = {
            enable = true;
            ttl = 3600;
            maxEntries = 10000;
          };
        };
      };
    };

    # Enterprise audit logging
    services.auditd = {
      enable = true;
      rules = [
        # ATProto authentication events
        "-w /var/log/atproto/auth.log -p wa -k atproto_auth"
        
        # User management events
        "-w /var/log/atproto/users.log -p wa -k atproto_users"
        
        # Content moderation events
        "-w /var/log/atproto/moderation.log -p wa -k atproto_moderation"
      ];
    };

    # Compliance and data governance
    systemd.services.compliance-monitor = {
      description = "ATProto Compliance Monitor";
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "simple";
        User = "compliance";
        Group = "compliance";
        
        ExecStart = pkgs.writeScript "compliance-monitor" ''
          #!/bin/bash
          
          # Monitor for compliance events
          while true; do
            # Check for data retention policies
            find /var/lib/pds -name "*.data" -mtime +2555 -exec rm {} \; # 7 years
            
            # Generate compliance reports
            ${pkgs.python3}/bin/python /opt/compliance/generate_report.py
            
            sleep 3600 # Run hourly
          done
        '';
      };
    };
  };

  # Content Moderation Platform
  # Advanced content moderation with ML and human review
  moderation-platform = { config, lib, pkgs, ... }: {
    imports = [
      inputs.atproto-nur.nixosModules.default
    ];

    # Moderation-focused AppView
    services.parakeet-social-parakeet = {
      enable = true;
      settings = {
        # Moderation features
        moderation = {
          enable = true;
          
          # Automated moderation
          automated = {
            enable = true;
            
            # Content analysis
            contentAnalysis = {
              textAnalysis = {
                enable = true;
                models = [
                  {
                    name = "toxicity";
                    endpoint = "http://localhost:8001/analyze/toxicity";
                    threshold = 0.7;
                    action = "flag";
                  }
                  {
                    name = "spam";
                    endpoint = "http://localhost:8001/analyze/spam";
                    threshold = 0.8;
                    action = "hide";
                  }
                  {
                    name = "hate_speech";
                    endpoint = "http://localhost:8001/analyze/hate";
                    threshold = 0.6;
                    action = "remove";
                  }
                ];
              };
              
              imageAnalysis = {
                enable = true;
                models = [
                  {
                    name = "nsfw";
                    endpoint = "http://localhost:8002/analyze/nsfw";
                    threshold = 0.8;
                    action = "blur";
                  }
                  {
                    name = "violence";
                    endpoint = "http://localhost:8002/analyze/violence";
                    threshold = 0.7;
                    action = "remove";
                  }
                ];
              };
            };
            
            # Behavioral analysis
            behaviorAnalysis = {
              enable = true;
              
              # Spam detection
              spamDetection = {
                rateLimit = {
                  posts = { count = 10; window = "1h"; };
                  follows = { count = 50; window = "1h"; };
                  likes = { count = 100; window = "1h"; };
                };
                
                patterns = [
                  "duplicate_content"
                  "mass_following"
                  "coordinated_behavior"
                ];
              };
              
              # Harassment detection
              harassmentDetection = {
                enable = true;
                patterns = [
                  "targeted_harassment"
                  "brigading"
                  "doxxing"
                ];
              };
            };
          };
          
          # Human moderation
          humanModeration = {
            enable = true;
            
            # Review queue
            reviewQueue = {
              prioritization = "severity"; # or "chronological", "random"
              
              # Auto-assignment
              autoAssignment = {
                enable = true;
                strategy = "round_robin"; # or "expertise", "workload"
              };
              
              # SLA targets
              sla = {
                high_priority = "1h";
                medium_priority = "4h";
                low_priority = "24h";
              };
            };
            
            # Moderator tools
            tools = {
              bulkActions = true;
              templateResponses = true;
              escalationPaths = true;
              auditTrail = true;
            };
          };
          
          # Appeals process
          appeals = {
            enable = true;
            
            # Appeal workflow
            workflow = {
              stages = [ "initial_review" "senior_review" "final_decision" ];
              timeouts = [ "3d" "7d" "14d" ];
            };
            
            # Appeal criteria
            criteria = {
              allowedReasons = [
                "false_positive"
                "context_missing"
                "policy_misapplication"
                "technical_error"
              ];
              
              evidenceRequired = true;
              maxAppeals = 3;
            };
          };
        };
      };
    };

    # ML moderation services
    systemd.services.text-moderation = {
      description = "Text Moderation ML Service";
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "simple";
        User = "ml-moderation";
        Group = "ml-moderation";
        WorkingDirectory = "/var/lib/ml-moderation";
        
        ExecStart = "${pkgs.python3.withPackages (ps: with ps; [
          transformers
          torch
          fastapi
          uvicorn
          numpy
          scikit-learn
        ])}/bin/python -m uvicorn text_moderation:app --host 0.0.0.0 --port 8001";
        
        # Resource limits for ML workloads
        MemoryMax = "4G";
        CPUQuota = "200%";
      };
    };

    systemd.services.image-moderation = {
      description = "Image Moderation ML Service";
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "simple";
        User = "ml-moderation";
        Group = "ml-moderation";
        WorkingDirectory = "/var/lib/ml-moderation";
        
        ExecStart = "${pkgs.python3.withPackages (ps: with ps; [
          tensorflow
          pillow
          fastapi
          uvicorn
          numpy
          opencv4
        ])}/bin/python -m uvicorn image_moderation:app --host 0.0.0.0 --port 8002";
        
        # GPU access if available
        DeviceAllow = [ "/dev/nvidia0 rw" "/dev/nvidiactl rw" ];
        MemoryMax = "8G";
      };
    };

    # Moderation dashboard
    services.nginx = {
      enable = true;
      virtualHosts."moderation.example.com" = {
        enableACME = true;
        forceSSL = true;
        
        locations = {
          "/" = {
            root = "/var/www/moderation-dashboard";
            index = "index.html";
          };
          
          "/api/" = {
            proxyPass = "http://localhost:3000/moderation/api/";
            extraConfig = ''
              # Authentication required for moderation API
              auth_request /auth;
              
              # Rate limiting for moderation actions
              limit_req zone=moderation burst=10 nodelay;
            '';
          };
          
          "/auth" = {
            internal = true;
            proxyPass = "http://localhost:3000/auth/verify";
            proxyPassRequestBody = "off";
            extraConfig = ''
              proxy_set_header Content-Length "";
              proxy_set_header X-Original-URI $request_uri;
            '';
          };
        };
      };
    };

    # Moderation metrics and reporting
    services.prometheus = {
      enable = true;
      scrapeConfigs = [
        {
          job_name = "moderation-metrics";
          static_configs = [{
            targets = [
              "localhost:3000" # Parakeet moderation metrics
              "localhost:8001" # Text moderation ML
              "localhost:8002" # Image moderation ML
            ];
          }];
        }
      ];
      
      rules = [
        ''
          groups:
          - name: moderation
            rules:
            - alert: HighModerationQueue
              expr: moderation_queue_size > 1000
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: "Moderation queue is growing large"
                
            - alert: MLServiceDown
              expr: up{job="moderation-metrics"} == 0
              for: 2m
              labels:
                severity: critical
              annotations:
                summary: "ML moderation service is down"
                
            - alert: HighFalsePositiveRate
              expr: rate(moderation_appeals_upheld[1h]) > 0.1
              for: 10m
              labels:
                severity: warning
              annotations:
                summary: "High false positive rate in moderation"
        ''
      ];
    };

    # Users and permissions
    users.users.ml-moderation = {
      isSystemUser = true;
      group = "ml-moderation";
      home = "/var/lib/ml-moderation";
      createHome = true;
    };
    
    users.groups.ml-moderation = {};
  };

  # Research and Analytics Platform
  # Advanced analytics and research tools for ATproto data
  research-platform = { config, lib, pkgs, ... }: {
    imports = [
      inputs.atproto-nur.nixosModules.default
    ];

    # Analytics-focused data processing
    services.microcosm-constellation = {
      enable = true;
      settings = {
        # Research-oriented configuration
        research = {
          enable = true;
          
          # Data collection
          dataCollection = {
            firehose = {
              enable = true;
              sampleRate = 1.0; # Collect all data for research
              
              # Data types to collect
              dataTypes = [
                "posts"
                "likes"
                "reposts"
                "follows"
                "blocks"
                "reports"
              ];
            };
            
            # Metadata enrichment
            enrichment = {
              enable = true;
              
              # Language detection
              languageDetection = {
                enable = true;
                model = "fasttext";
              };
              
              # Sentiment analysis
              sentimentAnalysis = {
                enable = true;
                model = "vader";
              };
              
              # Topic modeling
              topicModeling = {
                enable = true;
                model = "lda";
                numTopics = 50;
                updateInterval = "daily";
              };
              
              # Network analysis
              networkAnalysis = {
                enable = true;
                metrics = [
                  "centrality"
                  "clustering"
                  "community_detection"
                ];
              };
            };
          };
          
          # Data export
          dataExport = {
            formats = [ "csv" "json" "parquet" ];
            
            # Privacy protection
            anonymization = {
              enable = true;
              methods = [
                "k_anonymity"
                "differential_privacy"
                "data_masking"
              ];
              
              # Anonymization parameters
              kAnonymity = 5;
              epsilonDP = 1.0;
            };
            
            # Export scheduling
            schedules = {
              daily_export = {
                frequency = "daily";
                format = "parquet";
                destination = "s3://research-data/daily/";
              };
              
              weekly_aggregates = {
                frequency = "weekly";
                format = "csv";
                destination = "s3://research-data/weekly/";
                aggregation = true;
              };
            };
          };
        };
      };
    };

    # Jupyter notebook server for researchers
    services.jupyter = {
      enable = true;
      ip = "0.0.0.0";
      port = 8888;
      
      # Research-focused Python environment
      kernels = {
        python3 = let
          env = pkgs.python3.withPackages (ps: with ps; [
            # Data science stack
            numpy
            pandas
            scipy
            scikit-learn
            matplotlib
            seaborn
            plotly
            
            # Network analysis
            networkx
            igraph
            
            # NLP and text analysis
            nltk
            spacy
            gensim
            transformers
            
            # Time series analysis
            statsmodels
            
            # Database connectivity
            psycopg2
            sqlalchemy
            
            # ATproto specific
            requests
            websockets
            
            # Jupyter extensions
            jupyterlab
            ipywidgets
          ]);
        in {
          displayName = "ATproto Research";
          argv = [
            "${env.interpreter}"
            "-m"
            "ipykernel_launcher"
            "-f"
            "{connection_file}"
          ];
          language = "python";
        };
      };
    };

    # Apache Superset for data visualization
    services.superset = {
      enable = true;
      
      # Database configuration
      database = {
        type = "postgresql";
        host = "localhost";
        port = 5432;
        name = "superset";
        user = "superset";
        passwordFile = "/run/secrets/superset-db-password";
      };
      
      # Configuration
      config = {
        # Security
        SECRET_KEY_FILE = "/run/secrets/superset-secret-key";
        
        # Features
        FEATURE_FLAGS = {
          ENABLE_TEMPLATE_PROCESSING = true;
          DASHBOARD_NATIVE_FILTERS = true;
          DASHBOARD_CROSS_FILTERS = true;
          GLOBAL_ASYNC_QUERIES = true;
        };
        
        # Data sources
        DATABASES = {
          atproto_analytics = {
            ENGINE = "postgresql";
            NAME = "analytics";
            USER = "analytics_readonly";
            HOST = "localhost";
            PORT = 5432;
          };
        };
      };
    };

    # ClickHouse for high-performance analytics
    services.clickhouse = {
      enable = true;
      
      config = ''
        <yandex>
          <logger>
            <level>information</level>
            <log>/var/log/clickhouse-server/clickhouse-server.log</log>
            <errorlog>/var/log/clickhouse-server/clickhouse-server.err.log</errorlog>
          </logger>
          
          <http_port>8123</http_port>
          <tcp_port>9000</tcp_port>
          
          <listen_host>127.0.0.1</listen_host>
          
          <max_connections>4096</max_connections>
          <keep_alive_timeout>3</keep_alive_timeout>
          <max_concurrent_queries>100</max_concurrent_queries>
          
          <uncompressed_cache_size>8589934592</uncompressed_cache_size>
          <mark_cache_size>5368709120</mark_cache_size>
          
          <path>/var/lib/clickhouse/</path>
          <tmp_path>/var/lib/clickhouse/tmp/</tmp_path>
          <user_files_path>/var/lib/clickhouse/user_files/</user_files_path>
          
          <users>
            <default>
              <password></password>
              <networks incl="networks" replace="replace">
                <ip>::1</ip>
                <ip>127.0.0.1</ip>
              </networks>
              <profile>default</profile>
              <quota>default</quota>
            </default>
            
            <analytics>
              <password_sha256_hex><!-- password hash --></password_sha256_hex>
              <networks>
                <ip>127.0.0.1</ip>
              </networks>
              <profile>readonly</profile>
              <quota>default</quota>
            </analytics>
          </users>
          
          <profiles>
            <default>
              <max_memory_usage>10000000000</max_memory_usage>
              <use_uncompressed_cache>0</use_uncompressed_cache>
              <load_balancing>random</load_balancing>
            </default>
            
            <readonly>
              <readonly>1</readonly>
            </readonly>
          </profiles>
          
          <quotas>
            <default>
              <interval>
                <duration>3600</duration>
                <queries>0</queries>
                <errors>0</errors>
                <result_rows>0</result_rows>
                <read_rows>0</read_rows>
                <execution_time>0</execution_time>
              </interval>
            </default>
          </quotas>
        </yandex>
      '';
    };

    # Data pipeline with Apache Airflow
    services.airflow = {
      enable = true;
      
      # Configuration
      config = {
        core = {
          executor = "LocalExecutor";
          sql_alchemy_conn = "postgresql://airflow@localhost/airflow";
          dags_folder = "/var/lib/airflow/dags";
          base_log_folder = "/var/lib/airflow/logs";
          remote_logging = false;
          encrypt_s3_logs = false;
        };
        
        webserver = {
          web_server_port = 8080;
          web_server_host = "127.0.0.1";
          secret_key_file = "/run/secrets/airflow-secret-key";
        };
        
        scheduler = {
          job_heartbeat_sec = 5;
          scheduler_heartbeat_sec = 5;
          run_duration = -1;
          min_file_process_interval = 0;
          dag_dir_list_interval = 300;
          print_stats_interval = 30;
          child_process_timeout = 600;
          scheduler_zombie_task_threshold = 300;
          catchup_by_default = false;
          max_threads = 2;
        };
      };
    };

    # Database setup for analytics
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      
      # Analytics-optimized settings
      settings = {
        # Memory settings
        shared_buffers = "1GB";
        effective_cache_size = "4GB";
        maintenance_work_mem = "256MB";
        work_mem = "64MB";
        
        # Parallel processing
        max_parallel_workers_per_gather = 8;
        max_parallel_workers = 16;
        max_parallel_maintenance_workers = 8;
        
        # Analytics workload optimization
        random_page_cost = "1.1";
        seq_page_cost = "1.0";
        cpu_tuple_cost = "0.01";
        cpu_index_tuple_cost = "0.005";
        cpu_operator_cost = "0.0025";
        
        # Checkpoint and WAL
        checkpoint_completion_target = "0.9";
        wal_buffers = "16MB";
        
        # Query optimization
        default_statistics_target = "500";
        constraint_exclusion = "partition";
        
        # Logging for analysis
        log_statement = "all";
        log_duration = true;
        log_min_duration_statement = "1000";
        log_checkpoints = true;
        log_connections = true;
        log_disconnections = true;
        log_lock_waits = true;
      };
      
      # Extensions for analytics
      extraPlugins = with pkgs.postgresql15Packages; [
        timescaledb
        pg_stat_statements
        pg_partman
        postgis
      ];
      
      initialScript = pkgs.writeText "analytics-init.sql" ''
        -- Create analytics databases
        CREATE DATABASE analytics;
        CREATE DATABASE superset;
        CREATE DATABASE airflow;
        
        -- Create users
        CREATE USER analytics_readonly WITH PASSWORD 'readonly_password';
        CREATE USER superset WITH PASSWORD 'superset_password';
        CREATE USER airflow WITH PASSWORD 'airflow_password';
        
        -- Grant permissions
        GRANT CONNECT ON DATABASE analytics TO analytics_readonly;
        GRANT USAGE ON SCHEMA public TO analytics_readonly;
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_readonly;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO analytics_readonly;
        
        GRANT ALL PRIVILEGES ON DATABASE superset TO superset;
        GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;
        
        -- Enable extensions
        \c analytics;
        CREATE EXTENSION IF NOT EXISTS timescaledb;
        CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
        CREATE EXTENSION IF NOT EXISTS postgis;
        
        -- Create analytics tables
        CREATE TABLE posts (
          id BIGSERIAL PRIMARY KEY,
          uri TEXT NOT NULL,
          cid TEXT NOT NULL,
          author_did TEXT NOT NULL,
          created_at TIMESTAMPTZ NOT NULL,
          content TEXT,
          language TEXT,
          sentiment REAL,
          topics TEXT[],
          engagement_score REAL,
          INDEX_TIME TIMESTAMPTZ DEFAULT NOW()
        );
        
        CREATE TABLE interactions (
          id BIGSERIAL PRIMARY KEY,
          type TEXT NOT NULL, -- like, repost, reply, follow, block
          actor_did TEXT NOT NULL,
          target_did TEXT,
          target_uri TEXT,
          created_at TIMESTAMPTZ NOT NULL,
          INDEX_TIME TIMESTAMPTZ DEFAULT NOW()
        );
        
        CREATE TABLE network_metrics (
          did TEXT PRIMARY KEY,
          followers_count INTEGER DEFAULT 0,
          following_count INTEGER DEFAULT 0,
          posts_count INTEGER DEFAULT 0,
          centrality_score REAL,
          clustering_coefficient REAL,
          community_id INTEGER,
          updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        -- Convert to time-series tables
        SELECT create_hypertable('posts', 'created_at');
        SELECT create_hypertable('interactions', 'created_at');
        
        -- Create indexes for analytics queries
        CREATE INDEX idx_posts_author_time ON posts (author_did, created_at);
        CREATE INDEX idx_posts_language ON posts (language);
        CREATE INDEX idx_posts_sentiment ON posts (sentiment);
        CREATE INDEX idx_interactions_type_time ON interactions (type, created_at);
        CREATE INDEX idx_interactions_actor ON interactions (actor_did);
      '';
    };

    # Research data access controls
    security.sudo.extraRules = [
      {
        users = [ "researcher" ];
        commands = [
          {
            command = "${pkgs.postgresql}/bin/psql -d analytics -U analytics_readonly";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Users for research platform
    users.users.researcher = {
      isNormalUser = true;
      home = "/home/researcher";
      createHome = true;
      extraGroups = [ "wheel" ];
      
      # Research tools in PATH
      packages = with pkgs; [
        python3
        R
        julia
        postgresql
        clickhouse-cli
      ];
    };
  };
}