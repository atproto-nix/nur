{ config, lib, pkgs, ... }:

with lib;

{
  options.blacksky.jetstreamSubscriber = {
    enable = mkEnableOption "Blacksky Jetstream Subscriber service";
    port = mkOption {
      type = types.port;
      default = 8004;
      description = "Port for the Blacksky Jetstream Subscriber service.";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/blacksky-jetstream-subscriber";
      description = "Data directory for the Blacksky Jetstream Subscriber service.";
    };
  };

  config = mkIf config.blacksky.jetstreamSubscriber.enable {
    # User and group management
    users.users.blacksky-jetstream-subscriber = {
      isSystemUser = true;
      group = "blacksky-jetstream-subscriber";
      home = config.blacksky.jetstreamSubscriber.dataDir;
    };
    
    users.groups.blacksky-jetstream-subscriber = {};
    
    # Directory management using systemd tmpfiles
    systemd.tmpfiles.rules = [
      "d '${config.blacksky.jetstreamSubscriber.dataDir}' 0750 blacksky-jetstream-subscriber blacksky-jetstream-subscriber - -"
    ];
    
    systemd.services.blacksky-jetstream-subscriber = {
      description = "Blacksky Jetstream Subscriber service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "exec";
        User = "blacksky-jetstream-subscriber";
        Group = "blacksky-jetstream-subscriber";
        WorkingDirectory = config.blacksky.jetstreamSubscriber.dataDir;
        ExecStart = "${pkgs.blacksky-jetstreamSubscriber}/bin/rsky-jetstream-subscriber --port ${toString config.blacksky.jetstreamSubscriber.port}";
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
        ReadWritePaths = [ config.blacksky.jetstreamSubscriber.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };
    };
  };
}