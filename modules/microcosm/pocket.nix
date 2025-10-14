# Defines the NixOS module for the Pocket service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-pocket;
in
{
  options.services.microcosm-pocket = {
    enable = mkEnableOption "Pocket service";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.pocket;
      description = "The Pocket package to use.";
    };

    dbDir = mkOption {
      type = types.str;
      default = "microcosm-pocket";
      description = "The directory to store the database in, relative to /var/lib.";
    };

    domain = mkOption {
      type = types.str;
      description = "The domain for serving a did doc.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-pocket = {
      description = "Pocket Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/pocket --db /var/lib/${cfg.dbDir}/prefs.sqlite3 --domain ${cfg.domain}";
        Restart = "always";
        RestartSec = "10s";
        DynamicUser = true;
        StateDirectory = cfg.dbDir;
        ReadWritePaths = [ "/var/lib/${cfg.dbDir}" ];

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
