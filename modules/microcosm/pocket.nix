# Defines the NixOS module for the Pocket service
#
# Pocket acts as a Slingshot record edge cache, storing data in an SQLite database.
# This module allows configuring the database path, enabling database initialization,
# and setting a domain for serving DID documents.
#
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

    db = mkOption {
      type = types.str;
      default = "${cfg.dataDir}/pocket.sqlite";
      description = "Path to the SQLite database file.";
    };

    initDb = mkOption {
      type = types.bool;
      default = false;
      description = "If true, the database will be initialized and the service will exit. Useful for setup.";
    };

    domain = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The domain for serving a DID document. This is typically unused if running behind a reflector.";
    };
  };

  config = mkIf cfg.enable {
    # Create a static user and group for the service for security isolation.
    users.users.microcosm-pocket = {
      isSystemUser = true;
      group = "microcosm-pocket";
      home = cfg.dataDir;
    };
    users.groups.microcosm-pocket = {};

    # Use tmpfiles to declaratively manage the data directory's existence and ownership.
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-pocket microcosm-pocket - -"
    ];

    # Define the systemd service for Pocket.
    systemd.services.microcosm-pocket = {
      description = "Pocket Server - Slingshot record edge cache";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-pocket";
        Group = "microcosm-pocket";

        WorkingDirectory = cfg.dataDir;

        # Security hardening settings for the service.
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

      script =
        let
          args = flatten [
            [
              "--db"
              (escapeShellArg cfg.db)
            ]
            (optional cfg.initDb [
              "--init-db"
            ])
            (optional (cfg.domain != null) [
              "--domain"
              (escapeShellArg cfg.domain)
            ])
          ];
        in
        ''
          exec ${cfg.package}/bin/pocket ${concatStringsSep " " args}
        '';
    };
  };
}