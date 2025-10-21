{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.bluesky.frontpage;
in {
  options.services.bluesky.frontpage = {
    enable = mkEnableOption "Bluesky Frontpage web application";
    
    package = mkOption {
      type = types.package;
      default = pkgs.nur.repos.atproto.bluesky-frontpage;
      description = "Frontpage package to use";
    };
    
    user = mkOption {
      type = types.str;
      default = "bluesky-frontpage";
      description = "User account for Frontpage service";
    };
    
    group = mkOption {
      type = types.str;
      default = "bluesky-frontpage";
      description = "Group for Frontpage service";
    };
    
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/bluesky-frontpage";
      description = "Data directory for Frontpage service";
    };
    
    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 3000;
            description = "Port for Frontpage web server";
          };
          
          hostname = mkOption {
            type = types.str;
            default = "localhost";
            description = "Hostname for Frontpage service";
          };
          
          nodeEnv = mkOption {
            type = types.enum [ "development" "production" ];
            default = "production";
            description = "Node.js environment";
          };
          
          database = {
            type = mkOption {
              type = types.enum [ "sqlite" "libsql" ];
              default = "sqlite";
              description = "Database backend type";
            };
            
            url = mkOption {
              type = types.str;
              default = "file:${cfg.dataDir}/frontpage.db";
              description = "Database connection URL";
            };
            
            authToken = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Database authentication token (for libsql)";
            };
          };
          
          oauth = {
            clientId = mkOption {
              type = types.str;
              description = "OAuth client ID";
            };
            
            clientSecret = mkOption {
              type = types.str;
              description = "OAuth client secret";
            };
            
            redirectUri = mkOption {
              type = types.str;
              description = "OAuth redirect URI";
            };
          };
          
          nextAuth = {
            secret = mkOption {
              type = types.str;
              description = "NextAuth.js secret for session encryption";
            };
            
            url = mkOption {
              type = types.str;
              default = "http://${cfg.settings.hostname}:${toString cfg.settings.port}";
              description = "NextAuth.js URL";
            };
          };
        };
      };
      default = {};
      description = "Frontpage service configuration";
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
    systemd.services.bluesky-frontpage = {
      description = "Bluesky Frontpage web application";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      
      environment = {
        NODE_ENV = cfg.settings.nodeEnv;
        PORT = toString cfg.settings.port;
        HOSTNAME = cfg.settings.hostname;
        
        # Database configuration
        DATABASE_URL = cfg.settings.database.url;
        TURSO_AUTH_TOKEN = mkIf (cfg.settings.database.authToken != null) cfg.settings.database.authToken;
        
        # OAuth configuration
        OAUTH_CLIENT_ID = cfg.settings.oauth.clientId;
        OAUTH_CLIENT_SECRET = cfg.settings.oauth.clientSecret;
        OAUTH_REDIRECT_URI = cfg.settings.oauth.redirectUri;
        
        # NextAuth configuration
        NEXTAUTH_SECRET = cfg.settings.nextAuth.secret;
        NEXTAUTH_URL = cfg.settings.nextAuth.url;
      };
      
      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/bluesky-frontpage";
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
    
    # Firewall configuration
    networking.firewall.allowedTCPPorts = mkIf cfg.enable [ cfg.settings.port ];
  };
}