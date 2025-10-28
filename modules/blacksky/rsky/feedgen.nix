{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.feedgen = {
    enable = mkEnableOption "Blacksky Feed Generator service";
    port = mkOption {
      type = types.port;
      default = 8001;
      description = "Port for the Blacksky Feed Generator service.";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/blacksky-feedgen";
      description = "Data directory for the Blacksky Feed Generator service.";
    };
  };

  config = mkIf config.blacksky.feedgen.enable {
    # User and group management
    users.users.blacksky-feedgen = {
      isSystemUser = true;
      group = "blacksky-feedgen";
      home = config.blacksky.feedgen.dataDir;
    };
    
    users.groups.blacksky-feedgen = {};
    
    # Directory management using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d '${config.blacksky.feedgen.dataDir}' 0750 blacksky-feedgen blacksky-feedgen - -"
    ];
    
    systemd.services.blacksky-feedgen = {
      description = "Blacksky Feed Generator service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "exec";
        User = "blacksky-feedgen";
        Group = "blacksky-feedgen";
        WorkingDirectory = config.blacksky.feedgen.dataDir;
        ExecStart = "${pkgs.blacksky-feedgen}/bin/rsky-feedgen --port ${toString config.blacksky.feedgen.port}";
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
        ReadWritePaths = [ config.blacksky.feedgen.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };
    };
  };
}