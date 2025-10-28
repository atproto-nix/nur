{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.labeler = {
    enable = mkEnableOption "Blacksky Labeler service";
    port = mkOption {
      type = types.port;
      default = 8005;
      description = "Port for the Blacksky Labeler service.";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/blacksky-labeler";
      description = "Data directory for the Blacksky Labeler service.";
    };
  };

  config = mkIf config.blacksky.labeler.enable {
    # User and group management
    users.users.blacksky-labeler = {
      isSystemUser = true;
      group = "blacksky-labeler";
      home = config.blacksky.labeler.dataDir;
    };
    
    users.groups.blacksky-labeler = {};
    
    # Directory management using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d '${config.blacksky.labeler.dataDir}' 0750 blacksky-labeler blacksky-labeler - -"
    ];
    
    systemd.services.blacksky-labeler = {
      description = "Blacksky Labeler service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "exec";
        User = "blacksky-labeler";
        Group = "blacksky-labeler";
        WorkingDirectory = config.blacksky.labeler.dataDir;
        ExecStart = "${pkgs.blacksky-labeler}/bin/rsky-labeler --port ${toString config.blacksky.labeler.port}";
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
        ReadWritePaths = [ config.blacksky.labeler.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };
    };
  };
}