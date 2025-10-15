# Defines the NixOS module for the Slingshot service
#
# Slingshot acts as a record edge cache, connecting to a Jetstream server.
# It supports features like zstd compression, caching, domain configuration,
# ACME/LetsEncrypt integration, and health checks.
#
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-slingshot;
in
{
  options.services.microcosm-slingshot = {
    enable = mkEnableOption "Slingshot server";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.slingshot;
      description = "The Slingshot package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/microcosm-slingshot";
      description = "The absolute path to the directory to store data in.";
    };

    jetstream = mkOption {
      type = types.str;
      description = "Jetstream server to connect to. This is a required option.";
      example = "wss://jetstream.example.com";
    };

    jetstreamNoZstd = mkOption {
      type = types.bool;
      default = false;
      description = "If true, don't request zstd-compressed Jetstream events, reducing CPU at the expense of more ingress bandwidth.";
    };

    cacheDir = mkOption {
      type = types.str;
      default = "${cfg.dataDir}/cache";
      description = "Directory where disk caches are kept.";
    };

    domain = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The domain pointing to this server. Enables DID document serving and HTTPS certs with Acme/LetsEncrypt.";
    };

    acmeContact = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Email address for LetsEncrypt contact. Recommended in production.";
    };

    certs = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "A location to cache ACME HTTPS certificates. Only used if 'domain' is specified.";
    };

    healthcheck = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "An web address to send healthcheck pings to periodically.";
    };
  };

  config = mkIf cfg.enable {
    # Create a static user and group for the service for security isolation.
    users.users.microcosm-slingshot = {
      isSystemUser = true;
      group = "microcosm-slingshot";
      home = cfg.dataDir;
    };
    users.groups.microcosm-slingshot = {};

    # Use tmpfiles to declaratively manage the data directory's existence and ownership.
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-slingshot microcosm-slingshot - -"
    ] ++ lib.optional (cfg.cacheDir != null) [
      "d ${cfg.cacheDir} 0755 microcosm-slingshot microcosm-slingshot - -"
    ];

    # Define the systemd service for Slingshot.
    systemd.services.microcosm-slingshot = {
      description = "Slingshot Server - Record edge cache";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-slingshot";
        Group = "microcosm-slingshot";

        WorkingDirectory = cfg.dataDir;

        # Security hardening settings for the service.
        NoNewPrivileges = true;
        ProtectSystem = "full";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ] ++ lib.optional (cfg.cacheDir != null) cfg.cacheDir;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
      };

      script =
        let
          args = flatten [
            [
              "--jetstream"
              (escapeShellArg cfg.jetstream)
              "--cache-dir"
              (escapeShellArg cfg.cacheDir)
            ]
            (optional cfg.jetstreamNoZstd [
              "--jetstream-no-zstd"
            ])
            (optional (cfg.domain != null) [
              "--domain"
              (escapeShellArg cfg.domain)
            ])
            (optional (cfg.acmeContact != null) [
              "--acme-contact"
              (escapeShellArg cfg.acmeContact)
            ])
            (optional (cfg.certs != null) [
              "--certs"
              (escapeShellArg cfg.certs)
            ])
            (optional (cfg.healthcheck != null) [
              "--healthcheck"
              (escapeShellArg cfg.healthcheck)
            ])
          ];
        in
        ''
          exec ${cfg.package}/bin/slingshot ${concatStringsSep " " args}
        '';
    };
  };
}