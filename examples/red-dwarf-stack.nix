# Example NixOS configuration for deploying Red Dwarf with Constellation and Slingshot
# This demonstrates a complete self-hosted Bluesky client stack
{
  imports = [
    # Import the ATProto NUR modules
    # In practice, you would add atproto-nur as a flake input
  ];

  # Enable Constellation - Global backlink index
  services.microcosm-constellation = {
    enable = true;

    # Jetstream connection
    jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";

    # Use RocksDB for persistent storage (recommended for production)
    backend = "rocks";

    # Data directory
    dataDir = "/var/lib/microcosm-constellation";

    # Enable backups
    backup = {
      enable = true;
      interval = 24; # Backup every 24 hours
      maxOldBackups = 7; # Keep 7 days of backups
    };

    # Logging
    logLevel = "info";

    # Don't open firewall (Constellation is internal-only)
    openFirewall = false;
  };

  # Enable Slingshot - PDS edge cache
  services.microcosm-slingshot = {
    enable = true;

    # Jetstream connection
    jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";

    # Don't request zstd compression (optional)
    jetstreamNoZstd = false;

    # Public domain for TLS
    domain = "slingshot.example.com";

    # ACME contact for Let's Encrypt
    acmeContact = "admin@example.com";

    # Optional healthcheck URL
    healthcheckUrl = null;

    # Data directory
    dataDir = "/var/lib/microcosm-slingshot";

    # Logging
    logLevel = "info";

    # Open firewall for public access
    openFirewall = true;
  };

  # Enable Red Dwarf - Bluesky client
  services.whey-party-red-dwarf = {
    enable = true;

    # Data directory
    dataDir = "/var/lib/red-dwarf";

    # Server configuration
    settings = {
      server = {
        port = 3768;
        hostname = "reddwarf.example.com";

        # OAuth callback URL (REQUIRED)
        publicUrl = "https://reddwarf.example.com";

        # Development URL (optional, for local development)
        devUrl = null;
      };

      # Microcosm integration - use local services
      microcosm = {
        constellation = {
          enable = true;
          # Point to local Constellation instance
          url = "http://localhost:4444"; # Adjust to Constellation's actual port
        };

        slingshot = {
          enable = true;
          # Point to local Slingshot instance
          url = "https://slingshot.example.com";
        };
      };

      # Features
      features = {
        # Disable password auth in production
        passwordAuth = false;

        # Enable custom feeds
        customFeeds = true;
      };

      # UI settings
      ui = {
        theme = "auto"; # "light", "dark", or "auto"
      };
    };

    # Don't open firewall (use nginx reverse proxy)
    openFirewall = false;
  };

  # Nginx reverse proxy for Red Dwarf (recommended)
  services.nginx = {
    enable = true;

    virtualHosts."reddwarf.example.com" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:3768";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          # Security headers
          add_header X-Frame-Options DENY;
          add_header X-Content-Type-Options nosniff;
          add_header X-XSS-Protection "1; mode=block";
          add_header Referrer-Policy strict-origin-when-cross-origin;

          # SPA routing support
          try_files $uri $uri/ /index.html;
        '';
      };
    };
  };

  # ACME (Let's Encrypt) configuration
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
  };

  # Firewall configuration
  networking.firewall = {
    # Allow HTTP and HTTPS for Nginx
    allowedTCPPorts = [ 80 443 ];
  };
}
