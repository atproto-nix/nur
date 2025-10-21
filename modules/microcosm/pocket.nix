# Defines the NixOS module for the Pocket service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-pocket;
  microcosmLib = import ../../lib/microcosm.nix { inherit lib; };
in
{
  options.services.microcosm-pocket = microcosmLib.mkMicrocosmServiceOptions "Pocket" {
    package = mkOption {
      type = types.package;
      default = pkgs.microcosm.pocket;
      description = "The Pocket package to use.";
    };

    domain = mkOption {
      type = types.str;
      description = "The domain for serving a DID document.";
      example = "pocket.example.com";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Configuration validation
    (microcosmLib.mkConfigValidation cfg "Pocket" [
      {
        assertion = cfg.domain != "";
        message = "Domain cannot be empty.";
      }
      {
        assertion = builtins.match "^[a-zA-Z0-9.-]+$" cfg.domain != null;
        message = "Domain must be a valid hostname.";
      }
    ])

    # User and group management
    (microcosmLib.mkUserConfig cfg)

    # Directory management
    (microcosmLib.mkDirectoryConfig cfg [])

    # systemd service
    (microcosmLib.mkSystemdService cfg "Pocket" {
      description = "DID document service";
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/pocket --db ${cfg.dataDir}/prefs.sqlite3 --domain ${cfg.domain}";
      };
    })
  ]);
}
