{ pkgs, lib, ... }:

let
  # Test the updated rsky packages
  testPackages = pkgs.callPackage ../pkgs/blacksky { 
    craneLib = pkgs.craneLib; 
  };
in
{
  name = "blacksky-rsky-updated-packages";
  
  # Test that all service packages build
  testServicePackages = pkgs.runCommand "test-rsky-services" {} ''
    echo "Testing rsky service packages..."
    
    # Test that all services have the expected binaries
    test -f ${testPackages.pds}/bin/rsky-pds
    test -f ${testPackages.relay}/bin/rsky-relay
    test -f ${testPackages.feedgen}/bin/rsky-feedgen
    test -f ${testPackages.satnav}/bin/rsky-satnav
    test -f ${testPackages.firehose}/bin/rsky-firehose
    test -f ${testPackages.jetstreamSubscriber}/bin/rsky-jetstream-subscriber
    test -f ${testPackages.labeler}/bin/rsky-labeler
    # test -f ${testPackages.pdsadmin}/bin/pdsadmin  # Temporarily disabled
    
    echo "All rsky service binaries found!"
    touch $out
  '';
  
  # Test that library packages build
  testLibraryPackages = pkgs.runCommand "test-rsky-libraries" {} ''
    echo "Testing rsky library packages..."
    
    # Test that libraries have the expected structure
    test -d ${testPackages.common}/lib
    test -d ${testPackages.crypto}/lib
    test -d ${testPackages.identity}/lib
    test -d ${testPackages.lexicon}/lib
    test -d ${testPackages.repo}/lib
    test -d ${testPackages.syntax}/lib
    
    echo "All rsky library packages found!"
    touch $out
  '';
  
  # Test ATproto metadata
  testAtprotoMetadata = pkgs.runCommand "test-rsky-atproto-metadata" {} ''
    echo "Testing ATproto metadata..."
    
    # Check that packages have proper ATproto metadata (using passthru.atproto instead of metadata files)
    echo "Checking ATproto metadata for PDS package..."
    echo "${testPackages.pds.passthru.atproto.type}" | grep -q "application" || {
      echo "PDS package missing or invalid ATproto metadata"
      exit 1
    }
    
    echo "Checking ATproto metadata for Common library package..."
    echo "${testPackages.common.passthru.atproto.type}" | grep -q "library" || {
      echo "Common library package missing or invalid ATproto metadata"
      exit 1
    }
    
    echo "ATproto metadata validation passed!"
    touch $out
  '';
  
  # Test module configuration
  testModuleConfiguration = pkgs.nixosTest {
    name = "rsky-pds-module";
    
    nodes.server = { config, pkgs, ... }: {
      imports = [ ../modules/blacksky ];
      
      services.blacksky.pds = {
        enable = true;
        hostname = "test.example.com";
        database.url = "postgresql://test:test@localhost/test";
        port = 3000;
      };
      
      services.postgresql = {
        enable = true;
        initialDatabases = [{ name = "test"; }];
        authentication = ''
          local all all trust
        '';
      };
    };
    
    testScript = ''
      server.start()
      server.wait_for_unit("postgresql.service")
      server.wait_for_unit("rsky-pds.service")
      server.wait_for_open_port(3000)
      
      # Test that the service is running
      server.succeed("systemctl is-active rsky-pds.service")
      
      # Test that configuration file exists
      server.succeed("test -f /etc/rsky-pds/config.toml")
      
      # Test that data directory was created
      server.succeed("test -d /var/lib/rsky-pds")
    '';
  };
}