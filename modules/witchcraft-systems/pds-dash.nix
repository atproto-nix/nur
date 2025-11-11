{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.witchcraft-systems.pds-dash;

  # Available themes
  availableThemes = [ "default" "express" "sunset" "witchcraft" ];

  # Build themed package if theme is specified and no custom package provided
  defaultPackage =
    if cfg.buildTheme then
      pkgs.callPackage ../../pkgs/witchcraft-systems/pds-dash-themed.nix {
        theme = cfg.theme;
        pdsUrl = cfg.pdsUrl;
        frontendUrl = cfg.frontendUrl;
        maxPosts = cfg.maxPosts;
        footerText = cfg.footerText;
        showFuturePosts = cfg.showFuturePosts;
      }
    else
      pkgs.witchcraft-systems-pds-dash or (throw "witchcraft-systems-pds-dash package not found");
in
{
  options.services.witchcraft-systems.pds-dash = {
    enable = mkEnableOption "pds-dash - ATProto PDS monitoring dashboard";

    package = mkOption {
      type = types.package;
      default = defaultPackage;
      defaultText = "Generated themed package if buildTheme=true, else witchcraft-systems-pds-dash";
      description = "The pds-dash package to use. Can be auto-generated from configuration if buildTheme is true.";
    };

    buildTheme = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to build pds-dash with theme and configuration at build time.
        When enabled, configuration options (theme, pdsUrl, frontendUrl, etc.) are
        built into the dashboard. When disabled, uses pre-built package.
      '';
    };

    theme = mkOption {
      type = types.enum availableThemes;
      default = "default";
      description = "pds-dash theme to use (only used if buildTheme is true).";
      example = "sunset";
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

    frontendUrl = mkOption {
      type = types.str;
      default = "https://deer.social";
      description = "The URL of the frontend service for linking to replies/quotes/accounts.";
      example = "https://bsky.app";
    };

    maxPosts = mkOption {
      type = types.int;
      default = 20;
      description = "Maximum number of posts to fetch from the PDS per request.";
    };

    footerText = mkOption {
      type = types.str;
      default = "<a href='https://git.witchcraft.systems/scientific-witchery/pds-dash' target='_blank'>Source</a> (<a href='https://github.com/witchcraft-systems/pds-dash/' target='_blank'>github mirror</a>)";
      description = "Footer text for the dashboard. Supports HTML.";
      example = "Powered by my PDS";
    };

    showFuturePosts = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to show posts with timestamps that are in the future.";
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
