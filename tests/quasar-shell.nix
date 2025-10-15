{ pkgs }:

pkgs.nixosTest {
  name = "quasar-shell";

  nodes.machine = { ... }:
  {
    imports = [ ../modules/microcosm/quasar.nix ];

    services.microcosm-quasar = {
      enable = true;
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("microcosm-quasar.service")
    machine.log(machine.succeed("systemctl status microcosm-quasar.service"))
  '';
}
