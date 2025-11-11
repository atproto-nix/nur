{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.firehose = {
    enable = mkEnableOption "Blacksky Firehose service";
    port = mkOption {
      type = types.port;
      default = 8003;
      description = "Port for the Blacksky Firehose service.";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/blacksky-firehose";
      description = "Data directory for the Blacksky Firehose service.";
    };
  };

  config = mkIf config.blacksky.firehose.enable {
    # User and group management
    users.users.blacksky-firehose = {
      isSystemUser = true;
      group = "blacksky-firehose";
      home = config.blacksky.firehose.dataDir;
    };
    
    users.groups.blacksky-firehose = {};
    
    # Directory management using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d '${config.blacksky.firehose.dataDir}' 0750 blacksky-firehose blacksky-firehose - -"
    ];
    
    systemd.services.blacksky-firehose = {
      description = "Blacksky Firehose service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "exec";
        User = "blacksky-firehose";
        Group = "blacksky-firehose";
        WorkingDirectory = config.blacksky.firehose.dataDir;
        ExecStart = "${pkgs.blacksky-firehose}/bin/rsky-firehose --port ${toString config.blacksky.firehose.port}";
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
        ReadWritePaths = [ config.blacksky.firehose.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };
    };
  };
}