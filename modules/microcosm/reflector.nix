# Defines the NixOS module for the Reflector service
#
# Reflector serves DID documents and acts as a Slingshot record edge cache.
# This module configures its DID, type, service endpoint, and optional domain.
#
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-reflector;
in
{
  options.services.microcosm-reflector = {
    enable = mkEnableOption "Reflector server";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.reflector;
      description = "The Reflector package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/microcosm-reflector";
      description = "The absolute path to the directory to store data in.";
    };

    id = mkOption {
      type = types.str;
      description = "The DID document service ID to serve (e.g., #bsky_appview). This is a required option.";
      example = "#bsky_appview";
    };

    type = mkOption {
      type = types.str;
      description = "Service type (e.g., BlueskyAppview). This is a required option.";
      example = "BlueskyAppview";
    };

    serviceEndpoint = mkOption {
      type = types.str;
      description = "The HTTPS endpoint for the service. This is a required option.";
      example = "https://reflector.example.com";
    };

    domain = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The parent domain; requests should come from subdomains of this. Used for DID resolution.";
    };
  };

  config = mkIf cfg.enable {
    # Create a static user and group for the service for security isolation.
    users.users.microcosm-reflector = {
      isSystemUser = true;
      group = "microcosm-reflector";
      home = cfg.dataDir;
    };
    users.groups.microcosm-reflector = {};

    # Use tmpfiles to declaratively manage the data directory's existence and ownership.
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-reflector microcosm-reflector - -"
    ];

    # Define the systemd service for Reflector.
    systemd.services.microcosm-reflector = {
      description = "Reflector Server - Slingshot record edge cache and DID document server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-reflector";
        Group = "microcosm-reflector";

        WorkingDirectory = cfg.dataDir;

        # Security hardening settings for the service.
        NoNewPrivileges = true;
        ProtectSystem = "full";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ];
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
              "--id"
              (escapeShellArg cfg.id)
              "--type"
              (escapeShellArg cfg.type)
              "--service-endpoint"
              (escapeShellArg cfg.serviceEndpoint)
            ]
            (optional (cfg.domain != null) [
              "--domain"
              (escapeShellArg cfg.domain)
            ])
          ];
        in
        ''
          exec ${cfg.package}/bin/reflector ${concatStringsSep " " args}
        '';
    };
  };
}