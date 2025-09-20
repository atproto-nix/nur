{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-constellation;
  microcosmPkgs = pkgs.microcosm; # Access the packages we built
in
{
  options.services.microcosm-constellation = {
    enable = mkEnableOption "Microcosm Constellation service";
    package = mkOption {
      type = types.package;
      default = microcosmPkgs.constellation;
      description = "The Microcosm Constellation package to use.";
    };
    port = mkOption {
      type = types.port;
      default = 8080; # Example default port
      description = "The port on which the Constellation service listens.";
    };
    # Add other service-specific options here (e.g., databaseUrl, logLevel)
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-constellation = {
      description = "Microcosm Constellation Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/constellation --port ${toString cfg.port}"; # Example command
        Restart = "always";
        User = "microcosm-constellation"; # Create a dedicated user
        Group = "microcosm-constellation";
        # Add other systemd options as needed (e.g., working directory, environment variables)
      };
      # Create user and group
      users.users.microcosm-constellation = {
        isSystem = true;
        group = "microcosm-constellation";
      };
      users.groups.microcosm-constellation = {
        isSystem = true;
      };
    };
  };
}
