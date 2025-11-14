# Common service configuration patterns for NixOS ATproto modules
{ lib, pkgs, ... }:

with lib;

rec {
  # Standard security hardening configuration for ATproto services
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

    # Network restrictions (can be overridden per service)
    RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];

    # Additional hardening
    SystemCallArchitectures = "native";
    UMask = "0077";
  };

  # Standard restart configuration for ATproto services
  standardRestartConfig = {
    Restart = "on-failure";
    RestartSec = "5s";
    StartLimitBurst = 3;
    StartLimitIntervalSec = "60s";
  };

  # Standard ATproto service module template
  mkAtprotoServiceModule = { name, package, defaultConfig ? {}, extraOptions ? {}, ... }@args:
    let
      serviceName = toLower name;
      defaultServiceConfig = {
        user = "atproto-${serviceName}";
        group = "atproto-${serviceName}";
        dataDir = "/var/lib/atproto/${serviceName}";
        logLevel = "info";
        openFirewall = false;
      } // defaultConfig;
    in
    {
      options.services.atproto.${serviceName} = {
        enable = mkEnableOption "${name} ATproto service";

        package = mkOption {
          type = types.package;
          default = package;
          description = "The ${name} package to use.";
        };

        user = mkOption {
          type = types.str;
          default = defaultServiceConfig.user;
          description = "User account for ${name} service.";
        };

        group = mkOption {
          type = types.str;
          default = defaultServiceConfig.group;
          description = "Group for ${name} service.";
        };

        dataDir = mkOption {
          type = types.path;
          default = defaultServiceConfig.dataDir;
          description = "Data directory for ${name} service.";
        };

        logLevel = mkOption {
          type = types.enum [ "trace" "debug" "info" "warn" "error" ];
          default = defaultServiceConfig.logLevel;
          description = "Logging level for ${name} service.";
        };

        openFirewall = mkOption {
          type = types.bool;
          default = defaultServiceConfig.openFirewall;
          description = "Whether to open the firewall for ${name} service ports.";
        };

        extraConfig = mkOption {
          type = types.attrs;
          default = {};
          description = "Additional configuration options for ${name} service.";
        };
      } // extraOptions;

      config = mkIf config.services.atproto.${serviceName}.enable (
        let
          cfg = config.services.atproto.${serviceName};
        in
        mkMerge [
          # User and group configuration
          (mkUserConfig cfg)

          # Directory management
          (mkDirectoryConfig cfg (args.extraDirectories or []))

          # systemd service
          (mkSystemdService cfg name (args.serviceConfig or {}))

          # Firewall configuration
          (mkFirewallConfig cfg (args.ports or []))

          # Configuration validation
          (mkConfigValidation cfg name (args.extraAssertions or []))
        ]
      );
    };

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
      "d '${cfg.dataDira}' 0750 ${cfg.user} ${cfg.group} - -"
    ] ++ (map (dir: "d '${dir}' 0750 ${cfg.user} ${cfg.group} - -") extraDirs);
  };

  # Helper function to create standard systemd service configuration
  mkSystemdService = cfg: serviceName: serviceConfig: {
    systemd.services."atproto-${toLower serviceName}" = {
      description = "${serviceName} ATproto Service - ${serviceConfig.description or "ATproto service"}";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ (serviceConfig.after or []);
      wants = [ "network.target" ] ++ (serviceConfig.wants or []);
      requires = serviceConfig.requires or [];

      serviceConfig = standardSecurityConfig // standardRestartConfig // {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;

        # Standard paths
        ReadWritePaths = [ cfg.dataDir ] ++ (serviceConfig.extraReadWritePaths or []);
        ReadOnlyPaths = [ "/nix/store" ] ++ (serviceConfig.extraReadOnlyPaths or []);

        # Environment
        Environment = [
          "RUST_LOG=${cfg.logLevel}"
        ] ++ (serviceConfig.extraEnvironment or []);

        # Service-specific configuration
        ExecStart = serviceConfig.execStart or "${cfg.package}/bin/${toLower serviceName}";
        ExecReload = serviceConfig.execReload or null;

        # Resource limits
        MemoryMax = serviceConfig.memoryMax or null;
        CPUQuota = serviceConfig.cpuQuota or null;
        TasksMax = serviceConfig.tasksMax or null;
      } // (serviceConfig.serviceConfig or {});

      # Service-specific overrides
      preStart = serviceConfig.preStart or "";
      postStart = serviceConfig.postStart or "";
      preStop = serviceConfig.preStop or "";
      postStop = serviceConfig.postStop or "";
    };
  };

  # Helper function for firewall configuration
  mkFirewallConfig = cfg: ports: {
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = ports;
    };
  };

  # Helper function to create standard configuration validation
  mkConfigValidation = cfg: serviceName: extraAssertions: {
    assertions = [
      {
        assertion = cfg.package != null;
        message = "services.atproto.${toLower serviceName}.package must be set to a valid package.";
      }
      {
        assertion = cfg.dataDir != "";
        message = "services.atproto.${toLower serviceName}.dataDir cannot be empty.";
      }
      {
        assertion = cfg.user != "" && cfg.group != "";
        message = "services.atproto.${toLower serviceName} user and group cannot be empty.";
      }
    ] ++ extraAssertions;

    warnings = lib.optionals (cfg.logLevel == "trace") [
      "Trace logging enabled for atproto-${toLower serviceName} - this may impact performance and expose sensitive information"
    ] ++ lib.optionals (cfg.logLevel == "debug") [
      "Debug logging enabled for atproto-${toLower serviceName} - this may impact performance in production"
    ];
  };

  # Database integration patterns
  mkDatabaseIntegration = { dbType ? "postgresql", migrations ? [], ... }@args:
    let
      supportedTypes = [ "postgresql" "sqlite" "rocksdb" ];
      validType = builtins.elem dbType supportedTypes;
    in
    if !validType then
      throw "Unsupported database type: ${dbType}. Supported: ${builtins.toString supportedTypes}"
    else
    {
      options = {
        database = {
          type = mkOption {
            type = types.enum supportedTypes;
            default = dbType;
            description = "Database type to use.";
          };

          url = mkOption {
            type = types.str;
            description = "Database connection URL.";
          };

          passwordFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "File containing database password.";
          };

          autoMigrate = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to automatically run database migrations.";
          };
        };
      };

      config = cfg: {
        # Database-specific service dependencies and migration service
        systemd.services = (mkIf (cfg.database.type == "postgresql") {
          "atproto-${cfg.serviceName}".after = [ "postgresql.service" ];
          "atproto-${cfg.serviceName}".wants = [ "postgresql.service" ];
        }) // (mkIf (cfg.database.autoMigrate && migrations != []) {
          "atproto-${cfg.serviceName}-migrate" = {
            description = "Database migrations for ${cfg.serviceName}";
            wantedBy = [ "atproto-${cfg.serviceName}.service" ];
            before = [ "atproto-${cfg.serviceName}.service" ];

            serviceConfig = {
              Type = "oneshot";
              User = cfg.user;
              Group = cfg.group;

              # Run migrations
              ExecStart = "${cfg.package}/bin/${cfg.serviceName}-migrate";
            };
          };
        });
      };
    };

  # Security hardening for ATproto services
  mkServiceSecurity = { networkAccess ? true, fileSystem ? "strict", ... }@args:
    let
      baseConfig = standardSecurityConfig;

      networkConfig = if networkAccess then {
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      } else {
        RestrictAddressFamilies = [ "AF_UNIX" ];
        PrivateNetwork = true;
      };

      fileSystemConfig = if fileSystem == "strict" then {
        ProtectSystem = "strict";
        ReadOnlyPaths = [ "/nix/store" ];
      } else if fileSystem == "full" then {
        ProtectSystem = "full";
      } else {
        ProtectSystem = "true";
      };
    in
    baseConfig // networkConfig // fileSystemConfig // (args.extraConfig or {});

  # Service dependency management
  mkServiceDependencies = { dependencies ? [], optionalDependencies ? [], ... }@args:
    {
      systemdConfig = {
        after = dependencies ++ optionalDependencies;
        wants = optionalDependencies;
        requires = dependencies;
      };

      # Health check dependencies
      healthChecks = lib.mapAttrs (dep: config: {
        enabled = true;
        endpoint = config.healthEndpoint or "/health";
        timeout = config.timeout or 10;
      }) (args.dependencyConfigs or {});
    };

  # Configuration file management
  mkConfigFile = { name, content, format ? "json", ... }@args:
    let
      formatContent =
        if format == "json" then
          builtins.toJSON content
        else if format == "yaml" then
          # TODO: Implement YAML formatting
          throw "YAML format not yet implemented"
        else if format == "toml" then
          # TODO: Implement TOML formatting
          throw "TOML format not yet implemented"
        else
          toString content;
    in
    pkgs.writeText name formatContent;

  # Service monitoring and health checks
  mkHealthCheck = { endpoint ? "/health", port, interval ? 30, timeout ? 10, ... }@args:
    {
      systemdConfig = {
        # Health check timer
        systemd.timers."atproto-${args.serviceName}-healthcheck" = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "${toString interval}s";
            OnUnitActiveSec = "${toString interval}s";
          };
        };

        # Health check service
        systemd.services."atproto-${args.serviceName}-healthcheck" = {
          description = "Health check for ${args.serviceName}";

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.curl}/bin/curl -f -m ${toString timeout} http://localhost:${toString port}${endpoint}";
          };
        };
      };
    };

  # Log management configuration
  mkLogConfig = { logLevel ? "info", logFormat ? "json", logFile ? null, ... }@args:
    {
      environment = [
        "RUST_LOG=${logLevel}"
        "LOG_FORMAT=${logFormat}"
      ] ++ (if logFile != null then [ "LOG_FILE=${logFile}" ] else []);

      # Log rotation if file logging is enabled
      logrotateConfig = mkIf (logFile != null) {
        services.logrotate.settings."${args.serviceName}" = {
          files = [ logFile ];
          frequency = "daily";
          rotate = 7;
          compress = true;
          delaycompress = true;
          missingok = true;
          notifempty = true;
          postrotate = "systemctl reload atproto-${args.serviceName}";
        };
      };
    };

  # Network configuration helpers
  mkNetworkConfig = { bindAddress ? "127.0.0.1", port, openFirewall ? false, ... }@args:
    {
      environment = [
        "BIND_ADDRESS=${bindAddress}"
        "PORT=${toString port}"
      ];

      firewall = mkIf openFirewall {
        networking.firewall.allowedTCPPorts = [ port ];
      };

      # Port validation
      assertions = [
        {
          assertion = port > 0 && port < 65536;
          message = "Port must be a valid port number (1-65535), got: ${toString port}";
        }
      ];
    };

  # Helper functions for common validation patterns
  # These are shared across all service types (ATproto, Microcosm, PLCBundle)

  mkJetstreamValidation = jetstreamUrl: [
    {
      assertion = jetstreamUrl != "";
      message = "Jetstream URL cannot be empty.";
    }
    {
      assertion = hasPrefix "ws://" jetstreamUrl || hasPrefix "wss://" jetstreamUrl;
      message = "Jetstream URL must start with ws:// or wss://.";
    }
  ];

  mkPortValidation = port: portName: [
    {
      assertion = port > 0 && port < 65536;
      message = "${portName} must be a valid port number (1-65535).";
    }
  ];

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

  # Extract port from bind address helper
  extractPortFromBind = bindAddr:
    let
      parts = splitString ":" bindAddr;
    in
    if length parts >= 2
    then toInt (last parts)
    else throw "Invalid bind address format: ${bindAddr}";

  # Standard service options builder (generic, for any service type)
  mkStandardServiceOptions = serviceName: extraOptions: {
    enable = mkEnableOption "${serviceName} service";

    package = mkOption {
      type = types.package;
      default = null;
      description = "The ${serviceName} package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "service-${toLower serviceName}";
      description = "User account for ${serviceName} service.";
    };

    group = mkOption {
      type = types.str;
      default = "service-${toLower serviceName}";
      description = "Group for ${serviceName} service.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/service-${toLower serviceName}";
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

  # Service coordination helpers (enhanced with new discovery system)
  mkServiceCoordination = { services ? [], discoveryBackend ? "consul", ... }@args:
    let
      serviceDiscovery = import ./service-discovery.nix { inherit lib pkgs; };
      dependencyManagement = import ./dependency-management.nix { inherit lib pkgs; };
    in
    {
      # Service discovery configuration
      discovery = serviceDiscovery.mkServiceDiscovery {
        backend = discoveryBackend;
        services = lib.mapAttrs (name: config: {
          port = config.port;
          healthCheck = config.healthCheck or "/health";
          tags = config.tags or [];
        }) (args.serviceConfigs or {});
      };

      # Dependency management
      dependencies = dependencyManagement.mkDependencyManagement {
        services = args.serviceConfigs or {};
        startupStrategy = args.startupStrategy or "sequential";
      };

      # Load balancing configuration
      loadBalancer = {
        strategy = args.lbStrategy or "round-robin";
        healthyThreshold = args.healthyThreshold or 2;
        unhealthyThreshold = args.unhealthyThreshold or 3;
      };
    };
}
