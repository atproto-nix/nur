{ pkgs, ... }:

let
  services = [
    {
      name = "pds";
      testPort = 2585;
      extraOptions = {
        # Example configuration, adjust as needed
        plcDirectory = "https://plc.directory";
      };
    }
    {
      name = "relay";
      testPort = 2594;
      extraOptions = {};
    }
    {
      name = "feedgen";
      testPort = 2590;
      extraOptions = {};
    }
    {
      name = "firehose";
      testPort = 2600;
      extraOptions = {};
    }
    {
      name = "jetstream-subscriber";
      testPort = 2610;
      extraOptions = {};
    }
    {
      name = "labeler";
      testPort = 2620;
      extraOptions = {};
    }
    {
      name = "pdsadmin";
      testPort = 2630;
      extraOptions = {};
    }
    {
      name = "satnav";
      testPort = 2640;
      extraOptions = {};
    }
  ];

  makeServiceTest = { name, testPort, extraOptions }:
    pkgs.nixosTest {
      name = "blacksky-${name}";
      nodes.machine = { config, pkgs, ... }:
      {
        imports = [ ../../modules/blacksky ];

        services."blacksky-${name}" = {
          enable = true;
          package = (pkgs.callPackage ../../pkgs/blacksky/rsky/default.nix { })."${name}";
          openFirewall = true;
        } // extraOptions;
      };

      testScript = ''
        machine.start()

        # Check that binary exists
        machine.succeed("test -f ${(pkgs.callPackage ../../pkgs/blacksky/rsky/default.nix { })."${name}"}/bin/${name}")

        # Verify service is configured
        machine.succeed("systemctl cat blacksky-${name}.service")

        # Verify firewall configuration
        machine.succeed("iptables -L | grep -q ${toString testPort} || (echo 'Firewall rule for port ${toString testPort} missing' && exit 1)")

        print("Blacksky ${name} service test passed!")
      '';
    };
in
  builtins.listToAttrs (map (service: {
    name = "blacksky-${service.name}";
    value = makeServiceTest service;
  }) services)