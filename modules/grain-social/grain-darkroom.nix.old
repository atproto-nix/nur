# Defines the NixOS module for the Grain Darkroom image processing service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.grain-darkroom;
in
{
  options.services.grain-darkroom = {
    enable = mkEnableOption "Grain Darkroom image processing service";

    package = mkOption {
      type = types.package;
      default = pkgs.bluesky-social-grain-darkroom;
      description = "The Grain Darkroom package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/grain-darkroom";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "grain-darkroom";
      description = "User account for Grain Darkroom service.";
    };

    group = mkOption {
      type = types.str;
      default = "grain-darkroom";
      description = "Group for Grain Darkroom service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 3001;
            description = "Port for the darkroom service to listen on.";
          };

          hostname = mkOption {
            type = types.str;
            default = "localhost";
            description = "Hostname for the darkroom service.";
          };

          processing = {
            maxWidth = mkOption {
              type = types.int;
              default = 2048;
              description = "Maximum width for processed images.";
            };

            maxHeight = mkOption {
              type = types.int;
              default = 2048;
              description = "Maximum height for processed images.";
            };

            quality = mkOption {
              type = types.int;
              default = 85;
              description = "JPEG quality for processed images (1-100).";
            };

            workers = mkOption {
              type = types.int;
              default = 4;
              description = "Number of image processing worker threads.";
            };

            timeout = mkOption {
              type = types.int;
              default = 30;
              description = "Processing timeout in seconds.";
            };
          };

          cache = {
            enable = mkEnableOption "image caching";

            directory = mkOption {
              type = types.path;
              default = "${cfg.dataDir}/cache";
              description = "Cache directory for processed images.";
            };

            maxSize = mkOption {
              type = types.str;
              default = "1GB";
              description = "Maximum cache size.";
            };

            ttl = mkOption {
              type = types.int;
              default = 86400;
              description = "Cache TTL in seconds.";
            };
          };

          screenshot = {
            enable = mkEnableOption "screenshot generation for galleries";

            chromeExecutable = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "Path to Chrome/Chromium executable.";
            };

            viewport = {
              width = mkOption {
                type = types.int;
                default = 1200;
                description = "Screenshot viewport width.";
              };

              height = mkOption {
                type = types.int;
                default = 800;
                description = "Screenshot viewport height.";
              };
            };

            timeout = mkOption {
              type = types.int;
              default = 10;
              description = "Screenshot timeout in seconds.";
            };
          };

          logLevel = mkOption {
            type = types.enum [ "trace" "debug" "info" "warn" "error" ];
            default = "info";
            description = "Logging level.";
          };

          metrics = {
            enable = mkEnableOption "Prometheus metrics endpoint";
            
            port = mkOption {
              type = types.port;
              default = 3011;
              description = "Port for metrics endpoint.";
            };
          };
        };
      };
      default = {};
      description = "Grain Darkroom service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.processing.quality >= 1 && cfg.settings.processing.quality <= 100;
        message = "services.grain-darkroom: processing quality must be between 1 and 100";
      }
      {
        assertion = cfg.settings.screenshot.enable -> (cfg.settings.screenshot.chromeExecutable != null);
        message = "services.grain-darkroom: chromeExecutable must be specified when screenshot is enabled";
      }
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
    ] ++ lib.optional (cfg.settings.cache.enable) [
      "d '${cfg.settings.cache.directory}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # systemd service
    systemd.services.grain-darkroom = {
      description = "Grain Darkroom image processing service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        RestartSec = "10s";

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
        # Note: MemoryDenyWriteExecute disabled for image processing libraries
        # MemoryDenyWriteExecute = true;

        # File system access
        ReadWritePaths = [ cfg.dataDir ] 
          ++ lib.optional (cfg.settings.cache.enable) cfg.settings.cache.directory;
        ReadOnlyPaths = [ "/nix/store" ];
      };

      environment = {
        RUST_LOG = cfg.settings.logLevel;
        DARKROOM_HOSTNAME = cfg.settings.hostname;
        DARKROOM_PORT = toString cfg.settings.port;
        DARKROOM_PROCESSING_MAX_WIDTH = toString cfg.settings.processing.maxWidth;
        DARKROOM_PROCESSING_MAX_HEIGHT = toString cfg.settings.processing.maxHeight;
        DARKROOM_PROCESSING_QUALITY = toString cfg.settings.processing.quality;
        DARKROOM_PROCESSING_WORKERS = toString cfg.settings.processing.workers;
        DARKROOM_PROCESSING_TIMEOUT = toString cfg.settings.processing.timeout;
      } // lib.optionalAttrs (cfg.settings.cache.enable) {
        DARKROOM_CACHE_ENABLED = "true";
        DARKROOM_CACHE_DIRECTORY = cfg.settings.cache.directory;
        DARKROOM_CACHE_MAX_SIZE = cfg.settings.cache.maxSize;
        DARKROOM_CACHE_TTL = toString cfg.settings.cache.ttl;
      } // lib.optionalAttrs (cfg.settings.screenshot.enable) {
        DARKROOM_SCREENSHOT_ENABLED = "true";
        DARKROOM_CHROME_EXECUTABLE = cfg.settings.screenshot.chromeExecutable;
        DARKROOM_SCREENSHOT_VIEWPORT_WIDTH = toString cfg.settings.screenshot.viewport.width;
        DARKROOM_SCREENSHOT_VIEWPORT_HEIGHT = toString cfg.settings.screenshot.viewport.height;
        DARKROOM_SCREENSHOT_TIMEOUT = toString cfg.settings.screenshot.timeout;
      } // lib.optionalAttrs (cfg.settings.metrics.enable) {
        DARKROOM_METRICS_PORT = toString cfg.settings.metrics.port;
      };

      script = ''
        exec ${cfg.package}/bin/darkroom
      '';
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [ cfg.settings.port ] 
      ++ lib.optional cfg.settings.metrics.enable cfg.settings.metrics.port;
  };
}