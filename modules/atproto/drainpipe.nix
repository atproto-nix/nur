# NixOS module for Drainpipe firehose consumer
{ config, lib, pkgs, ... }:

let
  cfg = config.services.atproto.drainpipe;
  
in
{
  options.services.atproto.drainpipe = {
    enable = lib.mkEnableOption "Drainpipe firehose consumer";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.atproto.frontpage.drainpipe;
      description = "Drainpipe package to use";
    };
    
    user = lib.mkOption {
      type = lib.types.str;
      default = "drainpipe";
      description = "User to run Drainpipe as";
    };
    
    group = lib.mkOption {
      type = lib.types.str;
      default = "drainpipe";
      description = "Group to run Drainpipe as";
    };
    
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/drainpipe";
      description = "Data directory for Drainpipe";
    };
    
    firehose = {
      url = lib.mkOption {
        type = lib.types.str;
        default = "wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos";
        description = "ATproto firehose WebSocket URL";
      };
      
      cursor = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Starting cursor for firehose consumption";
      };
    };
    
    storage = {
      backend = lib.mkOption {
        type = lib.types.enum [ "sled" "rocksdb" ];
        default = "sled";
        description = "Storage backend to use";
      };
      
      path = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/drainpipe/storage";
        description = "Storage path";
      };
      
      compression = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable storage compression";
      };
    };
    
    processing = {
      batchSize = lib.mkOption {
        type = lib.types.int;
        default = 1000;
        description = "Batch size for processing records";
      };
      
      workers = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Number of worker threads";
      };
    };
    
    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional configuration options";
    };
  };  config =
 lib.mkIf cfg.enable {
    # User and group management
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
      description = "Drainpipe firehose consumer user";
    };
    
    users.groups.${cfg.group} = {};
    
    # Directory management
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.storage.path}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/logs' 0750 ${cfg.user} ${cfg.group} - -"
    ];
    
    # Configuration file
    environment.etc."drainpipe/config.env" = {
      text = ''
        # Firehose configuration
        FIREHOSE_URL=${cfg.firehose.url}
        ${lib.optionalString (cfg.firehose.cursor != null) "FIREHOSE_CURSOR=${cfg.firehose.cursor}"}
        
        # Storage configuration
        STORAGE_BACKEND=${cfg.storage.backend}
        STORAGE_PATH=${cfg.storage.path}
        STORAGE_COMPRESSION=${lib.boolToString cfg.storage.compression}
        
        # Processing configuration
        BATCH_SIZE=${toString cfg.processing.batchSize}
        WORKER_THREADS=${toString cfg.processing.workers}
        
        # Logging
        RUST_LOG=info
        
        # Additional configuration
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}=${toString v}") cfg.extraConfig)}
      '';
      mode = "0640";
      user = cfg.user;
      group = cfg.group;
    };
    
    # systemd service
    systemd.services.drainpipe = {
      description = "Drainpipe ATproto firehose consumer";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      
      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        
        # Environment
        EnvironmentFile = "/etc/drainpipe/config.env";
        
        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        
        # File system access
        ReadWritePaths = [ cfg.dataDir cfg.storage.path ];
        
        # Process management
        Restart = "always";
        RestartSec = "10s";
        
        # Resource limits
        LimitNOFILE = 65536;
      };
      
      script = ''
        # Ensure storage directory exists
        mkdir -p "${cfg.storage.path}"
        
        # Start drainpipe
        exec ${cfg.package}/bin/drainpipe
      '';
    };
  };
}