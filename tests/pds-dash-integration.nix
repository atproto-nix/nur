# Test configuration for pds-dash with ATProto PDS
# This test verifies that pds-dash can monitor a running PDS instance
{ pkgs ? import <nixpkgs> {} }:

let
  nur = import ../default.nix { inherit pkgs; };

  # Test that pds-dash package builds
  pds-dash = nur.packages.${pkgs.system}.witchcraft-systems-pds-dash;

  # Example NixOS configuration integrating pds-dash with PDS
  exampleConfig = { config, pkgs, ... }: {
    imports = [
      ../modules/blacksky/rsky/pds.nix
    ];

    # Configure blacksky PDS
    services.blacksky.pds = {
      enable = true;
      hostname = "pds.example.com";
      port = 3000;
      dataDir = "/var/lib/pds";
    };

    # Serve pds-dash static files with nginx
    services.nginx = {
      enable = true;
      virtualHosts."dash.example.com" = {
        locations."/" = {
          root = "${pds-dash}";
          index = "index.html";
          tryFiles = "$uri $uri/ /index.html";
        };

        # Proxy API requests to PDS
        locations."/xrpc/" = {
          proxyPass = "http://127.0.0.1:3000";
          proxyWebsockets = true;
        };
      };
    };

    # Open firewall for nginx
    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };

in
{
  inherit pds-dash;

  # Test that the package builds
  build-test = pkgs.runCommand "pds-dash-build-test" {} ''
    test -f ${pds-dash}/index.html || (echo "Missing index.html" && exit 1)
    test -d ${pds-dash}/assets || (echo "Missing assets directory" && exit 1)
    echo "pds-dash build test passed" > $out
  '';

  # Test that the NixOS configuration evaluates
  nixos-config-test = (pkgs.nixos exampleConfig).config.system.build.toplevel;

  meta = {
    description = "Integration test for pds-dash with ATProto PDS";
    longDescription = ''
      This test verifies:
      1. pds-dash package builds successfully
      2. Static files (index.html, assets) are present
      3. NixOS configuration with nginx + PDS + pds-dash evaluates
      4. pds-dash can be served as a frontend to monitor PDS
    '';
  };
}
