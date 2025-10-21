# Defines the NixOS module for the Constellation service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-constellation;
  microcosmLib = import ../../lib/microcosm.nix { inherit lib; };
in
{
  options.services.microcosm-constellation = microcosmLib.mkMicrocosmServiceOptions "Constellation" {
    package = mkOption {
      type = types.package;
      default = pkgs.microcosm.constellation;
      description = "The Constellation package to use.";
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

  config = mkIf cfg.enable (mkMerge [
    # Configuration validation
    (microcosmLib.mkConfigValidation cfg "Constellation" (
      microcosmLib.mkJetstreamValidation cfg.jetstream ++
      [
        {
          assertion = cfg.backup.enable -> cfg.backup.directory != "";
          message = "Backup directory cannot be empty when backups are enabled.";
        }
        {
          assertion = cfg.backup.enable && cfg.backup.interval != null -> cfg.backup.interval > 0;
          message = "Backup interval must be greater than 0 when specified.";
        }
        {
          assertion = cfg.backup.enable && cfg.backup.maxOldBackups != null -> cfg.backup.maxOldBackups > 0;
          message = "Maximum old backups must be greater than 0 when specified.";
        }
      ]
    ))

    # User and group management
    (microcosmLib.mkUserConfig cfg)

    # Directory management
    (microcosmLib.mkDirectoryConfig cfg (optional cfg.backup.enable cfg.backup.directory))

    # systemd service
    (microcosmLib.mkSystemdService cfg "Constellation" {
      description = "Global backlink index for AT Protocol";
      extraReadWritePaths = optional cfg.backup.enable cfg.backup.directory;
      serviceConfig = {
        ExecStart = 
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
          "${cfg.package}/bin/main ${concatStringsSep " " args}";
      };
    })
  ]);
}
