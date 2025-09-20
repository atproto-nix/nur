{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-pocket;
  microcosmPkgs = pkgs.microcosm;
in
{
  options.services.microcosm-pocket = {
    enable = mkEnableOption "Microcosm Pocket service";
    package = mkOption {
      type = types.package;
      default = microcosmPkgs.pocket;
      description = "The Microcosm Pocket package to use.";
    };
    # Add other service-specific options here
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-pocket = {
      description = "Microcosm Pocket Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/pocket"; # This command likely needs adjustment
        Restart = "always";
        User = "microcosm-pocket";
        Group = "microcosm-pocket";
      };
      users.users.microcosm-pocket = {
        isSystem = true;
        group = "microcosm-pocket";
      };
      users.groups.microcosm-pocket = {
        isSystem = true;
      };
    };
  };
}
