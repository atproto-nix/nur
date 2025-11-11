{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.relay = {
    enable = mkEnableOption "Blacksky Relay service";
    port = mkOption {
      type = types.port;
      default = 9000;
      description = "Port for the Blacksky Relay service (hard-coded in binary, option exists for documentation).";
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
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "exec";
        User = "blacksky-relay";
        Group = "blacksky-relay";
        WorkingDirectory = config.blacksky.relay.dataDir;
        ExecStart = "${pkgs.blacksky.relay}/bin/rsky-relay --no-plc-export";
        Restart = "on-failure";
        RestartSec = "5s";
        
        # Security hardening (relaxed for SQLite and Rust compatibility)
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
        # MemoryDenyWriteExecute and RestrictNamespaces disabled for SQLite/Rust compatibility

        # File system access
        ReadWritePaths = [ config.blacksky.relay.dataDir ];
      };
    };
  };
}