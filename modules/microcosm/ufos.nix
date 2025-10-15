# Defines the NixOS module for the Ufos service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-ufos;
in
{
  options.services.microcosm-ufos = {
    enable = mkEnableOption "Ufos server";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.ufos;
      description = "The Ufos package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/microcosm-ufos";
      description = "The absolute path to the directory to store data in.";
    };
  };

  config = mkIf cfg.enable {
    users.users.microcosm-ufos = {
      isSystemUser = true;
      group = "microcosm-ufos";
      home = cfg.dataDir;
    };
    users.groups.microcosm-ufos = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-ufos microcosm-ufos - -"
    ];

    systemd.services.microcosm-ufos = {
      description = "Ufos Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-ufos";
        Group = "microcosm-ufos";

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
        exec ${cfg.package}/bin/ufos
      '';
    };
  };
}