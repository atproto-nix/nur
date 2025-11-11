{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.bluesky.pds-gatekeeper;
  
  # Generate environment file for pds-gatekeeper
  envFile = pkgs.writeText "pds-gatekeeper.env" (concatStringsSep "\n" (
    mapAttrsToList (name: value: "${name}=${toString value}") cfg.environment
  ));
  
  # Create startup script
  startupScript = pkgs.writeShellScript "pds-gatekeeper-start" ''
    set -euo pipefail
    
    # Set up data directory
    mkdir -p ${cfg.dataDir}
    cd ${cfg.dataDir}
    
    # Copy email templates if custom directory is specified
    ${optionalString (cfg.settings.emailTemplatesDirectory != null) ''
      if [ -d "${cfg.settings.emailTemplatesDirectory}" ]; then
        export GATEKEEPER_EMAIL_TEMPLATES_DIRECTORY="${cfg.settings.emailTemplatesDirectory}"
      fi
    ''}
    
    # Set up environment
    export PDS_DATA_DIRECTORY="${cfg.settings.pdsDataDirectory}"
    export PDS_ENV_LOCATION="${cfg.settings.pdsEnvLocation}"
    export PDS_BASE_URL="${cfg.settings.pdsBaseUrl}"
    export GATEKEEPER_HOST="${cfg.settings.host}"
    export GATEKEEPER_PORT="${toString cfg.settings.port}"
    
    ${optionalString (cfg.settings.twoFactorEmailSubject != null) ''
      export GATEKEEPER_TWO_FACTOR_EMAIL_SUBJECT="${cfg.settings.twoFactorEmailSubject}"
    ''}
    
    ${optionalString (cfg.settings.createAccountPerSecond != null) ''
      export GATEKEEPER_CREATE_ACCOUNT_PER_SECOND="${toString cfg.settings.createAccountPerSecond}"
    ''}
    
    ${optionalString (cfg.settings.createAccountBurst != null) ''
      export GATEKEEPER_CREATE_ACCOUNT_BURST="${toString cfg.settings.createAccountBurst}"
    ''}
    
    # Start the service
    exec ${cfg.package}/bin/pds_gatekeeper
  '';
in
{
  options.services.bluesky.pds-gatekeeper = {
    enable = mkEnableOption "PDS Gatekeeper security microservice";

    package = mkOption {
      type = types.package;
      default = pkgs.individual-pds-gatekeeper or pkgs.pds-gatekeeper;
      defaultText = literalExpression "pkgs.pds-gatekeeper";
      description = "PDS Gatekeeper package to use";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/pds-gatekeeper";
      description = "Data directory for PDS Gatekeeper";
    };

    user = mkOption {
      type = types.str;
      default = "pds-gatekeeper";
      description = "User account for PDS Gatekeeper service";
    };

    group = mkOption {
      type = types.str;
      default = "pds-gatekeeper";
      description = "Group for PDS Gatekeeper service";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          pdsDataDirectory = mkOption {
            type = types.path;
            default = "/var/lib/pds";
            description = "Root directory of the PDS installation";
          };

          pdsEnvLocation = mkOption {
            type = types.path;
            default = "/var/lib/pds/pds.env";
            description = "Location of the PDS environment file";
          };

          pdsBaseUrl = mkOption {
            type = types.str;
            default = "http://localhost:3000";
            description = "Base URL of the PDS service";
          };

          host = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Host address to bind to";
          };

          port = mkOption {
            type = types.port;
            default = 8080;
            description = "Port to listen on";
          };

          emailTemplatesDirectory = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Custom directory for email templates";
          };

          twoFactorEmailSubject = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "Sign in to Bluesky";
            description = "Subject line for 2FA emails";
          };

          createAccountPerSecond = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
            description = "Rate limit: seconds between account creation attempts";
          };

          createAccountBurst = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
            description = "Rate limit: maximum burst of account creation requests";
          };

          openFirewall = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to open the firewall for the gatekeeper port";
          };
        };
      };
      default = {};
      description = "PDS Gatekeeper configuration";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Additional environment variables for PDS Gatekeeper";
    };
  };

  config = mkIf cfg.enable {
    # Configuration validation
    assertions = [
      {
        assertion = cfg.settings.port > 0 && cfg.settings.port < 65536;
        message = "services.bluesky.pds-gatekeeper.settings.port must be a valid port number (1-65535)";
      }
      {
        assertion = pathExists cfg.settings.pdsDataDirectory;
        message = "services.bluesky.pds-gatekeeper.settings.pdsDataDirectory must exist and be accessible";
      }
      {
        assertion = cfg.settings.createAccountPerSecond == null || cfg.settings.createAccountPerSecond > 0;
        message = "services.bluesky.pds-gatekeeper.settings.createAccountPerSecond must be positive if set";
      }
      {
        assertion = cfg.settings.createAccountBurst == null || cfg.settings.createAccountBurst > 0;
        message = "services.bluesky.pds-gatekeeper.settings.createAccountBurst must be positive if set";
      }
    ];

    warnings = [
      (mkIf (cfg.settings.host == "0.0.0.0" && !cfg.settings.openFirewall)
        "PDS Gatekeeper is binding to 0.0.0.0 but firewall is not opened. Consider setting openFirewall = true or using a more restrictive bind address.")
    ];

    # User and group management
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      description = "PDS Gatekeeper service user";
    };

    users.groups.${cfg.group} = {};

    # Directory management using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      # Ensure PDS data directory is accessible (read-only)
      "d '${cfg.settings.pdsDataDirectory}' 0755 - - - -"
    ];

    # systemd service with security hardening
    systemd.services.pds-gatekeeper = {
      description = "PDS Gatekeeper security microservice";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = startupScript;
        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitBurst = 3;
        StartLimitIntervalSec = "60s";

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        
        # File system access
        ReadWritePaths = [ cfg.dataDir ];
        ReadOnlyPaths = [ 
          "/nix/store" 
          cfg.settings.pdsDataDirectory
        ];
        
        # Network access
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        
        # Capabilities - minimal required for network binding
        CapabilityBoundingSet = [ "" ];
        AmbientCapabilities = [ "" ];
      };

      # Ensure PDS data directory is accessible
      preStart = ''
        # Verify PDS data directory exists and is readable
        if [ ! -d "${cfg.settings.pdsDataDirectory}" ]; then
          echo "ERROR: PDS data directory ${cfg.settings.pdsDataDirectory} does not exist"
          exit 1
        fi
        
        if [ ! -r "${cfg.settings.pdsEnvLocation}" ]; then
          echo "WARNING: PDS environment file ${cfg.settings.pdsEnvLocation} is not readable"
        fi
      '';
    };

    # Firewall configuration
    networking.firewall.allowedTCPPorts = mkIf cfg.settings.openFirewall [ cfg.settings.port ];
  };
}