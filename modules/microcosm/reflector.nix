{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-reflector;
  microcosmPkgs = pkgs.microcosm;
in
{
  options.services.microcosm-reflector = {
    enable = mkEnableOption "Microcosm Reflector service";
    package = mkOption {
      type = types.package;
      default = microcosmPkgs.reflector;
      description = "The Microcosm Reflector package to use.";
    };
    # Add other service-specific options here
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-reflector = {
      description = "Microcosm Reflector Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/reflector"; # This command likely needs adjustment
        Restart = "always";
        User = "microcosm-reflector";
        Group = "microcosm-reflector";
      };
      users.users.microcosm-reflector = {
        isSystem = true;
        group = "microcosm-reflector";
      };
      users.groups.microcosm-reflector = {
        isSystem = true;
      };
    };
  };
}
