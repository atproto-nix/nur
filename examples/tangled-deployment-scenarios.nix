# Tangled Deployment Scenarios
# Comprehensive examples for different Tangled deployment configurations
# This file demonstrates various ways to deploy Tangled services with custom endpoints

{ config, lib, pkgs, ... }:

{
  # Import the Tangled deployment profile
  imports = [
    ../profiles/tangled-deployment.nix
  ];

  # Scenario 1: Single-node development setup
  # Perfect for local development and testing
  # services.tangled-deployment = {
  #   profile = "development";
  #   domain = "localhost";
  #   owner = "did:plc:development-test-did";
  #   
  #   endpoints = {
  #     appview = "http://localhost:3000";
  #     knot = "http://localhost:5555";
  #     jetstream = "ws://localhost:6666";
  #     nixery = "http://localhost:7777";
  #     atproto = "https://bsky.social"; # Use public ATProto for development
  #     plc = "https://plc.directory"; # Use public PLC directory
  #   };
  #   
  #   enableServices = {
  #     appview = true;
  #     knot = true;
  #     spindle = false; # Disable CI/CD for simple development
  #   };
  #   
  #   networking = {
  #     enableTLS = false; # HTTP only for development
  #     enableFirewall = false; # No firewall restrictions locally
  #   };
  # };

  # Scenario 2: Small team deployment
  # Suitable for small teams with all services on one server
  # services.tangled-deployment = {
  #   profile = "standalone";
  #   domain = "git.myteam.com";
  #   owner = "did:plc:team-admin-did";
  #   
  #   endpoints = {
  #     appview = "https://git.myteam.com";
  #     knot = "https://git.myteam.com";
  #     jetstream = "wss://git.myteam.com/events";
  #     nixery = "https://git.myteam.com/registry";
  #     atproto = "https://bsky.social";
  #     plc = "https://plc.directory";
  #   };
  #   
  #   enableServices = {
  #     appview = true;
  #     knot = true;
  #     spindle = true;
  #   };
  #   
  #   networking = {
  #     enableTLS = true;
  #     enableFirewall = true;
  #   };
  # };

  # Scenario 3: Enterprise distributed deployment
  # Large-scale deployment with services on separate machines
  services.tangled-deployment = {
    profile = "distributed";
    domain = "forge.enterprise.com";
    owner = "did:plc:enterprise-forge-admin";
    
    endpoints = {
      appview = "https://forge.enterprise.com";
      knot = "https://git.enterprise.com";
      jetstream = "wss://events.enterprise.com";
      nixery = "https://registry.enterprise.com";
      atproto = "https://atproto.enterprise.com"; # Private ATProto network
      plc = "https://identity.enterprise.com"; # Private identity service
    };
    
    enableServices = {
      appview = true;
      knot = false; # Knot runs on separate git.enterprise.com server
      spindle = false; # Spindle runs on separate ci.enterprise.com server
    };
    
    networking = {
      enableTLS = true;
      enableFirewall = true;
      customPorts = {
        appview = 443;
        knot = 443;
        spindle = 443;
      };
    };
  };

  # Scenario 4: High-security production deployment
  # Maximum security configuration for sensitive environments
  # services.tangled-deployment = {
  #   profile = "production";
  #   domain = "secure-forge.gov";
  #   owner = "did:plc:government-forge-admin";
  #   
  #   endpoints = {
  #     appview = "https://secure-forge.gov";
  #     knot = "https://git.secure-forge.gov";
  #     jetstream = "wss://events.secure-forge.gov";
  #     nixery = "https://registry.secure-forge.gov";
  #     atproto = "https://atproto.secure-forge.gov"; # Air-gapped ATProto
  #     plc = "https://identity.secure-forge.gov"; # Private identity service
  #   };
  #   
  #   enableServices = {
  #     appview = true;
  #     knot = true;
  #     spindle = true;
  #   };
  #   
  #   networking = {
  #     enableTLS = true;
  #     enableFirewall = true;
  #   };
  # };

  # Scenario 5: Multi-region deployment with load balancing
  # Custom configuration for complex multi-region setups
  # services.tangled-deployment = {
  #   profile = "custom";
  #   domain = "global-forge.com";
  #   owner = "did:plc:global-forge-admin";
  #   
  #   endpoints = {
  #     appview = "https://forge-us-east.global-forge.com";
  #     knot = "https://git-us-east.global-forge.com";
  #     jetstream = "wss://events-global.global-forge.com";
  #     nixery = "https://registry-us-east.global-forge.com";
  #     atproto = "https://atproto-global.global-forge.com";
  #     plc = "https://identity-global.global-forge.com";
  #   };
  #   
  #   enableServices = {
  #     appview = true;
  #     knot = true;
  #     spindle = false; # Centralized CI/CD in different region
  #   };
  #   
  #   networking = {
  #     enableTLS = true;
  #     enableFirewall = true;
  #     customPorts = {
  #       appview = 8443;
  #       knot = 9443;
  #       spindle = 10443;
  #     };
  #   };
  # };

  # Scenario 6: Hybrid cloud deployment
  # Mix of cloud and on-premises services
  # services.tangled-deployment = {
  #   profile = "custom";
  #   domain = "hybrid-forge.company.com";
  #   owner = "did:plc:hybrid-company-admin";
  #   
  #   endpoints = {
  #     appview = "https://forge.company.com"; # Cloud-hosted web interface
  #     knot = "https://git.internal.company.com"; # On-premises git server
  #     jetstream = "wss://events.company.com"; # Cloud-hosted events
  #     nixery = "https://registry.internal.company.com"; # On-premises registry
  #     atproto = "https://bsky.social"; # Public ATProto network
  #     plc = "https://plc.directory"; # Public PLC directory
  #   };
  #   
  #   enableServices = {
  #     appview = true; # This node hosts the web interface
  #     knot = false; # Git server is on different internal machine
  #     spindle = false; # CI/CD is cloud-hosted separately
  #   };
  #   
  #   networking = {
  #     enableTLS = true;
  #     enableFirewall = true;
  #     customPorts = {
  #       appview = 443;
  #       knot = 22; # Standard SSH port for git
  #       spindle = 443;
  #     };
  #   };
  # };

  # Additional configuration for all scenarios
  environment.systemPackages = with pkgs; [
    git
    curl
    jq # For API testing and debugging
  ];

  # Optional: Enable monitoring and logging
  # services.prometheus.enable = true;
  # services.grafana.enable = true;
  # services.loki.enable = true;
}