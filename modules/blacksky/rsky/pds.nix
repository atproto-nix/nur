{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.pds = {
    enable = mkEnableOption "Blacksky PDS service";
    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port for the Blacksky PDS service.";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/blacksky-pds";
      description = "Data directory for the Blacksky PDS service.";
    };
  };

  config = mkIf config.blacksky.pds.enable {
    systemd.services.blacksky-pds = {
      description = "Blacksky PDS service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.blacksky.pds}/bin/rsky-pds";
        Restart = "always";
        DynamicUser = true;
      # Ensure data directory exists and has correct permissions
      preStart = ''
        mkdir -p ${config.blacksky.pds.dataDir}
        chown -R blacksky-pds:blacksky-pds ${config.blacksky.pds.dataDir}
      '';
    };
  };
}