{ pkgs }:

pkgs.nixosTest {
  name = "slingshot-shell";

  nodes.machine = { ... }:
  {
    imports = [ ../modules/microcosm/slingshot.nix ];

    services.microcosm-slingshot = {
      enable = true;
      jetstream = "us-east-1";
      cacheDir = "/var/lib/microcosm-slingshot/cache";
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("microcosm-slingshot.service")
    machine.log(machine.succeed("systemctl status microcosm-slingshot.service"))
  '';
}
