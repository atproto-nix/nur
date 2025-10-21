{ config, lib, pkgs, ... }:

let
  cfg = config.services.tangled-dev.appview;
in

with lib;

{
  options.services.tangled-dev.appview = {
    enable = mkEnableOption "Tangled AppView - Web interface for ATProto git forge";

    package = mkOption {
      type = types.package;
      default = pkgs.tangled-dev-appview or pkgs.appview;
      defaultText = literalExpression "pkgs.appview";
      description = "Package to use for Tangled AppView";
    };

    user = mkOption {
      type = types.str;
      default = "tangled-appview";
      description = "User account under which Tangled AppView runs";
    };

    group = mkOption {
      type = types.str;
      default = "tangled-appview";
      description = "Group under which Tangled AppView runs";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/tangled-appview";
      description = "Directory where Tangled AppView stores its data";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port on which Tangled AppView listens";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host address on which Tangled AppView listens";
    };

    cookieSecret = mkOption {
      type = types.str;
      default = "00000000000000000000000000000000";
      description = "Cookie secret for session management";
    };

    environmentFile = mkOption {
      type = with types; nullOr path;
      default = null;
      example = "/etc/tangled-appview.env";
      description = ''
        Additional environment file as defined in {manpage}`systemd.exec(5)`.

        Sensitive secrets such as `TANGLED_COOKIE_SECRET` may be
        passed to the service without making them world readable in the
        nix store.
      '';
    };

    endpoints = mkOption {
      type = types.submodule {
        options = {
          knot = mkOption {
            type = types.str;
            default = "https://git.tangled.sh";
            description = "Knot git server endpoint URL for repository operations";
            example = "https://git.example.com";
          };

          jetstream = mkOption {
            type = types.str;
            default = "wss://jetstream.tangled.sh";
            description = "Jetstream WebSocket endpoint URL for real-time updates";
            example = "wss://jetstream.example.com";
          };

          nixery = mkOption {
            type = types.str;
            default = "https://nixery.tangled.sh";
            description = "Nixery container registry endpoint URL for build integration";
            example = "https://nixery.example.com";
          };

          atproto = mkOption {
            type = types.str;
            default = "https://bsky.social";
            description = "Primary ATProto network endpoint for social features";
            example = "https://my-atproto.example.com";
          };

          plc = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "PLC directory endpoint for user identity resolution";
            example = "https://plc.example.com";
          };
        };
      };
      default = {};
      description = "Configurable service endpoints for enhanced Tangled and ATProto integration";
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Additional environment variables for Tangled AppView";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for Tangled AppView";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = {};

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.tangled-appview = {
      description = "Tangled AppView - Web interface for ATProto git forge";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/appview";
        Restart = "always";
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
        
        # Environment file
        EnvironmentFile = optional (cfg.environmentFile != null) cfg.environmentFile;
      };

      environment = {
        TANGLED_DB_PATH = "${cfg.dataDir}/appview.db";
        TANGLED_COOKIE_SECRET = cfg.cookieSecret;
        TANGLED_HOST = cfg.host;
        TANGLED_PORT = toString cfg.port;
        KNOT_ENDPOINT = cfg.endpoints.knot;
        JETSTREAM_ENDPOINT = cfg.endpoints.jetstream;
        NIXERY_ENDPOINT = cfg.endpoints.nixery;
        ATPROTO_ENDPOINT = cfg.endpoints.atproto;
        PLC_ENDPOINT = cfg.endpoints.plc;
      } // cfg.extraEnvironment;
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}