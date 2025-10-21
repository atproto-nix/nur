{ config, lib, pkgs, ... }:

let
  cfg = config.services.atproto.indigo;
  atprotoCfg = config.services.atproto;
  
  # Import service utilities
  serviceCommon = import ../../lib/service-common.nix { inherit lib; };
  
  # Service-specific configuration generators
  mkIndigoService = name: serviceCfg: {
    description = "Indigo ${name} - ATproto service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ] ++ lib.optionals serviceCfg.database.enable [ "postgresql.service" ];
    wants = lib.optionals serviceCfg.database.enable [ "postgresql.service" ];
    
    serviceConfig = {
      Type = "simple";
      User = serviceCfg.user;
      Group = serviceCfg.group;
      ExecStart = "${serviceCfg.package}/bin/indigo-${name} ${lib.escapeShellArgs serviceCfg.args}";
      Restart = "always";
      RestartSec = "10s";
      
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
      ReadWritePaths = [ serviceCfg.dataDir ];
      PrivateTmp = true;
      PrivateDevices = true;
      
      # Network access (required for ATproto services)
      PrivateNetwork = false;
      
      # Capabilities
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
    };
    
    environment = serviceCfg.environment // {
      # Common ATproto environment variables
      GOLOG_LOG_LEVEL = serviceCfg.logLevel;
    } // lib.optionalAttrs serviceCfg.database.enable {
      DATABASE_URL = serviceCfg.database.url;
    };
  };

  # Common service options
  mkServiceOptions = name: {
    enable = lib.mkEnableOption "Indigo ${name} service";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nur.repos.atproto.atproto.indigo.${name};
      defaultText = lib.literalExpression "pkgs.nur.repos.atproto.atproto.indigo.${name}";
      description = "Package to use for Indigo ${name}";
    };
    
    user = lib.mkOption {
      type = lib.types.str;
      default = "indigo-${name}";
      description = "User account for Indigo ${name}";
    };
    
    group = lib.mkOption {
      type = lib.types.str;
      default = "indigo-${name}";
      description = "Group for Indigo ${name}";
    };
    
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "${atprotoCfg.dataDir}/indigo-${name}";
      description = "Data directory for Indigo ${name}";
    };
    
    logLevel = lib.mkOption {
      type = lib.types.enum [ "debug" "info" "warn" "error" ];
      default = "info";
      description = "Log level for Indigo ${name}";
    };
    
    args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional command line arguments";
    };
    
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional environment variables";
    };
    
    database = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable database integration";
      };
      
      url = lib.mkOption {
        type = lib.types.str;
        default = "postgres://indigo:indigo@localhost/indigo_${lib.replaceStrings ["-"] ["_"] name}";
        description = "Database connection URL";
      };
    };
    
    network = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host to bind to";
      };
      
      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Port to bind to";
      };
    };
  };

in
{
  options.services.atproto.indigo = {
    # Core services as specified in the task
    relay = mkServiceOptions "relay" // {
      network.port = lib.mkDefault 8110;
    };
    
    rainbow = mkServiceOptions "rainbow" // {
      network.port = lib.mkDefault 8120;
    };
    
    palomar = mkServiceOptions "palomar" // {
      network.port = lib.mkDefault 8130;
    };
    
    hepa = mkServiceOptions "hepa" // {
      network.port = lib.mkDefault 8140;
    };
  };
  
  config = lib.mkMerge [
    # Relay service configuration
    (lib.mkIf cfg.relay.enable {
      systemd.services.indigo-relay = mkIndigoService "relay" cfg.relay;
      
      users.users.${cfg.relay.user} = {
        isSystemUser = true;
        group = cfg.relay.group;
        home = cfg.relay.dataDir;
        createHome = false;
      };
      
      users.groups.${cfg.relay.group} = {};
      
      systemd.tmpfiles.rules = [
        "d '${cfg.relay.dataDir}' 0750 ${cfg.relay.user} ${cfg.relay.group} - -"
      ];
    })
    
    # Rainbow service configuration  
    (lib.mkIf cfg.rainbow.enable {
      systemd.services.indigo-rainbow = mkIndigoService "rainbow" cfg.rainbow;
      
      users.users.${cfg.rainbow.user} = {
        isSystemUser = true;
        group = cfg.rainbow.group;
        home = cfg.rainbow.dataDir;
        createHome = false;
      };
      
      users.groups.${cfg.rainbow.group} = {};
      
      systemd.tmpfiles.rules = [
        "d '${cfg.rainbow.dataDir}' 0750 ${cfg.rainbow.user} ${cfg.rainbow.group} - -"
      ];
    })
    
    # Palomar service configuration
    (lib.mkIf cfg.palomar.enable {
      systemd.services.indigo-palomar = mkIndigoService "palomar" cfg.palomar;
      
      users.users.${cfg.palomar.user} = {
        isSystemUser = true;
        group = cfg.palomar.group;
        home = cfg.palomar.dataDir;
        createHome = false;
      };
      
      users.groups.${cfg.palomar.group} = {};
      
      systemd.tmpfiles.rules = [
        "d '${cfg.palomar.dataDir}' 0750 ${cfg.palomar.user} ${cfg.palomar.group} - -"
      ];
    })
    
    # Hepa service configuration
    (lib.mkIf cfg.hepa.enable {
      systemd.services.indigo-hepa = mkIndigoService "hepa" cfg.hepa;
      
      users.users.${cfg.hepa.user} = {
        isSystemUser = true;
        group = cfg.hepa.group;
        home = cfg.hepa.dataDir;
        createHome = false;
      };
      
      users.groups.${cfg.hepa.group} = {};
      
      systemd.tmpfiles.rules = [
        "d '${cfg.hepa.dataDir}' 0750 ${cfg.hepa.user} ${cfg.hepa.group} - -"
      ];
    })
  ];
}