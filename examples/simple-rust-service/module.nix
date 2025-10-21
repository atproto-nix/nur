# Example: NixOS Module for Simple ATProto Service
# This demonstrates best practices for ATProto service modules

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.simple-atproto-service;
  
  # Configuration file generation
  configFile = pkgs.writeText "simple-service-config.json" (builtins.toJSON {
    port = cfg.settings.port;
    host = cfg.settings.host;
    log_level = cfg.settings.logLevel;
    database_url = cfg.settings.database.url;
  });
  
  # Service startup script
  startScript = pkgs.writeShellScript "simple-service-start" ''
    set -euo pipefail
    
    # Ensure data directory exists and has correct permissions
    mkdir -p ${cfg.dataDir}
    chown ${cfg.user}:${cfg.group} ${cfg.dataDir}
    chmod 750 ${cfg.dataDir}
    
    # Start the service
    exec ${cfg.package}/bin/simple-service \
      --port ${toString cfg.settings.port} \
      --host ${cfg.settings.host} \
      --log-level ${cfg.settings.logLevel}
  '';

in {
  options.services.simple-atproto-service = {
    enable = mkEnableOption (lib.mdDoc "Simple ATProto service example");
    
    package = mkOption {
      type = types.package;
      default = pkgs.nur.repos.atproto.simple-atproto-service or pkgs.simple-atproto-service;
      defaultText = literalExpression "pkgs.simple-atproto-service";
      description = lib.mdDoc "Package to use for the simple ATProto service.";
    };
    
    user = mkOption {
      type = types.str;
      default = "simple-atproto";
      description = lib.mdDoc "User account under which the service runs.";
    };
    
    group = mkOption {
      type = types.str;
      default = "simple-atproto";
      description = lib.mdDoc "Group under which the service runs.";
    };
    
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/simple-atproto-service";
      description = lib.mdDoc "Directory where the service stores its data.";
    };
    
    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 8080;
            description = lib.mdDoc ''
              Port on which the service listens for HTTP requests.
              
              Note: Ports below 1024 require additional system privileges.
            '';
            example = 3000;
          };
          
          host = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = lib.mdDoc ''
              Host address to bind to.
              
              - `127.0.0.1`: Local access only (recommended for development)
              - `0.0.0.0`: Accept connections from any address (production with firewall)
            '';
            example = "0.0.0.0";
          };
          
          logLevel = mkOption {
            type = types.enum [ "trace" "debug" "info" "warn" "error" ];
            default = "info";
            description = lib.mdDoc ''
              Logging level for the service.
              
              - `trace`: Very verbose debugging (not recommended for production)
              - `debug`: Debugging information
              - `info`: General information (recommended for production)
              - `warn`: Warning messages only
              - `error`: Error messages only
            '';
          };
          
          database = mkOption {
            type = types.submodule {
              options = {
                url = mkOption {
                  type = types.str;
                  default = "sqlite://${cfg.dataDir}/simple-service.db";
                  defaultText = literalExpression ''"sqlite://$${cfg.dataDir}/simple-service.db"'';
                  description = lib.mdDoc ''
                    Database connection URL.
                    
                    Supported formats:
                    - SQLite: `sqlite:///path/to/database.db`
                    - PostgreSQL: `postgresql://user:pass@host:port/dbname`
                  '';
                  example = "postgresql://atproto:password@localhost:5432/atproto";
                };
              };
            };
            default = {};
            description = lib.mdDoc "Database configuration options.";
          };
        };
      };
      default = {};
      description = lib.mdDoc "Configuration options for the simple ATProto service.";
    };
    
    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Whether to automatically open the firewall for the service port.
        
        Only enable this if the service needs to be accessible from external networks.
      '';
    };
  };
  
  config = mkIf cfg.enable {
    # Input validation and assertions
    assertions = [
      {
        assertion = cfg.settings.port > 0 && cfg.settings.port < 65536;
        message = "services.simple-atproto-service.settings.port must be a valid port number (1-65535)";
      }
      {
        assertion = cfg.settings.host != "" && cfg.settings.host != null;
        message = "services.simple-atproto-service.settings.host cannot be empty";
      }
      {
        assertion = cfg.dataDir != "" && cfg.dataDir != null;
        message = "services.simple-atproto-service.dataDir cannot be empty";
      }
    ];
    
    # Warnings for potentially problematic configurations
    warnings = lib.optionals (cfg.settings.logLevel == "trace") [
      "Trace logging is enabled for simple-atproto-service - this may impact performance and expose sensitive information"
    ] ++ lib.optionals (cfg.settings.host == "0.0.0.0" && !cfg.openFirewall) [
      "simple-atproto-service is configured to bind to 0.0.0.0 but firewall is not opened - service may not be accessible"
    ];
    
    # User and group management
    users.users = mkIf (cfg.user == "simple-atproto") {
      simple-atproto = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
        description = "Simple ATProto service user";
      };
    };
    
    users.groups = mkIf (cfg.group == "simple-atproto") {
      simple-atproto = {};
    };
    
    # Directory management using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "Z '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ];
    
    # systemd service configuration
    systemd.services.simple-atproto-service = {
      description = "Simple ATProto Service";
      documentation = [ "https://github.com/atproto-nix/nur" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];
      
      # Service configuration
      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = startScript;
        
        # Restart configuration
        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitBurst = 3;
        StartLimitIntervalSec = "60s";
        
        # Security hardening (comprehensive systemd security features)
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
        
        # File system access control
        ReadWritePaths = [ cfg.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
        
        # Capabilities (none needed for this service)
        CapabilityBoundingSet = [ "" ];
        AmbientCapabilities = [ "" ];
        
        # System call filtering
        SystemCallFilter = [ "@system-service" "~@privileged @resources" ];
        SystemCallErrorNumber = "EPERM";
        
        # Process limits
        LimitNOFILE = 65536;
        LimitNPROC = 64;
        
        # Network isolation (can be enabled for internal-only services)
        # PrivateNetwork = true; # Uncomment for network isolation
      };
      
      # Environment variables
      environment = {
        RUST_LOG = cfg.settings.logLevel;
        DATABASE_URL = cfg.settings.database.url;
      };
    };
    
    # Firewall configuration
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.settings.port ];
    
    # Monitoring integration (optional)
    services.prometheus.scrapeConfigs = mkIf (config.services.prometheus.enable or false) [
      {
        job_name = "simple-atproto-service";
        static_configs = [{
          targets = [ "${cfg.settings.host}:${toString cfg.settings.port}" ];
        }];
        metrics_path = "/metrics"; # If the service exposes Prometheus metrics
      }
    ];
  };
  
  # Module metadata for documentation and tooling
  meta = {
    maintainers = with lib.maintainers; [ ]; # Add actual maintainers
    doc = ./module.md; # Link to detailed module documentation
    
    # ATProto-specific module metadata
    atproto = {
      serviceType = "application";
      protocols = [ "com.atproto" ];
      endpoints = [
        "/health"
        "/xrpc/com.atproto.repo.createRecord"
        "/xrpc/com.atproto.repo.getRecord"
      ];
    };
  };
}