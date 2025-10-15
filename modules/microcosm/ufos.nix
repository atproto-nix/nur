# Defines the NixOS module for the UFOs service
#
# UFOs (Unidentified Flying Objects) aggregates links in the AT Protocol.
# This module configures its connection to a Jetstream server, data storage,
# and various debugging and backfill options.
#
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

    jetstream = mkOption {
      type = types.str;
      description = "Jetstream server to connect to. This is a required option.";
      example = "wss://jetstream.example.com";
    };

    jetstreamForce = mkOption {
      type = types.bool;
      default = false;
      description = "If true, allow changing Jetstream endpoints.";
    };

    jetstreamNoZstd = mkOption {
      type = types.bool;
      default = false;
      description = "If true, don't request zstd-compressed Jetstream events, reducing CPU at the expense of more ingress bandwidth.";
    };

    data = mkOption {
      type = types.str;
      default = "${cfg.dataDir}/data";
      description = "Location to store persistent data to disk.";
    };

    pauseWriter = mkOption {
      type = types.bool;
      default = false;
      description = "DEBUG: If true, don't start the Jetstream consumer or its write loop.";
    };

    backfill = mkOption {
      type = types.bool;
      default = false;
      description = "If true, adjust runtime settings like background task intervals for efficient backfill.";
    };

    pauseRw = mkOption {
      type = types.bool;
      default = false;
      description = "DEBUG: If true, force the read/write loop to fall behind by pausing it.";
    };

    reroll = mkOption {
      type = types.bool;
      default = false;
      description = "If true, reset the rollup cursor and scrape through missed things in the past (backfill).";
    };

    jetstreamFixture = mkOption {
      type = types.bool;
      default = false;
      description = "DEBUG: If true, interpret the Jetstream argument as a file fixture.";
    };
  };

  config = mkIf cfg.enable {
    # Create a static user and group for the service for security isolation.
    users.users.microcosm-ufos = {
      isSystemUser = true;
      group = "microcosm-ufos";
      home = cfg.dataDir;
    };
    users.groups.microcosm-ufos = {};

    # Use tmpfiles to declaratively manage the data directory's existence and ownership.
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-ufos microcosm-ufos - -"
    ] ++ lib.optional (cfg.data != null) [
      "d ${cfg.data} 0755 microcosm-ufos microcosm-ufos - -"
    ];

    # Define the systemd service for UFOs.
    systemd.services.microcosm-ufos = {
      description = "UFOs Server - Aggregate links in the AT Protocol";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-ufos";
        Group = "microcosm-ufos";

        WorkingDirectory = cfg.dataDir;

        # Security hardening settings for the service.
        NoNewPrivileges = true;
        ProtectSystem = "full";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ] ++ lib.optional (cfg.data != null) cfg.data;
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
              "--jetstream"
              (escapeShellArg cfg.jetstream)
              "--data"
              (escapeShellArg cfg.data)
            ]
            (optional cfg.jetstreamForce [
              "--jetstream-force"
            ])
            (optional cfg.jetstreamNoZstd [
              "--jetstream-no-zstd"
            ])
            (optional cfg.pauseWriter [
              "--pause-writer"
            ])
            (optional cfg.backfill [
              "--backfill"
            ])
            (optional cfg.pauseRw [
              "--pause-rw"
            ])
            (optional cfg.reroll [
              "--reroll"
            ])
            (optional cfg.jetstreamFixture [
              "--jetstream-fixture"
            ])
          ];
        in
        ''
          exec ${cfg.package}/bin/ufos ${concatStringsSep " " args}
        '';
    };
  };
}