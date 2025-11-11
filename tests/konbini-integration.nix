# Integration test for konbini AppView module and frontend
# This demonstrates a complete konbini deployment configuration with all features
#
# Test with: nixos-rebuild build-vm -I nixos-config=./tests/konbini-integration.nix
# Or eval with: nix-instantiate --eval '<nixpkgs/nixos>' -A config.services.whyrusleeping.konbini.enable --arg configuration ./tests/konbini-integration.nix

{ config, pkgs, lib, ... }:

{
  # Import konbini modules
  imports = [
    ../modules/whyrusleeping
  ];

  # Minimal system config for testing
  system.stateVersion = "24.05";
  boot.loader.grub.enable = false;
  fileSystems."/" = { device = "/dev/null"; };

  # Konbini backend configuration
  services.whyrusleeping.konbini = {
    enable = true;

    # Port configuration (note: ports are hardcoded in the application)
    # These options control firewall rules and reverse proxy configuration
    apiPort = 4444;
    xrpcPort = 4446;
    pprofPort = 4445;
    pprofEnable = false; # Disabled by default for security

    # Network and hostname configuration
    hostname = "konbini.example.com";

    # Database setup (creates local PostgreSQL automatically)
    database = {
      createLocally = true;
      url = "postgresql://konbini@localhost/konbini";
    };

    # Bluesky credentials (file-based for security)
    bluesky = {
      handleFile = "/run/secrets/konbini-handle";
      passwordFile = "/run/secrets/konbini-password";
    };

    # Sync backend configuration (default: bsky.network firehose)
    syncConfig = {
      backends = [
        {
          type = "firehose";
          host = "bsky.network";
        }
      ];
    };

    # Performance tuning (optional)
    maxDatabaseConnections = 0; # 0 = auto (CPU count)

    # Redis caching (optional, improves performance)
    redis = {
      enable = false; # Set to true if Redis is available
      url = "redis://localhost:6379";
    };

    # Observability (optional)
    observability = {
      jaeger = false; # Set to true to enable Jaeger tracing
      environment = "production";
    };

    # Additional environment variables
    extraEnv = {
      LOG_LEVEL = "info";
    };

    # Open firewall for API and XRPC ports
    openFirewall = true;
  };

  # Konbini frontend configuration (optional)
  services.whyrusleeping.konbini-frontend = {
    enable = true;

    # Frontend web server port
    port = 3000;

    # Optional: Virtual host configuration
    domain = "konbini.example.com";

    # Backend API URL (should match the apiPort)
    backendUrl = "http://localhost:${toString config.services.whyrusleeping.konbini.apiPort}";

    # Optional: Enable SSL/TLS (requires acme configuration)
    enableSSL = false;

    # Open firewall for frontend port
    openFirewall = true;
  };

  # ADVANCED EXAMPLES:

  # Example: Using jetstream instead of firehose (lower bandwidth)
  # services.whyrusleeping.konbini.syncConfig = {
  #   backends = [
  #     {
  #       type = "jetstream";
  #       host = "jetstream1.us-west.bsky.network";
  #     }
  #   ];
  # };

  # Example: Multiple backends (main relay + specific PDSs)
  # services.whyrusleeping.konbini.syncConfig = {
  #   backends = [
  #     {
  #       type = "firehose";
  #       host = "bsky.network";
  #     }
  #     {
  #       type = "firehose";
  #       host = "my-pds.example.com";
  #     }
  #   ];
  # };

  # Example: Using environmentFile for all configuration
  # services.whyrusleeping.konbini = {
  #   enable = true;
  #   environmentFile = "/run/secrets/konbini-env";
  # };
  #
  # Where /run/secrets/konbini-env contains:
  # DATABASE_URL=postgresql://konbini:password@localhost:5432/konbini
  # BSKY_HANDLE=user.bsky.social
  # BSKY_PASSWORD=app-password-here
  # LOG_LEVEL=debug

  # Example: Enable Redis caching (requires Redis to be running)
  # services.whyrusleeping.konbini.redis = {
  #   enable = true;
  #   url = "redis://localhost:6379";
  # };

  # Example: Enable Jaeger tracing for observability
  # services.whyrusleeping.konbini.observability = {
  #   jaeger = true;
  #   environment = "development";
  # };

  # Example: Disable frontend and use external reverse proxy instead
  # services.whyrusleeping.konbini-frontend.enable = false;

  # Example: Frontend on custom domain with SSL
  # services.whyrusleeping.konbini-frontend = {
  #   enable = true;
  #   port = 443;
  #   domain = "my-appview.example.com";
  #   enableSSL = true;
  # };
  # # Note: Requires ACME certificate setup in nixos configuration

  # Example: Using XRPC endpoint with official Bluesky app
  # Set up a did:web service with:
  #   service: "atproto_pds"
  #   type: "AtprotoPubService"
  #   endpoint: "http://konbini.example.com:4446"
}
