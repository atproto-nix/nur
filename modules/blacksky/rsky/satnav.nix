{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.satnav = {
    enable = mkEnableOption "Blacksky Satnav service";
    port = mkOption {
      type = types.port;
      default = 8002;
      description = "Port for the Blacksky Satnav service.";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/blacksky-satnav";
      description = "Data directory for the Blacksky Satnav service.";
    };
  };

  config = mkIf config.blacksky.satnav.enable {
    # User and group management
    users.users.blacksky-satnav = {
      isSystemUser = true;
      group = "blacksky-satnav";
      home = config.blacksky.satnav.dataDir;
    };
    
    users.groups.blacksky-satnav = {};
    
    # Directory management using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d '${config.blacksky.satnav.dataDir}' 0750 blacksky-satnav blacksky-satnav - -"
    ];
    
    systemd.services.blacksky-satnav = {
      description = "Blacksky Satnav service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "exec";
        User = "blacksky-satnav";
        Group = "blacksky-satnav";
        WorkingDirectory = config.blacksky.satnav.dataDir;
        ExecStart = "${pkgs.blacksky-satnav}/bin/rsky-satnav --port ${toString config.blacksky.satnav.port}";
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
        ReadWritePaths = [ config.blacksky.satnav.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };
    };
  };
}