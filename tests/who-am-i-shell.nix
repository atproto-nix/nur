{ pkgs }:

pkgs.nixosTest {
  name = "who-am-i-shell";

  nodes.machine = { ... }:
  {
    imports = [ ../modules/microcosm/who-am-i.nix ];

    services.microcosm-who-am-i = {
      enable = true;
      appSecret = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="; # 64 bytes base64 encoded
      jwtPrivateKey = pkgs.writeText "jwt-private-key.pem" "dummy-private-key-content";
      bind = "127.0.0.1:9997"; # Explicitly set bind address for testing
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("microcosm-who-am-i.service")
    machine.log(machine.succeed("systemctl status microcosm-who-am-i.service"))

    # Wait for the service to be ready to accept connections
    machine.wait_for_port(9997)

    # Perform a curl request to the service endpoint
    machine.succeed("curl -v http://127.0.0.1:9997")
  '';
}
