# Defines the NixOS module for the UFOs service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-ufos;
in
{
  options.services.microcosm-ufos = {
    enable = mkEnableOption "UFOs service";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.ufos;
      description = "The UFOs package to use.";
    };

    jetstream = mkOption {
      type = types.str;
      description = "The Jetstream server to connect to.";
    };

    jetstreamForce = mkOption {
      type = types.bool;
      default = false;
      description = "Allow changing jetstream endpoints.";
    };

    jetstreamNoZstd = mkOption {
      type = types.bool;
      default = false;
      description = "Don't request zstd-compressed jetstream events.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "microcosm-ufos";
      description = "The directory to store data in, relative to /var/lib.";
    };

    backfill = mkOption {
      type = types.bool;
      default = false;
      description = "Adjust runtime settings for efficient backfill.";
    };

    reroll = mkOption {
      type = types.bool;
      default = false;
      description = "Reset the rollup cursor and backfill.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-ufos = {
      description = "UFOs Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/ufos --jetstream ${escapeShellArg cfg.jetstream} ${optionalString cfg.jetstreamForce "--jetstream-force"} ${optionalString cfg.jetstreamNoZstd "--jetstream-no-zstd"} --data /var/lib/${cfg.dataDir} ${optionalString cfg.backfill "--backfill"} ${optionalString cfg.reroll "--reroll"}";
        Restart = "always";
        RestartSec = "10s";
        DynamicUser = true;
        StateDirectory = cfg.dataDir;
        ReadWritePaths = [ "/var/lib/${cfg.dataDir}" ];

        # Security settings
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
      };
    };
  };
}
