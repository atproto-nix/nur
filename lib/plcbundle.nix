# Shared utilities and patterns for plcbundle service modules
# Imports and re-exports common patterns from service-common for backward compatibility
{ lib, pkgs, ... }:

with lib;

let
  # Import shared patterns from service-common
  commonLib = import ./service-common.nix { inherit lib pkgs; };
in

rec {
  # Re-export common security and restart configs
  inherit (commonLib) standardSecurityConfig standardRestartConfig;

  # Re-export common validation and helper functions
  inherit (commonLib) mkJetstreamValidation mkPortValidation mkUrlValidation extractPortFromBind mkFirewallConfig;

  # Helper function to create standard plcbundle service options
  mkPlcbundleServiceOptions = serviceName: extraOptions: {
    enable = mkEnableOption "${serviceName} service";

    package = mkOption {
      type = types.package;
      default = null; # Will be set by each service module
      description = "The ${serviceName} package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "plcbundle-${toLower serviceName}";
      description = "User account for ${serviceName} service.";
    };

    group = mkOption {
      type = types.str;
      default = "plcbundle-${toLower serviceName}";
      description = "Group for ${serviceName} service.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/plcbundle-${toLower serviceName}";
      description = "Data directory for ${serviceName} service.";
    };

    logLevel = mkOption {
      type = types.enum [ "trace" "debug" "info" "warn" "error" ];
      default = "info";
      description = "Logging level for ${serviceName} service.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for ${serviceName} service ports.";
    };
  } // extraOptions;

  # Helper function to create standard user and group configuration
  mkUserConfig = cfg: {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = false;
    };

    users.groups.${cfg.group} = {};
  };

  # Helper function to create standard directory management
  mkDirectoryConfig = cfg: extraDirs: {
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ] ++ (map (dir: "d '${dir}' 0750 ${cfg.user} ${cfg.group} - -") extraDirs);
  };

  # Helper function to create standard systemd service configuration
  mkSystemdService = cfg: serviceName: serviceConfig: {
    systemd.services."plcbundle-${toLower serviceName}" = {
      description = "${serviceName} Service - ${serviceConfig.description or "PLC Bundle archiving service"}";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = standardSecurityConfig // standardRestartConfig // {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;

        # Standard paths
        ReadWritePaths = [ cfg.dataDir ] ++ (if serviceConfig ? extraReadWritePaths then serviceConfig.extraReadWritePaths else []);
        ReadOnlyPaths = [ "/nix/store" ];

        # Environment
        Environment = [
          "RUST_LOG=${cfg.logLevel}"
        ] ++ (if serviceConfig ? extraEnvironment then serviceConfig.extraEnvironment else []);
      } // (removeAttrs (serviceConfig.serviceConfig or {}) [ "extraReadWritePaths" "extraEnvironment" ]);
    };
  };

  # Helper function to create standard configuration validation
  mkConfigValidation = cfg: serviceName: extraAssertions: {
    assertions = [
      {
        assertion = cfg.package != null;
        message = "services.plcbundle-${toLower serviceName}.package must be set to a valid package.";
      }
      {
        assertion = cfg.dataDir != "";
        message = "services.plcbundle-${toLower serviceName}.dataDir cannot be empty.";
      }
      {
        assertion = cfg.user != "" && cfg.group != "";
        message = "services.plcbundle-${toLower serviceName} user and group cannot be empty.";
      }
    ] ++ extraAssertions;

    warnings = lib.optionals (cfg.logLevel == "trace") [
      "Trace logging enabled for plcbundle-${toLower serviceName} - this may impact performance and expose sensitive information"
    ] ++ lib.optionals (cfg.logLevel == "debug") [
      "Debug logging enabled for plcbundle-${toLower serviceName} - this may impact performance in production"
    ];
  };

}
