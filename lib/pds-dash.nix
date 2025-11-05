# Shared utilities for pds-dash configuration and NixOS module support
# Provides helpers for building themed dashboards and creating dashboard submodules
{ lib }:

with lib;

rec {
  # Available themes in pds-dash
  availableThemes = [ "default" "express" "sunset" "witchcraft" ];

  # Validate theme name
  validateTheme = theme:
    if elem theme availableThemes then true
    else throw "Invalid theme '${theme}'. Must be one of: ${concatStringsSep ", " availableThemes}";

  # Default configuration for pds-dash
  defaultConfig = {
    pdsUrl = "http://127.0.0.1:3000";
    frontendUrl = "https://deer.social";
    maxPosts = 20;
    footerText = "<a href='https://git.witchcraft.systems/scientific-witchery/pds-dash' target='_blank'>Source</a>";
    showFuturePosts = false;
  };

  # Create dashboard submodule options
  mkDashboardOptions = serviceName: {
    enable = mkEnableOption "pds-dash dashboard for ${serviceName}";

    theme = mkOption {
      type = types.enum availableThemes;
      default = "default";
      description = "Theme to use for pds-dash dashboard.";
      example = "sunset";
    };

    virtualHost = mkOption {
      type = types.str;
      description = "Hostname to serve dashboard on.";
      example = "dash.example.com";
    };

    port = mkOption {
      type = types.int;
      description = "Port of the PDS service (used for proxy configuration).";
      example = 3000;
    };

    hostname = mkOption {
      type = types.str;
      description = "Hostname of the PDS service.";
      example = "pds.example.com";
    };

    frontendUrl = mkOption {
      type = types.str;
      default = "https://deer.social";
      description = "Frontend URL for feed/post links.";
      example = "https://bsky.app";
    };

    maxPosts = mkOption {
      type = types.int;
      default = 20;
      description = "Maximum posts to fetch per request.";
    };

    footerText = mkOption {
      type = types.str;
      default = "Powered by pds-dash";
      description = "HTML footer text for dashboard.";
    };

    showFuturePosts = mkOption {
      type = types.bool;
      default = false;
      description = "Show posts with future timestamps.";
    };

    enableSSL = mkOption {
      type = types.bool;
      default = false;
      description = "Enable SSL for dashboard.";
    };

    acmeEmail = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Email for ACME certificate (if using Let's Encrypt).";
    };
  };

  # Build pds-dash configuration submodule
  mkDashboardModule = serviceName: serviceNameUpper: pkgs:
    {
      options.dashboard = mkDashboardOptions serviceName;

      config = mkIf config.dashboard.enable {
        # Enable nginx if dashboard is enabled
        services.nginx.enable = true;

        # Build dashboard with theme
        dashboard.package = pkgs.callPackage ../pkgs/witchcraft-systems/pds-dash-themed.nix {
          theme = config.dashboard.theme;
          pdsUrl = "http://${config.dashboard.hostname}:${toString config.dashboard.port}";
          frontendUrl = config.dashboard.frontendUrl;
          maxPosts = config.dashboard.maxPosts;
          footerText = config.dashboard.footerText;
          showFuturePosts = config.dashboard.showFuturePosts;
        };

        # Configure nginx virtual host
        services.nginx.virtualHosts.${config.dashboard.virtualHost} = {
          # Serve dashboard static files
          locations."/" = {
            root = config.dashboard.package;
            index = "index.html";
            tryFiles = "$uri $uri/ /index.html";

            extraConfig = ''
              # SPA caching policy
              add_header Cache-Control "no-cache, must-revalidate";
            '';
          };

          # Proxy /xrpc to PDS
          locations."/xrpc/" = {
            proxyPass = "http://${config.dashboard.hostname}:${toString config.dashboard.port}";
            proxyWebsockets = true;

            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_read_timeout 300s;
              proxy_connect_timeout 75s;
            '';
          };

          # SSL configuration
          enableACME = config.dashboard.acmeEmail != null;
          useACMEHost = if config.dashboard.acmeEmail != null then config.dashboard.virtualHost else null;
          forceSSL = config.dashboard.enableSSL;
        };

        # Assertions
        assertions = [
          {
            assertion = config.dashboard.enableSSL || config.dashboard.acmeEmail == null;
            message = "${serviceName} dashboard: SSL is required for ACME";
          }
        ];
      };
    };

  # Helper to add dashboard support to a PDS module
  # Usage in a PDS module:
  # imports = [ (pds-dash-lib.addDashboardSupport config lib pkgs "rsky") ];
  addDashboardSupport = config: lib: pkgs: serviceName:
    {
      options.services.${serviceName}.dashboard = mkDashboardOptions serviceName;

      config = mkIf config.services.${serviceName}.dashboard.enable {
        services.nginx.enable = true;

        # Build themed dashboard
        services.${serviceName}.dashboard.package = pkgs.callPackage ../../pkgs/witchcraft-systems/pds-dash-themed.nix {
          theme = config.services.${serviceName}.dashboard.theme;
          pdsUrl = "http://127.0.0.1:${toString config.services.${serviceName}.port}";
          frontendUrl = config.services.${serviceName}.dashboard.frontendUrl;
          maxPosts = config.services.${serviceName}.dashboard.maxPosts;
          footerText = config.services.${serviceName}.dashboard.footerText;
          showFuturePosts = config.services.${serviceName}.dashboard.showFuturePosts;
        };

        # Configure nginx
        services.nginx.virtualHosts.${config.services.${serviceName}.dashboard.virtualHost} = {
          locations."/" = {
            root = config.services.${serviceName}.dashboard.package;
            index = "index.html";
            tryFiles = "$uri $uri/ /index.html";

            extraConfig = ''add_header Cache-Control "no-cache, must-revalidate";'';
          };

          locations."/xrpc/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.${serviceName}.port}";
            proxyWebsockets = true;

            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_read_timeout 300s;
              proxy_connect_timeout 75s;
            '';
          };

          enableACME = config.services.${serviceName}.dashboard.acmeEmail != null;
          useACMEHost = if config.services.${serviceName}.dashboard.acmeEmail != null
            then config.services.${serviceName}.dashboard.virtualHost else null;
          forceSSL = config.services.${serviceName}.dashboard.enableSSL;
        };
      };
    };
}
