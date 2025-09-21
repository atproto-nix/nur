{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.feedgen = {
    enable = mkEnableOption "Blacksky Feed Generator service";
    port = mkOption {
      type = types.port;
      default = 8001;
      description = "Port for the Blacksky Feed Generator service.";
    };
    # Add other options specific to the feedgen service
  };

  config = mkIf config.blacksky.feedgen.enable {
    systemd.services.blacksky-feedgen = {
      description = "Blacksky Feed Generator service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.blacksky.feedgen}/bin/rsky-feedgen";
        Restart = "always";
        DynamicUser = true;
        StateDirectory = "blacksky-feedgen";
        # Add other environment variables or arguments as needed by rsky-feedgen
      };
    };
  };
}