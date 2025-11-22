{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.blacksky.pds;

  # Import service configuration utilities
  serviceLib = import ../../../lib/service-common.nix { inherit lib pkgs; };
in
{
  options.services.blacksky.pds = {
    enable = mkEnableOption "rsky Personal Data Server (PDS)";

    package = mkOption {
      type = types.package;
      default = pkgs.blacksky-pds;
      defaultText = literalExpression "pkgs.blacksky-pds";
      description = "The rsky-pds package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "rsky-pds";
      description = "User account under which rsky-pds runs.";
    };

    group = mkOption {
      type = types.str;
      default = "rsky-pds";
      description = "Group under which rsky-pds runs.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/rsky-pds";
      description = "Directory where rsky-pds stores its data.";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port for the rsky PDS service.";
    };

    hostname = mkOption {
      type = types.str;
      description = "Hostname for the PDS service.";
      example = "pds.example.com";
    };

    database = {
      url = mkOption {
        type = types.str;
        description = "PostgreSQL database URL.";
        example = "postgresql://user:password@localhost/pds";
      };
    };

    blobstore = {
      type = mkOption {
        type = types.enum [ "s3" "local" ];
        default = "local";
        description = "Type of blob storage to use.";
      };

      s3 = {
        bucket = mkOption {
          type = types.str;
          default = "";
          description = "S3 bucket name for blob storage.";
        };

        region = mkOption {
          type = types.str;
          default = "us-east-1";
          description = "S3 region.";
        };
      };

      localPath = mkOption {
        type = types.path;
        default = "/var/lib/rsky-pds/blobs";
        description = "Local path for blob storage when using local storage.";
      };
    };

    email = {
      smtpUrl = mkOption {
        type = types.str;
        default = "";
        description = "SMTP URL for sending emails.";
        example = "smtps://user:pass@smtp.example.com:465";
      };

      fromAddress = mkOption {
        type = types.str;
        default = "";
        description = "From address for emails.";
        example = "noreply@example.com";
      };
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional configuration settings for rsky-pds.";
      example = literalExpression ''
        {
          log_level = "info";
          max_subscription_buffer = 200;
          repo_backfill_limit_ms = 60000;
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # User and group configuration
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      description = "rsky PDS service user";
    };

    users.groups.${cfg.group} = {};

    # Directory management
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/config' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/logs' 0750 ${cfg.user} ${cfg.group} - -"
    ] ++ optionals (cfg.blobstore.type == "local") [
      "d '${cfg.blobstore.localPath}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # Configuration file
    environment.etc."rsky-pds/config.toml" = {
      text = ''
        # rsky PDS Configuration
        hostname = "${cfg.hostname}"
        port = ${toString cfg.port}
        database_url = "${cfg.database.url}"
        data_dir = "${cfg.dataDir}"
        
        [blobstore]
        type = "${cfg.blobstore.type}"
        ${optionalString (cfg.blobstore.type == "s3") ''
        bucket = "${cfg.blobstore.s3.bucket}"
        region = "${cfg.blobstore.s3.region}"
        ''}
        ${optionalString (cfg.blobstore.type == "local") ''
        path = "${cfg.blobstore.localPath}"
        ''}
        
        ${optionalString (cfg.email.smtpUrl != "") ''
        [email]
        smtp_url = "${cfg.email.smtpUrl}"
        from_address = "${cfg.email.fromAddress}"
        ''}
        
        ${lib.generators.toINI {} cfg.settings}
      '';
      mode = "0640";
      user = cfg.user;
      group = cfg.group;
    };

    # systemd service
    systemd.services.rsky-pds = {
      description = "rsky Personal Data Server (PDS)";
      documentation = [ "https://github.com/blacksky-algorithms/rsky" ];
      after = [ "network.target" "postgresql.service" ];
      wants = [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/rsky-pds --config /etc/rsky-pds/config.toml";
        Restart = "on-failure";
        RestartSec = "5s";
        
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
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        
        # File system access
        ReadWritePaths = [ 
          cfg.dataDir 
        ] ++ optionals (cfg.blobstore.type == "local") [
          cfg.blobstore.localPath
        ];
        ReadOnlyPaths = [ "/nix/store" ];
        
        # Resource limits
        LimitNOFILE = 65536;
      };

      environment = {
        RUST_LOG = "info";
        RUST_BACKTRACE = "1";
      };
    };

    # Security assertions
    assertions = [
      {
        assertion = cfg.hostname != "";
        message = "rsky-pds requires a hostname to be configured.";
      }
      {
        assertion = cfg.database.url != "";
        message = "rsky-pds requires a database URL to be configured.";
      }
      {
        assertion = cfg.blobstore.type != "s3" || cfg.blobstore.s3.bucket != "";
        message = "rsky-pds S3 blobstore requires a bucket name.";
      }
    ];

    # Open firewall port if needed
    networking.firewall.allowedTCPPorts = mkIf cfg.enable [ cfg.port ];
  };
}