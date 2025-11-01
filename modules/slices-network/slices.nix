# Defines the NixOS module for the Slices custom AppView platform
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.slices-network-slices;
  
  # Multi-tenant configuration helpers
  tenantType = types.submodule {
    options = {
      enable = mkEnableOption "this tenant";
      
      sliceUri = mkOption {
        type = types.str;
        description = "Slice URI for this tenant.";
        example = "at://did:plc:example/network.slices.slice/tenant1";
      };
      
      adminDid = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Admin DID for this tenant.";
        example = "did:plc:example123";
      };
      
      database = {
        name = mkOption {
          type = types.str;
          description = "Database name for this tenant.";
          example = "slices_tenant1";
        };
        
        isolationLevel = mkOption {
          type = types.enum [ "database" "schema" "table_prefix" ];
          default = "schema";
          description = "Level of database isolation for multi-tenancy.";
        };
      };
      
      oauth = {
        clientId = mkOption {
          type = types.str;
          description = "OAuth client ID for this tenant.";
        };
        
        clientSecretFile = mkOption {
          type = types.path;
          description = "File containing OAuth client secret for this tenant.";
        };
        
        redirectUri = mkOption {
          type = types.str;
          description = "OAuth redirect URI for this tenant.";
          example = "https://tenant1.slices.example.com/auth/callback";
        };
      };
      
      customDomain = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Custom domain for this tenant.";
        example = "tenant1.slices.example.com";
      };
      
      resourceLimits = {
        maxSyncRepos = mkOption {
          type = types.int;
          default = 1000;
          description = "Maximum repositories this tenant can sync.";
        };
        
        maxStorageGB = mkOption {
          type = types.int;
          default = 10;
          description = "Maximum storage in GB for this tenant.";
        };
        
        maxApiRequestsPerMinute = mkOption {
          type = types.int;
          default = 1000;
          description = "Maximum API requests per minute for this tenant.";
        };
      };
      
      features = {
        jetstreamEnabled = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Jetstream real-time sync for this tenant.";
        };
        
        customLexicons = mkOption {
          type = types.bool;
          default = true;
          description = "Allow custom lexicon definitions for this tenant.";
        };
        
        sdkGeneration = mkOption {
          type = types.bool;
          default = true;
          description = "Enable automatic SDK generation for this tenant.";
        };
      };
    };
  };
