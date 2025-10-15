{ pkgs }:

pkgs.nixosTest {
  name = "ufos-shell";

  nodes.machine = { ... }:
  {
    imports = [ ../modules/microcosm/ufos.nix ];

    services.microcosm-ufos = {
      enable = true;
      jetstream = "us-east-1";
      data = "/var/lib/microcosm-ufos/data";
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("microcosm-ufos.service")
    machine.log(machine.succeed("systemctl status microcosm-ufos.service"))

    # Check if the data directory is created
    machine.succeed("test -d /var/lib/microcosm-ufos/data")
  '';
}
