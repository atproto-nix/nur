{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-ufos;
  microcosmPkgs = pkgs.microcosm;
in
{
  options.services.microcosm-ufos = {
    enable = mkEnableOption "Microcosm UFOs service";
    package = mkOption {
      type = types.package;
      default = microcosmPkgs.ufos;
      description = "The Microcosm UFOs package to use.";
    };
    # Add other service-specific options here
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-ufos = {
      description = "Microcosm UFOs Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/ufos"; # This command likely needs adjustment
        Restart = "always";
        User = "microcosm-ufos";
        Group = "microcosm-ufos";
      };
      users.users.microcosm-ufos = {
        isSystem = true;
        group = "microcosm-ufos";
      };
      users.groups.microcosm-ufos = {
        isSystem = true;
      };
    };
  };
}
