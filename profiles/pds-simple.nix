# Simple PDS deployment profile
# Provides a basic PDS setup with minimal management tools
{ config, lib, pkgs, ... }:

with lib;

{
  options.profiles.pds-simple = {
    enable = mkEnableOption "Simple PDS deployment profile";
    
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
    
    enableDashboard = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable the PDS dashboard";
    };
    
    dashboardPort = mkOption {
      type = types.port;
      default = 3001;
      description = "Port for the PDS dashboard";
    };
  };
  
  config = mkIf config.profiles.pds-simple.enable {
    # Note: This assumes a future services.bluesky.pds module will be implemented
    # For now, we configure the management tools that work with any PDS
    
    services.witchcraft-systems-pds-dash = mkIf config.profiles.pds-simple.enableDashboard {
      enable = true;
      settings = {
        pdsUrl = "https://${config.profiles.pds-simple.hostname}";
        host = "127.0.0.1";
        port = config.profiles.pds-simple.dashboardPort;
        theme = "default";
        frontendUrl = "https://bsky.app";
        maxPosts = 20;
        footerText = "<a href='https://github.com/witchcraft-systems/pds-dash' target='_blank'>PDS Dashboard</a>";
        showFuturePosts = false;
        openFirewall = false; # Assume reverse proxy handles external access
      };
    };
    
    # Basic firewall configuration
    networking.firewall = {
      # PDS typically runs on port 3000, dashboard on configured port
      # In production, these should be behind a reverse proxy
      allowedTCPPorts = mkIf config.profiles.pds-simple.enableDashboard [ 
        config.profiles.pds-simple.dashboardPort 
      ];
    };
    
    # Ensure data directory exists
    systemd.tmpfiles.rules = [
      "d '${config.profiles.pds-simple.dataDirectory}' 0755 - - - -"
    ];
  };
}