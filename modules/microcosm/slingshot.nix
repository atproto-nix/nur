# Defines the NixOS module for the Slingshot service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-slingshot;
  microcosmLib = import ../../lib/microcosm.nix { inherit lib; };
in
{
  options.services.microcosm-slingshot = microcosmLib.mkMicrocosmServiceOptions "Slingshot" {
    package = mkOption {
      type = types.package;
      default = pkgs.microcosm.slingshot;
      description = "The Slingshot package to use.";
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

    domain = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The domain pointing to this server.";
    };

    acmeContact = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The email address for letsencrypt contact.";
    };

    healthcheckUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The web address to send healthcheck pings to.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Configuration validation
    (microcosmLib.mkConfigValidation cfg "Slingshot" (
      microcosmLib.mkJetstreamValidation cfg.jetstream ++
      [
        {
          assertion = cfg.domain != null -> cfg.acmeContact != null;
          message = "ACME contact email is required when domain is specified for TLS certificate generation.";
        }
        {
          assertion = cfg.acmeContact != null -> (builtins.match ".*@.*" cfg.acmeContact != null);
          message = "ACME contact must be a valid email address.";
        }
        {
          assertion = cfg.healthcheckUrl != null -> (hasPrefix "http://" cfg.healthcheckUrl || hasPrefix "https://" cfg.healthcheckUrl);
          message = "Healthcheck URL must start with http:// or https://.";
        }
      ]
    ))

    # User and group management
    (microcosmLib.mkUserConfig cfg)

    # Directory management
    (microcosmLib.mkDirectoryConfig cfg [ "${cfg.dataDir}/cache" "${cfg.dataDir}/certs" ])

    # systemd service
    (microcosmLib.mkSystemdService cfg "Slingshot" {
      description = "ATProto service component with TLS support";
      extraReadWritePaths = [ "${cfg.dataDir}/cache" "${cfg.dataDir}/certs" ];
      serviceConfig = {
        ExecStart = ''
          ${cfg.package}/bin/slingshot \
            --jetstream ${escapeShellArg cfg.jetstream} \
            ${optionalString cfg.jetstreamNoZstd "--jetstream-no-zstd"} \
            --cache-dir ${cfg.dataDir}/cache \
            ${optionalString (cfg.domain != null) "--domain ${escapeShellArg cfg.domain}"} \
            ${optionalString (cfg.acmeContact != null) "--acme-contact ${escapeShellArg cfg.acmeContact}"} \
            --certs ${cfg.dataDir}/certs \
            ${optionalString (cfg.healthcheckUrl != null) "--healthcheck ${escapeShellArg cfg.healthcheckUrl}"}
        '';
      };
    })
  ]);
}
