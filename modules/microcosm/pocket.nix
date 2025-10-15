# Defines the NixOS module for the Pocket service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-pocket;
in
{
  options.services.microcosm-pocket = {
    enable = mkEnableOption "Pocket server";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.pocket;
      description = "The Pocket package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/microcosm-pocket";
      description = "The absolute path to the directory to store data in.";
    };
  };

  config = mkIf cfg.enable {
    users.users.microcosm-pocket = {
      isSystemUser = true;
      group = "microcosm-pocket";
      home = cfg.dataDir;
    };
    users.groups.microcosm-pocket = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-pocket microcosm-pocket - -"
    ];

    systemd.services.microcosm-pocket = {
      description = "Pocket Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-pocket";
        Group = "microcosm-pocket";

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
        exec ${cfg.package}/bin/pocket
      '';
    };
  };
}