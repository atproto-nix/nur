{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.blacksky.pdsadmin;
  
  # Import service configuration utilities
  serviceLib = import ../../../lib/service-common.nix { inherit lib; };
in
{
  options.services.blacksky.pdsadmin = {
    enable = mkEnableOption "rsky PDS Admin CLI tool";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.repos.atproto.blacksky.rsky.pdsadmin;
      defaultText = literalExpression "pkgs.nur.repos.atproto.blacksky.rsky.pdsadmin";
      description = "The rsky-pdsadmin package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "rsky-pdsadmin";
      description = "User account under which rsky-pdsadmin runs.";
    };

    group = mkOption {
      type = types.str;
      default = "rsky-pdsadmin";
      description = "Group under which rsky-pdsadmin runs.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/rsky-pdsadmin";
      description = "Directory where rsky-pdsadmin stores its data.";
    };

    database = {
      url = mkOption {
        type = types.str;
        description = "PostgreSQL database URL for PDS connection.";
        example = "postgresql://user:password@localhost/pds";
      };
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional configuration settings for rsky-pdsadmin.";
      example = literalExpression ''
        {
          log_level = "info";
          backup_retention_days = 30;
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # User and group configuration
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      description = "rsky PDS Admin service user";
    };

    users.groups.${cfg.group} = {};

    # Directory management
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/config' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.dataDir}/logs' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # Configuration file
    environment.etc."rsky-pdsadmin/config.toml" = {
      text = ''
        # rsky PDS Admin Configuration
        database_url = "${cfg.database.url}"
        data_dir = "${cfg.dataDir}"
        
        ${lib.generators.toINI {} cfg.settings}
      '';
      mode = "0640";
      user = cfg.user;
      group = cfg.group;
    };

    # Make the CLI tool available system-wide
    environment.systemPackages = [ cfg.package ];

    # Security assertions
    assertions = [
      {
        assertion = cfg.database.url != "";
        message = "rsky-pdsadmin requires a database URL to be configured.";
      }
    ];
  };
}