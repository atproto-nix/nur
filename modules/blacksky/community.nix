{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.community = {
    enable = mkEnableOption "Blacksky Community web client service";
    port = mkOption {
      type = types.port;
      default = 80;
      description = "Port for the Blacksky Community web client.";
    };
    hostName = mkOption {
      type = types.str;
      default = "localhost";
      description = "Host name for the Blacksky Community web client.";
    };
  };

  config = mkIf config.blacksky.community.enable {
    services.nginx = {
      enable = true;
      virtualHosts.${config.blacksky.community.hostName} = {
        enable = true;
        root = "${pkgs.blacksky-community}/share/nginx/html";
        listen = [{
          addr = "127.0.0.1";
          port = config.blacksky.community.port;
        }];
      };
    };
  };
}