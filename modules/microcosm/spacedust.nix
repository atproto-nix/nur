# Defines the NixOS module for the Spacedust service
#
# Spacedust aggregates links in the AT Protocol. This module configures
# its connection to a Jetstream server and optional zstd compression.
#
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-spacedust;
in
{
  options.services.microcosm-spacedust = {
    enable = mkEnableOption "Spacedust server";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.spacedust;
      description = "The Spacedust package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/microcosm-spacedust";
      description = "The absolute path to the directory to store data in.";
    };

    jetstream = mkOption {
      type = types.str;
      description = "Jetstream server to connect to. This is a required option.";
      example = "wss://jetstream.example.com";
    };

    jetstreamNoZstd = mkOption {
      type = types.bool;
      default = false;
      description = "If true, don't request zstd-compressed Jetstream events, reducing CPU at the expense of more ingress bandwidth.";
    };
  };

  config = mkIf cfg.enable {
    # Create a static user and group for the service for security isolation.
    users.users.microcosm-spacedust = {
      isSystemUser = true;
      group = "microcosm-spacedust";
      home = cfg.dataDir;
    };
    users.groups.microcosm-spacedust = {};

    # Use tmpfiles to declaratively manage the data directory's existence and ownership.
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-spacedust microcosm-spacedust - -"
    ];

    # Define the systemd service for Spacedust.
    systemd.services.microcosm-spacedust = {
      description = "Spacedust Server - Aggregate links in the AT Protocol";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-spacedust";
        Group = "microcosm-spacedust";

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
              "--jetstream"
              (escapeShellArg cfg.jetstream)
            ]
            (optional cfg.jetstreamNoZstd [
              "--jetstream-no-zstd"
            ])
          ];
        in
        ''
          exec ${cfg.package}/bin/spacedust ${concatStringsSep " " args}
        '';
    };
  };
}