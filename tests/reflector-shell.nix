{ pkgs }:

pkgs.nixosTest {
  name = "reflector-shell";

  nodes.machine = { ... }:
  {
    imports = [ ../modules/microcosm/reflector.nix ];

    services.microcosm-reflector = {
      enable = true;
      id = "#test_appview";
      type = "TestAppview";
      serviceEndpoint = "https://test.example.com";
    };

  testScript = ''
    start_all()
    machine.wait_for_unit("microcosm-reflector.service")
    machine.log(machine.succeed("systemctl status microcosm-reflector.service"))
  '';
}
