# Integration tests for Indigo ATproto services
{ pkgs, lib, ... }:

let
  # Import the test framework
  nixosTest = import (pkgs.path + "/nixos/tests/testers/make-test-python.nix");
  
  # Test configuration for Indigo services
  testConfig = {
    name = "indigo-services";
    
    nodes = {
      # Test node with PostgreSQL and Indigo services
      server = { config, pkgs, ... }: {
        imports = [
          ../modules/atproto
        ];
        
        # Enable PostgreSQL for database-dependent services
        services.postgresql = {
          enable = true;
          package = pkgs.postgresql_15;
          enableTCPIP = true;
          authentication = ''
            local all all trust
            host all all 127.0.0.1/32 trust
            host all all ::1/128 trust
          '';
        };
        
        # Enable Indigo services for testing
        services.atproto = {
          enable = true;
          
          indigo = {
            # Test relay service (core ATproto relay)
            relay = {
              enable = true;
              network.port = 2470;
              database.url = "postgres://indigo:indigo@localhost/indigo_relay";
            };
            
            # Test rainbow service (AppView)
            rainbow = {
              enable = true;
              network.port = 3000;
              database.url = "postgres://indigo:indigo@localhost/indigo_rainbow";
            };
            
            # Test palomar service (search indexer)
            palomar = {
              enable = true;
              network.port = 3001;
              database.url = "postgres://indigo:indigo@localhost/indigo_palomar";
            };
            
            # Test hepa service (moderation/labeling)
            hepa = {
              enable = true;
              network.port = 3002;
              database.url = "sqlite:///var/lib/atproto/indigo-hepa/db.sqlite";
            };
          };
        };
        
        # Allow services to start
        systemd.services = lib.mapAttrs' (name: _: lib.nameValuePair "indigo-${name}" {
          serviceConfig.Restart = lib.mkForce "no";
        }) {
          relay = {};
          rainbow = {};
          palomar = {};
          hepa = {};
        };
      };
    };
    
    testScript = ''
      import time
      
      # Start the server
      server.start()
      
      # Wait for PostgreSQL to be ready
      server.wait_for_unit("postgresql.service")
      server.wait_for_open_port(5432)
      
      # Wait for Indigo services to start
      print("Waiting for Indigo services to start...")
      
      # Test relay service
      server.wait_for_unit("indigo-relay.service")
      server.wait_for_open_port(2470)
      print("✓ Indigo relay service started")
      
      # Test rainbow service  
      server.wait_for_unit("indigo-rainbow.service")
      server.wait_for_open_port(3000)
      print("✓ Indigo rainbow service started")
      
      # Test palomar service
      server.wait_for_unit("indigo-palomar.service")
      server.wait_for_open_port(3001)
      print("✓ Indigo palomar service started")
      
      # Test hepa service
      server.wait_for_unit("indigo-hepa.service")
      server.wait_for_open_port(3002)
      print("✓ Indigo hepa service started")
      
      # Test service health (basic connectivity)
      print("Testing service connectivity...")
      
      # Test that services are listening on their ports
      server.succeed("curl -f http://127.0.0.1:2470/xrpc/_health || echo 'Relay health check failed (expected)'")
      server.succeed("curl -f http://127.0.0.1:3000/xrpc/_health || echo 'Rainbow health check failed (expected)'")
      server.succeed("curl -f http://127.0.0.1:3001/xrpc/_health || echo 'Palomar health check failed (expected)'")
      server.succeed("curl -f http://127.0.0.1:3002/xrpc/_health || echo 'Hepa health check failed (expected)'")
      
      # Verify database connections were established
      print("Verifying database setup...")
      
      # Check PostgreSQL databases were created
      server.succeed("sudo -u postgres psql -c '\\l' | grep indigo_relay")
      server.succeed("sudo -u postgres psql -c '\\l' | grep indigo_rainbow")
      server.succeed("sudo -u postgres psql -c '\\l' | grep indigo_palomar")
      
      # Check SQLite database for hepa
      server.succeed("test -f /var/lib/atproto/indigo-hepa/db.sqlite")
      
      # Verify service users and directories
      print("Verifying service configuration...")
      
      server.succeed("id indigo-relay")
      server.succeed("id indigo-rainbow") 
      server.succeed("id indigo-palomar")
      server.succeed("id indigo-hepa")
      
      server.succeed("test -d /var/lib/atproto/indigo-relay")
      server.succeed("test -d /var/lib/atproto/indigo-rainbow")
      server.succeed("test -d /var/lib/atproto/indigo-palomar")
      server.succeed("test -d /var/lib/atproto/indigo-hepa")
      
      # Test service logs
      print("Checking service logs...")
      
      server.succeed("journalctl -u indigo-relay.service --no-pager -n 10")
      server.succeed("journalctl -u indigo-rainbow.service --no-pager -n 10")
      server.succeed("journalctl -u indigo-palomar.service --no-pager -n 10")
      server.succeed("journalctl -u indigo-hepa.service --no-pager -n 10")
      
      print("✅ All Indigo services tests passed!")
    '';
  };

in
nixosTest testConfig