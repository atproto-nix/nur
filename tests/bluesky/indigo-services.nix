{ pkgs, ... }:

let
  services = [
    {
      name = "indigo-hepa";
      testPort = 4090;
      extraOptions = {};
    }
    {
      name = "indigo-palomar";
      testPort = 4100;
      extraOptions = {};
    }
    {
      name = "indigo-rainbow";
      testPort = 4110;
      extraOptions = {};
    }
    {
      name = "indigo-relay";
      testPort = 4120;
      extraOptions = {};
    }
  ];

  makeServiceTest = { name, testPort, extraOptions }:
    pkgs.testers.nixosTest {
      name = "bluesky-${name}";
      nodes.machine = { config, pkgs, ... }:
      {
        imports = [ ../../modules/bluesky/bluesky-social ];

        services."bluesky-${name}" = {
          enable = true;
          # Assuming the package is in the bluesky packages set
          package = (pkgs.callPackage ../../pkgs/bluesky-social/default.nix { })."${name}";
          openFirewall = true;
        } // extraOptions;
      };

      testScript = ''
        machine.start()

        # Check that binary exists
        machine.succeed("test -f ${(pkgs.callPackage ../../pkgs/bluesky-social/default.nix { })."${name}"}/bin/${name}")

        # Verify service is configured
        machine.succeed("systemctl cat bluesky-${name}.service")

        # Verify firewall configuration
        machine.succeed("iptables -L | grep -q ${toString testPort} || (echo 'Firewall rule for port ${toString testPort} missing' && exit 1)")

        print("Bluesky ${name} service test passed!")
      '';
    };
in
  builtins.listToAttrs (map (service: {
    name = "bluesky-${service.name}";
    value = makeServiceTest service;
  }) services)