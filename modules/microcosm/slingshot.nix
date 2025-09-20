{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-slingshot;
  microcosmPkgs = pkgs.microcosm;
in
{
  options.services.microcosm-slingshot = {
    enable = mkEnableOption "Microcosm Slingshot service";
    package = mkOption {
      type = types.package;
      default = microcosmPkgs.slingshot;
      description = "The Microcosm Slingshot package to use.";
    };
    # Add other service-specific options here
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-slingshot = {
      description = "Microcosm Slingshot Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/slingshot"; # This command likely needs adjustment
        Restart = "always";
        User = "microcosm-slingshot";
        Group = "microcosm-slingshot";
      };
      users.users.microcosm-slingshot = {
        isSystem = true;
        group = "microcosm-slingshot";
      };
      users.groups.microcosm-slingshot = {
        isSystem = true;
      };
    };
  };
}
