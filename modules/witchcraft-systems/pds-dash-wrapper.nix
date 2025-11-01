# Wrapper module that automatically configures pds-dash for nixpkgs bluesky-pds
{ config, lib, pkgs, ... }:

with lib;

let
  pdsCfg = config.services.bluesky.pds or null;
  cfg = config.services.witchcraft-systems.pds-dash-auto;
in
{
  options.services.witchcraft-systems.pds-dash-auto = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Automatically configure pds-dash when services.bluesky.pds is enabled.
        This creates a monitoring dashboard for the nixpkgs bluesky-pds service.
      '';
    };

    dashHostname = mkOption {
      type = types.str;
      default = "dash.${pdsCfg.settings.PDS_HOSTNAME or "localhost"}";
      defaultText = literalExpression ''"dash.''${config.services.bluesky.pds.settings.PDS_HOSTNAME}"'';
      description = "Hostname to serve pds-dash on.";
      example = "dash.example.com";
    };

    enableSSL = mkOption {
      type = types.bool;
      default = config.services.bluesky.pds.settings.PDS_HOSTNAME or "" != "localhost";
      defaultText = literalExpression "true if PDS_HOSTNAME is not localhost";
      description = "Whether to enable SSL for pds-dash (usually matches PDS SSL setup).";
    };

    useACME = mkOption {
      type = types.bool;
      default = cfg.enableSSL;
      defaultText = literalExpression "same as enableSSL";
      description = "Whether to use ACME for SSL certificates.";
    };
  };

  config = mkIf (cfg.enable && pdsCfg != null && pdsCfg.enable or false) {
    # Enable pds-dash module
    services.witchcraft-systems.pds-dash = {
      enable = true;
      virtualHost = cfg.dashHostname;

      # Auto-detect PDS URL from bluesky.pds configuration
      pdsUrl =
        let
          port = pdsCfg.settings.PDS_PORT or 3000;
          hostname = pdsCfg.settings.PDS_HOSTNAME or "localhost";
        in
          # If PDS is on localhost, connect directly
          if hostname == "localhost" || hasPrefix "127." hostname
          then "http://127.0.0.1:${toString port}"
          # Otherwise use the configured hostname (for distributed setups)
          else "http://${hostname}:${toString port}";

      enableSSL = cfg.enableSSL;
      acmeHost = mkIf cfg.useACME (pdsCfg.settings.PDS_HOSTNAME or null);
    };

    # Helpful assertions
    assertions = [
      {
        assertion = pdsCfg.enable or false;
        message = "services.witchcraft-systems.pds-dash-auto requires services.bluesky.pds to be enabled";
      }
      {
        assertion = !cfg.enableSSL || cfg.useACME || config.services.witchcraft-systems.pds-dash.sslCertificate != null;
        message = "services.witchcraft-systems.pds-dash-auto: SSL enabled but no certificate source configured";
      }
    ];
  };
}
