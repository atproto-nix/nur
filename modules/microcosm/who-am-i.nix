# Defines the NixOS module for the Who-Am-I service
#
# Who-Am-I is an authentication service that handles app secrets, OAuth private keys,
# JWT private keys, base URLs, bind addresses, dev mode, and allowed hosts.
#
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-who-am-i;
in
{
  options.services.microcosm-who-am-i = {
    enable = mkEnableOption "Who-Am-I server";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.who-am-i;
      description = "The Who-Am-I package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/microcosm-who-am-i";
      description = "The absolute path to the directory to store data in.";
    };

    appSecret = mkOption {
      type = types.str;
      description = "Secret key from which the cookie-signing key is derived. Must be at least 512 bits (64 bytes) of randomness.";
      example = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==";
    };

    oauthPrivateKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to at-oauth private key (PEM pk8 format). Required for OAuth functionality.";
    };

    jwtPrivateKey = mkOption {
      type = types.str;
      description = "Path to JWT private key (PEM pk8 format). This is a required option.";
      example = "/path/to/jwt-private-key.pem";
    };

    baseUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "This server's client-reachable base URL, used for OAuth redirect and JWT checks. Required unless running in localhost mode with --dev.";
    };

    bind = mkOption {
      type = types.str;
      default = "127.0.0.1:9997";
      description = "Host:port to bind to on startup.";
    };

    dev = mkOption {
      type = types.bool;
      default = false;
      description = "Enable development mode, which enables automatic template reloading and uses localhost OAuth config.";
    };

    allowedHosts = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of hosts who are allowed to one-click authentication.";
    };
  };

  config = mkIf cfg.enable {
    # Create a static user and group for the service for security isolation.
    users.users.microcosm-who-am-i = {
      isSystemUser = true;
      group = "microcosm-who-am-i";
      home = cfg.dataDir;
    };
    users.groups.microcosm-who-am-i = {};

    # Use tmpfiles to declaratively manage the data directory's existence and ownership.
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 microcosm-who-am-i microcosm-who-am-i - -"
    ];

    # Define the systemd service for Who-Am-I.
    systemd.services.microcosm-who-am-i = {
      description = "Who-Am-I Server - Authentication service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      wants = [ "network.target" ];

      serviceConfig = {
        Restart = "always";
        RestartSec = "10s";

        User = "microcosm-who-am-i";
        Group = "microcosm-who-am-i";

        WorkingDirectory = cfg.dataDir;

        # Security hardening settings for the service.
        NoNewPrivileges = true;
        ProtectSystem = "full";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ] ++ lib.optional (cfg.oauthPrivateKey != null) (builtins.dirOf cfg.oauthPrivateKey) ++ [ (builtins.dirOf cfg.jwtPrivateKey) ];
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
      };

      script =
        let
          args = flatten [
            [
              "--app-secret"
              (escapeShellArg cfg.appSecret)
              "--jwt-private-key"
              (escapeShellArg cfg.jwtPrivateKey)
            ]
            (optional (cfg.oauthPrivateKey != null) [
              "--oauth-private-key"
              (escapeShellArg cfg.oauthPrivateKey)
            ])
            (optional (cfg.baseUrl != null) [
              "--base-url"
              (escapeShellArg cfg.baseUrl)
            ])
            [
              "--bind"
              (escapeShellArg cfg.bind)
            ]
            (optional cfg.dev [
              "--dev"
            ])
            (map (host: [ "--allow_host" (escapeShellArg host) ]) cfg.allowedHosts)
          ];
        in
        ''
          exec ${cfg.package}/bin/who-am-i ${concatStringsSep " " args}
        '';
    };
  };
}