{ pkgs, ... }:

let
  organizations = {
    "hyperlink-academy" = {
      services = [
        {
          name = "leaflet";
          testPort = 7777;
          extraOptions = {};
        }
      ];
      modulePath = "../../modules/hyperlink-academy";
      pkgsPath = "../../pkgs/hyperlink-academy";
    };
    "slices-network" = {
      services = [
        {
          name = "slices";
          testPort = 8888;
          extraOptions = {};
        }
      ];
      modulePath = "../../modules/slices-network";
      pkgsPath = "../../pkgs/slices-network";
    };
    "teal-fm" = {
      services = [
        {
          name = "teal";
          testPort = 9999;
          extraOptions = {};
        }
      ];
      modulePath = "../../modules/teal-fm";
      pkgsPath = "../../pkgs/teal-fm";
    };
    "parakeet-social" = {
      services = [
        {
          name = "parakeet";
          testPort = 7070;
          extraOptions = {};
        }
      ];
      modulePath = "../../modules/parakeet-social";
      pkgsPath = "../../pkgs/parakeet-social";
    };
    "stream-place" = {
      services = [
        {
          name = "streamplace";
          testPort = 8080;
          extraOptions = {};
        }
      ];
      modulePath = "../../modules/stream-place";
      pkgsPath = "../../pkgs/stream-place";
    };
    "yoten-app" = {
      services = [
        {
          name = "yoten";
          testPort = 9090;
          extraOptions = {};
        }
      ];
      modulePath = "../../modules/yoten-app";
      pkgsPath = "../../pkgs/yoten-app";
    };
    "red-dwarf-client" = {
      services = [
        {
          name = "red-dwarf";
          testPort = 6060;
          extraOptions = {};
        }
      ];
      modulePath = "../../modules/red-dwarf-client";
      pkgsPath = "../../pkgs/red-dwarf-client";
    };
    "tangled" = {
      services = [
        {
          name = "tangled-appview";
          testPort = 5050;
          extraOptions = {};
        }
        {
          name = "tangled-avatar";
          testPort = 5051;
          extraOptions = {};
        }
        {
          name = "tangled-camo";
          testPort = 5052;
          extraOptions = {};
        }
        {
          name = "tangled-knot";
          testPort = 5053;
          extraOptions = {};
        }
        {
          name = "tangled-spindle";
          testPort = 5054;
          extraOptions = {};
        }
      ];
      modulePath = "../../modules/tangled";
      pkgsPath = "../../pkgs/tangled";
    };
    "smokesignal-events" = {
      services = [
        {
          name = "quickdid";
          testPort = 6666;
          extraOptions = {};
        }
      ];
      modulePath = "../../modules/smokesignal-events";
      pkgsPath = "../../pkgs/smokesignal-events";
    };
  };

  makeServiceTest = orgName: { name, testPort, extraOptions }:
    let
      orgConfig = organizations."${orgName}";
    in
    pkgs.nixosTest {
      name = "${orgName}-${name}";
      nodes.machine = { config, pkgs, ... }:
      {
        imports = [ orgConfig.modulePath ];

        services."${orgName}-${name}" = {
          enable = true;
          package = (pkgs.callPackage orgConfig.pkgsPath { })."${name}";
          openFirewall = true;
        } // extraOptions;
      };

      testScript = ''
        machine.start()

        # Check that binary exists
        machine.succeed("test -f ${(pkgs.callPackage orgConfig.pkgsPath { })."${name}"}/bin/${name}")

        # Verify service is configured
        machine.succeed("systemctl cat ${orgName}-${name}.service")

        # Verify firewall configuration
        machine.succeed("iptables -L | grep -q ${toString testPort} || (echo 'Firewall rule for port ${toString testPort} missing' && exit 1)")

        print("${orgName} ${name} service test passed!")
      '';
    };

  generateTestsForOrg = orgName:
    let
      orgServices = organizations."${orgName}".services;
    in
    builtins.listToAttrs (map (service: {
      name = "${orgName}-${service.name}";
      value = makeServiceTest orgName service;
    }) orgServices);

  allTests = builtins.mapAttrs (orgName: _: generateTestsForOrg orgName) organizations;
in
  allTests