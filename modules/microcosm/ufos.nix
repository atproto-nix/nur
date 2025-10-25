# Defines the NixOS module for the UFOs service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-ufos;
  microcosmLib = import ../../lib/microcosm.nix { inherit lib; };
in
{
  options.services.microcosm-ufos = microcosmLib.mkMicrocosmServiceOptions "UFOs" {
    package = mkOption {
      type = types.package;
      default = pkgs.microcosm.ufos;
      description = "The UFOs package to use.";
    };

    jetstream = mkOption {
      type = types.str;
      description = "The Jetstream server to connect to.";
      example = "wss://jetstream1.us-east.bsky.network/subscribe";
    };

    jetstreamForce = mkOption {
      type = types.bool;
      default = false;
      description = "Allow changing jetstream endpoints.";
    };

    jetstreamNoZstd = mkOption {
      type = types.bool;
      default = false;
      description = "Don't request zstd-compressed jetstream events.";
    };

    backfill = mkOption {
      type = types.bool;
      default = false;
      description = "Adjust runtime settings for efficient backfill.";
    };

    reroll = mkOption {
      type = types.bool;
      default = false;
      description = "Reset the rollup cursor and backfill.";
    };

    bind = mkOption {
      type = types.str;
      default = "0.0.0.0:9999";
      description = "UFOs server's listen address";
    };

    metrics = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Prometheus metrics endpoint";
          port = mkOption {
            type = types.port;
            default = 9093;
            description = "Metrics endpoint port";
          };
        };
      };
      default = {};
      description = "Metrics configuration";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Configuration validation
    (microcosmLib.mkConfigValidation cfg "UFOs" (
      microcosmLib.mkJetstreamValidation cfg.jetstream
    ))

    # User and group management
    (microcosmLib.mkUserConfig cfg)

    # Directory management
    (microcosmLib.mkDirectoryConfig cfg [])

    # systemd service
    (microcosmLib.mkSystemdService cfg "UFOs" {
      description = "ATProto service component";
      serviceConfig = {
        ExecStart = let
  args = flatten [
    [
      "--jetstream"
      (escapeShellArg cfg.jetstream)
    ]
    (optional cfg.jetstreamForce [ "--jetstream-force" ])
    (optional cfg.jetstreamNoZstd [ "--jetstream-no-zstd" ])
    [
      "--data"
      (escapeShellArg cfg.dataDir)
    ]
    (optional cfg.backfill [ "--backfill" ])
    (optional cfg.reroll [ "--reroll" ])
    [
      "--bind"
      (escapeShellArg cfg.bind)
    ]
    (optional cfg.metrics.enable [
      "--bind-metrics"
      (escapeShellArg "0.0.0.0:${toString cfg.metrics.port}")
    ])
  ];
in
"${cfg.package}/bin/ufos ${concatStringsSep " " args}";
      };
    })

    # Warnings for potentially destructive operations
    {
      warnings = lib.optionals cfg.reroll [
        "UFOs reroll option is enabled - this will reset the rollup cursor and may cause data loss"
      ] ++ lib.optionals cfg.backfill [
        "UFOs backfill mode is enabled - this may impact performance during initial sync"
      ];
    }
  ]);
}
