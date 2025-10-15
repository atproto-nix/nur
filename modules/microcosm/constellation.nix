# Defines the NixOS module for the Constellation service
#
# Constellation is a global backlink index for the AT Protocol.
# This module provides options to configure its behavior, including
# the Jetstream server to connect to, storage backend, data directory,
# and backup settings.
#
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
      description = "The storage backend to use. 'memory' for in-memory storage, 'rocks' for RocksDB persistent storage.";
    };

    jetstream = mkOption {
      type = types.str;
      description = "The Jetstream server to connect to. This is a required option.";
      example = "wss://jetstream1.us-east.bsky.network/subscribe";
    };

    fixture = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Saved jsonl from jetstream to use instead of a live subscription. Useful for testing.";
      example = "/path/to/fixture.jsonl";
    };

    backup = {
      enable = mkEnableOption "database backups";

      directory = mkOption {
        type = types.path;
        default = "${cfg.dataDir}/backups";
        description = "Directory to store database backups.";
      };

      interval = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Take backups every N hours. If null, no automatic backups are performed.";
        example = 24;
      };

      maxOldBackups = mkOption {
        type = types.nullOr types.int;
        default = 7;
        description = "Keep at most this many backups, purging oldest first. Only used when 'interval' is set.";
      };
    };
  };

  config = mkIf cfg.enable {
    # Create a static user and group for the service for security isolation.
    users.users.microcosm-constellation = {
      isSystemUser = true;
      group = "microcosm-constellation";
      home = cfg.dataDir;
    };
    users.groups.microcosm-constellation = {};

    # Use tmpfiles to declaratively manage the data directory's existence and ownership.
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-constellation microcosm-constellation - -"
    ] ++ optional cfg.backup.enable
      "d ${cfg.backup.directory} 0755 microcosm-constellation microcosm-constellation - -";

    # Define the systemd service for Constellation.
    systemd.services.microcosm-constellation = {
      description = "Constellation Server - Global backlink index for AT Protocol";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-constellation";
        Group = "microcosm-constellation";

        WorkingDirectory = cfg.dataDir;

        # Security hardening settings for the service.
        NoNewPrivileges = true;
        ProtectSystem = "full";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ] ++ optional cfg.backup.enable cfg.backup.directory;
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
            (optional (cfg.fixture != null) [
              "--fixture"
              (escapeShellArg cfg.fixture)
            ])
          ];
        in
        ''
          exec "${cfg.package}/bin/main" ${concatStringsSep " " args}
        '';
    };
  };
}
