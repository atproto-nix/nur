# Defines the NixOS module for Red Dwarf Bluesky client
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.atproto-red-dwarf;
in
{
  options.services.atproto-red-dwarf = {
    enable = mkEnableOption "Red Dwarf Bluesky client";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.atproto.red-dwarf;
      description = "The Red Dwarf package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/atproto-red-dwarf";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "atproto-red-dwarf";
      description = "User account for Red Dwarf service.";
    };

    group = mkOption {
      type = types.str;
      default = "atproto-red-dwarf";
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
              description = "Public URL for the Red Dwarf service (used for OAuth).";
              example = "https://reddwarf.example.com";
            };

            devUrl = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Development URL for OAuth (optional).";
              example = "https://dev.reddwarf.example.com";
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
                description = "Slingshot PDS proxy URL.";
              };

              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Enable Slingshot integration to reduce PDS load.";
              };
            };
          };

          oauth = {
            clientId = mkOption {
              type = types.str;
              description = "AT Protocol OAuth client ID.";
            };

            clientSecretFile = mkOption {
              type = types.path;
              description = "File containing AT Protocol OAuth client secret.";
            };

            redirectUri = mkOption {
              type = types.str;
              description = "OAuth redirect URI.";
              example = "https://reddwarf.example.com/auth/callback";
            };

            issuer = mkOption {
              type = types.str;
              default = "https://bsky.social";
              description = "OAuth issuer URL.";
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

            notifications = mkOption {
              type = types.bool;
              default = true;
              description = "Enable notifications.";
            };

            keepAlive = mkOption {
              type = types.bool;
              default = true;
              description = "Enable route keep-alive for better performance.";
            };
          };

          ui = {
            theme = mkOption {
              type = types.enum [ "light" "dark" "auto" ];
              default = "auto";
              description = "Default UI theme.";
            };

            iconSet = mkOption {
              type = types.enum [ "material-symbols" "mdi" ];
              default = "material-symbols";
              description = "Icon set to use in the UI.";
            };

            maxPostsPerPage = mkOption {
              type = types.int;
              default = 50;
              description = "Maximum posts to load per page.";
            };
          };

          caching = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Enable client-side caching with Tanstack Query.";
            };

            maxAge = mkOption {
              type = types.int;
              default = 300000; # 5 minutes
              description = "Cache maximum age in milliseconds.";
            };

            gcTime = mkOption {
              type = types.int;
              default = 600000; # 10 minutes
              description = "Garbage collection time for stale cache entries in milliseconds.";
            };
          };

          monitoring = {
            enable = mkEnableOption "monitoring and analytics";

            webVitals = mkOption {
              type = types.bool;
              default = true;
              description = "Enable Web Vitals performance monitoring.";
            };
          };

          security = {
            contentSecurityPolicy = mkOption {
              type = types.bool;
              default = true;
              description = "Enable Content Security Policy headers.";
            };

            domPurify = mkOption {
              type = types.bool;
              default = true;
              description = "Enable DOMPurify for HTML sanitization.";
            };
          };
        };
      };
      default = {};
      description = "Red Dwarf service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.server.publicUrl != "";
        message = "services.atproto-red-dwarf: public URL must be specified";
      }
      {
        assertion = cfg.settings.oauth.clientId != "";
        message = "services.atproto-red-dwarf: OAuth client ID must be specified";
      }
      {
        assertion = cfg.settings.microcosm.constellation.enable -> (cfg.settings.microcosm.constellation.url != "");
        message = "services.atproto-red-dwarf: Constellation URL must be specified when Constellation is enabled";
      }
    ];

    warnings = [
      (mkIf cfg.settings.features.passwordAuth 
        "Red Dwarf password authentication is enabled - this is intended for development only")
    ];

    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
    };

    users.groups.${cfg.group} = {};

    # Directory management
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/logs' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # Red Dwarf web application service
    systemd.services.atproto-red-dwarf = {
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
        ReadOnlyPaths = [ "/nix/store" "${cfg.package}/share/red-dwarf" ];

        # Network access
        PrivateNetwork = false;
      };

      environment = {
        # Server configuration
        PORT = toString cfg.settings.server.port;
        HOSTNAME = cfg.settings.server.hostname;
        PUBLIC_URL = cfg.settings.server.publicUrl;
        
        # OAuth configuration
        OAUTH_CLIENT_ID = cfg.settings.oauth.clientId;
        OAUTH_REDIRECT_URI = cfg.settings.oauth.redirectUri;
        OAUTH_ISSUER = cfg.settings.oauth.issuer;
        
        # Microcosm integration
        CONSTELLATION_URL = cfg.settings.microcosm.constellation.url;
        CONSTELLATION_ENABLED = if cfg.settings.microcosm.constellation.enable then "true" else "false";
        SLINGSHOT_URL = cfg.settings.microcosm.slingshot.url;
        SLINGSHOT_ENABLED = if cfg.settings.microcosm.slingshot.enable then "true" else "false";
        
        # Feature flags
        PASSWORD_AUTH_ENABLED = if cfg.settings.features.passwordAuth then "true" else "false";
        CUSTOM_FEEDS_ENABLED = if cfg.settings.features.customFeeds then "true" else "false";
        NOTIFICATIONS_ENABLED = if cfg.settings.features.notifications then "true" else "false";
        KEEP_ALIVE_ENABLED = if cfg.settings.features.keepAlive then "true" else "false";
        
        # UI configuration
        DEFAULT_THEME = cfg.settings.ui.theme;
        ICON_SET = cfg.settings.ui.iconSet;
        MAX_POSTS_PER_PAGE = toString cfg.settings.ui.maxPostsPerPage;
        
        # Caching configuration
        CACHING_ENABLED = if cfg.settings.caching.enable then "true" else "false";
        CACHE_MAX_AGE = toString cfg.settings.caching.maxAge;
        CACHE_GC_TIME = toString cfg.settings.caching.gcTime;
        
        # Security configuration
        CSP_ENABLED = if cfg.settings.security.contentSecurityPolicy then "true" else "false";
        DOM_PURIFY_ENABLED = if cfg.settings.security.domPurify then "true" else "false";
        
        # Monitoring
        WEB_VITALS_ENABLED = if cfg.settings.monitoring.webVitals then "true" else "false";
      } // optionalAttrs (cfg.settings.server.devUrl != null) {
        DEV_URL = cfg.settings.server.devUrl;
      };

      script = ''
        # Load OAuth client secret
        export OAUTH_CLIENT_SECRET="$(cat ${cfg.settings.oauth.clientSecretFile})"

        # Copy static files to working directory
        cp -r ${cfg.package}/share/red-dwarf/* ${cfg.dataDir}/

        # Start the web server
        cd ${cfg.dataDir}
        exec ${pkgs.python3}/bin/python -m http.server ${toString cfg.settings.server.port}
      '';
    };

    # Nginx reverse proxy configuration (optional)
    services.nginx = mkIf config.services.nginx.enable {
      virtualHosts."${cfg.settings.server.hostname}" = mkDefault {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.settings.server.port}";
          proxyWebsockets = true;
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
            
            ${optionalString cfg.settings.security.contentSecurityPolicy ''
              add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' wss: https:; font-src 'self' data:; media-src 'self' https:;";
            ''}
          '';
        };
      };
    };
  };
}