{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-spacedust;
  microcosmPkgs = pkgs.microcosm;
in
{
  options.services.microcosm-spacedust = {
    enable = mkEnableOption "Microcosm Spacedust service";
    package = mkOption {
      type = types.package;
      default = microcosmPkgs.spacedust;
      description = "The Microcosm Spacedust package to use.";
    };
    # Add other service-specific options here
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-spacedust = {
      description = "Microcosm Spacedust Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/spacedust"; # This command likely needs adjustment
        Restart = "always";
        User = "microcosm-spacedust";
        Group = "microcosm-spacedust";
      };
      users.users.microcosm-spacedust = {
        isSystem = true;
        group = "microcosm-spacedust";
      };
      users.groups.microcosm-spacedust = {
        isSystem = true;
      };
    };
  };
}
