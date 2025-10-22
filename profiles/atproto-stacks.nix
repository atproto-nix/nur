# ATproto Stack Deployment Profiles
# Unified deployment profiles for common ATproto service combinations
{ config, lib, pkgs, ... }:

with lib;

let
  serviceDiscovery = import ../lib/service-discovery.nix { inherit lib pkgs; };
in

{
  options.services.atproto-stacks = {
    profile = mkOption {
      type = types.enum [ "simple-pds" "full-node" "dev-cluster" "prod-cluster" "custom" ];
      default = "simple-pds";
      description = ''
        ATproto deployment profile to use.
        
        - simple-pds: Single PDS with basic services
        - full-node: Complete ATproto network node
        - dev-cluster: Development cluster with relaxed security
        - prod-cluster: Production cluster with enhanced security
        - custom: Custom configuration
      '';
    };

    domain = mkOption {
      type = types.str;
      example = "atproto.example.com";
      description = "Base domain for ATproto services";
    };

    discovery = mkOption {
      type = types.submodule {
        options = {
          backend = mkOption {
            type = types.enum [ "consul" "etcd" "dns" "file" "env" ];
            default = "file";
            description = "Service discovery backend to use";
          };

          consulAddress = mkOption {
            type = types.str;
            default = "127.0.0.1:8500";
            description = "Consul server address";
          };

          etcdEndpoints = mkOption {
            type = types.listOf types.str;
            default = [ "127.0.0.1:2379" ];
            description = "etcd server endpoints";
          };
        };
      };
      default = {};
      description = "Service discovery configuration";
    };

    coordination = mkOption {
      type = types.submodule {
        options = {
          strategy = mkOption {
            type = types.enum [ "leader-follower" "peer-to-peer" "hub-spoke" "mesh" ];
            default = "hub-spoke";
            description = "Service coordination strategy";
          };

          enableHealthChecks = mkOption {
            type = types.bool;
            default = true;
            description = "Enable automatic health checks";
          };

          dependencyTimeout = mkOption {
            type = types.int;
            default = 30;
            description = "Timeout for dependency health checks";
          };
        };
      };
      default = {};
      description = "Service coordination configuration";
    };
  };  
config = let
    cfg = config.services.atproto-stacks;
    
    # Create service discovery configuration
    discoveryConfig = serviceDiscovery.mkServiceDiscovery {
      backend = cfg.discovery.backend;
      consulAddress = cfg.discovery.consulAddress;
      etcdEndpoints = cfg.discovery.etcdEndpoints;
    };
    
    # Create coordination configuration
    coordinationConfig = serviceDiscovery.mkServiceCoordination {
      strategy = cfg.coordination.strategy;
    };
    
    # Profile configurations
    profileConfigs = {
      simple-pds = serviceDiscovery.deploymentProfiles.simplePDS;
      full-node = serviceDiscovery.deploymentProfiles.fullNode;
      dev-cluster = serviceDiscovery.deploymentProfiles.devCluster;
      prod-cluster = serviceDiscovery.deploymentProfiles.prodCluster;
    };
    
    selectedProfile = profileConfigs.${cfg.profile} or null;
    
  in mkIf (selectedProfile != null) (mkMerge [
    # Apply the selected profile configuration
    (selectedProfile.toNixOSConfig)
    
    # Common configuration for all profiles
    {
      assertions = [
        {
          assertion = cfg.domain != "";
          message = "services.atproto-stacks.domain must be set";
        }
        {
          assertion = selectedProfile.validate.valid;
          message = "Profile validation failed: ${builtins.toString selectedProfile.validate.errors}";
        }
      ];

      # Service discovery system packages
      environment.systemPackages = 
        (if cfg.discovery.backend == "consul" then [ pkgs.consul ] else []) ++
        (if cfg.discovery.backend == "etcd" then [ pkgs.etcd ] else []);

      # Generate service discovery configuration files
      environment.etc = mkMerge (mapAttrsToList (serviceName: serviceConfig:
        let
          discoveryFile = serviceDiscovery.generateDiscoveryConfig 
            discoveryConfig serviceName serviceConfig;
        in
        if cfg.discovery.backend == "file" then {
          "atproto/discovery/${serviceName}.json" = {
            text = builtins.toJSON discoveryFile;
            mode = "0644";
          };
        } else {}
      ) selectedProfile.services);

      # Coordination scripts for each service
      systemd.services = mkMerge (mapAttrsToList (serviceName: serviceConfig:
        let
          coordinationScript = serviceDiscovery.generateCoordinationScript 
            coordinationConfig serviceName;
        in
        {
          "atproto-${serviceName}-coordinator" = mkIf cfg.coordination.enableHealthChecks {
            description = "ATproto ${serviceName} service coordinator";
            wantedBy = [ "atproto-${serviceName}.service" ];
            before = [ "atproto-${serviceName}.service" ];
            
            serviceConfig = {
              Type = "oneshot";
              ExecStart = pkgs.writeScript "coordinate-${serviceName}" coordinationScript;
              TimeoutStartSec = cfg.coordination.dependencyTimeout;
            };
          };
        }
      ) selectedProfile.services);
    }
  ]);
}