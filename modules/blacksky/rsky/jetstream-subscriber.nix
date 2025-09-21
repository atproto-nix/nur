{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.jetstreamSubscriber = {
    enable = mkEnableOption "Blacksky Jetstream Subscriber service";
    port = mkOption {
      type = types.port;
      default = 8004;
      description = "Port for the Blacksky Jetstream Subscriber service.";
    };
    # Add other options specific to the jetstream subscriber service
  };

  config = mkIf config.blacksky.jetstreamSubscriber.enable {
    systemd.services.blacksky-jetstream-subscriber = {
      description = "Blacksky Jetstream Subscriber service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.blacksky.jetstreamSubscriber}/bin/rsky-jetstream-subscriber";
        Restart = "always";
        DynamicUser = true;
        StateDirectory = "blacksky-jetstream-subscriber";
        # Add other environment variables or arguments as needed by rsky-jetstream-subscriber
      };
    };
  };
}