# Grain Labeler Service Module
#
# STATUS: Experimental - Awaiting package implementation
#
# This module defines configuration for the Grain Labeler service (content moderation),
# but the actual package is not yet implemented.
#
# TO IMPLEMENT:
# - Create /Users/jack/Software/nur-vps/pkgs/grain-social/labeler.nix
# - Build with Rust (craneLib, similar to darkroom.nix)
# - Source: @grain.social/grain monorepo from Tangled.org
# - Requires: Cryptographic libs for key operations, PostgreSQL client
#
# FEATURES (configured but not yet functional):
# - Flexible content labeling rules with JSON configuration
# - Private key signing for label authentication
# - Prometheus metrics endpoint
# - API rate limiting and CORS support
# - Batch processing configuration
#
# CONFIGURATION:
# services.grain-labeler = {
#   enable = true;  # Will fail until package is implemented
#   settings = {
#     hostname = "labeler.grain.example.com";
#     firehoseHost = "bsky.network";
#     database.url = "postgres://...";
#     auth.did = "did:plc:labeler123";
#     auth.privateKeyFile = "/run/secrets/labeler-key";
#   };
# };
#
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.grain-labeler;
in
{
  options.services.grain-labeler = {
    enable = mkEnableOption "Grain Labeler content moderation service";

    package = mkOption {
      type = types.package;
      default = pkgs.grain-social-labeler or (throw "grain-social-labeler package not found in pkgs");
      description = "The Grain Labeler package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/grain-labeler";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "grain-labeler";
      description = "User account for Grain Labeler service.";
    };

    group = mkOption {
      type = types.str;
      default = "grain-labeler";
      description = "Group for Grain Labeler service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 3003;
            description = "Port for the labeler service to listen on.";
          };

          hostname = mkOption {
            type = types.str;
            description = "Hostname for the labeler service.";
            example = "labeler.grain.example.com";
          };

          firehoseHost = mkOption {
            type = types.str;
            description = "Firehose host to connect to for content monitoring.";
            example = "bsky.network";
          };

          database = {
            url = mkOption {
              type = types.str;
              description = "Database connection URL.";
              example = "postgres://user:pass@localhost/grain_labeler";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing database password.";
            };
          };

          auth = {
            did = mkOption {
              type = types.str;
              description = "DID for the labeler service.";
              example = "did:plc:labeler123";
            };

            privateKeyFile = mkOption {
              type = types.path;
              description = "File containing private key for signing labels.";
            };
          };

          labeling = {
            rules = mkOption {
              type = types.listOf (types.submodule {
                options = {
                  name = mkOption {
                    type = types.str;
                    description = "Rule name.";
                  };

                  description = mkOption {
                    type = types.str;
                    description = "Rule description.";
                  };

                  pattern = mkOption {
                    type = types.str;
                    description = "Content pattern to match (regex).";
                  };

                  label = mkOption {
                    type = types.str;
                    description = "Label to apply when pattern matches.";
                  };

                  severity = mkOption {
                    type = types.enum [ "inform" "alert" "warn" "hide" ];
                    default = "inform";
                    description = "Severity level of the label.";
                  };

                  contentTypes = mkOption {
                    type = types.listOf (types.enum [ "post" "profile" "image" "gallery" ]);
                    default = [ "post" "image" "gallery" ];
                    description = "Content types this rule applies to.";
                  };
                };
              });
              default = [];
              description = "Labeling rules configuration.";
            };

            batchSize = mkOption {
              type = types.int;
              default = 50;
              description = "Batch size for processing content.";
            };

            workers = mkOption {
              type = types.int;
              default = 2;
              description = "Number of labeling worker threads.";
            };

            cooldown = mkOption {
              type = types.int;
              default = 300;
              description = "Cooldown period in seconds between labeling same content.";
            };

            autoApprove = mkOption {
              type = types.bool;
              default = false;
              description = "Automatically approve labels without manual review.";
            };
          };

          plcHost = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "PLC directory host URL.";
          };

          logLevel = mkOption {
            type = types.enum [ "DEBUG" "INFO" "WARN" "ERROR" ];
            default = "INFO";
            description = "Logging level.";
          };

          metrics = {
            enable = mkEnableOption "Prometheus metrics endpoint";
            
            port = mkOption {
              type = types.port;
              default = 3013;
              description = "Port for metrics endpoint.";
            };
          };

          api = {
            rateLimit = {
              enable = mkEnableOption "API rate limiting";

              requestsPerMinute = mkOption {
                type = types.int;
                default = 100;
                description = "Maximum requests per minute per IP.";
              };
            };

            cors = {
              enable = mkEnableOption "CORS support";

              origins = mkOption {
                type = types.listOf types.str;
                default = [ "*" ];
                description = "Allowed CORS origins.";
              };
            };
          };
        };
      };
      default = {};
      description = "Grain Labeler service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.hostname != "";
        message = "services.grain-labeler: hostname must be specified";
      }
      {
        assertion = cfg.settings.firehoseHost != "";
        message = "services.grain-labeler: firehoseHost must be specified";
      }
      {
        assertion = cfg.settings.database.url != "";
        message = "services.grain-labeler: database URL must be specified";
      }
      {
        assertion = cfg.settings.auth.did != "";
        message = "services.grain-labeler: auth DID must be specified";
      }
    ];

    warnings = lib.optionals (cfg.settings.labeling.autoApprove) [
      "Grain Labeler auto-approve is enabled - labels will be applied without manual review"
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
      "d '${cfg.dataDir}/config' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # Generate labeling rules config file
    environment.etc."grain-labeler/labeling-rules.json" = lib.mkIf (cfg.settings.labeling.rules != []) {
      text = builtins.toJSON {
        rules = cfg.settings.labeling.rules;
      };
      mode = "0640";
      user = cfg.user;
      group = cfg.group;
    };

    # systemd service
    systemd.services.grain-labeler = {
      description = "Grain Labeler content moderation service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" ];
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
        ReadOnlyPaths = [ "/nix/store" "/etc/grain-labeler" ];
      };

      environment = {
        LOG_LEVEL = cfg.settings.logLevel;
        LABELER_HOSTNAME = cfg.settings.hostname;
        LABELER_PORT = toString cfg.settings.port;
        LABELER_FIREHOSE_HOST = cfg.settings.firehoseHost;
        LABELER_PLC_HOST = cfg.settings.plcHost;
        LABELER_DATABASE_URL = cfg.settings.database.url;
        LABELER_AUTH_DID = cfg.settings.auth.did;
        LABELER_BATCH_SIZE = toString cfg.settings.labeling.batchSize;
        LABELER_WORKERS = toString cfg.settings.labeling.workers;
        LABELER_COOLDOWN = toString cfg.settings.labeling.cooldown;
        LABELER_AUTO_APPROVE = if cfg.settings.labeling.autoApprove then "true" else "false";
      } // lib.optionalAttrs (cfg.settings.labeling.rules != []) {
        LABELER_RULES_FILE = "/etc/grain-labeler/labeling-rules.json";
      } // lib.optionalAttrs (cfg.settings.api.rateLimit.enable) {
        LABELER_RATE_LIMIT_ENABLED = "true";
        LABELER_RATE_LIMIT_RPM = toString cfg.settings.api.rateLimit.requestsPerMinute;
      } // lib.optionalAttrs (cfg.settings.api.cors.enable) {
        LABELER_CORS_ENABLED = "true";
        LABELER_CORS_ORIGINS = concatStringsSep "," cfg.settings.api.cors.origins;
      } // lib.optionalAttrs (cfg.settings.metrics.enable) {
        LABELER_METRICS_PORT = toString cfg.settings.metrics.port;
      };

      script = 
        let
          dbPasswordEnv = if cfg.settings.database.passwordFile != null
            then "LABELER_DATABASE_URL=$(sed \"s/:pass@/:$(cat ${cfg.settings.database.passwordFile})@/\" <<< \"${cfg.settings.database.url}\")"
            else "";
          
          privateKeyEnv = "LABELER_AUTH_PRIVATE_KEY=$(cat ${cfg.settings.auth.privateKeyFile})";
        in
        ''
          ${lib.optionalString (cfg.settings.database.passwordFile != null) dbPasswordEnv}
          ${privateKeyEnv}
          ${lib.optionalString (cfg.settings.database.passwordFile != null) "export LABELER_DATABASE_URL"}
          export LABELER_AUTH_PRIVATE_KEY
          
          exec ${cfg.package}/bin/grain-labeler
        '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.port ] 
      ++ lib.optional cfg.settings.metrics.enable cfg.settings.metrics.port;
  };
}