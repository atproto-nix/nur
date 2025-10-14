# Defines the NixOS module for the Slingshot service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-slingshot;
in
{
  options.services.microcosm-slingshot = {
    enable = mkEnableOption "Slingshot service";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.slingshot;
      description = "The Slingshot package to use.";
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

    dataDir = mkOption {
      type = types.str;
      default = "microcosm-slingshot";
      description = "The directory to store data in, relative to /var/lib.";
    };

    domain = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The domain pointing to this server.";
    };

    acmeContact = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The email address for letsencrypt contact.";
    };

    healthcheckUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The web address to send healtcheck pings to.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-slingshot = {
      description = "Slingshot Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = ''
          ${cfg.package}/bin/slingshot \
            --jetstream ${escapeShellArg cfg.jetstream} \
            ${optionalString cfg.jetstreamNoZstd "--jetstream-no-zstd"} \
            --cache-dir /var/lib/${cfg.dataDir}/cache \
            ${optionalString (cfg.domain != null) "--domain ${escapeShellArg cfg.domain}"} \
            ${optionalString (cfg.acmeContact != null) "--acme-contact ${escapeShellArg cfg.acmeContact}"} \
            --certs /var/lib/${cfg.dataDir}/certs \
            ${optionalString (cfg.healthcheckUrl != null) "--healthcheck ${escapeShellArg cfg.healthcheckUrl}"}
        '';
        Restart = "always";
        RestartSec = "10s";
        DynamicUser = true;
        StateDirectory = cfg.dataDir;
        ReadWritePaths = [ "/var/lib/${cfg.dataDir}" ];

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
