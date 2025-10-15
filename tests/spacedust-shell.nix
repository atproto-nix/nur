{ pkgs }:

pkgs.nixosTest {
  name = "spacedust-shell";

  nodes.machine = { ... }:
  {
    imports = [ ../modules/microcosm/spacedust.nix ];

    services.microcosm-spacedust = {
      enable = true;
      jetstream = "us-east-1";
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("microcosm-spacedust.service")
    machine.log(machine.succeed("systemctl status microcosm-spacedust.service"))
  '';
}
