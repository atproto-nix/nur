# Defines the NixOS module for the Spacedust service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-spacedust;
  microcosmLib = import ../../lib/microcosm.nix { inherit lib pkgs; };
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

    # Note: spacedust binary doesn't currently support --bind or --bind-metrics options
    # These options are retained for backwards compatibility but are not used
    bind = mkOption {
      type = types.str;
      default = "0.0.0.0:9998";
      description = "Spacedust server's listen address (currently unused - spacedust binary doesn't support this option)";
    };

    metrics = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Prometheus metrics endpoint";
          port = mkOption {
            type = types.port;
            default = 9091;
            description = "Metrics endpoint port (currently unused - spacedust binary doesn't support this option)";
          };
        };
      };
      default = {};
      description = "Metrics configuration (currently unused - spacedust binary doesn't support this option)";
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
          # Only pass arguments that spacedust binary actually supports
          args = flatten [
            [
              "--jetstream"
              (escapeShellArg cfg.jetstream)
            ]
            (optional cfg.jetstreamNoZstd [ "--jetstream-no-zstd" ])
            # Note: --bind and --bind-metrics are not supported by spacedust binary
            # See: spacedust --help for supported options
          ];
        in
        "${cfg.package}/bin/spacedust ${concatStringsSep " " args}";
      };
    })
  ]);
}
