# Defines the NixOS module for the Quasar service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-quasar;
  microcosmLib = import ../../lib/microcosm.nix { inherit lib pkgs; };
in
{
  options.services.microcosm-quasar = microcosmLib.mkMicrocosmServiceOptions "Quasar" {
    package = mkOption {
      type = types.package;
      default = pkgs.microcosm.quasar;
      description = "The Quasar package to use.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Configuration validation
    (microcosmLib.mkConfigValidation cfg "Quasar" [])

    # User and group management
    (microcosmLib.mkUserConfig cfg)

    # Directory management
    (microcosmLib.mkDirectoryConfig cfg [])

    # systemd service (placeholder implementation)
    {
      systemd.services.microcosm-quasar = {
        description = "Microcosm Quasar Service (Not Implemented)";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/false";
          RemainAfterExit = false;
        };
      };

      warnings = [
        "The Quasar service is not yet implemented - see https://github.com/at-microcosm/microcosm-rs/issues/1"
      ];
    }
  ]);
}