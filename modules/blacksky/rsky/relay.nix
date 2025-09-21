{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.relay = {
    enable = mkEnableOption "Blacksky Relay service";
    port = mkOption {
      type = types.port;
      default = 8000;
      description = "Port for the Blacksky Relay service.";
    };
    # Add other options specific to the relay service, e.g., certs, private_key
  };

  config = mkIf config.blacksky.relay.enable {
    systemd.services.blacksky-relay = {
      description = "Blacksky Relay service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.blacksky.relay}/bin/rsky-relay";
        Restart = "always";
        DynamicUser = true;
        StateDirectory = "blacksky-relay";
        # Add other environment variables or arguments as needed by rsky-relay
      };
    };
  };
}