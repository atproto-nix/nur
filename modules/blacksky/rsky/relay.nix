{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.relay = {
    enable = mkEnableOption "Blacksky Relay service";
    port = mkOption {
      type = types.port;
      default = 8000;
      description = "Port for the Blacksky Relay service.";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/blacksky-relay";
      description = "Data directory for the Blacksky Relay service.";
    };
  };

  config = mkIf config.blacksky.relay.enable {
    # User and group management
    users.users.blacksky-relay = {
      isSystemUser = true;
      group = "blacksky-relay";
      home = config.blacksky.relay.dataDir;
    };
    
    users.groups.blacksky-relay = {};
    
    # Directory management using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d '${config.blacksky.relay.dataDir}' 0750 blacksky-relay blacksky-relay - -"
    ];
    
    systemd.services.blacksky-relay = {
      description = "Blacksky Relay service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "exec";
        User = "blacksky-relay";
        Group = "blacksky-relay";
        WorkingDirectory = config.blacksky.relay.dataDir;
        ExecStart = "${pkgs.blacksky-relay}/bin/rsky-relay --port ${toString config.blacksky.relay.port}";
        Restart = "on-failure";
        RestartSec = "5s";
        
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
        ReadWritePaths = [ config.blacksky.relay.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };
    };
  };
}