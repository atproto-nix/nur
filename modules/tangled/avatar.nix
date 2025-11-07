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
      home = "/var/lib/tangled-avatar";
      createHome = true;
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

        # Setup environment before starting: generate env file with secret
      ExecStartPre = let
        script = pkgs.writeShellScript "avatar-init" ''
          mkdir -p /var/lib/tangled-avatar /var/cache/tangled-avatar
          # Generate environment file with the shared secret
          cat > /var/lib/tangled-avatar/.avatar.env <<'ENVEOF'
          AVATAR_SHARED_SECRET="$(cat ${cfg.sharedSecretFile})"
          ENVEOF
          chmod 0600 /var/lib/tangled-avatar/.avatar.env
        '';
      in "${script}";

        ExecStart = "${cfg.package}/bin/avatar";

        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening (balanced for writable state directory)
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];

        # Runtime directory for wrangler cache
        RuntimeDirectory = "tangled-avatar";
        RuntimeDirectoryMode = "0700";
        StateDirectory = "tangled-avatar";
        StateDirectoryMode = "0700";
        CacheDirectory = "tangled-avatar";
        CacheDirectoryMode = "0700";

        # Working directory
        WorkingDirectory = "/var/lib/tangled-avatar";

        # Read-write paths for state and cache
        ReadWritePaths = [
          "/var/lib/tangled-avatar"
          "/var/cache/tangled-avatar"
          "/var/run/tangled-avatar"
        ];

        # Load environment file with shared secret
        EnvironmentFiles = [ "/var/lib/tangled-avatar/.avatar.env" ];

        # Default environment
        Environment = [
          "HOME=/var/lib/tangled-avatar"
          "NODE_ENV=production"
          "RUNTIME_DIRECTORY=/var/lib/tangled-avatar"
        ];
      };
    };

    # Ensure proper permissions and ownership of shared secret file at runtime
    system.activationScripts.tangled-avatar-secrets = ''
      if [ -f "${cfg.sharedSecretFile}" ]; then
        chmod 0600 "${cfg.sharedSecretFile}"
        chown ${cfg.user}:${cfg.group} "${cfg.sharedSecretFile}" 2>/dev/null || true
      fi

      # Create and set permissions on state directory
      mkdir -p /var/lib/tangled-avatar /var/cache/tangled-avatar
      chown ${cfg.user}:${cfg.group} /var/lib/tangled-avatar /var/cache/tangled-avatar
      chmod 0700 /var/lib/tangled-avatar /var/cache/tangled-avatar
    '';

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
