{ pkgs }:

pkgs.nixosTest {
  name = "pocket-shell";

  nodes.machine = { ... }:
  {
    imports = [ ../modules/microcosm/pocket.nix ];

    services.microcosm-pocket = {
      enable = true;
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("microcosm-pocket.service")
    machine.log(machine.succeed("systemctl status microcosm-pocket.service"))

    # Check if the SQLite database file is created
    machine.succeed("test -f /var/lib/microcosm-pocket/pocket.sqlite")
  '';
}
