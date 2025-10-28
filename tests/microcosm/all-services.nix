{ pkgs, craneLib, ... }:

let
  services = [
    {
      name = "constellation";
      testPort = 6730;
      extraOptions = {
        jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
        backend = "memory";
      };
    }
    {
      name = "spacedust";
      testPort = 8080;
      extraOptions = {};
    }
    {
      name = "slingshot";
      testPort = 7000;
      extraOptions = {};
    }
    {
      name = "ufos";
      testPort = 9090;
      extraOptions = {};
    }
    {
      name = "who-am-i";
      testPort = 8888;
      extraOptions = {};
    }
    {
      name = "quasar";
      testPort = 7070;
      extraOptions = {};
    }
    {
      name = "pocket";
      testPort = 6666;
      extraOptions = {};
    }
    {
      name = "reflector";
      testPort = 5050;
      extraOptions = {};
    }
    {
      name = "allegedly";
      testPort = 9999;
      extraOptions = {};
    }
  ];

  makeServiceTest = { name, testPort, extraOptions }:
    pkgs.nixosTest {
      name = "microcosm-${name}";
      nodes.machine = { config, pkgs, ... }:
      {
        imports = [ ../../modules/microcosm ];

        services."microcosm-${name}" = {
          enable = true;
          package = (pkgs.callPackage ../../pkgs/microcosm { inherit craneLib; })."${name}";
          openFirewall = true;
        } // extraOptions;
      };

      testScript = ''
        machine.start()

        # Check that binary exists
        machine.succeed("test -f ${(pkgs.callPackage ../../pkgs/microcosm { inherit craneLib; })."${name}"}/bin/${name}")

        # Verify service is configured
        machine.succeed("systemctl cat microcosm-${name}.service")

        # Verify firewall configuration
        machine.succeed("iptables -L | grep -q ${toString testPort} || (echo 'Firewall rule for port ${toString testPort} missing' && exit 1)")

        print("Microcosm ${name} service test passed!")
      '';
    };
in
  builtins.listToAttrs (map (service: {
    name = "microcosm-${service.name}";
    value = makeServiceTest service;
  }) services)