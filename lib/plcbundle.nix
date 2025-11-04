# Shared utilities and patterns for plcbundle service modules
{ lib, ... }:

with lib;

rec {
  # Standard security hardening configuration for plcbundle services
  standardSecurityConfig = {
    # Basic security restrictions
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;

    # Kernel and system protection
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectClock = true;

    # Process restrictions
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    RestrictNamespaces = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;

    # IPC and mount restrictions
    RemoveIPC = true;
    PrivateMounts = true;
    PrivateDevices = true;

    # Network restrictions (allow HTTP/HTTPS and WebSocket)
    RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];

    # Additional hardening
    SystemCallArchitectures = "native";
    UMask = "0077";
  };

  # Standard restart configuration
  standardRestartConfig = {
    Restart = "on-failure";
    RestartSec = "5s";
    StartLimitBurst = 3;
    StartLimitIntervalSec = "60s";
  };

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
        ReadWritePaths = [ cfg.dataDir ] ++ (serviceConfig.extraReadWritePaths or []);
        ReadOnlyPaths = [ "/nix/store" ];

        # Environment
        Environment = [
          "LOG_LEVEL=${cfg.logLevel}"
        ] ++ (serviceConfig.extraEnvironment or []);
      } // (serviceConfig.serviceConfig or {});
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

  # Helper function for URL validation
  mkUrlValidation = url: urlName: [
    {
      assertion = url != "";
      message = "${urlName} cannot be empty.";
    }
    {
      assertion = hasPrefix "http://" url || hasPrefix "https://" url;
      message = "${urlName} must start with http:// or https://.";
    }
  ];

  # Helper function for network port validation
  mkPortValidation = port: portName: [
    {
      assertion = port > 0 && port < 65536;
      message = "${portName} must be a valid port number (1-65535).";
    }
  ];

  # Helper function to extract port from bind address
  extractPortFromBind = bindAddr:
    let
      parts = splitString ":" bindAddr;
    in
    if length parts >= 2
    then toInt (last parts)
    else throw "Invalid bind address format: ${bindAddr}";

  # Helper function for firewall configuration
  mkFirewallConfig = cfg: ports: {
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = ports;
    };
  };
}
