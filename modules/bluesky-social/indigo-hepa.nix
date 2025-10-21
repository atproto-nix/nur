# Defines the NixOS module for the Indigo Hepa (auto-moderation) service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.indigo-hepa;
in
{
  options.services.indigo-hepa = {
    enable = mkEnableOption "Indigo Hepa auto-moderation service";

    package = mkOption {
      type = types.package;
      default = pkgs.bluesky-social-indigo-hepa or pkgs.indigo-hepa;
      description = "The Indigo Hepa package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/indigo-hepa";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "indigo-hepa";
      description = "User account for Indigo Hepa service.";
    };

    group = mkOption {
      type = types.str;
      default = "indigo-hepa";
      description = "Group for Indigo Hepa service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 2476;
            description = "Port for the hepa service to listen on.";
          };

          hostname = mkOption {
            type = types.str;
            description = "Hostname for the hepa service.";
            example = "hepa.example.com";
          };

          firehoseHost = mkOption {
            type = types.str;
            description = "Firehose host to connect to for content monitoring.";
            example = "bsky.network";
          };

          ozoneHost = mkOption {
            type = types.str;
            description = "Ozone moderation service host.";
            example = "https://ozone.example.com";
          };

          database = {
            url = mkOption {
              type = types.str;
              description = "Database connection URL.";
              example = "postgres://user:pass@localhost/hepa";
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
              description = "DID for authentication with Ozone.";
              example = "did:plc:example123";
            };

            privateKeyFile = mkOption {
              type = types.path;
              description = "File containing private key for authentication.";
            };
          };

          moderation = {
            rules = mkOption {
              type = types.listOf (types.submodule {
                options = {
                  name = mkOption {
                    type = types.str;
                    description = "Rule name.";
                  };

                  pattern = mkOption {
                    type = types.str;
                    description = "Content pattern to match (regex).";
                  };

                  action = mkOption {
                    type = types.enum [ "flag" "warn" "hide" "takedown" ];
                    description = "Action to take when pattern matches.";
                  };

                  severity = mkOption {
                    type = types.enum [ "low" "medium" "high" "critical" ];
                    default = "medium";
                    description = "Severity level of the rule.";
                  };
                };
              });
              default = [];
              description = "Moderation rules configuration.";
            };

            batchSize = mkOption {
              type = types.int;
              default = 50;
              description = "Batch size for processing content.";
            };

            workers = mkOption {
              type = types.int;
              default = 2;
              description = "Number of moderation worker threads.";
            };

            cooldown = mkOption {
              type = types.int;
              default = 60;
              description = "Cooldown period in seconds between actions on same content.";
            };
          };

          plcHost = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "PLC directory host URL.";
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
              default = 2477;
              description = "Port for metrics endpoint.";
            };
          };
        };
      };
      default = {};
      description = "Indigo Hepa service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.hostname != "";
        message = "services.indigo-hepa: hostname must be specified";
      }
      {
        assertion = cfg.settings.firehoseHost != "";
        message = "services.indigo-hepa: firehoseHost must be specified";
      }
      {
        assertion = cfg.settings.ozoneHost != "";
        message = "services.indigo-hepa: ozoneHost must be specified";
      }
      {
        assertion = cfg.settings.database.url != "";
        message = "services.indigo-hepa: database URL must be specified";
      }
      {
        assertion = cfg.settings.auth.did != "";
        message = "services.indigo-hepa: auth DID must be specified";
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
      "d '${cfg.dataDir}/config' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # Generate moderation rules config file
    environment.etc."hepa/moderation-rules.json" = lib.mkIf (cfg.settings.moderation.rules != []) {
      text = builtins.toJSON {
        rules = cfg.settings.moderation.rules;
      };
      mode = "0640";
      user = cfg.user;
      group = cfg.group;
    };

    # systemd service
    systemd.services.indigo-hepa = {
      description = "Indigo Hepa auto-moderation service";
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
        ReadOnlyPaths = [ "/nix/store" "/etc/hepa" ];
      };

      environment = {
        GOLOG_LOG_LEVEL = cfg.settings.logLevel;
        HEPA_HOSTNAME = cfg.settings.hostname;
        HEPA_PORT = toString cfg.settings.port;
        HEPA_FIREHOSE_HOST = cfg.settings.firehoseHost;
        HEPA_OZONE_HOST = cfg.settings.ozoneHost;
        HEPA_PLC_HOST = cfg.settings.plcHost;
        HEPA_DATABASE_URL = cfg.settings.database.url;
        HEPA_AUTH_DID = cfg.settings.auth.did;
        HEPA_MODERATION_BATCH_SIZE = toString cfg.settings.moderation.batchSize;
        HEPA_MODERATION_WORKERS = toString cfg.settings.moderation.workers;
        HEPA_MODERATION_COOLDOWN = toString cfg.settings.moderation.cooldown;
      } // lib.optionalAttrs (cfg.settings.moderation.rules != []) {
        HEPA_MODERATION_RULES_FILE = "/etc/hepa/moderation-rules.json";
      } // lib.optionalAttrs (cfg.settings.metrics.enable) {
        HEPA_METRICS_PORT = toString cfg.settings.metrics.port;
      };

      script = 
        let
          dbPasswordEnv = if cfg.settings.database.passwordFile != null
            then "HEPA_DATABASE_URL=$(sed \"s/:pass@/:$(cat ${cfg.settings.database.passwordFile})@/\" <<< \"${cfg.settings.database.url}\")"
            else "";
          
          privateKeyEnv = "HEPA_AUTH_PRIVATE_KEY=$(cat ${cfg.settings.auth.privateKeyFile})";
        in
        ''
          ${lib.optionalString (cfg.settings.database.passwordFile != null) dbPasswordEnv}
          ${privateKeyEnv}
          ${lib.optionalString (cfg.settings.database.passwordFile != null) "export HEPA_DATABASE_URL"}
          export HEPA_AUTH_PRIVATE_KEY
          
          exec ${cfg.package}/bin/hepa
        '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.port ] 
      ++ lib.optional cfg.settings.metrics.enable cfg.settings.metrics.port;
  };
}