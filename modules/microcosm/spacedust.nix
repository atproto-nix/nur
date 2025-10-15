# Defines the NixOS module for the Spacedust service
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.microcosm-spacedust;
in
{
  options.services.microcosm-spacedust = {
    enable = mkEnableOption "Spacedust service";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.microcosm.spacedust;
      description = "The Spacedust package to use.";
    };

    jetstream = mkOption {
      type = types.str;
      description = "The Jetstream server to connect to.";
      example = "wss://jetstream1.us-east.bsky.network/subscribe";
    };

    jetstreamNoZstd = mkOption {
      type = types.bool;
      default = false;
      description = "Don't request zstd-compressed jetstream events.";
    };
  };

  config = mkIf cfg.enable {
    # Create a static user and group for the service
    users.users.microcosm-spacedust = {
      isSystemUser = true;
      group = "microcosm-spacedust";
      home = "/var/lib/microcosm-spacedust"; # Placeholder home directory
    };
    users.groups.microcosm-spacedust = {};

    systemd.services.microcosm-spacedust = {
      description = "Spacedust Service - Realtime link event processing for AT Protocol";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        # Use the static user and group
        User = "microcosm-spacedust";
        Group = "microcosm-spacedust";

        # Spacedust doesn't seem to use a data directory in the same way constellation does
        # WorkingDirectory = "/var/lib/microcosm-spacedust";

        # Security settings
        NoNewPrivileges = true;
        ProtectSystem = "full";
        ProtectHome = true;
        # ReadWritePaths = [ ]; # No specific data directory to write to
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
          exec ${cfg.package}/bin/main ${concatStringsSep " " args}
        '';
    };
  };
}