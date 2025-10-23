{ config, lib, pkgs, ... }:

let
  cfg = config.services.tangled-dev.knot;
in

with lib;

{
  options.services.tangled-dev.knot = {
    enable = mkEnableOption "Tangled Knot - Git server with ATProto integration";

    package = mkOption {
      type = types.package;
      default = pkgs.tangled-dev-knot or pkgs.knot;
      defaultText = literalExpression "pkgs.knot";
      description = "Package to use for Tangled Knot";
    };

    user = mkOption {
      type = types.str;
      default = "tangled-knot";
      description = "User account under which Tangled Knot runs";
    };

    group = mkOption {
      type = types.str;
      default = "tangled-knot";
      description = "Group under which Tangled Knot runs";
    };

    gitUser = mkOption {
      type = types.str;
      default = "git";
      description = "User that hosts git repos and performs git operations";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/tangled-knot";
      description = "Directory where Tangled Knot stores its data";
    };

    repoDir = mkOption {
      type = types.path;
      default = "/var/lib/tangled-knot/repos";
      description = "Directory where git repositories are stored";
    };

    endpoints = mkOption {
      type = types.submodule {
        options = {
          appview = mkOption {
            type = types.str;
            default = "https://tangled.org";
            description = "AppView endpoint URL for web interface integration";
            example = "https://my-appview.example.com";
          };

          jetstream = mkOption {
            type = types.str;
            default = "wss://jetstream.tangled.sh";
            description = "Jetstream WebSocket endpoint URL for real-time events";
            example = "wss://jetstream.example.com";
          };

          nixery = mkOption {
            type = types.str;
            default = "https://nixery.tangled.sh";
            description = "Nixery container registry endpoint URL for CI/CD integration";
            example = "https://nixery.example.com";
          };

          atproto = mkOption {
            type = types.str;
            default = "https://bsky.social";
            description = "Primary ATProto network endpoint for identity and data";
            example = "https://my-atproto.example.com";
          };

          plc = mkOption {
            type = types.str;
            default = "https://plc.directory";
            description = "PLC directory endpoint for DID resolution and identity management";
            example = "https://plc.example.com";
          };
        };
      };
      default = {};
      description = "Configurable service endpoints for enhanced Tangled and ATProto integration";
    };

    server = {
      listenAddr = mkOption {
        type = types.str;
        default = "0.0.0.0:5555";
        description = "Address to listen on for external connections";
      };

      internalListenAddr = mkOption {
        type = types.str;
        default = "127.0.0.1:5444";
        description = "Internal address for inter-service communication";
      };

      hostname = mkOption {
        type = types.str;
        example = "my.knot.com";
        description = "Hostname for the server (required)";
      };

      owner = mkOption {
        type = types.str;
        example = "did:plc:qfpnj4og54vl56wngdriaxug";
        description = "DID of the server owner (required)";
      };

      dbPath = mkOption {
        type = types.path;
        default = "/var/lib/tangled-knot/knotserver.db";
        description = "Path to the database file";
      };

      dev = mkOption {
        type = types.bool;
        default = false;
        description = "Enable development mode (disables signature verification)";
      };
    };

    repo = {
      mainBranch = mkOption {
        type = types.str;
        default = "main";
        description = "Default branch name for repositories";
      };
    };

    motd = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Message of the day shown to users.
        
        The contents are shown as-is; you may want to add a newline
        since knot won't add one automatically.
      '';
    };

    motdFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        File containing message of the day.
        
        The contents are shown as-is; you may want to add a newline
        since knot won't add one automatically.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open SSH port (22) in the firewall";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.server.hostname != "";
        message = "services.tangled-dev.knot.server.hostname must be set";
      }
      {
        assertion = cfg.server.owner != "";
        message = "services.tangled-dev.knot.server.owner must be set";
      }
      {
        assertion = !(cfg.motd != null && cfg.motdFile != null);
        message = "services.tangled-dev.knot.motd and motdFile cannot both be set";
      }
    ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.users.${cfg.gitUser} = {
      isSystemUser = true;
      useDefaultShell = true;
      home = cfg.repoDir;
      createHome = true;
      group = cfg.gitUser;
    };

    users.groups.${cfg.group} = {};
    users.groups.${cfg.gitUser} = {};

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.repoDir}' 0750 ${cfg.gitUser} ${cfg.gitUser} - -"
    ];

    environment.systemPackages = [
      pkgs.git
      cfg.package
    ];

    services.openssh = {
      enable = true;
      extraConfig = ''
        Match User ${cfg.gitUser}
            AuthorizedKeysCommand /etc/ssh/tangled-keyfetch-wrapper
            AuthorizedKeysCommandUser nobody
      '';
    };

    environment.etc."ssh/tangled-keyfetch-wrapper" = {
      mode = "0555";
      text = ''
        #!${pkgs.stdenv.shell}
        ${cfg.package}/bin/knot keys \
          -output authorized-keys \
          -internal-api "http://${cfg.server.internalListenAddr}" \
          -git-dir "${cfg.repoDir}" \
          -log-path /tmp/tangled-knotguard.log
      '';
    };

    systemd.services.tangled-knot = {
      description = "Tangled Knot - Git server with ATProto integration";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "sshd.service" ];

      preStart = let
        setMotd = ''
          ${optionalString (cfg.motdFile != null) "cat ${cfg.motdFile} > ${cfg.dataDir}/motd"}
          ${optionalString (cfg.motd != null) ''printf "${cfg.motd}" > ${cfg.dataDir}/motd''}
        '';
      in ''
        mkdir -p "${cfg.repoDir}"
        chown -R ${cfg.gitUser}:${cfg.gitUser} "${cfg.repoDir}"

        mkdir -p "${cfg.dataDir}/.config/git"
        cat > "${cfg.dataDir}/.config/git/config" << EOF
        [user]
            name = Tangled Git User
            email = git@${cfg.server.hostname}
        [receive]
            advertisePushOptions = true
        EOF
        ${setMotd}
        chown -R ${cfg.user}:${cfg.group} "${cfg.dataDir}"
      '';

      serviceConfig = {
        Type = "exec";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/knot server";
        Restart = "always";
        RestartSec = "10s";
        
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
        
        # File system access
        ReadWritePaths = [ cfg.dataDir cfg.repoDir ];
        ReadOnlyPaths = [ "/nix/store" ];
      };

      environment = {
        KNOT_REPO_SCAN_PATH = cfg.repoDir;
        KNOT_REPO_MAIN_BRANCH = cfg.repo.mainBranch;
        APPVIEW_ENDPOINT = cfg.endpoints.appview;
        JETSTREAM_ENDPOINT = cfg.endpoints.jetstream;
        NIXERY_ENDPOINT = cfg.endpoints.nixery;
        ATPROTO_ENDPOINT = cfg.endpoints.atproto;
        PLC_ENDPOINT = cfg.endpoints.plc;
        KNOT_SERVER_INTERNAL_LISTEN_ADDR = cfg.server.internalListenAddr;
        KNOT_SERVER_LISTEN_ADDR = cfg.server.listenAddr;
        KNOT_SERVER_DB_PATH = cfg.server.dbPath;
        KNOT_SERVER_HOSTNAME = cfg.server.hostname;
        KNOT_SERVER_OWNER = cfg.server.owner;
        KNOT_SERVER_DEV = boolToString cfg.server.dev;
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 22 ];
    };
  };
}