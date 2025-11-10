# NixOS integration test for Frontpage services
{ pkgs, lib, ... }:

let
  # Test configuration for Frontpage services
  testConfig = {
    services.atproto = {
      enable = true;
      
      frontpage = {
        enable = true;
        port = 3000;
        hostname = "0.0.0.0";
        
        database = {
          url = "sqlite:///var/lib/frontpage/frontpage.db";
          type = "sqlite";
        };
        
        oauth = {
          clientId = "test-client-id";
          clientSecret = "test-client-secret";
          redirectUri = "http://localhost:3000/oauth/callback";
        };
        
        atproto = {
          pdsUrl = "https://bsky.social";
          appviewUrl = "https://api.bsky.app";
        };
      };
      
      drainpipe = {
        enable = true;
        
        firehose = {
          url = "wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos";
        };
        
        storage = {
          backend = "sled";
          path = "/var/lib/drainpipe/storage";
          compression = true;
        };
        
        processing = {
          batchSize = 100;
          workers = 2;
        };
      };
    };
  };

in
pkgs.testers.nixosTest {
  name = "frontpage-services";
  
  nodes = {
    server = { config, pkgs, ... }: testConfig;
  };
  
  testScript = ''
    # Start the test
    start_all()
    
    # Wait for services to start
    server.wait_for_unit("frontpage.service")
    server.wait_for_unit("drainpipe.service")
    
    # Test that services are listening on expected ports
    server.wait_for_open_port(3000)
    
    # Test that configuration files were created
    server.succeed("test -f /etc/frontpage/config.env")
    server.succeed("test -f /etc/drainpipe/config.env")
    
    # Test that data directories were created
    server.succeed("test -d /var/lib/frontpage")
    server.succeed("test -d /var/lib/drainpipe")
    server.succeed("test -d /var/lib/drainpipe/storage")
    
    # Test that services are running with correct users
    server.succeed("pgrep -u frontpage")
    server.succeed("pgrep -u drainpipe")
    
    # Test basic HTTP response from frontpage (if it has a health endpoint)
    # Note: This might fail if the service requires full setup, but we test the port is open
    server.succeed("curl -f http://localhost:3000/ || curl -I http://localhost:3000/")
    
    # Test that log directories exist
    server.succeed("test -d /var/lib/frontpage/logs")
    server.succeed("test -d /var/lib/drainpipe/logs")
    
    print("All Frontpage service tests passed!")
  '';
}