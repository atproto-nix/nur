# Defines the NixOS module for the Allegedly PLC tools service
{ config, lib, pkgs, ... }:

with lib;

let
  inherit (lib) hasInfix optionalString optional flatten escapeShellArg concatStringsSep optionals;
  cfg = config.services.microcosm-blue.allegedly;
in
{
  options.services.microcosm-blue.allegedly = {
    enable = mkEnableOption "Allegedly PLC tools service";

    package = mkOption {
      type = types.package;
      default = pkgs.microcosm-blue-allegedly or pkgs.allegedly;
      description = "The Allegedly package to use.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/allegedly";
      description = "Data directory for Allegedly";
    };

    user = mkOption {
      type = types.str;
      default = "allegedly";
      description = "User account for Allegedly service.";
    };

    group = mkOption {
      type = types.str;
      default = "allegedly";
      description = "Group for Allegedly service.";
    };

    mode = mkOption {
      type = types.enum [ "mirror" "wrap" "tail" "bundle" "backfill" ];
      default = "mirror";
      description = "Operation mode for Allegedly service.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          upstream = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "Upstream PLC directory URL.";
          };

          wrapUrl = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "URL to wrap (for mirror/wrap modes).";
            example = "http://127.0.0.1:3000";
          };

          database = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Enable PostgreSQL database integration";
            };

            connectionString = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "PostgreSQL connection string.";
              example = "postgresql://user:pass@localhost:5432/plc-db";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "File containing database password.";
            };

            certFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "PostgreSQL client certificate file.";
            };

            createDatabase = mkOption {
              type = types.bool;
              default = true;
              description = "Automatically create database and user";
            };

            databaseName = mkOption {
              type = types.str;
              default = "allegedly";
              description = "Name of the PostgreSQL database";
            };

            username = mkOption {
              type = types.str;
              default = "allegedly";
              description = "PostgreSQL username";
            };
          };

          acme = {
            enable = mkEnableOption "ACME TLS certificate provisioning";

            domains = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Domains to provision certificates for.";
              example = [ "plc.example.com" "alt.plc.example.com" ];
            };

            experimentalDomains = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Experimental domains for certificate provisioning.";
            };

            cachePath = mkOption {
              type = types.path;
              default = "${cfg.dataDir}/acme-cache";
              description = "ACME cache directory.";
            };

            directoryUrl = mkOption {
              type = types.str;
              default = "https://acme-staging-v02.api.letsencrypt.org/directory";
              description = "ACME directory URL.";
            };

            ipv6 = mkEnableOption "IPv6 support for ACME";
          };

          experimental = {
            writeUpstream = mkEnableOption "experimental write upstream support";
          };

          bundle = {
            destination = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = "Destination directory for bundle exports.";
            };

            sourceWorkers = mkOption {
              type = types.int;
              default = 6;
              description = "Number of source workers for backfill operations.";
            };
          };

          logLevel = mkOption {
            type = types.enum [ "trace" "debug" "info" "warn" "error" ];
            default = "info";
            description = "Logging level.";
          };
        };
      };
      default = {};
      description = "Allegedly service configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.mode == "mirror" -> (cfg.settings.wrapUrl != null);
        message = "services.microcosm-blue.allegedly: wrapUrl must be specified when using mirror mode";
      }
      {
        assertion = cfg.settings.acme.enable -> (cfg.settings.acme.domains != []);
        message = "services.microcosm-blue.allegedly: ACME domains must be specified when ACME is enabled";
      }
      {
        assertion = cfg.mode == "bundle" -> (cfg.settings.bundle.destination != null);
        message = "services.microcosm-blue.allegedly: bundle destination must be specified when using bundle mode";
      }
    ];

    warnings = lib.optionals (cfg.settings.acme.enable && cfg.settings.acme.directoryUrl == "https://acme-staging-v02.api.letsencrypt.org/directory") [
      "Allegedly ACME is using staging directory - certificates will not be trusted in production"
    ] ++ lib.optionals (cfg.settings.database.enable && cfg.settings.database.connectionString != null && hasInfix "password" cfg.settings.database.connectionString) [
      "Allegedly database connection string contains password in plain text. Consider using environment variables."
    ];

    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
    };

    users.groups.${cfg.group} = {};

    # PostgreSQL setup if enabled
    services.postgresql = mkIf (cfg.settings.database.enable && cfg.settings.database.createDatabase) {
      enable = true;
      ensureDatabases = [ cfg.settings.database.databaseName ];
      ensureUsers = [
        {
          name = cfg.settings.database.username;
          ensureDBOwnership = true;
        }
      ];
    };

    # Directory management
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ] ++ lib.optional (cfg.settings.acme.enable) [
      "d '${cfg.settings.acme.cachePath}' 0750 ${cfg.user} ${cfg.group} - -"
    ] ++ lib.optional (cfg.settings.bundle.destination != null) [
      "d '${cfg.settings.bundle.destination}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # systemd service
    systemd.services.microcosm-blue-allegedly = {
      description = "Allegedly PLC tools service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ lib.optional (cfg.settings.database.enable && cfg.settings.database.createDatabase) [ "postgresql.service" ];
      requires = lib.optionals (cfg.settings.database.enable && cfg.settings.database.createDatabase) [ "postgresql.service" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        RestartSec = "10s";

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
        ReadWritePaths = [ cfg.dataDir ] 
          ++ lib.optional (cfg.settings.acme.enable) cfg.settings.acme.cachePath
          ++ lib.optional (cfg.settings.bundle.destination != null) cfg.settings.bundle.destination;
        ReadOnlyPaths = [ "/nix/store" ];

        # Network capabilities for ACME (if enabled)
        AmbientCapabilities = lib.mkIf cfg.settings.acme.enable [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = lib.mkIf cfg.settings.acme.enable [ "CAP_NET_BIND_SERVICE" ];
      };

      environment = {
        RUST_LOG = cfg.settings.logLevel;
      } // lib.optionalAttrs (cfg.settings.database.passwordFile != null) {
        ALLEGEDLY_WRAP_PG = "$(cat ${cfg.settings.database.passwordFile})";
      };

      script = 
        let
          args = flatten [
            [ cfg.mode ]
            (optional (cfg.settings.upstream != "https://plc.directory") [
              "--upstream" (escapeShellArg cfg.settings.upstream)
            ])
            (optional (cfg.settings.wrapUrl != null) [
              "--wrap" (escapeShellArg cfg.settings.wrapUrl)
            ])
            (optional (cfg.settings.database.connectionString != null && cfg.settings.database.passwordFile == null) [
              "--wrap-pg" (escapeShellArg cfg.settings.database.connectionString)
            ])
            (optional (cfg.settings.database.certFile != null) [
              "--wrap-pg-cert" (escapeShellArg (toString cfg.settings.database.certFile))
            ])
            (optionals (cfg.settings.acme.enable) (
              (map (domain: [ "--acme-domain" (escapeShellArg domain) ]) cfg.settings.acme.domains) ++
              (map (domain: [ "--experimental-acme-domain" (escapeShellArg domain) ]) cfg.settings.acme.experimentalDomains) ++
              [
                [ "--acme-cache-path" (escapeShellArg (toString cfg.settings.acme.cachePath)) ]
                [ "--acme-directory-url" (escapeShellArg cfg.settings.acme.directoryUrl) ]
              ] ++
              (optional cfg.settings.acme.ipv6 [ "--acme-ipv6" ])
            ))
            (optional cfg.settings.experimental.writeUpstream [ "--experimental-write-upstream" ])
            (optional (cfg.mode == "bundle" && cfg.settings.bundle.destination != null) [
              "--dest" (escapeShellArg (toString cfg.settings.bundle.destination))
            ])
            (optional (cfg.mode == "backfill") [
              "--source-workers" (escapeShellArg (toString cfg.settings.bundle.sourceWorkers))
            ])
          ];
        in
        ''
          exec ${cfg.package}/bin/allegedly ${concatStringsSep " " (flatten args)}
        '';

      # Database connectivity check
      preStart = mkIf cfg.settings.database.enable ''
        # Wait for PostgreSQL to be ready
        ${optionalString (cfg.settings.database.enable && cfg.settings.database.createDatabase) ''
          until ${pkgs.postgresql}/bin/pg_isready -h localhost -p 5432; do
            echo "Waiting for PostgreSQL..."
            sleep 2
          done
        ''}
      '';
    };

    # Open firewall ports for ACME if enabled
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.settings.acme.enable [ 80 443 ];
  };
}