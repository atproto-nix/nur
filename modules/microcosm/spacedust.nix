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
        ExecStart = "${cfg.package}/bin/spacedust --jetstream ${escapeShellArg cfg.jetstream} ${optionalString cfg.jetstreamNoZstd "--jetstream-no-zstd"}";
      };
    })
  ]);
}
