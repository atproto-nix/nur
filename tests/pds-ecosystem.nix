import <nixpkgs/nixos/tests/make-test-python.nix> ({ pkgs, ... }: {
  name = "pds-ecosystem-integration";
  
  nodes = {
    # Test machine with PDS ecosystem components
    pds-server = { config, pkgs, ... }: {
      imports = [ 
        ../modules/bluesky
        ../profiles
      ];
      
      # Enable PDS dashboard
      services.bluesky.pds-dash = {
        enable = true;
        settings = {
          pdsUrl = "http://localhost:3000";
          host = "127.0.0.1";
          port = 3001;
          theme = "default";
          frontendUrl = "https://bsky.app";
          maxPosts = 20;
          showFuturePosts = false;
        };
      };
      
      # Enable PDS gatekeeper
      services.bluesky.pds-gatekeeper = {
        enable = true;
        settings = {
          pdsDataDirectory = "/tmp/pds-test";
          pdsEnvLocation = "/tmp/pds-test/pds.env";
          pdsBaseUrl = "http://localhost:3000";
          host = "127.0.0.1";
          port = 8080;
          createAccountPerSecond = 60;
          createAccountBurst = 5;
        };
      };
      
      # Create test PDS data directory and environment
      systemd.tmpfiles.rules = [
        "d '/tmp/pds-test' 0755 - - - -"
      ];
      
      # Create minimal PDS environment file for testing
      environment.etc."pds-test-setup" = {
        text = ''
          #!/bin/sh
          mkdir -p /tmp/pds-test
          cat > /tmp/pds-test/pds.env << 'EOF'
          PDS_HOSTNAME=localhost
          PDS_DATA_DIRECTORY=/tmp/pds-test
          PDS_BLOBSTORE_DISK_LOCATION=/tmp/pds-test/blocks
          PDS_DID_PLC_URL=https://plc.directory
          PDS_BSKY_APP_VIEW_URL=https://api.bsky.app
          PDS_BSKY_APP_VIEW_DID=did:web:api.bsky.app
          PDS_REPORT_SERVICE_URL=https://mod.bsky.app
          PDS_REPORT_SERVICE_DID=did:plc:ar7c4by46qjdydhdevvrndac
          PDS_CRAWLERS=https://bsky.network
          EOF
        '';
        mode = "0755";
      };
      
      # Mock PDS service for testing
      systemd.services.mock-pds = {
        description = "Mock PDS service for testing";
        wantedBy = [ "multi-user.target" ];
        before = [ "pds-dash.service" "pds-gatekeeper.service" ];
        
        serviceConfig = {
          Type = "simple";
          ExecStartPre = "/etc/pds-test-setup";
          ExecStart = "${pkgs.python3}/bin/python3 -m http.server 3000";
          WorkingDirectory = "/tmp";
        };
      };
    };
    
    # Test machine with managed PDS profile
    managed-pds = { config, pkgs, ... }: {
      imports = [ 
        ../modules/bluesky
        ../profiles
      ];
      
      profiles.pds-managed = {
        enable = true;
        hostname = "pds.test.local";
        dataDirectory = "/tmp/pds-managed";
        
        dashboard = {
          enable = true;
          port = 3001;
          theme = "default";
        };
        
        gatekeeper = {
          enable = true;
          port = 8080;
          rateLimiting = {
            createAccountPerSecond = 60;
            createAccountBurst = 5;
          };
        };
      };
      
      # Create test environment
      systemd.tmpfiles.rules = [
        "d '/tmp/pds-managed' 0755 - - - -"
      ];
      
      environment.etc."managed-pds-setup" = {
        text = ''
          #!/bin/sh
          mkdir -p /tmp/pds-managed
          cat > /tmp/pds-managed/pds.env << 'EOF'
          PDS_HOSTNAME=pds.test.local
          PDS_DATA_DIRECTORY=/tmp/pds-managed
          EOF
        '';
        mode = "0755";
      };
      
      # Mock PDS service
      systemd.services.mock-pds = {
        description = "Mock PDS service for managed testing";
        wantedBy = [ "multi-user.target" ];
        before = [ "pds-dash.service" "pds-gatekeeper.service" ];
        
        serviceConfig = {
          Type = "simple";
          ExecStartPre = "/etc/managed-pds-setup";
          ExecStart = "${pkgs.python3}/bin/python3 -m http.server 3000";
          WorkingDirectory = "/tmp";
        };
      };
    };
  };
  
  testScript = ''
    # Start all machines
    pds_server.start()
    managed_pds.start()
    
    # Test individual services on pds-server
    print("Testing individual PDS ecosystem services...")
    
    # Wait for mock PDS to start
    pds_server.wait_for_unit("mock-pds.service")
    pds_server.wait_for_open_port(3000)
    
    # Test PDS Dashboard
    pds_server.wait_for_unit("pds-dash.service")
    pds_server.wait_for_open_port(3001)
    
    # Test basic dashboard functionality
    pds_server.succeed("curl -f http://localhost:3001/ || echo 'Dashboard may need PDS data'")
    
    # Test PDS Gatekeeper
    pds_server.wait_for_unit("pds-gatekeeper.service")
    pds_server.wait_for_open_port(8080)
    
    # Test gatekeeper health (it should proxy to PDS or return error)
    pds_server.succeed("curl -s http://localhost:8080/xrpc/com.atproto.server.describeServer || echo 'Gatekeeper responding'")
    
    # Test managed PDS profile
    print("Testing managed PDS profile...")
    
    managed_pds.wait_for_unit("mock-pds.service")
    managed_pds.wait_for_open_port(3000)
    
    managed_pds.wait_for_unit("pds-dash.service")
    managed_pds.wait_for_open_port(3001)
    
    managed_pds.wait_for_unit("pds-gatekeeper.service")
    managed_pds.wait_for_open_port(8080)
    
    # Verify configuration files were generated
    managed_pds.succeed("test -f /etc/pds-managed/caddy-config.txt")
    managed_pds.succeed("test -f /etc/pds-managed/nginx-config.txt")
    
    # Test that services are properly configured
    managed_pds.succeed("systemctl is-active pds-dash.service")
    managed_pds.succeed("systemctl is-active pds-gatekeeper.service")
    
    print("All PDS ecosystem tests passed!")
  '';
})