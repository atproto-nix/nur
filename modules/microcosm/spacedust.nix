# Defines the NixOS module for the Spacedust service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-spacedust;
  microcosmLib = import ../../lib/microcosm.nix { inherit lib; };
in
{
  options.services.microcosm-spacedust = microcosmLib.mkMicrocosmServiceOptions "Spacedust" {
    package = mkOption {
      type = types.package;
      default = pkgs.microcosm.spacedust;
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


    metrics = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Prometheus metrics endpoint";
        };
      };
      default = {};
      description = "Metrics configuration";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Configuration validation
    (microcosmLib.mkConfigValidation cfg "Spacedust" (
      microcosmLib.mkJetstreamValidation cfg.jetstream
    ))

    # User and group management
    (microcosmLib.mkUserConfig cfg)

    # Directory management
    (microcosmLib.mkDirectoryConfig cfg [])

    # systemd service
    (microcosmLib.mkSystemdService cfg "Spacedust" {
      description = "ATProto service component";
      serviceConfig = {
        ExecStart = let
          args = flatten [
            [
              "--jetstream"
              (escapeShellArg cfg.jetstream)
            ]
            (optional cfg.jetstreamNoZstd [ "--jetstream-no-zstd" ])

            (optional cfg.metrics.enable [
              "--bind-metrics"
            ])
          ];
        in
        "${cfg.package}/bin/spacedust ${concatStringsSep " " args}";
      };
    })
  ]);
}
