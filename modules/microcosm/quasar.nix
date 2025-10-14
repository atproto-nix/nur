# Defines the NixOS module for the Quasar service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-quasar;
  microcosmPkgs = pkgs.nur.microcosm;
in
{
  options.services.microcosm-quasar = {
    enable = mkEnableOption "Quasar service";

    package = mkOption {
      type = types.package;
      default = microcosmPkgs.quasar;
      description = "The Quasar package to use.";
    };
  };

  config = mkIf cfg.enable {
    # The quasar service is not yet implemented.
    # This module is a placeholder.
    # See: https://github.com/at-microcosm/microcosm-rs/issues/1
    systemd.services.microcosm-quasar = {
      description = "Microcosm Quasar Service (Not Implemented)";
      serviceConfig.ExecStart = "${pkgs.coreutils}/bin/false";
    };
  };
}
