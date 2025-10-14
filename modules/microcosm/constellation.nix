# Defines the NixOS module for the Constellation service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-constellation;
in
{
  options.services.microcosm-constellation = {
    enable = mkEnableOption "Constellation server";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.constellation;
      description = "The Constellation package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/microcosm-constellation";
      description = "The absolute path to the directory to store data in.";
    };

    backend = mkOption {
      type = types.enum [ "memory" "rocks" ];
      default = "rocks";
      description = "The storage backend to use.";
    };

    jetstream = mkOption {
      type = types.str;
      description = "The Jetstream server to connect to.";
      example = "wss://jetstream1.us-east.bsky.network/subscribe";
    };

    backup = {
      enable = mkEnableOption "database backups";

      directory = mkOption {
        type = types.path;
        default = "${cfg.dataDir}/backups";
        description = "Directory to store backups.";
      };

      interval = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Take backups every N hours. If null, no automatic backups.";
        example = 24;
      };

      maxOldBackups = mkOption {
        type = types.nullOr types.int;
        default = 7;
        description = "Keep at most this many backups, purging oldest first. Only used with interval.";
      };
    };
  };

  config = mkIf cfg.enable {
    # Create a static user and group for the service
    users.users.microcosm-constellation = {
      isSystemUser = true;
      group = "microcosm-constellation";
      home = cfg.dataDir;
    };
    users.groups.microcosm-constellation = {};

    # Use tmpfiles to declaratively manage the data directory's existence and ownership
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-constellation microcosm-constellation - -"
    ] ++ lib.optional (cfg.backup.enable) [
      "d ${cfg.backup.directory} 0755 microcosm-constellation microcosm-constellation - -"
    ];

    systemd.services.microcosm-constellation = {
      description = "Constellation Server - Global backlink index for AT Protocol";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        # Use the static user and group
        User = "microcosm-constellation";
        Group = "microcosm-constellation";

        WorkingDirectory = cfg.dataDir;

        # Security settings
        NoNewPrivileges = true;
        ProtectSystem = "full";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ] ++ optional (cfg.backup.enable) cfg.backup.directory;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
      };

      script =
        let
          args = flatten [
            [
              "--jetstream"
              (escapeShellArg cfg.jetstream)
              "--backend"
              (escapeShellArg cfg.backend)
            ]
            (optional (cfg.backend == "rocks") [
              "--data"
              (escapeShellArg "${cfg.dataDir}/db")
            ])
            (optional cfg.backup.enable [
              "--backup"
              (escapeShellArg cfg.backup.directory)
            ])
            (optional (cfg.backup.enable && cfg.backup.interval != null) [
              "--backup-interval"
              (escapeShellArg (toString cfg.backup.interval))
            ])
            (optional (cfg.backup.enable && cfg.backup.interval != null && cfg.backup.maxOldBackups != null) [
              "--max-old-backups"
              (escapeShellArg (toString cfg.backup.maxOldBackups))
            ])
          ];
        in
        ''
          exec ${cfg.package}/bin/main ${concatStringsSep " " args}
        '';
    };
  };
}
