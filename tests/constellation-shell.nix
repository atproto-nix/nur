{ pkgs }:

pkgs.nixosTest {
  name = "constellation-shell";

  nodes.machine = { ... }:
  {
    imports = [ ../modules/microcosm/constellation.nix ];

    services.microcosm-constellation = {
      enable = true;
      jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
      backend = "rocks";
    };
  };

  # The corrected test script
  testScript = ''
    start_all()
    machine.wait_for_unit("microcosm-constellation.service")
    # The line below was removed. wait_for_unit is all you need.
    # machine.succeed("systemctl status --wait microcosm-constellation.service")

    # If you want to be extra sure, you can log the status
    machine.log(machine.succeed("systemctl status microcosm-constellation.service"))
  '';
}
