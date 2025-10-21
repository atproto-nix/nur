{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.individual.drainpipe;
in {
  options.services.individual.drainpipe = {
    enable = mkEnableOption "Bluesky Drainpipe ATProto firehose consumer";
    
    package = mkOption {
      type = types.package;
      default = pkgs.individual-drainpipe or pkgs.drainpipe;
      description = "Drainpipe package to use";
    };
    
    user = mkOption {
      type = types.str;
      default = "bluesky-drainpipe";
      description = "User account for Drainpipe service";
    };
    
    group = mkOption {
      type = types.str;
      default = "bluesky-drainpipe";
      description = "Group for Drainpipe service";
    };
    
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/bluesky-drainpipe";
      description = "Data directory for Drainpipe service";
    };
    
    settings = mkOption {
      type = types.submodule {
        options = {
          firehoseUrl = mkOption {
            type = types.str;
            default = "wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos";
            description = "ATProto firehose WebSocket URL";
          };
          
          logLevel = mkOption {
            type = types.enum [ "trace" "debug" "info" "warn" "error" ];
            default = "info";
            description = "Logging level";
          };
          
          storage = {
            backend = mkOption {
              type = types.enum [ "sled" "memory" ];
              default = "sled";
              description = "Storage backend type";
            };
            
            path = mkOption {
              type = types.str;
              default = "${cfg.dataDir}/drainpipe.db";
              description = "Storage path (for sled backend)";
            };
          };
          
          metrics = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Enable metrics collection";
            };
            
            port = mkOption {
              type = types.port;
              default = 9090;
              description = "Metrics server port";
            };
          };
          
          processing = {
            batchSize = mkOption {
              type = types.int;
              default = 100;
              description = "batch size for processing events";
            };
            
            workers = mkOption {
              type = types.int;
              default = 4;
              description = "Number of worker threads";
            };
          };
        };
      };
      default = {};
      description = "Drainpipe service configuration";
    };
    
    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Environment file containing sensitive configuration";
    };
  };
  
  config = mkIf cfg.enable {
    # User and group management
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
    };
    
    users.groups.${cfg.group} = {};
    
    # Directory management using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ];
    
    # systemd service
    systemd.services.bluesky-drainpipe = {
      description = "Bluesky Drainpipe ATProto firehose consumer";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      
      environment = {
        RUST_LOG = cfg.settings.logLevel;
        FIREHOSE_URL = cfg.settings.firehoseUrl;
        STORAGE_BACKEND = cfg.settings.storage.backend;
        STORAGE_PATH = cfg.settings.storage.path;
        BATCH_SIZE = toString cfg.settings.processing.batchSize;
        WORKERS = toString cfg.settings.processing.workers;
        METRICS_PORT = toString cfg.settings.metrics.port;
      };
      
      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/drainpipe";
        Restart = "on-failure";
        RestartSec = "5s";
        
        # Load additional environment from file if specified
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;
        
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
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      };
    };
    
    # Firewall configuration for metrics
    networking.firewall.allowedTCPPorts = mkIf (cfg.enable && cfg.settings.metrics.enable) [ cfg.settings.metrics.port ];
  };
}