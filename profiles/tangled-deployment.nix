# Tangled Deployment Profiles
# Common deployment configurations for Tangled git forge with configurable endpoints

{ config, lib, pkgs, ... }:

with lib;

{
  options.services.tangled-deployment = {
    profile = mkOption {
      type = types.enum [ "standalone" "distributed" "development" "production" "custom" ];
      default = "standalone";
      description = ''
        Deployment profile for Tangled services.
        
        - standalone: All services on one machine with default endpoints
        - distributed: Services on separate machines with custom endpoints
        - development: Development configuration with relaxed security
        - production: Production configuration with enhanced security
        - custom: Custom configuration with manual endpoint specification
      '';
    };

    domain = mkOption {
      type = types.str;
      example = "tangled.example.com";
      description = "Base domain for Tangled services";
    };

    endpoints = mkOption {
      type = types.submodule {
        options = {
          appview = mkOption {
            type = types.str;
            default = if config.services.tangled-deployment.domain != "" 
                     then "https://${config.services.tangled-deployment.domain}"
                     else "https://tangled.org";
            defaultText = "https://\${config.services.tangled-deployment.domain} or https://tangled.org";
            description = "AppView endpoint URL for web interface";
            example = "https://forge.example.com";
          };

          knot = mkOption {
            type = types.str;
            default = if config.services.tangled-deployment.domain != ""
                     then "https://git.${config.services.tangled-deployment.domain}"
                     else "https://git.tangled.sh";
            defaultText = "https://git.\${config.services.tangled-deployment.domain} or https://git.tangled.sh";
            description = "Knot git server endpoint URL";
            example = "https://git.example.com";
          };

          jetstream = mkOption {
            type = types.str;
            default = if config.services.tangled-deployment.domain != ""
                     then "wss://jetstream.${config.services.tangled-deployment.domain}"
                     else "wss://jetstream.tangled.sh";
            defaultText = "wss://jetstream.\${config.services.tangled-deployment.domain} or wss://jetstream.tangled.sh";
            description = "Jetstream WebSocket endpoint URL for real-time events";
            example = "wss://events.example.com";
          };

          nixery = mkOption {
            type = types.str;
            default = if config.services.tangled-deployment.domain != ""
                     then "https://nixery.${config.services.tangled-deployment.domain}"
                     else "https://nixery.tangled.sh";
            defaultText = "https://nixery.\${config.services.tangled-deployment.domain} or https://nixery.tangled.sh";
            description = "Nixery container registry endpoint URL";
            example = "https://containers.example.com";
          };

          # Additional configurable endpoints for enhanced integration
          atproto = mkOption {
            type = types.str;
            default = "https://bsky.social";
            description = "Primary ATProto network endpoint";
            example = "https://my-atproto.example.com";
          };

          plc = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "PLC directory endpoint for DID resolution";
            example = "https://plc.example.com";
          };
        };
      };
      default = {};
      description = "Service endpoints configuration with enhanced ATProto integration";
    };

    owner = mkOption {
      type = types.str;
      example = "did:plc:qfpnj4og54vl56wngdriaxug";
      description = "DID of the deployment owner (required for all profiles)";
    };

    enableServices = mkOption {
      type = types.submodule {
        options = {
          appview = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Tangled AppView web interface service";
          };

          knot = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Tangled Knot git server service";
          };

          spindle = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Tangled Spindle CI/CD and event processing service";
          };
        };
      };
      default = {};
      description = "Which Tangled services to enable in this deployment";
    };

    networking = mkOption {
      type = types.submodule {
        options = {
          enableTLS = mkOption {
            type = types.bool;
            default = true;
            description = "Enable TLS/SSL for all services";
          };

          enableFirewall = mkOption {
            type = types.bool;
            default = true;
            description = "Enable firewall rules for Tangled services";
          };

          customPorts = mkOption {
            type = types.submodule {
              options = {
                appview = mkOption {
                  type = types.port;
                  default = 3000;
                  description = "Port for AppView service";
                };

                knot = mkOption {
                  type = types.port;
                  default = 5555;
                  description = "Port for Knot git server";
                };

                spindle = mkOption {
                  type = types.port;
                  default = 6555;
                  description = "Port for Spindle CI/CD service";
                };
              };
            };
            default = {};
            description = "Custom port configuration for services";
          };
        };
      };
      default = {};
      description = "Network configuration options";
    };
  };

  config = let
    cfg = config.services.tangled-deployment;
    
    # Profile-specific configurations
    standaloneConfig = {
      # All services on localhost with default ports
      services.tangled-dev.appview = mkIf cfg.enableServices.appview {
        enable = true;
        host = "0.0.0.0";
        port = 3000;
        endpoints = cfg.endpoints;
        openFirewall = true;
      };

      services.tangled-dev.knot = mkIf cfg.enableServices.knot {
        enable = true;
        server = {
          hostname = cfg.domain;
          owner = cfg.owner;
          listenAddr = "0.0.0.0:5555";
        };
        endpoints = cfg.endpoints;
        openFirewall = true;
      };

      services.tangled-dev.spindle = mkIf cfg.enableServices.spindle {
        enable = true;
        server = {
          hostname = "spindle.${cfg.domain}";
          owner = cfg.owner;
          listenAddr = "0.0.0.0:6555";
        };
        endpoints = cfg.endpoints;
        openFirewall = true;
      };
    };

    distributedConfig = {
      # Services configured for distributed deployment
      services.tangled-dev.appview = mkIf cfg.enableServices.appview {
        enable = true;
        host = "0.0.0.0";
        port = 80;
        endpoints = cfg.endpoints;
        openFirewall = true;
      };

      services.tangled-dev.knot = mkIf cfg.enableServices.knot {
        enable = true;
        server = {
          hostname = cfg.domain;
          owner = cfg.owner;
          listenAddr = "0.0.0.0:80";
        };
        endpoints = cfg.endpoints;
        openFirewall = true;
      };

      services.tangled-dev.spindle = mkIf cfg.enableServices.spindle {
        enable = true;
        server = {
          hostname = "spindle.${cfg.domain}";
          owner = cfg.owner;
          listenAddr = "0.0.0.0:80";
        };
        endpoints = cfg.endpoints;
        openFirewall = true;
      };
    };

    developmentConfig = {
      # Development configuration with relaxed security
      services.tangled-dev.appview = mkIf cfg.enableServices.appview {
        enable = true;
        host = "127.0.0.1";
        port = 3000;
        endpoints = cfg.endpoints;
        cookieSecret = "development-secret-not-secure";
      };

      services.tangled-dev.knot = mkIf cfg.enableServices.knot {
        enable = true;
        server = {
          hostname = cfg.domain;
          owner = cfg.owner;
          listenAddr = "127.0.0.1:5555";
          dev = true; # Disable signature verification
        };
        endpoints = cfg.endpoints;
      };

      services.tangled-dev.spindle = mkIf cfg.enableServices.spindle {
        enable = true;
        server = {
          hostname = "localhost";
          owner = cfg.owner;
          listenAddr = "127.0.0.1:6555";
          dev = true;
        };
        endpoints = cfg.endpoints;
      };
    };

    productionConfig = {
      # Production configuration with enhanced security
      services.tangled-dev.appview = mkIf cfg.enableServices.appview {
        enable = true;
        host = "0.0.0.0";
        port = if cfg.networking.enableTLS then 443 else cfg.networking.customPorts.appview;
        endpoints = cfg.endpoints;
        openFirewall = cfg.networking.enableFirewall;
        environmentFile = "/etc/tangled/appview.env"; # For secure cookie secret
      };

      services.tangled-dev.knot = mkIf cfg.enableServices.knot {
        enable = true;
        server = {
          hostname = cfg.domain;
          owner = cfg.owner;
          listenAddr = "0.0.0.0:${toString (if cfg.networking.enableTLS then 443 else cfg.networking.customPorts.knot)}";
          dev = false;
        };
        endpoints = cfg.endpoints;
        openFirewall = cfg.networking.enableFirewall;
      };

      services.tangled-dev.spindle = mkIf cfg.enableServices.spindle {
        enable = true;
        server = {
          hostname = "spindle.${cfg.domain}";
          owner = cfg.owner;
          listenAddr = "0.0.0.0:${toString (if cfg.networking.enableTLS then 443 else cfg.networking.customPorts.spindle)}";
          dev = false;
          secrets.provider = "openbao"; # Use secure secret management
        };
        endpoints = cfg.endpoints;
        openFirewall = cfg.networking.enableFirewall;
      };

      # Production security enhancements
      security.acme = mkIf cfg.networking.enableTLS {
        acceptTerms = true;
        defaults.email = "admin@${cfg.domain}";
      };

      services.nginx = mkIf cfg.networking.enableTLS {
        enable = true;
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;
        recommendedProxySettings = true;
      };
    };

    customConfig = {
      # Custom configuration with manual endpoint specification
      services.tangled-dev.appview = mkIf cfg.enableServices.appview {
        enable = true;
        host = "0.0.0.0";
        port = cfg.networking.customPorts.appview;
        endpoints = cfg.endpoints;
        openFirewall = cfg.networking.enableFirewall;
      };

      services.tangled-dev.knot = mkIf cfg.enableServices.knot {
        enable = true;
        server = {
          hostname = cfg.domain;
          owner = cfg.owner;
          listenAddr = "0.0.0.0:${toString cfg.networking.customPorts.knot}";
          dev = false;
        };
        endpoints = cfg.endpoints;
        openFirewall = cfg.networking.enableFirewall;
      };

      services.tangled-dev.spindle = mkIf cfg.enableServices.spindle {
        enable = true;
        server = {
          hostname = "spindle.${cfg.domain}";
          owner = cfg.owner;
          listenAddr = "0.0.0.0:${toString cfg.networking.customPorts.spindle}";
          dev = false;
        };
        endpoints = cfg.endpoints;
        openFirewall = cfg.networking.enableFirewall;
      };
    };

  in mkMerge [
    # Common configuration for all profiles
    {
      assertions = [
        {
          assertion = cfg.domain != "";
          message = "services.tangled-deployment.domain must be set";
        }
        {
          assertion = cfg.owner != "";
          message = "services.tangled-deployment.owner must be set";
        }
      ];

      # Ensure git is available for all profiles
      environment.systemPackages = [ pkgs.git ];
    }

    # Profile-specific configurations
    (mkIf (cfg.profile == "standalone") standaloneConfig)
    (mkIf (cfg.profile == "distributed") distributedConfig)
    (mkIf (cfg.profile == "development") developmentConfig)
    (mkIf (cfg.profile == "production") productionConfig)
    (mkIf (cfg.profile == "custom") customConfig)
  ];
}