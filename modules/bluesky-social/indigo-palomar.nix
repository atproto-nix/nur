# Defines the NixOS module for the Indigo Palomar (search service) service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.indigo-palomar;
in
{
  options.services.indigo-palomar = {
    enable = mkEnableOption "Indigo Palomar fulltext search service";

    package = mkOption {
      type = types.package;
      default = pkgs.bluesky-social-indigo-palomar or pkgs.indigo-palomar;
      description = "The Indigo Palomar package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/indigo-palomar";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "indigo-palomar";
      description = "User account for Indigo Palomar service.";
    };

    group = mkOption {
      type = types.str;
      default = "indigo-palomar";
      description = "Group for Indigo Palomar service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 2474;
            description = "Port for the palomar service to listen on.";
          };

          hostname = mkOption {
            type = types.str;
            description = "Hostname for the palomar service.";
            example = "search.example.com";
          };

          firehoseHost = mkOption {
            type = types.str;
            description = "Firehose host to connect to for indexing.";
            example = "bsky.network";
          };

          database = {
            url = mkOption {
              type = types.str;
              description = "Database connection URL.";
              example = "postgres://user:pass@localhost/palomar";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing database password.";
            };
          };

          elasticsearch = {
            url = mkOption {
              type = types.str;
              description = "Elasticsearch cluster URL.";
              example = "http://localhost:9200";
            };

            index = mkOption {
              type = types.str;
              default = "bsky_posts";
              description = "Elasticsearch index name for posts.";
            };

            username = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Elasticsearch username.";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing Elasticsearch password.";
            };
          };

          plcHost = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "PLC directory host URL.";
          };

          indexing = {
            batchSize = mkOption {
              type = types.int;
              default = 100;
              description = "Batch size for indexing operations.";
            };

            workers = mkOption {
              type = types.int;
              default = 4;
              description = "Number of indexing worker threads.";
            };

            flushInterval = mkOption {
              type = types.int;
              default = 30;
              description = "Flush interval in seconds for batch operations.";
            };
          };

          search = {
            maxResults = mkOption {
              type = types.int;
              default = 100;
              description = "Maximum number of search results to return.";
            };

            timeout = mkOption {
              type = types.int;
              default = 30;
              description = "Search timeout in seconds.";
            };
          };

          logLevel = mkOption {
            type = types.enum [ "debug" "info" "warn" "error" ];
            default = "info";
            description = "Logging level.";
          };

          metrics = {
            enable = mkEnableOption "Prometheus metrics endpoint";
            
            port = mkOption {
              type = types.port;
              default = 2475;
              description = "Port for metrics endpoint.";
            };
          };
        };
      };
      default = {};
      description = "Indigo Palomar service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.hostname != "";
        message = "services.indigo-palomar: hostname must be specified";
      }
      {
        assertion = cfg.settings.firehoseHost != "";
        message = "services.indigo-palomar: firehoseHost must be specified";
      }
      {
        assertion = cfg.settings.database.url != "";
        message = "services.indigo-palomar: database URL must be specified";
      }
      {
        assertion = cfg.settings.elasticsearch.url != "";
        message = "services.indigo-palomar: elasticsearch URL must be specified";
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
    ];

    # systemd service
    systemd.services.indigo-palomar = {
      description = "Indigo Palomar fulltext search service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" "elasticsearch.service" ];
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
        GOLOG_LOG_LEVEL = cfg.settings.logLevel;
        PALOMAR_HOSTNAME = cfg.settings.hostname;
        PALOMAR_PORT = toString cfg.settings.port;
        PALOMAR_FIREHOSE_HOST = cfg.settings.firehoseHost;
        PALOMAR_PLC_HOST = cfg.settings.plcHost;
        PALOMAR_DATABASE_URL = cfg.settings.database.url;
        PALOMAR_ELASTICSEARCH_URL = cfg.settings.elasticsearch.url;
        PALOMAR_ELASTICSEARCH_INDEX = cfg.settings.elasticsearch.index;
        PALOMAR_INDEXING_BATCH_SIZE = toString cfg.settings.indexing.batchSize;
        PALOMAR_INDEXING_WORKERS = toString cfg.settings.indexing.workers;
        PALOMAR_INDEXING_FLUSH_INTERVAL = toString cfg.settings.indexing.flushInterval;
        PALOMAR_SEARCH_MAX_RESULTS = toString cfg.settings.search.maxResults;
        PALOMAR_SEARCH_TIMEOUT = toString cfg.settings.search.timeout;
      } // lib.optionalAttrs (cfg.settings.elasticsearch.username != null) {
        PALOMAR_ELASTICSEARCH_USERNAME = cfg.settings.elasticsearch.username;
      } // lib.optionalAttrs (cfg.settings.metrics.enable) {
        PALOMAR_METRICS_PORT = toString cfg.settings.metrics.port;
      };

      script = 
        let
          dbPasswordEnv = if cfg.settings.database.passwordFile != null
            then "PALOMAR_DATABASE_URL=$(sed \"s/:pass@/:$(cat ${cfg.settings.database.passwordFile})@/\" <<< \"${cfg.settings.database.url}\")"
            else "";
          
          esPasswordEnv = if cfg.settings.elasticsearch.passwordFile != null
            then "PALOMAR_ELASTICSEARCH_PASSWORD=$(cat ${cfg.settings.elasticsearch.passwordFile})"
            else "";
        in
        ''
          ${lib.optionalString (cfg.settings.database.passwordFile != null) dbPasswordEnv}
          ${lib.optionalString (cfg.settings.elasticsearch.passwordFile != null) esPasswordEnv}
          ${lib.optionalString (cfg.settings.database.passwordFile != null) "export PALOMAR_DATABASE_URL"}
          ${lib.optionalString (cfg.settings.elasticsearch.passwordFile != null) "export PALOMAR_ELASTICSEARCH_PASSWORD"}
          
          exec ${cfg.package}/bin/palomar
        '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.port ] 
      ++ lib.optional cfg.settings.metrics.enable cfg.settings.metrics.port;
  };
}