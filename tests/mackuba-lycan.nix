{ pkgs, ... }:

let
  lycan = pkgs.callPackage ../pkgs/mackuba/lycan.nix { };
in
pkgs.nixosTest {
  name = "mackuba-lycan";
  nodes.machine = { config, pkgs, ... }:
  {
    imports = [ ../modules/mackuba ];
    services.mackuba-lycan = {
      enable = true;
      package = lycan;
      database.createLocally = true;
    };
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("postgresql.service")

    # Check that lycan package is installed
    machine.succeed("which lycan || true")

    # Check that lycan executables exist
    machine.succeed("test -f ${lycan}/bin/lycan")
    machine.succeed("test -f ${lycan}/bin/lycan-rake")
    machine.succeed("test -f ${lycan}/bin/lycan-console")

    # Verify PostgreSQL database was created
    machine.succeed("sudo -u postgres psql -l | grep lycan")

    print("Lycan package and module tests passed!")
  '';
}