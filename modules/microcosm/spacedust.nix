# Defines the NixOS module for the Spacedust service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-spacedust;
in
{
  options.services.microcosm-spacedust = {
    enable = mkEnableOption "Spacedust server";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.spacedust;
      description = "The Spacedust package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/microcosm-spacedust";
      description = "The absolute path to the directory to store data in.";
    };
  };

  config = mkIf cfg.enable {
    users.users.microcosm-spacedust = {
      isSystemUser = true;
      group = "microcosm-spacedust";
      home = cfg.dataDir;
    };
    users.groups.microcosm-spacedust = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-spacedust microcosm-spacedust - -"
    ];

    systemd.services.microcosm-spacedust = {
      description = "Spacedust Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-spacedust";
        Group = "microcosm-spacedust";

        WorkingDirectory = cfg.dataDir;

        NoNewPrivileges = true;
        ProtectSystem = "full";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ];
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
      };

      script = ''
        exec ${cfg.package}/bin/spacedust
      '';
    };
  };
}