in
{
  options.services.slices-network-slices = {
    enable = mkEnableOption "Slices custom AppView platform";

    package = mkOption {
      type = types.package;
      default = pkgs.slices-network-slices;
      description = "The Slices package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/atproto-slices";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "atproto-slices";
      description = "User account for Slices service.";
    };

    group = mkOption {
      type = types.str;
      default = "atproto-slices";
      description = "Group for Slices service.";
    };
    
    # Multi-tenant configuration
    multiTenant = {
      enable = mkEnableOption "multi-tenant mode";
      
      tenants = mkOption {
        type = types.attrsOf tenantType;
        default = {};
        description = "Configuration for individual tenants.";
        example = {
          tenant1 = {
            enable = true;
            sliceUri = "at://did:plc:example/network.slices.slice/tenant1";
            database.name = "slices_tenant1";
            oauth = {
              clientId = "tenant1-client";
              clientSecretFile = "/run/secrets/tenant1-oauth-secret";
              redirectUri = "https://tenant1.example.com/auth/callback";
            };
          };
        };
      };
      
      defaultTenant = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default tenant name for requests without tenant specification.";
      };
      
      tenantResolution = {
        method = mkOption {
          type = types.enum [ "subdomain" "path" "header" ];
          default = "subdomain";
          description = "Method for resolving tenant from requests.";
        };
        
        headerName = mkOption {
          type = types.str;
          default = "X-Tenant-ID";
          description = "Header name for tenant resolution when method is 'header'.";
        };
      };
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          api = {
            port = mkOption {
              type = types.port;
              default = 3000;
              description = "Port for the Slices API server.";
            };

            processType = mkOption {
              type = types.enum [ "all" "app" "worker" ];
              default = "all";
              description = "Process type: all (HTTP + Jetstream), app, or worker.";
            };

            maxSyncRepos = mkOption {
              type = types.int;
              default = 5000;
              description = "Maximum repositories per sync operation (global default).";
            };
            
            # Multi-tenant API configuration
            multiTenantConfig = {
              tenantIsolation = mkOption {
                type = types.enum [ "strict" "shared" "hybrid" ];
                default = "strict";
                description = "Level of tenant isolation in API layer.";
              };
              
              rateLimiting = {
                enabled = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Enable per-tenant rate limiting.";
                };
                
                globalLimit = mkOption {
                  type = types.int;
                  default = 10000;
                  description = "Global API requests per minute limit.";
                };
              };
              
              crossTenantAccess = mkOption {
                type = types.bool;
                default = false;
                description = "Allow cross-tenant data access (for shared services).";
              };
            };
          };

          frontend = {
            enable = mkEnableOption "Slices frontend service";

            port = mkOption {
              type = types.port;
              default = 8080;
              description = "Port for the Slices frontend server.";
            };
            
            # Multi-tenant frontend configuration
            multiTenantUI = {
              tenantSwitcher = mkOption {
                type = types.bool;
                default = true;
                description = "Enable tenant switcher in UI for multi-tenant deployments.";
              };
              
              customBranding = mkOption {
                type = types.bool;
                default = true;
                description = "Enable per-tenant custom branding and themes.";
              };
              
              sharedResources = mkOption {
                type = types.bool;
                default = true;
                description = "Share static resources across tenants for efficiency.";
              };
            };
          };

          database = {
            url = mkOption {
              type = types.str;
              description = "PostgreSQL database URL (base connection for multi-tenant).";
              example = "postgresql://user:pass@localhost:5432/slices";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing database password.";
            };
            
            # Multi-tenant database configuration
            multiTenantConfig = {
              isolationStrategy = mkOption {
                type = types.enum [ "database_per_tenant" "schema_per_tenant" "shared_with_tenant_id" ];
                default = "schema_per_tenant";
                description = "Database isolation strategy for multi-tenancy.";
              };
              
              connectionPooling = {
                enabled = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Enable connection pooling for multi-tenant databases.";
                };
                
                maxConnectionsPerTenant = mkOption {
                  type = types.int;
                  default = 10;
                  description = "Maximum database connections per tenant.";
                };
                
                globalMaxConnections = mkOption {
                  type = types.int;
                  default = 100;
                  description = "Global maximum database connections.";
                };
              };
              
              migrations = {
                autoMigrate = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Automatically run migrations for new tenants.";
                };
                
                migrationTimeout = mkOption {
                  type = types.int;
                  default = 300;
                  description = "Timeout in seconds for tenant migrations.";
                };
              };
            };
          };

          oauth = {
            clientId = mkOption {
              type = types.str;
              description = "OAuth application client ID (default/global).";
            };

            clientSecretFile = mkOption {
              type = types.path;
              description = "File containing OAuth client secret (default/global).";
            };

            redirectUri = mkOption {
              type = types.str;
              description = "OAuth callback URL (default/global).";
              example = "https://slices.example.com/auth/callback";
            };

            aipBaseUrl = mkOption {
              type = types.str;
              description = "AIP OAuth service URL.";
              example = "https://auth.slices.example.com";
            };
          };

          atproto = {
            relayEndpoint = mkOption {
              type = types.str;
              default = "https://relay1.us-west.bsky.network";
              description = "AT Protocol relay endpoint for backfill.";
            };

            jetstreamHostname = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "AT Protocol Jetstream hostname.";
              example = "jetstream1.us-east.bsky.network";
            };

            systemSliceUri = mkOption {
              type = types.str;
              description = "System slice URI (global default).";
              example = "at://did:plc:example/network.slices.slice/system";
            };

            sliceUri = mkOption {
              type = types.str;
              description = "Default slice URI for queries (fallback).";
              example = "at://did:plc:example/network.slices.slice/default";
            };
          };

          redis = {
            url = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Redis connection URL (optional, falls back to in-memory cache).";
              example = "redis://localhost:6379";
            };

            ttlSeconds = mkOption {
              type = types.int;
              default = 3600;
              description = "Redis cache TTL in seconds.";
            };
            
            # Multi-tenant Redis configuration
            multiTenantConfig = {
              keyPrefix = mkOption {
                type = types.str;
                default = "slices";
                description = "Redis key prefix for multi-tenant isolation.";
              };
              
              separateNamespaces = mkOption {
                type = types.bool;
                default = true;
                description = "Use separate Redis namespaces per tenant.";
              };
            };
          };

          jetstream = {
            cursorWriteIntervalSecs = mkOption {
              type = types.int;
              default = 30;
              description = "Interval for writing Jetstream cursor position.";
            };
            
            # Multi-tenant Jetstream configuration
            multiTenantConfig = {
              perTenantCursors = mkOption {
                type = types.bool;
                default = true;
                description = "Maintain separate Jetstream cursors per tenant.";
              };
              
              sharedConnection = mkOption {
                type = types.bool;
                default = true;
                description = "Share Jetstream connection across tenants for efficiency.";
              };
            };
          };

          adminDid = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Global admin DID for privileged operations.";
            example = "did:plc:example123";
          };

          logLevel = mkOption {
            type = types.enum [ "trace" "debug" "info" "warn" "error" ];
            default = "info";
            description = "Logging level.";
          };
          
          # Multi-tenant monitoring and observability
          monitoring = {
            perTenantMetrics = mkOption {
              type = types.bool;
              default = true;
              description = "Collect metrics per tenant for monitoring.";
            };
            
            tenantUsageTracking = mkOption {
              type = types.bool;
              default = true;
              description = "Track resource usage per tenant.";
            };
            
            alerting = {
              tenantQuotaAlerts = mkOption {
                type = types.bool;
                default = true;
                description = "Enable alerts when tenants approach resource quotas.";
              };
            };
          };
        };
      };
      default = {};
      description = "Slices service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.database.url != "";
        message = "services.slices-network-slices: database URL must be specified";
      }
      {
        assertion = cfg.settings.oauth.clientId != "";
        message = "services.slices-network-slices: OAuth client ID must be specified";
      }
      {
        assertion = cfg.settings.atproto.systemSliceUri != "";
        message = "services.slices-network-slices: system slice URI must be specified";
      }
      {
        assertion = !cfg.multiTenant.enable || (cfg.multiTenant.tenants != {});
        message = "services.slices-network-slices: multi-tenant mode requires at least one tenant configuration";
      }
      {
        assertion = !cfg.multiTenant.enable || (cfg.multiTenant.defaultTenant == null || hasAttr cfg.multiTenant.defaultTenant cfg.multiTenant.tenants);
        message = "services.slices-network-slices: defaultTenant must be null or reference an existing tenant";
      }
    ] ++ (flatten (mapAttrsToList (tenantName: tenantCfg: [
      {
        assertion = !cfg.multiTenant.enable || tenantCfg.sliceUri != "";
        message = "services.slices-network-slices: tenant '${tenantName}' must have a slice URI";
      }
      {
        assertion = !cfg.multiTenant.enable || tenantCfg.oauth.clientId != "";
        message = "services.slices-network-slices: tenant '${tenantName}' must have OAuth client ID";
      }
      {
        assertion = !cfg.multiTenant.enable || tenantCfg.database.name != "";
        message = "services.slices-network-slices: tenant '${tenantName}' must have database name";
      }
    ]) cfg.multiTenant.tenants));

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
      "d '${cfg.dataDir}/tenants' 0750 ${cfg.user} ${cfg.group} - -"
    ] ++ (flatten (mapAttrsToList (tenantName: tenantCfg: [
      "d '${cfg.dataDir}/tenants/${tenantName}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/tenants/${tenantName}/logs' 0750 ${cfg.user} ${cfg.group} - -"
    ]) (filterAttrs (n: v: v.enable) cfg.multiTenant.tenants)));

    # Slices API service
    systemd.services.slices-network-slices-api = {
      description = "Slices API server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" ] ++ optional (cfg.settings.redis.url != null) [ "redis.service" ];
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
        DATABASE_URL = cfg.settings.database.url;
        PORT = toString cfg.settings.api.port;
        PROCESS_TYPE = cfg.settings.api.processType;
        RELAY_ENDPOINT = cfg.settings.atproto.relayEndpoint;
        SYSTEM_SLICE_URI = cfg.settings.atproto.systemSliceUri;
        DEFAULT_MAX_SYNC_REPOS = toString cfg.settings.api.maxSyncRepos;
        JETSTREAM_CURSOR_WRITE_INTERVAL_SECS = toString cfg.settings.jetstream.cursorWriteIntervalSecs;
        RUST_LOG = cfg.settings.logLevel;
        
        # Multi-tenant configuration
        MULTI_TENANT_ENABLED = if cfg.multiTenant.enable then "true" else "false";
        TENANT_RESOLUTION_METHOD = cfg.multiTenant.tenantResolution.method;
        TENANT_HEADER_NAME = cfg.multiTenant.tenantResolution.headerName;
        DEFAULT_TENANT = cfg.multiTenant.defaultTenant or "";
        
        # Multi-tenant database configuration
        DB_ISOLATION_STRATEGY = cfg.settings.database.multiTenantConfig.isolationStrategy;
        DB_MAX_CONNECTIONS_PER_TENANT = toString cfg.settings.database.multiTenantConfig.connectionPooling.maxConnectionsPerTenant;
        DB_GLOBAL_MAX_CONNECTIONS = toString cfg.settings.database.multiTenantConfig.connectionPooling.globalMaxConnections;
        
        # Multi-tenant Redis configuration
        REDIS_KEY_PREFIX = cfg.settings.redis.multiTenantConfig.keyPrefix;
        REDIS_SEPARATE_NAMESPACES = if cfg.settings.redis.multiTenantConfig.separateNamespaces then "true" else "false";
        
        # Multi-tenant API configuration
        API_TENANT_ISOLATION = cfg.settings.api.multiTenantConfig.tenantIsolation;
        API_RATE_LIMITING_ENABLED = if cfg.settings.api.multiTenantConfig.rateLimiting.enabled then "true" else "false";
        API_GLOBAL_RATE_LIMIT = toString cfg.settings.api.multiTenantConfig.rateLimiting.globalLimit;
        API_CROSS_TENANT_ACCESS = if cfg.settings.api.multiTenantConfig.crossTenantAccess then "true" else "false";
        
        # Monitoring configuration
        MONITORING_PER_TENANT_METRICS = if cfg.settings.monitoring.perTenantMetrics then "true" else "false";
        MONITORING_TENANT_USAGE_TRACKING = if cfg.settings.monitoring.tenantUsageTracking then "true" else "false";
      } // optionalAttrs (cfg.settings.atproto.jetstreamHostname != null) {
        JETSTREAM_HOSTNAME = cfg.settings.atproto.jetstreamHostname;
      } // optionalAttrs (cfg.settings.redis.url != null) {
        REDIS_URL = cfg.settings.redis.url;
        REDIS_TTL_SECONDS = toString cfg.settings.redis.ttlSeconds;
      } // optionalAttrs (cfg.settings.adminDid != null) {
        ADMIN_DID = cfg.settings.adminDid;
      };

      script = ''
        # Load secrets from files
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}
        
        # Generate tenant configuration file for multi-tenant mode
        ${optionalString cfg.multiTenant.enable ''
          cat > ${cfg.dataDir}/tenant-config.json << 'EOF'
          {
            "tenants": {
              ${concatStringsSep ",\n" (mapAttrsToList (tenantName: tenantCfg: ''
                "${tenantName}": {
                  "enabled": ${if tenantCfg.enable then "true" else "false"},
                  "sliceUri": "${tenantCfg.sliceUri}",
                  "adminDid": ${if tenantCfg.adminDid != null then ''"${tenantCfg.adminDid}"'' else "null"},
                  "database": {
                    "name": "${tenantCfg.database.name}",
                    "isolationLevel": "${tenantCfg.database.isolationLevel}"
                  },
                  "oauth": {
                    "clientId": "${tenantCfg.oauth.clientId}",
                    "redirectUri": "${tenantCfg.oauth.redirectUri}"
                  },
                  "customDomain": ${if tenantCfg.customDomain != null then ''"${tenantCfg.customDomain}"'' else "null"},
                  "resourceLimits": {
                    "maxSyncRepos": ${toString tenantCfg.resourceLimits.maxSyncRepos},
                    "maxStorageGB": ${toString tenantCfg.resourceLimits.maxStorageGB},
                    "maxApiRequestsPerMinute": ${toString tenantCfg.resourceLimits.maxApiRequestsPerMinute}
                  },
                  "features": {
                    "jetstreamEnabled": ${if tenantCfg.features.jetstreamEnabled then "true" else "false"},
                    "customLexicons": ${if tenantCfg.features.customLexicons then "true" else "false"},
                    "sdkGeneration": ${if tenantCfg.features.sdkGeneration then "true" else "false"}
                  }
                }
              '') (filterAttrs (n: v: v.enable) cfg.multiTenant.tenants))}
            }
          }
          EOF
          
          export TENANT_CONFIG_FILE="${cfg.dataDir}/tenant-config.json"
          
          # Load tenant OAuth secrets
          ${concatStringsSep "\n" (mapAttrsToList (tenantName: tenantCfg: ''
            export TENANT_${toUpper tenantName}_OAUTH_SECRET="$(cat ${tenantCfg.oauth.clientSecretFile})"
          '') (filterAttrs (n: v: v.enable) cfg.multiTenant.tenants))}
        ''}

        exec ${cfg.package}/bin/slices
      '';
    };

    # Optional Slices frontend service
    systemd.services.slices-network-slices-frontend = mkIf cfg.settings.frontend.enable {
      description = "Slices frontend server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "slices-network-slices-api.service" ];
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
        OAUTH_CLIENT_ID = cfg.settings.oauth.clientId;
        OAUTH_REDIRECT_URI = cfg.settings.oauth.redirectUri;
        OAUTH_AIP_BASE_URL = cfg.settings.oauth.aipBaseUrl;
        API_URL = "http://localhost:${toString cfg.settings.api.port}";
        SLICE_URI = cfg.settings.atproto.sliceUri;
        DATABASE_URL = "${cfg.dataDir}/slices-frontend.db";  # SQLite for frontend sessions
        PORT = toString cfg.settings.frontend.port;
        
        # Multi-tenant frontend configuration
        MULTI_TENANT_ENABLED = if cfg.multiTenant.enable then "true" else "false";
        TENANT_SWITCHER_ENABLED = if cfg.settings.frontend.multiTenantUI.tenantSwitcher then "true" else "false";
        CUSTOM_BRANDING_ENABLED = if cfg.settings.frontend.multiTenantUI.customBranding then "true" else "false";
        SHARED_RESOURCES_ENABLED = if cfg.settings.frontend.multiTenantUI.sharedResources then "true" else "false";
        TENANT_RESOLUTION_METHOD = cfg.multiTenant.tenantResolution.method;
        TENANT_HEADER_NAME = cfg.multiTenant.tenantResolution.headerName;
        DEFAULT_TENANT = cfg.multiTenant.defaultTenant or "";
      } // optionalAttrs (cfg.settings.adminDid != null) {
        ADMIN_DID = cfg.settings.adminDid;
      };

      script = ''
        # Load secrets from files
        export OAUTH_CLIENT_SECRET="$(cat ${cfg.settings.oauth.clientSecretFile})"
        
        # Generate tenant configuration for frontend
        ${optionalString cfg.multiTenant.enable ''
          cat > ${cfg.dataDir}/frontend-tenant-config.json << 'EOF'
          {
            "tenants": {
              ${concatStringsSep ",\n" (mapAttrsToList (tenantName: tenantCfg: ''
                "${tenantName}": {
                  "enabled": ${if tenantCfg.enable then "true" else "false"},
                  "sliceUri": "${tenantCfg.sliceUri}",
                  "customDomain": ${if tenantCfg.customDomain != null then ''"${tenantCfg.customDomain}"'' else "null"},
                  "oauth": {
                    "clientId": "${tenantCfg.oauth.clientId}",
                    "redirectUri": "${tenantCfg.oauth.redirectUri}"
                  },
                  "features": {
                    "customLexicons": ${if tenantCfg.features.customLexicons then "true" else "false"},
                    "sdkGeneration": ${if tenantCfg.features.sdkGeneration then "true" else "false"}
                  }
                }
              '') (filterAttrs (n: v: v.enable) cfg.multiTenant.tenants))}
            }
          }
          EOF
          
          export FRONTEND_TENANT_CONFIG_FILE="${cfg.dataDir}/frontend-tenant-config.json"
        ''}

        exec ${cfg.package}/bin/slices-frontend
      '';
    };
    
  } // (mkMerge (mapAttrsToList (tenantName: tenantCfg: 
    mkIf (cfg.multiTenant.enable && tenantCfg.enable && cfg.settings.api.multiTenantConfig.tenantIsolation == "strict") {
      systemd.services."atproto-slices-tenant-${tenantName}" = {
          description = "Slices tenant service for ${tenantName}";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" "postgresql.service" "slices-network-slices-api.service" ];
          wants = [ "network.target" ];
          
          serviceConfig = {
            Type = "exec";
            User = cfg.user;
            Group = cfg.group;
            WorkingDirectory = "${cfg.dataDir}/tenants/${tenantName}";
            Restart = "on-failure";
            RestartSec = "10s";
            
            # Security hardening
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            
            # File system access
            ReadWritePaths = [ "${cfg.dataDir}/tenants/${tenantName}" ];
            ReadOnlyPaths = [ "/nix/store" ];
          };
          
          environment = {
            TENANT_NAME = tenantName;
            TENANT_SLICE_URI = tenantCfg.sliceUri;
            TENANT_DATABASE_NAME = tenantCfg.database.name;
            TENANT_OAUTH_CLIENT_ID = tenantCfg.oauth.clientId;
            TENANT_OAUTH_REDIRECT_URI = tenantCfg.oauth.redirectUri;
            TENANT_MAX_SYNC_REPOS = toString tenantCfg.resourceLimits.maxSyncRepos;
            TENANT_MAX_STORAGE_GB = toString tenantCfg.resourceLimits.maxStorageGB;
            TENANT_MAX_API_REQUESTS_PER_MINUTE = toString tenantCfg.resourceLimits.maxApiRequestsPerMinute;
            RUST_LOG = cfg.settings.logLevel;
          } // optionalAttrs (tenantCfg.adminDid != null) {
            TENANT_ADMIN_DID = tenantCfg.adminDid;
          } // optionalAttrs (tenantCfg.customDomain != null) {
            TENANT_CUSTOM_DOMAIN = tenantCfg.customDomain;
          };
          
          script = ''
            # Load tenant-specific OAuth secret
            export TENANT_OAUTH_CLIENT_SECRET="$(cat ${tenantCfg.oauth.clientSecretFile})"
            
            # Run tenant-specific worker process
            exec ${cfg.package}/bin/slices --tenant=${tenantName}
          '';
        };
    }
  ) cfg.multiTenant.tenants));
}