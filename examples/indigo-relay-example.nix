# Example NixOS configuration for deploying Bluesky's Indigo Relay
# Indigo Relay is a service that relays information from the AT Protocol network
# and provides data to clients and other services
{
  imports = [
    # Import the ATProto NUR modules
    # In practice, you would add atproto-nur as a flake input
  ];

  # PostgreSQL database (required for Indigo Relay)
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;

    # Initialize database for Indigo Relay
    initialScript = pkgs.writeText "init.sql" ''
      CREATE USER relay WITH PASSWORD 'relay-password';
      CREATE DATABASE relay OWNER relay;
      GRANT ALL PRIVILEGES ON DATABASE relay TO relay;
    '';
  };

  # Enable Indigo Relay
  services.bluesky-indigo-relay = {
    enable = true;

    # User and group for the service
    user = "indigo-relay";
    group = "indigo-relay";

    # Data directory
    dataDir = "/var/lib/indigo-relay";

    # Service configuration
    settings = {
      # Basic settings
      hostname = "relay.example.com";  # REQUIRED: Your relay's hostname
      port = 2470;
      logLevel = "info";  # debug, info, warn, error

      # Database configuration (REQUIRED)
      database = {
        url = "postgres://relay:relay-password@localhost:5432/relay";
        # Alternatively, load password from file for security:
        # passwordFile = "/run/secrets/relay-db-password";
      };

      # AT Protocol directory services
      plcHost = "https://plc.directory";  # PLC (Public Ledger of Certificates) directory
      bgsHost = null;  # Optional: Big Graph Service host (null to use default)

      # Admin password (REQUIRED - choose one method)
      adminPassword = "change-me-to-secure-password";
      # OR use a file for better security:
      # adminPasswordFile = "/run/secrets/relay-admin-password";

      # Optional: Enable Prometheus metrics endpoint
      metrics = {
        enable = true;
        port = 2471;
      };

      # Optional: Enable rate limiting
      rateLimit = {
        enable = true;
        requestsPerMinute = 100;  # Requests per minute per IP
      };
    };

    # Open firewall for the relay service
    openFirewall = true;
  };

  # Nginx reverse proxy (recommended for production)
  services.nginx = {
    enable = true;

    virtualHosts."relay.example.com" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:2470";
        proxyWebsockets = true;
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
        '';
      };

      # Optional: Metrics endpoint (restrict to trusted IPs in production)
      locations."/metrics" = {
        proxyPass = "http://127.0.0.1:2471";
        extraConfig = ''
          # Restrict metrics to localhost or specific IPs
          allow 127.0.0.1;
          allow ::1;
          deny all;
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

    # Indigo Relay firewall is opened by the service configuration
    # But if you disable the service's openFirewall, add manually:
    # allowedTCPPorts = [ 2470 ];
  };

  # System user accounts (created automatically, but shown here for reference)
  # users.users.indigo-relay = {
  #   isSystemUser = true;
  #   group = "indigo-relay";
  #   home = "/var/lib/indigo-relay";
  # };
  #
  # users.groups.indigo-relay = {};

  # Logging configuration (optional)
  services.rsyslog = {
    enable = true;
  };

  # Monitoring (optional - if using Prometheus)
  # services.prometheus = {
  #   enable = true;
  #   scrapeConfigs = [
  #     {
  #       job_name = "indigo-relay";
  #       static_configs = [
  #         { targets = [ "localhost:2471" ]; }
  #       ];
  #       scrape_interval = "15s";
  #     }
  #   ];
  # };
}
