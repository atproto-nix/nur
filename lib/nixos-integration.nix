# NixOS ecosystem integration utilities for ATProto services
{ lib, config, ... }:

with lib;

rec {
  # Common database integration patterns
  mkDatabaseIntegration = serviceName: cfg: databaseConfig: {
    assertions = [
      {
        assertion = databaseConfig.type == "postgres" -> (hasInfix "postgresql://" databaseConfig.url);
        message = "${serviceName}: PostgreSQL URL must start with 'postgresql://' when using postgres database type";
      }
      {
        assertion = databaseConfig.type == "mysql" -> (hasInfix "mysql://" databaseConfig.url);
        message = "${serviceName}: MySQL URL must start with 'mysql://' when using mysql database type";
      }
    ];

    # Automatic service dependencies
    systemd.services.${serviceName} = {
      after = [ "network.target" ] 
        ++ optional (databaseConfig.type == "postgres") [ "postgresql.service" ]
        ++ optional (databaseConfig.type == "mysql") [ "mysql.service" ];
      
      wants = [ "network.target" ];
    };

    # Enable required database services
    services.postgresql = mkIf (databaseConfig.type == "postgres") {
      enable = mkDefault true;
      ensureDatabases = mkIf (databaseConfig.createDatabase or false) [ databaseConfig.database ];
      ensureUsers = mkIf (databaseConfig.createUser or false) [{
        name = databaseConfig.user;
        ensureDBOwnership = true;
      }];
    };

    services.mysql = mkIf (databaseConfig.type == "mysql") {
      enable = mkDefault true;
      ensureDatabases = mkIf (databaseConfig.createDatabase or false) [ databaseConfig.database ];
      ensureUsers = mkIf (databaseConfig.createUser or false) [{
        name = databaseConfig.user;
        ensurePermissions = {
          "${databaseConfig.database}.*" = "ALL PRIVILEGES";
        };
      }];
    };
  };

  # Redis integration for caching and real-time features
  mkRedisIntegration = serviceName: cfg: redisConfig: mkIf (redisConfig.enable or (redisConfig.url != null)) {
    assertions = [
      {
        assertion = redisConfig.url != null -> (hasPrefix "redis://" redisConfig.url || hasPrefix "rediss://" redisConfig.url);
        message = "${serviceName}: Redis URL must start with 'redis://' or 'rediss://'";
      }
    ];

    systemd.services.${serviceName} = {
      after = [ "redis.service" ];
    };

    # Enable Redis service with service-specific configuration
    services.redis.servers.${serviceName} = {
      enable = mkDefault true;
      port = redisConfig.port or 6379;
      bind = redisConfig.bind or "127.0.0.1";
      requirePass = mkIf (redisConfig.passwordFile != null) "$(cat ${redisConfig.passwordFile})";
    };
  };

  # Nginx reverse proxy integration
  mkNginxIntegration = serviceName: cfg: nginxConfig: mkIf nginxConfig.enable {
    assertions = [
      {
        assertion = nginxConfig.serverName != "";
        message = "${serviceName}: Nginx server name cannot be empty";
      }
      {
        assertion = nginxConfig.port > 0 && nginxConfig.port < 65536;
        message = "${serviceName}: Nginx upstream port must be valid (1-65535)";
      }
    ];

    services.nginx = {
      enable = mkDefault true;
      
      virtualHosts.${nginxConfig.serverName} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString nginxConfig.port}";
          proxyWebsockets = nginxConfig.websockets or false;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            ${nginxConfig.extraConfig or ""}
          '';
        };
        
        # SSL configuration if enabled
        enableACME = nginxConfig.ssl.enable or false;
        forceSSL = nginxConfig.ssl.force or false;
        
        # Additional locations for API endpoints, metrics, etc.
        locations = nginxConfig.locations or {};
      };
    };

    # ACME certificate management
    security.acme = mkIf (nginxConfig.ssl.enable or false) {
      acceptTerms = mkDefault true;
      defaults.email = nginxConfig.ssl.email or "admin@${nginxConfig.serverName}";
    };
  };

  # Prometheus metrics integration
  mkPrometheusIntegration = serviceName: cfg: metricsConfig: mkIf metricsConfig.enable {
    assertions = [
      {
        assertion = metricsConfig.port > 0 && metricsConfig.port < 65536;
        message = "${serviceName}: Metrics port must be valid (1-65535)";
      }
    ];

    services.prometheus = mkIf (metricsConfig.prometheus.enable or true) {
      enable = mkDefault true;
      
      scrapeConfigs = [{
        job_name = serviceName;
        static_configs = [{
          targets = [ "localhost:${toString metricsConfig.port}" ];
        }];
        scrape_interval = metricsConfig.scrapeInterval or "15s";
        metrics_path = metricsConfig.path or "/metrics";
      }];
    };

    # Grafana dashboard integration
    services.grafana = mkIf (metricsConfig.grafana.enable or false) {
      enable = mkDefault true;
      
      provision = {
        enable = mkDefault true;
        datasources.settings.datasources = [{
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          isDefault = true;
        }];
      };
    };
  };

  # Systemd journal integration with structured logging
  mkLoggingIntegration = serviceName: cfg: loggingConfig: {
    systemd.services.${serviceName} = {
      serviceConfig = {
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = serviceName;
      };
      
      environment = {
        LOG_LEVEL = loggingConfig.level or "info";
        LOG_FORMAT = loggingConfig.format or "json";
      } // (loggingConfig.extraEnv or {});
    };

    # Journald configuration for the service
    services.journald.extraConfig = ''
      # ${serviceName} logging configuration
      SystemMaxUse=${loggingConfig.maxDiskUsage or "1G"}
      SystemKeepFree=${loggingConfig.keepFree or "500M"}
      MaxRetentionSec=${toString (loggingConfig.retentionDays or 30 * 24 * 3600)}
    '';

    # Logrotate integration for file-based logs
    services.logrotate = mkIf (loggingConfig.files != []) {
      enable = mkDefault true;
      settings.${serviceName} = {
        files = loggingConfig.files;
        frequency = loggingConfig.rotateFrequency or "daily";
        rotate = loggingConfig.rotateCount or 7;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
        postrotate = "systemctl reload ${serviceName} || true";
      };
    };
  };

  # Security integration with common NixOS security tools
  mkSecurityIntegration = serviceName: cfg: securityConfig: {
    # Fail2ban integration for services with authentication
    services.fail2ban = mkIf (securityConfig.fail2ban.enable or false) {
      enable = mkDefault true;
      
      jails.${serviceName} = {
        settings = {
          enabled = true;
          port = toString cfg.port;
          filter = serviceName;
          logpath = "/var/log/${serviceName}/*.log";
          maxretry = securityConfig.fail2ban.maxRetry or 5;
          bantime = securityConfig.fail2ban.banTime or 3600;
          findtime = securityConfig.fail2ban.findTime or 600;
        };
      };
    };

    # AppArmor profile integration
    security.apparmor = mkIf (securityConfig.apparmor.enable or false) {
      enable = mkDefault true;
      
      profiles.${serviceName} = {
        enforce = securityConfig.apparmor.enforce or true;
        profile = ''
          #include <tunables/global>
          
          ${cfg.package}/bin/* {
            #include <abstractions/base>
            #include <abstractions/nameservice>
            
            # Network access
            network inet stream,
            network inet6 stream,
            
            # File system access
            ${cfg.dataDir}/** rw,
            /tmp/** rw,
            /proc/sys/kernel/random/uuid r,
            
            # Nix store access
            /nix/store/** r,
            
            ${securityConfig.apparmor.extraRules or ""}
          }
        '';
      };
    };

    # SELinux integration (if available)
    # Note: NixOS doesn't have built-in SELinux support, but we can prepare for it
    assertions = [
      {
        assertion = !(securityConfig.selinux.enable or false);
        message = "${serviceName}: SELinux is not currently supported on NixOS";
      }
    ];
  };

  # Backup integration with common backup tools
  mkBackupIntegration = serviceName: cfg: backupConfig: mkIf backupConfig.enable {
    # Restic backup integration
    services.restic.backups.${serviceName} = mkIf (backupConfig.restic.enable or false) {
      initialize = true;
      repository = backupConfig.restic.repository;
      passwordFile = backupConfig.restic.passwordFile;
      
      paths = [ cfg.dataDir ] ++ (backupConfig.extraPaths or []);
      
      timerConfig = {
        OnCalendar = backupConfig.schedule or "daily";
        Persistent = true;
      };
      
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4" 
        "--keep-monthly 12"
        "--keep-yearly 3"
      ] ++ (backupConfig.restic.pruneOpts or []);
    };

    # Borgbackup integration
    services.borgbackup.jobs.${serviceName} = mkIf (backupConfig.borg.enable or false) {
      paths = [ cfg.dataDir ] ++ (backupConfig.extraPaths or []);
      repo = backupConfig.borg.repository;
      encryption.mode = backupConfig.borg.encryption or "repokey-blake2";
      encryption.passCommand = "cat ${backupConfig.borg.passwordFile}";
      
      compression = backupConfig.borg.compression or "auto,lzma";
      startAt = backupConfig.schedule or "daily";
      
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 12;
        yearly = 3;
      } // (backupConfig.borg.pruneKeep or {});
    };

    # Simple rsync backup
    systemd.services."${serviceName}-backup" = mkIf (backupConfig.rsync.enable or false) {
      description = "${serviceName} rsync backup";
      
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${pkgs.rsync}/bin/rsync -av --delete ${cfg.dataDir}/ ${backupConfig.rsync.destination}/";
      };
    };

    systemd.timers."${serviceName}-backup" = mkIf (backupConfig.rsync.enable or false) {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = backupConfig.schedule or "daily";
        Persistent = true;
      };
    };
  };

  # Complete service integration helper
  mkServiceIntegration = serviceName: cfg: integrationConfig: mkMerge [
    # Database integration
    (mkIf (integrationConfig.database.enable or false) 
      (mkDatabaseIntegration serviceName cfg integrationConfig.database))
    
    # Redis integration  
    (mkIf (integrationConfig.redis.enable or false)
      (mkRedisIntegration serviceName cfg integrationConfig.redis))
    
    # Nginx integration
    (mkIf (integrationConfig.nginx.enable or false)
      (mkNginxIntegration serviceName cfg integrationConfig.nginx))
    
    # Prometheus integration
    (mkIf (integrationConfig.metrics.enable or false)
      (mkPrometheusIntegration serviceName cfg integrationConfig.metrics))
    
    # Logging integration
    (mkLoggingIntegration serviceName cfg (integrationConfig.logging or {}))
    
    # Security integration
    (mkSecurityIntegration serviceName cfg (integrationConfig.security or {}))
    
    # Backup integration
    (mkIf (integrationConfig.backup.enable or false)
      (mkBackupIntegration serviceName cfg integrationConfig.backup))
  ];

  # Service ordering and dependency management
  mkServiceDependencies = serviceName: dependencies: {
    systemd.services.${serviceName} = {
      after = [ "network.target" ] ++ dependencies.after;
      wants = [ "network.target" ] ++ dependencies.wants;
      requires = dependencies.requires or [];
      requisite = dependencies.requisite or [];
      bindsTo = dependencies.bindsTo or [];
      partOf = dependencies.partOf or [];
      conflicts = dependencies.conflicts or [];
      
      # Service ordering within ATProto ecosystem
      before = dependencies.before or [];
    };
  };

  # Common ATProto service dependency patterns
  atprotoServiceDependencies = {
    # PDS dependencies - needs database and optionally blob storage
    pds = {
      after = [ "postgresql.service" ];
      wants = [ "postgresql.service" ];
    };
    
    # Relay dependencies - needs PDS and network connectivity
    relay = {
      after = [ "postgresql.service" ];
      wants = [ "postgresql.service" ];
    };
    
    # Feed generator dependencies - needs ATProto network access
    feedgen = {
      after = [ ];
      wants = [ ];
    };
    
    # Labeler dependencies - similar to feed generator
    labeler = {
      after = [ ];
      wants = [ ];
    };
    
    # Indexer dependencies - needs database for storage
    indexer = {
      after = [ "postgresql.service" ];
      wants = [ "postgresql.service" ];
    };
  };
}