# Defines the NixOS module for Streamplace video infrastructure platform
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.stream-place-streamplace;
in
{
  options.services.stream-place-streamplace = {
    enable = mkEnableOption "Streamplace video infrastructure platform";

    package = mkOption {
      type = types.package;
      default = pkgs.stream-place-streamplace or pkgs.streamplace;
      description = "The Streamplace package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/atproto-streamplace";
      description = "The absolute path to the directory to store data in.";
    };

    user = mkOption {
      type = types.str;
      default = "atproto-streamplace";
      description = "User account for Streamplace service.";
    };

    group = mkOption {
      type = types.str;
      default = "atproto-streamplace";
      description = "Group for Streamplace service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          server = {
            port = mkOption {
              type = types.port;
              default = 8080;
              description = "Port for the Streamplace server.";
            };

            hostname = mkOption {
              type = types.str;
              default = "localhost";
              description = "Hostname for the Streamplace service.";
              example = "streamplace.example.com";
            };

            publicUrl = mkOption {
              type = types.str;
              description = "Public URL for the Streamplace service.";
              example = "https://streamplace.example.com";
            };
          };

          database = {
            url = mkOption {
              type = types.str;
              description = "PostgreSQL database URL.";
              example = "postgresql://user:pass@localhost:5432/streamplace";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing database password.";
            };
          };

          atproto = {
            pdsUrl = mkOption {
              type = types.str;
              default = "https://bsky.social";
              description = "AT Protocol PDS URL.";
            };

            handle = mkOption {
              type = types.str;
              description = "AT Protocol handle for the service.";
              example = "streamplace.example.com";
            };

            did = mkOption {
              type = types.str;
              description = "AT Protocol DID for the service.";
              example = "did:plc:example123";
            };

            signingKeyFile = mkOption {
              type = types.path;
              description = "File containing AT Protocol signing key.";
            };
          };

          video = {
            gstreamerPipeline = mkOption {
              type = types.str;
              default = "videotestsrc ! autovideosink";
              description = "Default GStreamer pipeline for video processing.";
            };

            ffmpegArgs = mkOption {
              type = types.listOf types.str;
              default = [ "-c:v" "libx264" "-preset" "fast" ];
              description = "Default FFmpeg arguments for video encoding.";
            };

            maxBitrate = mkOption {
              type = types.int;
              default = 5000000; # 5 Mbps
              description = "Maximum video bitrate in bits per second.";
            };

            maxResolution = mkOption {
              type = types.str;
              default = "1920x1080";
              description = "Maximum video resolution.";
            };
          };

          storage = {
            type = mkOption {
              type = types.enum [ "local" "s3" ];
              default = "local";
              description = "Storage backend type.";
            };

            localPath = mkOption {
              type = types.str;
              default = "/var/lib/atproto-streamplace/media";
              description = "Local storage path for media files.";
            };

            s3 = {
              bucket = mkOption {
                type = types.str;
                default = "";
                description = "S3 bucket name.";
              };

              region = mkOption {
                type = types.str;
                default = "us-east-1";
                description = "S3 region.";
              };

              accessKeyFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "File containing S3 access key.";
              };

              secretKeyFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "File containing S3 secret key.";
              };
            };
          };

          monitoring = {
            enable = mkEnableOption "monitoring and metrics";

            port = mkOption {
              type = types.port;
              default = 9090;
              description = "Port for metrics endpoint.";
            };
          };

          logLevel = mkOption {
            type = types.enum [ "trace" "debug" "info" "warn" "error" ];
            default = "info";
            description = "Logging level.";
          };
        };
      };
      default = {};
      description = "Streamplace service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.server.publicUrl != "";
        message = "services.stream-place-streamplace: public URL must be specified";
      }
      {
        assertion = cfg.settings.database.url != "";
        message = "services.stream-place-streamplace: database URL must be specified";
      }
      {
        assertion = cfg.settings.atproto.handle != "";
        message = "services.stream-place-streamplace: AT Protocol handle must be specified";
      }
      {
        assertion = cfg.settings.storage.type == "s3" -> (cfg.settings.storage.s3.bucket != "");
        message = "services.stream-place-streamplace: S3 bucket must be specified when using S3 storage";
      }
    ];

    warnings = [
      (mkIf (cfg.settings.video.maxBitrate > 10000000) 
        "Streamplace video bitrate is set very high (${toString cfg.settings.video.maxBitrate} bps) - this may impact performance")
    ];

    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      # Add to video group for hardware acceleration access
      extraGroups = [ "video" ];
    };

    users.groups.${cfg.group} = {};

    # Directory management
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/logs' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.settings.storage.localPath}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # Streamplace server service
    systemd.services.stream-place-streamplace = {
      description = "Streamplace video infrastructure platform";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        RestartSec = "10s";

        # Security hardening (relaxed for multimedia processing)
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = false; # Allow realtime for video processing
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = false; # Allow for JIT compilation in video codecs

        # File system access
        ReadWritePaths = [ cfg.dataDir cfg.settings.storage.localPath ];
        ReadOnlyPaths = [ "/nix/store" ];

        # Device access for hardware acceleration
        DeviceAllow = [
          "/dev/dri rw" # GPU access for hardware encoding
          "/dev/video* rw" # Video devices
        ];
      };

      environment = {
        # Server configuration
        PORT = toString cfg.settings.server.port;
        HOSTNAME = cfg.settings.server.hostname;
        PUBLIC_URL = cfg.settings.server.publicUrl;
        
        # Database configuration
        DATABASE_URL = cfg.settings.database.url;
        
        # AT Protocol configuration
        ATPROTO_PDS_URL = cfg.settings.atproto.pdsUrl;
        ATPROTO_HANDLE = cfg.settings.atproto.handle;
        ATPROTO_DID = cfg.settings.atproto.did;
        
        # Video processing configuration
        GSTREAMER_PIPELINE = cfg.settings.video.gstreamerPipeline;
        FFMPEG_ARGS = concatStringsSep " " cfg.settings.video.ffmpegArgs;
        MAX_BITRATE = toString cfg.settings.video.maxBitrate;
        MAX_RESOLUTION = cfg.settings.video.maxResolution;
        
        # Storage configuration
        STORAGE_TYPE = cfg.settings.storage.type;
        STORAGE_LOCAL_PATH = cfg.settings.storage.localPath;
        
        # Logging
        LOG_LEVEL = cfg.settings.logLevel;
        RUST_LOG = cfg.settings.logLevel;
        
        # GStreamer environment
        GST_PLUGIN_PATH = "${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-good}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0:${pkgs.gst_all_1.gst-plugins-ugly}/lib/gstreamer-1.0";
      } // optionalAttrs (cfg.settings.storage.type == "s3") {
        S3_BUCKET = cfg.settings.storage.s3.bucket;
        S3_REGION = cfg.settings.storage.s3.region;
      } // optionalAttrs cfg.settings.monitoring.enable {
        METRICS_PORT = toString cfg.settings.monitoring.port;
      };

      script = ''
        # Load secrets from files
        export ATPROTO_SIGNING_KEY="$(cat ${cfg.settings.atproto.signingKeyFile})"
        
        ${optionalString (cfg.settings.database.passwordFile != null) ''
          export DATABASE_PASSWORD="$(cat ${cfg.settings.database.passwordFile})"
        ''}
        
        ${optionalString (cfg.settings.storage.type == "s3" && cfg.settings.storage.s3.accessKeyFile != null) ''
          export S3_ACCESS_KEY="$(cat ${cfg.settings.storage.s3.accessKeyFile})"
        ''}
        
        ${optionalString (cfg.settings.storage.type == "s3" && cfg.settings.storage.s3.secretKeyFile != null) ''
          export S3_SECRET_KEY="$(cat ${cfg.settings.storage.s3.secretKeyFile})"
        ''}

        exec ${cfg.package}/bin/streamplace-server
      '';
    };

    # Enable required system services
    services.postgresql.enable = mkDefault true;
    
    # Hardware acceleration support
    hardware.opengl = {
      enable = mkDefault true;
      driSupport = mkDefault true;
    };
  };
}