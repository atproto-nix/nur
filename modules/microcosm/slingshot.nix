# Defines the NixOS module for the Slingshot service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-slingshot;
in
{
  options.services.microcosm-slingshot = {
    enable = mkEnableOption "Slingshot server";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.slingshot;
      description = "The Slingshot package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/microcosm-slingshot";
      description = "The absolute path to the directory to store data in.";
    };
  };

  config = mkIf cfg.enable {
    users.users.microcosm-slingshot = {
      isSystemUser = true;
      group = "microcosm-slingshot";
      home = cfg.dataDir;
    };
    users.groups.microcosm-slingshot = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-slingshot microcosm-slingshot - -"
    ];

    systemd.services.microcosm-slingshot = {
      description = "Slingshot Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-slingshot";
        Group = "microcosm-slingshot";

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
        exec ${cfg.package}/bin/slingshot
      '';
    };
  };
}