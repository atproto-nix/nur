# NixOS module for Red Dwarf Bluesky client
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.whey-party-red-dwarf;
in
{
  options.services.whey-party-red-dwarf = {
    enable = mkEnableOption "Red Dwarf Bluesky client";

    package = mkOption {
      type = types.package;
      default = pkgs.whey-party-red-dwarf or pkgs.red-dwarf;
      description = "The Red Dwarf package to use.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/red-dwarf";
      description = "Directory where Red Dwarf stores its data and static files.";
    };

    user = mkOption {
      type = types.str;
      default = "red-dwarf";
      description = "User account for Red Dwarf service.";
    };

    group = mkOption {
      type = types.str;
      default = "red-dwarf";
      description = "Group for Red Dwarf service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          server = {
            port = mkOption {
              type = types.port;
              default = 3768;
              description = "Port for the Red Dwarf web server.";
            };

            hostname = mkOption {
              type = types.str;
              default = "localhost";
              description = "Hostname for the Red Dwarf service.";
              example = "reddwarf.example.com";
            };

            publicUrl = mkOption {
              type = types.str;
              description = "Public URL for OAuth callback (PROD_URL in vite.config).";
              example = "https://reddwarf.example.com";
            };

            devUrl = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Development URL for OAuth callback (DEV_URL in vite.config).";
              example = "https://local3768.example.com";
            };
          };

          microcosm = {
            constellation = {
              url = mkOption {
                type = types.str;
                default = "https://constellation.microcosm.blue";
                description = "Constellation backlink indexer URL.";
              };

              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Enable Constellation integration for backlinks.";
              };
            };

            slingshot = {
              url = mkOption {
                type = types.str;
                default = "https://slingshot.microcosm.blue";
                description = "Slingshot PDS proxy URL to reduce load on individual PDSs.";
              };

              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Enable Slingshot integration to reduce PDS load.";
              };
            };
          };

          features = {
            passwordAuth = mkOption {
              type = types.bool;
              default = false;
              description = "Enable legacy password-based authentication (for development).";
            };

            customFeeds = mkOption {
              type = types.bool;
              default = true;
              description = "Enable custom feed support.";
            };
          };

          ui = {
            theme = mkOption {
              type = types.enum [ "light" "dark" "auto" ];
              default = "auto";
              description = "Default UI theme.";
            };
          };
        };
      };
      default = {};
      description = "Red Dwarf service configuration.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for Red Dwarf.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.server.publicUrl != "";
        message = "services.whey-party-red-dwarf.settings.server.publicUrl must be specified";
      }
      {
        assertion = cfg.settings.microcosm.constellation.enable -> (cfg.settings.microcosm.constellation.url != "");
        message = "services.whey-party-red-dwarf: Constellation URL must be specified when Constellation is enabled";
      }
    ];

    warnings = [
      (mkIf cfg.settings.features.passwordAuth
        "Red Dwarf password authentication is enabled - this is intended for development only and should not be used in production")
    ];

    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = {};

    # Directory management
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/logs' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # Red Dwarf web application service
    systemd.services.whey-party-red-dwarf = {
      description = "Red Dwarf Bluesky client";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;

        # File system access
        ReadWritePaths = [ cfg.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];

        # Network access
        PrivateNetwork = false;
      };

      environment = {
        # Server configuration
        PORT = toString cfg.settings.server.port;
        HOSTNAME = cfg.settings.server.hostname;
        PUBLIC_URL = cfg.settings.server.publicUrl;

        # Microcosm integration
        CONSTELLATION_URL = cfg.settings.microcosm.constellation.url;
        CONSTELLATION_ENABLED = if cfg.settings.microcosm.constellation.enable then "true" else "false";
        SLINGSHOT_URL = cfg.settings.microcosm.slingshot.url;
        SLINGSHOT_ENABLED = if cfg.settings.microcosm.slingshot.enable then "true" else "false";

        # Feature flags
        PASSWORD_AUTH_ENABLED = if cfg.settings.features.passwordAuth then "true" else "false";
        CUSTOM_FEEDS_ENABLED = if cfg.settings.features.customFeeds then "true" else "false";

        # UI configuration
        DEFAULT_THEME = cfg.settings.ui.theme;
      } // optionalAttrs (cfg.settings.server.devUrl != null) {
        DEV_URL = cfg.settings.server.devUrl;
      };

      script = ''
        # Copy static files to working directory for serving
        cp -r ${cfg.package}/share/red-dwarf/* ${cfg.dataDir}/
        chmod -R u+w ${cfg.dataDir}

        # Start the static file server
        cd ${cfg.dataDir}
        exec ${pkgs.python3}/bin/python -m http.server ${toString cfg.settings.server.port}
      '';
    };

    # Firewall configuration
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.settings.server.port ];
    };

    # Optional Nginx reverse proxy configuration
    services.nginx = mkIf config.services.nginx.enable {
      virtualHosts."${cfg.settings.server.hostname}" = mkDefault {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.settings.server.port}";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Security headers
            add_header X-Frame-Options DENY;
            add_header X-Content-Type-Options nosniff;
            add_header X-XSS-Protection "1; mode=block";
            add_header Referrer-Policy strict-origin-when-cross-origin;

            # SPA routing support - serve index.html for all routes
            try_files $uri $uri/ /index.html;
          '';
        };
      };
    };
  };
}
