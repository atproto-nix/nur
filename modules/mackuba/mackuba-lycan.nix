{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mackuba-lycan;
in
{
  options.services.mackuba-lycan = {
    enable = mkEnableOption "Lycan custom feed generator";

    package = mkOption {
      type = types.package;
      default = pkgs.mackuba-lycan or (pkgs.callPackage ../../pkgs/mackuba/lycan.nix { });
      description = "The lycan package to use.";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port for the Lycan service to listen on.";
    };

    hostname = mkOption {
      type = types.str;
      default = "lycan.feeds.blue";
      description = "Hostname for the Lycan server.";
      example = "feeds.example.com";
    };

    database = {
      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "PostgreSQL database URL. Leave null when using createLocally.";
        example = "postgresql://lycan:password@localhost/lycan";
      };

      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to create a local PostgreSQL database.";
      };

      name = mkOption {
        type = types.str;
        default = "lycan";
        description = "Name of the PostgreSQL database.";
      };
    };

    relay = {
      host = mkOption {
        type = types.str;
        default = "bsky.network";
        description = "ATProto relay host.";
      };

      jetstreamHost = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Jetstream host (alternative to relay).";
        example = "jetstream2.us-east.bsky.network";
      };
    };

    appview = {
      host = mkOption {
        type = types.str;
        default = "public.api.bsky.app";
        description = "AppView host for ATProto queries.";
      };
    };

    firehose = {
      userAgent = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "User agent string for firehose connections.";
        example = "Lycan (@my.handle)";
      };
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to environment file containing sensitive configuration.
        Should contain DATABASE_URL if not using createLocally.
      '';
      example = "/run/secrets/lycan.env";
    };

    user = mkOption {
      type = types.str;
      default = "lycan";
      description = "User account under which Lycan runs.";
    };

    group = mkOption {
      type = types.str;
      default = "lycan";
      description = "Group under which Lycan runs.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/lycan";
      description = "Directory where Lycan stores its data.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for Lycan.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.database.createLocally -> cfg.database.url == null;
        message = "Cannot specify database.url when database.createLocally is true.";
      }
      {
        assertion = !cfg.database.createLocally -> cfg.database.url != null;
        message = "Must specify database.url when database.createLocally is false.";
      }
    ];

    services.postgresql = mkIf cfg.database.createLocally {
      enable = true;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [{
        name = cfg.user;
        ensureDBOwnership = true;
      }];
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = { };

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/log' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.lycan = {
      description = "Lycan ATProto Feed Generator";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ optional cfg.database.createLocally "postgresql.service";
      wants = optional cfg.database.createLocally "postgresql.service";

      preStart = mkIf cfg.database.createLocally ''
        # Note: Database migrations should be run manually with:
        # systemctl start lycan-migrate.service
        # or: lycan-rake db:migrate
        echo "Lycan starting. Run migrations with: lycan-rake db:migrate"
      '';

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;

        ExecStart = "${cfg.package}/bin/lycan";

        # Environment variables
        Environment = [
          "SERVER_HOSTNAME=${cfg.hostname}"
          "RELAY_HOST=${cfg.relay.host}"
          "APPVIEW_HOST=${cfg.appview.host}"
          "PORT=${toString cfg.port}"
        ] ++ optional (cfg.database.createLocally)
          "DATABASE_URL=postgresql:///${cfg.database.name}?host=/run/postgresql"
        ++ optional (cfg.relay.jetstreamHost != null)
          "JETSTREAM_HOST=${cfg.relay.jetstreamHost}"
        ++ optional (cfg.firehose.userAgent != null)
          "FIREHOSE_USER_AGENT=${cfg.firehose.userAgent}";

        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        LockPersonality = true;

        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
