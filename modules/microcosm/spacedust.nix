# Defines the NixOS module for the Spacedust service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-spacedust;
in
{
  options.services.microcosm-spacedust = {
    enable = mkEnableOption "Spacedust service";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.spacedust;
      description = "The Spacedust package to use.";
    };

    jetstream = mkOption {
      type = types.str;
      description = "The Jetstream server to connect to.";
    };

    jetstreamNoZstd = mkOption {
      type = types.bool;
      default = false;
      description = "Don't request zstd-compressed jetstream events.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-spacedust = {
      description = "Spacedust Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/spacedust --jetstream ${escapeShellArg cfg.jetstream} ${optionalString cfg.jetstreamNoZstd "--jetstream-no-zstd"}";
        Restart = "always";
        RestartSec = "10s";
        DynamicUser = true;
        StateDirectory = "spacedust";

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
