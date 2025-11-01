# NixOS module for Red Dwarf - A Bluesky client
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.red-dwarf-client;
in
{
  options.services.red-dwarf-client = {
    enable = mkEnableOption "Red Dwarf Bluesky client";

    package = mkOption {
      type = types.package;
      default = pkgs.whey-party.red-dwarf or (throw "red-dwarf package not found in pkgs.whey-party");
      description = "The Red Dwarf package to use.";
    };

    hostname = mkOption {
      type = types.str;
      description = "Hostname for the Red Dwarf web interface.";
      example = "red-dwarf.example.com";
    };

    nginx = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable nginx virtual host for Red Dwarf.";
      };

      enableSSL = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable SSL via ACME.";
      };

      forceSSL = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to force redirect HTTP to HTTPS.";
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable nginx if requested
    services.nginx = mkIf cfg.nginx.enable {
      enable = true;
      virtualHosts.${cfg.hostname} = {
        root = "${cfg.package}/share/red-dwarf";

        enableACME = cfg.nginx.enableSSL;
        forceSSL = cfg.nginx.forceSSL;

        locations."/" = {
          tryFiles = "$uri $uri/ /index.html";
          extraConfig = ''
            add_header Cache-Control "public, max-age=3600";
          '';
        };

        locations."= /index.html" = {
          extraConfig = ''
            add_header Cache-Control "no-cache";
          '';
        };

        extraConfig = ''
          # Security headers
          add_header X-Frame-Options "SAMEORIGIN" always;
          add_header X-Content-Type-Options "nosniff" always;
          add_header X-XSS-Protection "1; mode=block" always;
        '';
      };
    };
  };
}
