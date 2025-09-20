{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-who-am-i;
  microcosmPkgs = pkgs.microcosm;
in
{
  options.services.microcosm-who-am-i = {
    enable = mkEnableOption "Microcosm Who-Am-I service";
    package = mkOption {
      type = types.package;
      default = microcosmPkgs."who-am-i";
      description = "The Microcosm Who-Am-I package to use.";
    };
    # Add other service-specific options here
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-who-am-i = {
      description = "Microcosm Who-Am-I Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/who-am-i"; # This command likely needs adjustment
        Restart = "always";
        User = "microcosm-who-am-i";
        Group = "microcosm-who-am-i";
      };
      users.users.microcosm-who-am-i = {
        isSystem = true;
        group = "microcosm-who-am-i";
      };
      users.groups.microcosm-who-am-i = {
        isSystem = true;
      };
    };
  };
}
