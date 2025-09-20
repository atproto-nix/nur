{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-quasar;
  microcosmPkgs = pkgs.microcosm;
in
{
  options.services.microcosm-quasar = {
    enable = mkEnableOption "Microcosm Quasar service";
    package = mkOption {
      type = types.package;
      default = microcosmPkgs.quasar;
      description = "The Microcosm Quasar package to use.";
    };
    # Add other service-specific options here
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-quasar = {
      description = "Microcosm Quasar Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/quasar"; # This command likely needs adjustment
        Restart = "always";
        User = "microcosm-quasar";
        Group = "microcosm-quasar";
      };
      users.users.microcosm-quasar = {
        isSystem = true;
        group = "microcosm-quasar";
      };
      users.groups.microcosm-quasar = {
        isSystem = true;
      };
    };
  };
}
