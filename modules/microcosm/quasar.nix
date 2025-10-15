# Defines the NixOS module for the Quasar service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-quasar;
in
{
  options.services.microcosm-quasar = {
    enable = mkEnableOption "Quasar server";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.quasar;
      description = "The Quasar package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/microcosm-quasar";
      description = "The absolute path to the directory to store data in.";
    };
  };

  config = mkIf cfg.enable {
    users.users.microcosm-quasar = {
      isSystemUser = true;
      group = "microcosm-quasar";
      home = cfg.dataDir;
    };
    users.groups.microcosm-quasar = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-quasar microcosm-quasar - -"
    ];

    systemd.services.microcosm-quasar = {
      description = "Quasar Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-quasar";
        Group = "microcosm-quasar";

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
        exec ${cfg.package}/bin/quasar
      '';
    };
  };
}