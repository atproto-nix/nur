# Example: Tangled with Custom Endpoints Configuration
# This example shows comprehensive deployment scenarios for Tangled services
# with custom endpoints instead of the default tangled.org/tangled.sh references

{ config, lib, pkgs, ... }:

{
  # Import the Tangled deployment profile
  imports = [
    ../profiles/tangled-deployment.nix
  ];

  # Example 1: Distributed deployment with custom endpoints
  services.tangled-deployment = {
    profile = "distributed";
    domain = "my-tangled.example.com";
    owner = "did:plc:your-did-here";

    # Custom endpoint configuration for distributed services
    endpoints = {
      appview = "https://forge.example.com";
      knot = "https://git.example.com";
      jetstream = "wss://events.example.com";
      nixery = "https://containers.example.com";
      # Enhanced ATProto integration
      atproto = "https://atproto.example.com";
      plc = "https://plc.example.com";
    };

    # Enable specific services for this node
    enableServices = {
      appview = true;
      knot = true;
      spindle = true;
    };

    # Network configuration
    networking = {
      enableTLS = true;
      enableFirewall = true;
      customPorts = {
        appview = 8080;
        knot = 8081;
        spindle = 8082;
      };
    };
  };

  # Example 2: Development profile with local endpoints
  # services.tangled-deployment = {
  #   profile = "development";
  #   domain = "localhost";
  #   owner = "did:plc:development-did";
  #   
  #   endpoints = {
  #     appview = "http://localhost:3000";
  #     knot = "http://localhost:5555";
  #     jetstream = "ws://localhost:6666";
  #     nixery = "http://localhost:7777";
  #   };
  #   
  #   enableServices = {
  #     appview = true;
  #     knot = true;
  #     spindle = false; # Disable CI/CD in development
  #   };
  # };

  # Example 3: Production profile with enhanced security
  # services.tangled-deployment = {
  #   profile = "production";
  #   domain = "tangled.mycompany.com";
  #   owner = "did:plc:production-company-did";
  #   
  #   endpoints = {
  #     appview = "https://code.mycompany.com";
  #     knot = "https://git.mycompany.com";
  #     jetstream = "wss://events.mycompany.com";
  #     nixery = "https://registry.mycompany.com";
  #     atproto = "https://atproto.mycompany.com";
  #     plc = "https://identity.mycompany.com";
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

  # Example 4: Custom profile with manual configuration
  # services.tangled-deployment = {
  #   profile = "custom";
  #   domain = "custom.example.com";
  #   owner = "did:plc:custom-deployment-did";
  #   
  #   endpoints = {
  #     appview = "https://custom-forge.example.com";
  #     knot = "https://custom-git.example.com:9443";
  #     jetstream = "wss://custom-events.example.com:9444";
  #     nixery = "https://custom-registry.example.com:9445";
  #   };
  #   
  #   enableServices = {
  #     appview = true;
  #     knot = true;
  #     spindle = true;
  #   };
  #   
  #   networking = {
  #     enableTLS = false; # Custom TLS termination
  #     enableFirewall = false; # Custom firewall rules
  #     customPorts = {
  #       appview = 9000;
  #       knot = 9001;
  #       spindle = 9002;
  #     };
  #   };
  # };

  # Alternative: Manual service configuration with enhanced endpoints
  # This approach gives you complete control over individual service configuration
  # services.tangled-dev.knot = {
  #   enable = true;
  #   server = {
  #     hostname = "git.example.com";
  #     owner = "did:plc:your-did-here";
  #     listenAddr = "0.0.0.0:443";
  #     dev = false;
  #   };
  #   endpoints = {
  #     appview = "https://forge.example.com";
  #     jetstream = "wss://events.example.com";
  #     nixery = "https://containers.example.com";
  #   };
  #   openFirewall = true;
  # };

  # services.tangled-dev.appview = {
  #   enable = true;
  #   host = "0.0.0.0";
  #   port = 443;
  #   endpoints = {
  #     knot = "https://git.example.com";
  #     jetstream = "wss://events.example.com";
  #     nixery = "https://containers.example.com";
  #   };
  #   openFirewall = true;
  #   environmentFile = "/etc/tangled/appview.env";
  # };

  # services.tangled-dev.spindle = {
  #   enable = true;
  #   server = {
  #     hostname = "ci.example.com";
  #     owner = "did:plc:your-did-here";
  #     listenAddr = "0.0.0.0:443";
  #     dev = false;
  #     secrets.provider = "openbao";
  #   };
  #   endpoints = {
  #     appview = "https://forge.example.com";
  #     knot = "https://git.example.com";
  #     jetstream = "wss://events.example.com";
  #     nixery = "https://containers.example.com";
  #   };
  #   openFirewall = true;
  # };
}