# Defines the NixOS module for the QuickDID identity resolution service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.smokesignal-events-quickdid;
in
{
  options.services.smokesignal-events-quickdid = {
    enable = mkEnableOption "QuickDID AT Protocol identity resolution service";

    package = mkOption {
      type = types.package;
      default = pkgs.smokesignal-events-quickdid or pkgs.quickdid;
      description = "The QuickDID package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/quickdid";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "quickdid";
      description = "User account for QuickDID service.";
    };

    group = mkOption {
      type = types.str;
      default = "quickdid";
      description = "Group for QuickDID service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          httpPort = mkOption {
            type = types.port;
            default = 8080;
            description = "HTTP server port.";
          };

          httpExternal = mkOption {
            type = types.str;
            description = "External hostname for service endpoints.";
            example = "quickdid.example.com";
          };

          plcHostname = mkOption {
            type = types.str;
            default = "plc.directory";
            description = "PLC directory hostname.";
          };

          userAgent = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "HTTP User-Agent for outgoing requests.";
          };

          dnsNameservers = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Custom DNS servers.";
            example = [ "8.8.8.8" "1.1.1.1" ];
          };

          cache = {
            ttlMemory = mkOption {
              type = types.int;
              default = 600;
              description = "In-memory cache TTL in seconds.";
            };

            ttlRedis = mkOption {
              type = types.int;
              default = 7776000;
              description = "Redis cache TTL in seconds (90 days).";
            };

            ttlSqlite = mkOption {
              type = types.int;
              default = 7776000;
              description = "SQLite cache TTL in seconds (90 days).";
            };

            redis = {
              url = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Redis connection URL.";
                example = "redis://localhost:6379";
              };

              passwordFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "File containing Redis password.";
              };
            };

            sqlite = {
              url = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "SQLite database URL.";
                example = "sqlite:./quickdid.db";
              };
            };
          };

          queue = {
            adapter = mkOption {
              type = types.enum [ "mpsc" "redis" "sqlite" "noop" "none" ];
              default = "mpsc";
              description = "Queue adapter type.";
            };

            workerId = mkOption {
              type = types.str;
              default = "worker1";
              description = "Worker identifier.";
            };

            bufferSize = mkOption {
              type = types.int;
              default = 1000;
              description = "MPSC queue buffer size.";
            };

            redis = {
              prefix = mkOption {
                type = types.str;
                default = "queue:handleresolver:";
                description = "Redis key prefix for queues.";
              };

              timeout = mkOption {
                type = types.int;
                default = 5;
                description = "Redis blocking timeout in seconds.";
              };

              dedup = {
                enable = mkEnableOption "queue deduplication";

                ttl = mkOption {
                  type = types.int;
                  default = 60;
                  description = "TTL for deduplication keys in seconds.";
                };
              };
            };

            sqlite = {
              maxSize = mkOption {
                type = types.int;
                default = 10000;
                description = "Max SQLite queue size for work shedding.";
              };
            };
          };

          resolver = {
            maxConcurrent = mkOption {
              type = types.int;
              default = 0;
              description = "Maximum concurrent handle resolutions (0 = disabled).";
            };

            maxConcurrentTimeoutMs = mkOption {
              type = types.int;
              default = 0;
              description = "Timeout for acquiring rate limit permit in ms (0 = no timeout).";
            };
          };

          httpCache = {
            maxAge = mkOption {
              type = types.int;
              default = 86400;
              description = "Max-age for Cache-Control header in seconds.";
            };

            staleIfError = mkOption {
              type = types.int;
              default = 172800;
              description = "Stale-if-error directive in seconds.";
            };

            staleWhileRevalidate = mkOption {
              type = types.int;
              default = 86400;
              description = "Stale-while-revalidate in seconds.";
            };

            maxStale = mkOption {
              type = types.int;
              default = 86400;
              description = "Max-stale directive in seconds.";
            };

            etagSeed = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Seed value for ETag generation.";
            };
          };

          metrics = {
            adapter = mkOption {
              type = types.enum [ "noop" "statsd" ];
              default = "noop";
              description = "Metrics adapter type.";
            };

            statsd = {
              host = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "StatsD host and port.";
                example = "localhost:8125";
              };

              bind = mkOption {
                type = types.str;
                default = "[::]:0";
                description = "Bind address for StatsD UDP socket.";
              };
            };

            prefix = mkOption {
              type = types.str;
              default = "quickdid";
              description = "Prefix for all metrics.";
            };

            tags = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Comma-separated tags.";
              example = [ "env:prod" "service:quickdid" ];
            };
          };

          proactiveRefresh = {
            enable = mkEnableOption "proactive cache refreshing";

            threshold = mkOption {
              type = types.float;
              default = 0.8;
              description = "Refresh when TTL remaining is below this threshold (0.0-1.0).";
            };
          };

          jetstream = {
            enable = mkEnableOption "Jetstream consumer for real-time cache updates";

            hostname = mkOption {
              type = types.str;
              default = "jetstream.atproto.tools";
              description = "Jetstream WebSocket hostname.";
            };
          };

          staticFiles = {
            directory = mkOption {
              type = types.path;
              default = "${cfg.dataDir}/www";
              description = "Directory for serving static files.";
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
      description = "QuickDID service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.httpExternal != "";
        message = "services.smokesignal-events-quickdid: httpExternal must be specified";
      }
      {
        assertion = cfg.settings.proactiveRefresh.threshold >= 0.0 && cfg.settings.proactiveRefresh.threshold <= 1.0;
        message = "services.smokesignal-events-quickdid: proactiveRefresh threshold must be between 0.0 and 1.0";
      }
      {
        assertion = cfg.settings.metrics.adapter == "statsd" -> (cfg.settings.metrics.statsd.host != null);
        message = "services.smokesignal-events-quickdid: StatsD host must be specified when using statsd metrics adapter";
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
      "d '${cfg.settings.staticFiles.directory}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # systemd service
    systemd.services.smokesignal-events-quickdid = {
      description = "QuickDID AT Protocol identity resolution service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] 
        ++ lib.optional (cfg.settings.cache.redis.url != null) [ "redis.service" ];
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
        ReadWritePaths = [ cfg.dataDir cfg.settings.staticFiles.directory ];
        ReadOnlyPaths = [ "/nix/store" ];
      };

      environment = {
        RUST_LOG = cfg.settings.logLevel;
        HTTP_PORT = toString cfg.settings.httpPort;
        HTTP_EXTERNAL = cfg.settings.httpExternal;
        PLC_HOSTNAME = cfg.settings.plcHostname;
        CACHE_TTL_MEMORY = toString cfg.settings.cache.ttlMemory;
        CACHE_TTL_REDIS = toString cfg.settings.cache.ttlRedis;
        CACHE_TTL_SQLITE = toString cfg.settings.cache.ttlSqlite;
        QUEUE_ADAPTER = cfg.settings.queue.adapter;
        QUEUE_WORKER_ID = cfg.settings.queue.workerId;
        QUEUE_BUFFER_SIZE = toString cfg.settings.queue.bufferSize;
        QUEUE_REDIS_PREFIX = cfg.settings.queue.redis.prefix;
        QUEUE_REDIS_TIMEOUT = toString cfg.settings.queue.redis.timeout;
        QUEUE_REDIS_DEDUP_ENABLED = if cfg.settings.queue.redis.dedup.enable then "true" else "false";
        QUEUE_REDIS_DEDUP_TTL = toString cfg.settings.queue.redis.dedup.ttl;
        QUEUE_SQLITE_MAX_SIZE = toString cfg.settings.queue.sqlite.maxSize;
        RESOLVER_MAX_CONCURRENT = toString cfg.settings.resolver.maxConcurrent;
        RESOLVER_MAX_CONCURRENT_TIMEOUT_MS = toString cfg.settings.resolver.maxConcurrentTimeoutMs;
        CACHE_MAX_AGE = toString cfg.settings.httpCache.maxAge;
        CACHE_STALE_IF_ERROR = toString cfg.settings.httpCache.staleIfError;
        CACHE_STALE_WHILE_REVALIDATE = toString cfg.settings.httpCache.staleWhileRevalidate;
        CACHE_MAX_STALE = toString cfg.settings.httpCache.maxStale;
        METRICS_ADAPTER = cfg.settings.metrics.adapter;
        METRICS_PREFIX = cfg.settings.metrics.prefix;
        METRICS_STATSD_BIND = cfg.settings.metrics.statsd.bind;
        PROACTIVE_REFRESH_ENABLED = if cfg.settings.proactiveRefresh.enable then "true" else "false";
        PROACTIVE_REFRESH_THRESHOLD = toString cfg.settings.proactiveRefresh.threshold;
        JETSTREAM_ENABLED = if cfg.settings.jetstream.enable then "true" else "false";
        JETSTREAM_HOSTNAME = cfg.settings.jetstream.hostname;
        STATIC_FILES_DIR = cfg.settings.staticFiles.directory;
      } // lib.optionalAttrs (cfg.settings.userAgent != null) {
        USER_AGENT = cfg.settings.userAgent;
      } // lib.optionalAttrs (cfg.settings.dnsNameservers != []) {
        DNS_NAMESERVERS = concatStringsSep "," cfg.settings.dnsNameservers;
      } // lib.optionalAttrs (cfg.settings.cache.redis.url != null) {
        REDIS_URL = cfg.settings.cache.redis.url;
      } // lib.optionalAttrs (cfg.settings.cache.sqlite.url != null) {
        SQLITE_URL = cfg.settings.cache.sqlite.url;
      } // lib.optionalAttrs (cfg.settings.httpCache.etagSeed != null) {
        ETAG_SEED = cfg.settings.httpCache.etagSeed;
      } // lib.optionalAttrs (cfg.settings.metrics.adapter == "statsd") {
        METRICS_STATSD_HOST = cfg.settings.metrics.statsd.host;
      } // lib.optionalAttrs (cfg.settings.metrics.tags != []) {
        METRICS_TAGS = concatStringsSep "," cfg.settings.metrics.tags;
      };

      script = 
        let
          redisPasswordEnv = if cfg.settings.cache.redis.url != null && cfg.settings.cache.redis.passwordFile != null
            then "REDIS_URL=$(sed \"s/:@/:$(cat ${cfg.settings.cache.redis.passwordFile})@/\" <<< \"${cfg.settings.cache.redis.url}\")"
            else "";
        in
        ''
          ${lib.optionalString (cfg.settings.cache.redis.url != null && cfg.settings.cache.redis.passwordFile != null) redisPasswordEnv}
          ${lib.optionalString (cfg.settings.cache.redis.url != null && cfg.settings.cache.redis.passwordFile != null) "export REDIS_URL"}
          
          exec ${cfg.package}/bin/quickdid
        '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.httpPort ];
  };
}