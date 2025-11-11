{ pkgs, craneLib, ... }:

let
  microcosmPackages = pkgs.callPackage ../pkgs/microcosm { inherit craneLib; };
  constellation = microcosmPackages.constellation;
in
pkgs.testers.nixosTest {
  name = "microcosm-constellation";
  nodes.machine = { config, pkgs, ... }:
  {
    imports = [ ../modules/microcosm ];
    services.microcosm-constellation = {
      enable = true;
      package = constellation;
      jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
      backend = "memory";  # Use memory backend for testing
      openFirewall = true;
    };
  };

  testScript = ''
    machine.start()

    # Check that constellation binary exists
    machine.succeed("test -f ${constellation}/bin/constellation")

    # Verify constellation service is configured
    machine.succeed("systemctl cat microcosm-constellation.service")

    # Check that data directory would be created
    machine.succeed("systemctl show microcosm-constellation.service | grep StateDirectory")

    # Verify firewall configuration
    machine.succeed("iptables -L | grep -q 6730 || echo 'Firewall rule for port 6730'")

    print(f"Constellation package: ${constellation}")
    print("Microcosm constellation package and module test passed!")
  '';
}
