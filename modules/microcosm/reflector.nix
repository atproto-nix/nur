# Defines the NixOS module for the Reflector service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-reflector;
  microcosmLib = import ../../lib/microcosm.nix { inherit lib; };
in
{
  options.services.microcosm-reflector = microcosmLib.mkMicrocosmServiceOptions "Reflector" {
    package = mkOption {
      type = types.package;
      default = pkgs.microcosm.reflector;
      description = "The Reflector package to use.";
    };

    serviceId = mkOption {
      type = types.str;
      description = "The DID document service ID.";
      example = "atproto_pds";
    };

    serviceType = mkOption {
      type = types.str;
      description = "The service type.";
      example = "AtprotoPersonalDataServer";
    };

    serviceEndpoint = mkOption {
      type = types.str;
      description = "The HTTPS endpoint for the service.";
      example = "https://pds.example.com";
    };

    domain = mkOption {
      type = types.str;
      description = "The parent domain.";
      example = "example.com";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Configuration validation
    (microcosmLib.mkConfigValidation cfg "Reflector" [
      {
        assertion = cfg.serviceId != "";
        message = "Service ID cannot be empty.";
      }
      {
        assertion = cfg.serviceType != "";
        message = "Service type cannot be empty.";
      }
      {
        assertion = hasPrefix "https://" cfg.serviceEndpoint;
        message = "Service endpoint must use HTTPS.";
      }
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
    (microcosmLib.mkSystemdService cfg "Reflector" {
      description = "DID document reflection service";
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/reflector --id ${cfg.serviceId} --type ${cfg.serviceType} --service-endpoint ${cfg.serviceEndpoint} --domain ${cfg.domain}";
      };
    })
  ]);
}
