# Test for standardized Microcosm service modules
{ pkgs }:

pkgs.nixosTest {
  name = "microcosm-standardized";

  nodes.machine = { ... }: {
    imports = [ ../modules/microcosm ];

    # Test multiple services with standardized configuration
    services = {
      microcosm-constellation = {
        enable = true;
        jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
        backend = "rocks";
        logLevel = "info";
      };

      microcosm-spacedust = {
        enable = true;
        jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
        jetstreamNoZstd = false;
        logLevel = "warn";
      };

      microcosm-pocket = {
        enable = true;
        domain = "pocket.example.com";
        logLevel = "info";
      };

      microcosm-reflector = {
        enable = true;
        serviceId = "atproto_pds";
        serviceType = "AtprotoPersonalDataServer";
        serviceEndpoint = "https://pds.example.com";
        domain = "example.com";
        logLevel = "info";
      };
    };
  };

  testScript = ''
    start_all()
    
    # Test that all services start successfully
    machine.wait_for_unit("microcosm-constellation.service")
    machine.wait_for_unit("microcosm-spacedust.service")
    machine.wait_for_unit("microcosm-pocket.service")
    machine.wait_for_unit("microcosm-reflector.service")
    
    # Test that services are running with correct users
    machine.succeed("systemctl show microcosm-constellation.service --property=User | grep 'User=microcosm-constellation'")
    machine.succeed("systemctl show microcosm-spacedust.service --property=User | grep 'User=microcosm-spacedust'")
    machine.succeed("systemctl show microcosm-pocket.service --property=User | grep 'User=microcosm-pocket'")
    machine.succeed("systemctl show microcosm-reflector.service --property=User | grep 'User=microcosm-reflector'")
    
    # Test that data directories exist with correct ownership
    machine.succeed("test -d /var/lib/microcosm-constellation")
    machine.succeed("test -d /var/lib/microcosm-spacedust")
    machine.succeed("test -d /var/lib/microcosm-pocket")
    machine.succeed("test -d /var/lib/microcosm-reflector")
    
    # Test security hardening is applied
    machine.succeed("systemctl show microcosm-constellation.service --property=NoNewPrivileges | grep 'NoNewPrivileges=yes'")
    machine.succeed("systemctl show microcosm-constellation.service --property=ProtectSystem | grep 'ProtectSystem=strict'")
    machine.succeed("systemctl show microcosm-constellation.service --property=PrivateTmp | grep 'PrivateTmp=yes'")
    
    # Log service statuses for debugging
    machine.log(machine.succeed("systemctl status microcosm-constellation.service"))
    machine.log(machine.succeed("systemctl status microcosm-spacedust.service"))
    machine.log(machine.succeed("systemctl status microcosm-pocket.service"))
    machine.log(machine.succeed("systemctl status microcosm-reflector.service"))
  '';
}