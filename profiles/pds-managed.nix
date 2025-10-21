# Managed PDS deployment profile
# Provides PDS with dashboard and gatekeeper for enhanced security and management
{ config, lib, pkgs, ... }:

with lib;

{
  options.profiles.pds-managed = {
    enable = mkEnableOption "Managed PDS deployment profile with security features";
    
    hostname = mkOption {
      type = types.str;
      example = "pds.example.com";
      description = "Hostname for the PDS service";
    };
    
    dataDirectory = mkOption {
      type = types.path;
      default = "/var/lib/pds";
      description = "Data directory for PDS storage";
    };
    
    dashboard = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable the PDS dashboard";
      };
      
      port = mkOption {
        type = types.port;
        default = 3001;
        description = "Port for the PDS dashboard";
      };
      
      theme = mkOption {
        type = types.str;
        default = "default";
        description = "Dashboard theme to use";
      };
    };
    
    gatekeeper = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable PDS Gatekeeper for enhanced security";
      };
      
      port = mkOption {
        type = types.port;
        default = 8080;
        description = "Port for PDS Gatekeeper";
      };
      
      rateLimiting = {
        createAccountPerSecond = mkOption {
          type = types.nullOr types.ints.positive;
          default = 60;
          description = "Seconds between account creation attempts";
        };
        
        createAccountBurst = mkOption {
          type = types.nullOr types.ints.positive;
          default = 5;
          description = "Maximum burst of account creation requests";
        };
      };
      
      twoFactorEmailSubject = mkOption {
        type = types.str;
        default = "Sign in to ${config.profiles.pds-managed.hostname}";
        description = "Subject line for 2FA emails";
      };
    };
    
    reverseProxy = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to configure reverse proxy integration";
      };
      
      gatekeeperPaths = mkOption {
        type = types.listOf types.str;
        default = [
          "/xrpc/com.atproto.server.getSession"
          "/xrpc/com.atproto.server.updateEmail"
          "/xrpc/com.atproto.server.createSession"
          "/xrpc/com.atproto.server.createAccount"
          "/@atproto/oauth-provider/~api/sign-in"
        ];
        description = "Paths that should be routed through the gatekeeper";
      };
    };
  };
  
  config = mkIf config.profiles.pds-managed.enable {
    # PDS Dashboard configuration
    services.bluesky.pds-dash = mkIf config.profiles.pds-managed.dashboard.enable {
      enable = true;
      settings = {
        pdsUrl = "https://${config.profiles.pds-managed.hostname}";
        host = "127.0.0.1";
        port = config.profiles.pds-managed.dashboard.port;
        theme = config.profiles.pds-managed.dashboard.theme;
        frontendUrl = "https://bsky.app";
        maxPosts = 20;
        footerText = "<a href='https://github.com/witchcraft-systems/pds-dash' target='_blank'>PDS Dashboard</a> | <a href='https://${config.profiles.pds-managed.hostname}' target='_blank'>${config.profiles.pds-managed.hostname}</a>";
        showFuturePosts = false;
        openFirewall = false; # Handled by reverse proxy
      };
    };
    
    # PDS Gatekeeper configuration
    services.bluesky.pds-gatekeeper = mkIf config.profiles.pds-managed.gatekeeper.enable {
      enable = true;
      settings = {
        pdsDataDirectory = config.profiles.pds-managed.dataDirectory;
        pdsEnvLocation = "${config.profiles.pds-managed.dataDirectory}/pds.env";
        pdsBaseUrl = "http://localhost:3000"; # Internal PDS URL
        host = "127.0.0.1";
        port = config.profiles.pds-managed.gatekeeper.port;
        twoFactorEmailSubject = config.profiles.pds-managed.gatekeeper.twoFactorEmailSubject;
        createAccountPerSecond = config.profiles.pds-managed.gatekeeper.rateLimiting.createAccountPerSecond;
        createAccountBurst = config.profiles.pds-managed.gatekeeper.rateLimiting.createAccountBurst;
        openFirewall = false; # Handled by reverse proxy
      };
    };
    
    # Ensure data directory exists with proper permissions
    systemd.tmpfiles.rules = [
      "d '${config.profiles.pds-managed.dataDirectory}' 0755 - - - -"
    ];
    
    # Service dependencies - gatekeeper should start after PDS
    systemd.services.pds-gatekeeper = mkIf config.profiles.pds-managed.gatekeeper.enable {
      after = [ "pds.service" ]; # Assumes future PDS service
      wants = [ "pds.service" ];
    };
    
    # Generate reverse proxy configuration hints
    environment.etc."pds-managed/caddy-config.txt" = mkIf config.profiles.pds-managed.reverseProxy.enable {
      text = ''
        # Caddy configuration for PDS with Gatekeeper
        # Add this to your Caddyfile:
        
        ${config.profiles.pds-managed.hostname} {
            # Gatekeeper paths
            @gatekeeper {
        ${concatMapStringsSep "\n" (path: "        path ${path}") config.profiles.pds-managed.reverseProxy.gatekeeperPaths}
            }
            
            handle @gatekeeper {
                reverse_proxy http://localhost:${toString config.profiles.pds-managed.gatekeeper.port}
            }
            
            # Dashboard (optional, can be on subdomain)
            handle /dashboard* {
                reverse_proxy http://localhost:${toString config.profiles.pds-managed.dashboard.port}
            }
            
            # Main PDS
            reverse_proxy http://localhost:3000
        }
        
        # Optional: Dashboard on subdomain
        dashboard.${config.profiles.pds-managed.hostname} {
            reverse_proxy http://localhost:${toString config.profiles.pds-managed.dashboard.port}
        }
      '';
    };
    
    # Generate nginx configuration hints
    environment.etc."pds-managed/nginx-config.txt" = mkIf config.profiles.pds-managed.reverseProxy.enable {
      text = ''
        # Nginx configuration for PDS with Gatekeeper
        # Add this to your nginx configuration:
        
        server {
            listen 443 ssl http2;
            server_name ${config.profiles.pds-managed.hostname};
            
            # SSL configuration (add your certificates)
            # ssl_certificate /path/to/cert.pem;
            # ssl_certificate_key /path/to/key.pem;
            
            # Gatekeeper paths
        ${concatMapStringsSep "\n" (path: "    location ${path} {") config.profiles.pds-managed.reverseProxy.gatekeeperPaths}
                proxy_pass http://localhost:${toString config.profiles.pds-managed.gatekeeper.port};
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }
        ${concatMapStringsSep "\n" (path: "") config.profiles.pds-managed.reverseProxy.gatekeeperPaths}
            
            # Dashboard (optional)
            location /dashboard {
                proxy_pass http://localhost:${toString config.profiles.pds-managed.dashboard.port};
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }
            
            # Main PDS
            location / {
                proxy_pass http://localhost:3000;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }
        }
        
        # Optional: Dashboard on subdomain
        server {
            listen 443 ssl http2;
            server_name dashboard.${config.profiles.pds-managed.hostname};
            
            location / {
                proxy_pass http://localhost:${toString config.profiles.pds-managed.dashboard.port};
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
            }
        }
      '';
    };
  };
}