# Defines the NixOS module for the Who-Am-I service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-who-am-i;
in
{
  options.services.microcosm-who-am-i = {
    enable = mkEnableOption "Who-Am-I server";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.who-am-i;
      description = "The Who-Am-I package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/microcosm-who-am-i";
      description = "The absolute path to the directory to store data in.";
    };
  };

  config = mkIf cfg.enable {
    users.users.microcosm-who-am-i = {
      isSystemUser = true;
      group = "microcosm-who-am-i";
      home = cfg.dataDir;
    };
    users.groups.microcosm-who-am-i = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-who-am-i microcosm-who-am-i - -"
    ];

    systemd.services.microcosm-who-am-i = {
      description = "Who-Am-I Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-who-am-i";
        Group = "microcosm-who-am-i";

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
        exec ${cfg.package}/bin/who-am-i
      '';
    };
  };
}