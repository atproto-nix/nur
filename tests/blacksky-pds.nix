{ pkgs, craneLib, ... }:

let
  rskyPackages = pkgs.callPackage ../pkgs/blacksky/rsky { inherit craneLib; };
  pds = rskyPackages.pds;
in
pkgs.nixosTest {
  name = "blacksky-pds";
  nodes.machine = { config, pkgs, ... }:
  {
    imports = [ ../modules/blacksky/rsky/pds.nix ];
    services.blacksky.pds = {
      enable = true;
      package = pds;
      hostname = "pds.test.local";
      port = 3000;
      database.url = "postgresql://test@localhost/pds";
    };
  };

  testScript = ''
    machine.start()

    # Check that PDS package binaries exist
    machine.succeed("test -f ${pds}/bin/pds")

    # Verify PDS service is configured
    machine.succeed("systemctl cat blacksky-pds.service")

    # Check package metadata
    print(f"PDS package: ${pds}")

    print("Blacksky PDS package and module test passed!")
  '';
}
