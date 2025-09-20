{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-jetstream;
  microcosmPkgs = pkgs.microcosm;
in
{
  options.services.microcosm-jetstream = {
    enable = mkEnableOption "Microcosm Jetstream service";
    package = mkOption {
      type = types.package;
      default = microcosmPkgs.jetstream;
      description = "The Microcosm Jetstream package to use.";
    };
    # Add other service-specific options here
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-jetstream = {
      description = "Microcosm Jetstream Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/jetstream"; # This command likely needs adjustment
        Restart = "always";
        User = "microcosm-jetstream";
        Group = "microcosm-jetstream";
      };
      users.users.microcosm-jetstream = {
        isSystem = true;
        group = "microcosm-jetstream";
      };
      users.groups.microcosm-jetstream = {
        isSystem = true;
      };
    };
  };
}
