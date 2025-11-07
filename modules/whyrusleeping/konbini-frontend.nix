{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.whyrusleeping.konbini-frontend;
  backendCfg = config.services.whyrusleeping.konbini;

in
{
  options.services.whyrusleeping.konbini-frontend = {
    enable = mkEnableOption "Konbini web frontend (React UI serving static files and proxying API requests)";

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port on which the frontend web server listens.";
    };

    domain = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "konbini.example.com";
      description = ''
        Optional domain name for virtual host configuration.
        If set, the frontend will be accessible at this domain.
      '';
    };

    backendUrl = mkOption {
      type = types.str;
      default = "http://localhost:${toString backendCfg.apiPort}";
      description = ''
        Backend API URL for the frontend to proxy requests to.
        Default points to the local konbini backend API server.
      '';
    };

    enableSSL = mkOption {
      type = types.bool;
      default = false;
      description = "Enable SSL/TLS for the frontend. Requires acme configuration.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the firewall for the frontend port.";
    };
  };

  config = mkIf cfg.enable {
    # Assertions
    assertions = [
      {
        assertion = backendCfg.enable;
        message = "services.whyrusleeping.konbini-frontend: konbini backend must be enabled";
      }
    ];

    # nginx configuration
    services.nginx = {
      enable = true;

      virtualHosts."${if cfg.domain != null then cfg.domain else "konbini-frontend"}" = {
        listen = [
          {
            addr = "0.0.0.0";
            port = cfg.port;
            ssl = cfg.enableSSL;
          }
          {
            addr = "[::]";
            port = cfg.port;
            ssl = cfg.enableSSL;
          }
        ];

        # Use ACME host if SSL is enabled
        useACMEHost = mkIf cfg.enableSSL cfg.domain;

        # Root for static files
        root = "${backendCfg.package}/share/konbini/frontend";

        # Redirect to index.html for React SPA routing
        locations."/" = {
          tryFiles = "$uri $uri/ /index.html";
          extraConfig = ''
            # Cache busting for HTML
            add_header Cache-Control "public, max-age=0, must-revalidate" always;
          '';
        };

        # Cache static assets
        locations."~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$" = {
          extraConfig = ''
            expires 1y;
            add_header Cache-Control "public, immutable" always;
          '';
        };

        # Proxy API requests to backend
        locations."/api" = {
          proxyPass = "${cfg.backendUrl}/api";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            # Timeouts for long-lived connections
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
          '';
        };

        # Security headers
        extraConfig = ''
          # Prevent framing
          add_header X-Frame-Options "SAMEORIGIN" always;

          # Content security policy (adjust as needed)
          add_header X-Content-Type-Options "nosniff" always;
          add_header X-XSS-Protection "1; mode=block" always;
          add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        '';
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
