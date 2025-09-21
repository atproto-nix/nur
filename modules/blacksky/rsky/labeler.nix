{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.labeler = {
    enable = mkEnableOption "Blacksky Labeler service";
    port = mkOption {
      type = types.port;
      default = 8005;
      description = "Port for the Blacksky Labeler service.";
    };
    # Add other options specific to the labeler service
  };

  config = mkIf config.blacksky.labeler.enable {
    systemd.services.blacksky-labeler = {
      description = "Blacksky Labeler service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.blacksky.labeler}/bin/rsky-labeler";
        Restart = "always";
        DynamicUser = true;
        StateDirectory = "blacksky-labeler";
        # Add other environment variables or arguments as needed by rsky-labeler
      };
    };
  };
}