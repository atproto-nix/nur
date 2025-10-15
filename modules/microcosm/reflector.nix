# Defines the NixOS module for the Reflector service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-reflector;
in
{
  options.services.microcosm-reflector = {
    enable = mkEnableOption "Reflector server";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.reflector;
      description = "The Reflector package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/microcosm-reflector";
      description = "The absolute path to the directory to store data in.";
    };
  };

  config = mkIf cfg.enable {
    users.users.microcosm-reflector = {
      isSystemUser = true;
      group = "microcosm-reflector";
      home = cfg.dataDir;
    };
    users.groups.microcosm-reflector = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-reflector microcosm-reflector - -"
    ];

    systemd.services.microcosm-reflector = {
      description = "Reflector Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-reflector";
        Group = "microcosm-reflector";

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
        exec ${cfg.package}/bin/reflector
      '';
    };
  };
}