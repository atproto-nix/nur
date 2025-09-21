{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.satnav = {
    enable = mkEnableOption "Blacksky Satnav service";
    port = mkOption {
      type = types.port;
      default = 8002;
      description = "Port for the Blacksky Satnav service.";
    };
    # Satnav is a web UI, so it might need a web server configuration
    # For simplicity, we'll just run the binary directly for now.
  };

  config = mkIf config.blacksky.satnav.enable {
    systemd.services.blacksky-satnav = {
      description = "Blacksky Satnav service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.blacksky.satnav}/bin/rsky-satnav";
        Restart = "always";
        DynamicUser = true;
        StateDirectory = "blacksky-satnav";
        # Add other environment variables or arguments as needed by rsky-satnav
      };
    };
  };
}