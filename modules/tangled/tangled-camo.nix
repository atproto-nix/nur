{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.tangled-camo;
in
{
  options.services.tangled-camo = {
    enable = mkEnableOption "Tangled Camo Service";

    package = mkOption {
      type = types.package;
      default = pkgs.tangled-camo or (pkgs.callPackage ../../pkgs/tangled/camo.nix { });
      description = "The tangled-camo package to use.";
    };

    port = mkOption {
      type = types.port;
      default = 8788;
      description = "Port for the camo service to listen on.";
    };

    sharedSecretFile = mkOption {
      type = types.path;
      description = ''
        Path to file containing the CAMO_SHARED_SECRET.
        This secret is used for HMAC signature verification.
        Must be the same secret configured in the appview/knot services.
      '';
      example = "/run/secrets/camo-shared-secret";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for the camo service port.";
    };

    user = mkOption {
      type = types.str;
      default = "tangled-camo";
      description = "User account under which the camo service runs.";
    };

    group = mkOption {
      type = types.str;
      default = "tangled-camo";
      description = "Group under which the camo service runs.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pathExists cfg.sharedSecretFile;
        message = "Camo shared secret file must exist at ${cfg.sharedSecretFile}";
      }
    ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      description = "Tangled Camo service user";
    };

    users.groups.${cfg.group} = { };

    systemd.services.tangled-camo = {
      description = "Tangled Camo Service - Image proxy with anonymized URLs";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;

        ExecStart = ''
          ${cfg.package}/bin/camo --port ${toString cfg.port}
        '';

        # Load shared secret from file
        EnvironmentFile = cfg.sharedSecretFile;

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [];

        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
