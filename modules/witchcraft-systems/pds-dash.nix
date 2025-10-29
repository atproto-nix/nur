{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.witchcraft-systems.pds-dash;
in
{
  options.services.witchcraft-systems.pds-dash = {
    enable = mkEnableOption "pds-dash - ATProto PDS monitoring dashboard";

    package = mkOption {
      type = types.package;
      default = pkgs.witchcraft-systems-pds-dash or (throw "witchcraft-systems-pds-dash package not found");
      defaultText = literalExpression "pkgs.witchcraft-systems-pds-dash";
      description = "The pds-dash package to use.";
    };

    virtualHost = mkOption {
      type = types.str;
      default = "dash.localhost";
      description = "The nginx virtual host to serve pds-dash on.";
      example = "dash.example.com";
    };

    pdsUrl = mkOption {
      type = types.str;
      default = "http://127.0.0.1:3000";
      description = "The URL of the PDS instance to monitor.";
      example = "http://pds.example.com:3000";
    };

    enableSSL = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable SSL for the pds-dash virtual host.";
    };

    sslCertificate = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to SSL certificate file.";
    };

    sslCertificateKey = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to SSL certificate key file.";
    };

    acmeHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "ACME host to use for SSL certificate (alternative to manual certificate).";
      example = "example.com";
    };

    extraNginxConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra nginx configuration for the pds-dash virtual host.";
    };
  };

  config = mkIf cfg.enable {
    # Ensure nginx is enabled
    services.nginx.enable = true;

    # Configure nginx virtual host for pds-dash
    services.nginx.virtualHosts.${cfg.virtualHost} = {
      # Serve static files from pds-dash package
      locations."/" = {
        root = cfg.package;
        index = "index.html";
        tryFiles = "$uri $uri/ /index.html";

        extraConfig = ''
          # SPA support - serve index.html for client-side routing
          add_header Cache-Control "no-cache, must-revalidate";
        '';
      };

      # Proxy /xrpc requests to PDS
      locations."/xrpc/" = {
        proxyPass = cfg.pdsUrl;
        proxyWebsockets = true;

        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          # Timeouts for long-lived connections
          proxy_read_timeout 300s;
          proxy_connect_timeout 75s;
        '';
      };

      # SSL configuration
      enableACME = cfg.acmeHost != null;
      useACMEHost = cfg.acmeHost;
      forceSSL = cfg.enableSSL;
      sslCertificate = cfg.sslCertificate;
      sslCertificateKey = cfg.sslCertificateKey;

      # Extra user-provided config
      extraConfig = cfg.extraNginxConfig;
    };

    # Add helpful assertion
    assertions = [
      {
        assertion = !cfg.enableSSL || (cfg.sslCertificate != null && cfg.sslCertificateKey != null) || cfg.acmeHost != null;
        message = "services.witchcraft-systems.pds-dash: SSL is enabled but no certificate configuration provided. Set either sslCertificate+sslCertificateKey or acmeHost.";
      }
    ];
  };
}
