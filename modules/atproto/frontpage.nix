# NixOS module for Frontpage web application
{ config, lib, pkgs, ... }:

let
  cfg = config.services.atproto.frontpage;
  
  # Import service utilities
  serviceCommon = import ../../lib/service-common.nix { inherit lib; };
  
in
{
  options.services.atproto.frontpage = {
    enable = lib.mkEnableOption "Frontpage web application";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.atproto.frontpage.frontpage;
      description = "Frontpage package to use";
    };
    
    user = lib.mkOption {
      type = lib.types.str;
      default = "frontpage";
      description = "User to run Frontpage as";
    };
    
    group = lib.mkOption {
      type = lib.types.str;
      default = "frontpage";
      description = "Group to run Frontpage as";
    };
    
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/frontpage";
      description = "Data directory for Frontpage";
    };
    
    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for Frontpage web server";
    };
    
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = "Hostname to bind to";
    };
    
    database = {
      url = lib.mkOption {
        type = lib.types.str;
        description = "Database connection URL";
        example = "sqlite:///var/lib/frontpage/frontpage.db";
      };
      
      type = lib.mkOption {
        type = lib.types.enum [ "sqlite" "libsql" "postgresql" ];
        default = "sqlite";
        description = "Database type";
      };
    };
    
    oauth = {
      clientId = lib.mkOption {
        type = lib.types.str;
        description = "OAuth client ID";
      };
      
      clientSecret = lib.mkOption {
        type = lib.types.str;
        description = "OAuth client secret";
      };
      
      redirectUri = lib.mkOption {
        type = lib.types.str;
        description = "OAuth redirect URI";
        example = "https://example.com/oauth/callback";
      };
    };
    
    atproto = {
      pdsUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://bsky.social";
        description = "ATproto PDS URL";
      };
      
      appviewUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://api.bsky.app";
        description = "ATproto AppView URL";
      };
    };
    
    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional configuration options";
    };
  };  c
onfig = lib.mkIf cfg.enable {
    # User and group management
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
      description = "Frontpage web application user";
    };
    
    users.groups.${cfg.group} = {};
    
    # Directory management using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/logs' 0750 ${cfg.user} ${cfg.group} - -"
    ];
    
    # Environment file for configuration
    environment.etc."frontpage/config.env" = {
      text = ''
        # Database configuration
        DATABASE_URL=${cfg.database.url}
        
        # Server configuration
        PORT=${toString cfg.port}
        HOSTNAME=${cfg.hostname}
        
        # OAuth configuration
        OAUTH_CLIENT_ID=${cfg.oauth.clientId}
        OAUTH_CLIENT_SECRET=${cfg.oauth.clientSecret}
        OAUTH_REDIRECT_URI=${cfg.oauth.redirectUri}
        
        # ATproto configuration
        ATPROTO_PDS_URL=${cfg.atproto.pdsUrl}
        ATPROTO_APPVIEW_URL=${cfg.atproto.appviewUrl}
        
        # Additional configuration
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}=${toString v}") cfg.extraConfig)}
      '';
      mode = "0640";
      user = cfg.user;
      group = cfg.group;
    };
    
    # systemd service configuration
    systemd.services.frontpage = {
      description = "Frontpage web application";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      
      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        
        # Environment
        EnvironmentFile = "/etc/frontpage/config.env";
        
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
        MemoryDenyWriteExecute = false; # Node.js needs JIT
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        
        # File system access
        ReadWritePaths = [ cfg.dataDir ];
        
        # Capabilities
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        AmbientCapabilities = lib.optionals (cfg.port < 1024) [ "CAP_NET_BIND_SERVICE" ];
        
        # Process management
        Restart = "always";
        RestartSec = "10s";
        
        # Resource limits
        LimitNOFILE = 65536;
      };
      
      script = ''
        # Initialize database if needed
        if [ "${cfg.database.type}" = "sqlite" ] && [ ! -f "${cfg.dataDir}/frontpage.db" ]; then
          echo "Initializing SQLite database..."
          ${cfg.package}/bin/frontpage db:migrate
        fi
        
        # Start the application
        exec ${cfg.package}/bin/frontpage start
      '';
    };
    
    # Open firewall port if needed
    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.port < 1024) [ cfg.port ];
  };
}