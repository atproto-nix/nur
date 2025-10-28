{ config, lib, pkgs, ... }:

let
  cfg = config.services.tangled-dev.spindle;
in

with lib;

{
  options.services.tangled-dev.spindle = {
    enable = mkEnableOption "Tangled Spindle - Event processor with ATProto integration";

    package = mkOption {
      type = types.package;
      default = pkgs.tangled-dev-spindle or pkgs.spindle;
      defaultText = literalExpression "pkgs.spindle";
      description = "Package to use for Tangled Spindle";
    };

    user = mkOption {
      type = types.str;
      default = "tangled-spindle";
      description = "User account under which Tangled Spindle runs";
    };

    group = mkOption {
      type = types.str;
      default = "tangled-spindle";
      description = "Group under which Tangled Spindle runs";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/tangled-spindle";
      description = "Directory where Tangled Spindle stores its data";
    };

    server = {
      listenAddr = mkOption {
        type = types.str;
        default = "0.0.0.0:6555";
        description = "Address to listen on";
      };

      hostname = mkOption {
        type = types.str;
        example = "my.spindle.com";
        description = "Hostname for the server (required)";
      };

      owner = mkOption {
        type = types.str;
        example = "did:plc:qfpnj4og54vl56wngdriaxug";
        description = "DID of the server owner (required)";
      };

      dbPath = mkOption {
        type = types.path;
        default = "/var/lib/tangled-spindle/spindle.db";
        description = "Path to the database file";
      };

      jetstreamEndpoint = mkOption {
        type = types.str;
        default = "wss://jetstream1.us-west.bsky.network/subscribe";
        description = "Jetstream endpoint to subscribe to for ATProto events";
      };

      dev = mkOption {
        type = types.bool;
        default = false;
        description = "Enable development mode (disables signature verification)";
      };

      maxJobCount = mkOption {
        type = types.int;
        default = 2;
        description = "Maximum number of concurrent jobs to run";
      };

      queueSize = mkOption {
        type = types.int;
        default = 100;
        description = "Maximum number of jobs to queue up";
      };

      secrets = {
        provider = mkOption {
          type = types.enum [ "sqlite" "openbao" ];
          default = "sqlite";
          description = "Backend to use for secret management";
        };

        openbao = {
          proxyAddr = mkOption {
            type = types.str;
            default = "http://127.0.0.1:8200";
            description = "OpenBao proxy address";
          };

          mount = mkOption {
            type = types.str;
            default = "spindle";
            description = "OpenBao mount point";
          };
        };
      };
    };

    endpoints = mkOption {
      type = types.submodule {
        options = {
          appview = mkOption {
            type = types.str;
            default = "https://tangled.org";
            description = "AppView endpoint URL for web interface integration";
            example = "https://my-appview.example.com";
          };

          knot = mkOption {
            type = types.str;
            default = "https://git.tangled.sh";
            description = "Knot git server endpoint URL for repository access";
            example = "https://git.example.com";
          };

          jetstream = mkOption {
            type = types.str;
            default = "wss://jetstream.tangled.sh";
            description = "Jetstream WebSocket endpoint URL for event processing";
            example = "wss://jetstream.example.com";
          };

          nixery = mkOption {
            type = types.str;
            default = "https://nixery.tangled.sh";
            description = "Nixery container registry endpoint URL for CI/CD builds";
            example = "https://nixery.example.com";
          };

          atproto = mkOption {
            type = types.str;
            default = "https://bsky.social";
            description = "Primary ATProto network endpoint for social integration";
            example = "https://my-atproto.example.com";
          };

          plc = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "PLC directory endpoint for identity verification in CI/CD";
            example = "https://plc.example.com";
          };
        };
      };
      default = {};
      description = "Configurable service endpoints for enhanced Tangled and ATProto integration";
    };

    pipelines = {
      workflowTimeout = mkOption {
        type = types.str;
        default = "5m";
        description = "Timeout for each step of a pipeline";
      };
    };

    environmentFile = mkOption {
      type = with types; nullOr path;
      default = null;
      example = "/etc/tangled-spindle.env";
      description = ''
        Additional environment file as defined in {manpage}`systemd.exec(5)`.

        Sensitive secrets may be passed to the service without making
        them world readable in the nix store.
      '';
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Additional environment variables for Tangled Spindle";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for Tangled Spindle";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.server.hostname != "";
        message = "services.tangled-dev.spindle.server.hostname must be set";
      }
      {
        assertion = cfg.server.owner != "";
        message = "services.tangled-dev.spindle.server.owner must be set";
      }
    ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = {};

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/logs' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.tangled-spindle = {
      description = "Tangled Spindle - Event processor with ATProto integration";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/spindle";
        Restart = "always";
        RestartSec = "10s";
        
        # Logging
        LogsDirectory = "tangled-spindle";
        StateDirectory = "tangled-spindle";
        
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
        
        # File system access
        ReadWritePaths = [ cfg.dataDir "/var/log/tangled-spindle" ];
        ReadOnlyPaths = [ "/nix/store" ];
        
        # Environment file
        EnvironmentFile = optional (cfg.environmentFile != null) cfg.environmentFile;
      };

      environment = {
        SPINDLE_SERVER_LISTEN_ADDR = cfg.server.listenAddr;
        SPINDLE_SERVER_DB_PATH = cfg.server.dbPath;
        SPINDLE_SERVER_HOSTNAME = cfg.server.hostname;
        SPINDLE_SERVER_JETSTREAM = cfg.server.jetstreamEndpoint;
        SPINDLE_SERVER_DEV = boolToString cfg.server.dev;
        SPINDLE_SERVER_OWNER = cfg.server.owner;
        SPINDLE_SERVER_MAX_JOB_COUNT = toString cfg.server.maxJobCount;
        SPINDLE_SERVER_QUEUE_SIZE = toString cfg.server.queueSize;
        SPINDLE_SERVER_SECRETS_PROVIDER = cfg.server.secrets.provider;
        SPINDLE_SERVER_SECRETS_OPENBAO_PROXY_ADDR = cfg.server.secrets.openbao.proxyAddr;
        SPINDLE_SERVER_SECRETS_OPENBAO_MOUNT = cfg.server.secrets.openbao.mount;
        SPINDLE_NIXERY_PIPELINES_WORKFLOW_TIMEOUT = cfg.pipelines.workflowTimeout;
        # Configurable endpoints
        APPVIEW_ENDPOINT = cfg.endpoints.appview;
        KNOT_ENDPOINT = cfg.endpoints.knot;
        JETSTREAM_ENDPOINT = cfg.endpoints.jetstream;
        NIXERY_ENDPOINT = cfg.endpoints.nixery;
        ATPROTO_ENDPOINT = cfg.endpoints.atproto;
        PLC_ENDPOINT = cfg.endpoints.plc;
      } // cfg.extraEnvironment;
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ (toInt (last (splitString ":" cfg.server.listenAddr))) ];
    };
  };
}