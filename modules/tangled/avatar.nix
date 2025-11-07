{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.tangled-avatar;
in
{
  options.services.tangled-avatar = {
    enable = mkEnableOption "Tangled Avatar Service";

    package = mkOption {
      type = types.package;
      default = pkgs.tangled-avatar or (pkgs.callPackage ../../pkgs/tangled/avatar.nix { });
      description = "The tangled-avatar package to use.";
    };

    port = mkOption {
      type = types.port;
      default = 8787;
      description = "Port for the avatar service to listen on.";
    };

    sharedSecretFile = mkOption {
      type = types.path;
      description = ''
        Path to file containing the AVATAR_SHARED_SECRET.
        This secret is used for HMAC signature verification.
        Must be the same secret configured in the appview service.
      '';
      example = "/run/secrets/avatar-shared-secret";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for the avatar service port.";
    };

    user = mkOption {
      type = types.str;
      default = "tangled-avatar";
      description = "User account under which the avatar service runs.";
    };

    group = mkOption {
      type = types.str;
      default = "tangled-avatar";
      description = "Group under which the avatar service runs.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pathExists cfg.sharedSecretFile;
        message = "Avatar shared secret file must exist at ${cfg.sharedSecretFile}";
      }
    ];

    # Create user and group for the service
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      description = "Tangled Avatar service user";
    };

    users.groups.${cfg.group} = {};

    # Create systemd service for avatar (runs via wrangler dev)
    systemd.services.tangled-avatar = {
      description = "Tangled Avatar Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/avatar";
        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;

        # Runtime directory
        RuntimeDirectory = "tangled-avatar";
        StateDirectory = "tangled-avatar";
        WorkingDirectory = "/var/lib/tangled-avatar";

        # Environment
        Environment = [
          "HOME=/var/lib/tangled-avatar"
        ];
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
