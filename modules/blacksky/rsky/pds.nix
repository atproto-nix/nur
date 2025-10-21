{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.pds = {
    enable = mkEnableOption "Blacksky PDS service";
    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port for the Blacksky PDS service.";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/blacksky-pds";
      description = "Data directory for the Blacksky PDS service.";
    };
  };

  config = mkIf config.blacksky.pds.enable {
    # User and group management
    users.users.blacksky-pds = {
      isSystemUser = true;
      group = "blacksky-pds";
      home = config.blacksky.pds.dataDir;
    };
    
    users.groups.blacksky-pds = {};
    
    # Directory management using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d '${config.blacksky.pds.dataDir}' 0750 blacksky-pds blacksky-pds - -"
    ];
    
    systemd.services.blacksky-pds = {
      description = "Blacksky PDS service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "exec";
        User = "blacksky-pds";
        Group = "blacksky-pds";
        WorkingDirectory = config.blacksky.pds.dataDir;
        ExecStart = "${pkgs.blacksky-pds}/bin/rsky-pds --port ${toString config.blacksky.pds.port}";
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
        ReadWritePaths = [ config.blacksky.pds.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };
    };
  };
}