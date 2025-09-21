{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.firehose = {
    enable = mkEnableOption "Blacksky Firehose service";
    port = mkOption {
      type = types.port;
      default = 8003;
      description = "Port for the Blacksky Firehose service.";
    };
    # Add other options specific to the firehose service
  };

  config = mkIf config.blacksky.firehose.enable {
    systemd.services.blacksky-firehose = {
      description = "Blacksky Firehose service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.blacksky.firehose}/bin/rsky-firehose";
        Restart = "always";
        DynamicUser = true;
        StateDirectory = "blacksky-firehose";
        # Add other environment variables or arguments as needed by rsky-firehose
      };
    };
  };
}