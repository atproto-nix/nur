# Defines the NixOS module for the Who-Am-I service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-who-am-i;
in
{
  options.services.microcosm-who-am-i = {
    enable = mkEnableOption "Microcosm Who-Am-I service (deprecated)";

    package = mkOption {
      type = types.package;
      default = microcosmPkgs."who-am-i";
      description = "The Who-Am-I package to use.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for the Who-Am-I API port.";
    };

    appSecret = mkOption {
      type = types.str;
      description = "The secret key for cookie-signing.";
    };

    oauthPrivateKey = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "The path to the at-oauth private key.";
    };

    jwtPrivateKey = mkOption {
      type = types.path;
      description = "The path to the jwt private key.";
    };

    baseUrl = mkOption {
      type = types.str;
      description = "The client-reachable base url.";
    };

    bind = mkOption {
      type = types.str;
      default = "127.0.0.1:9997";
      description = "The host:port to bind to.";
    };

    dev = mkOption {
      type = types.bool;
      default = false;
      description = "Enable dev mode.";
    };

    allowedHosts = mkOption {
      type = types.listOf types.str;
      description = "The hosts who are allowed to one-click auth.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-who-am-i = {
      description = "Microcosm Who-Am-I Service (deprecated)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        # Execution settings from the feature branch
        ExecStart = ''
          ${cfg.package}/bin/who-am-i \
            --app-secret ${escapeShellArg cfg.appSecret} \
            ${optionalString (cfg.oauthPrivateKey != null) "--oauth-private-key ${escapeShellArg cfg.oauthPrivateKey}"} \
            --jwt-private-key ${escapeShellArg cfg.jwtPrivateKey} \
            --base-url ${escapeShellArg cfg.baseUrl} \
            --bind ${escapeShellArg cfg.bind} \
            ${optionalString cfg.dev "--dev"} \
            ${concatStringsSep " " (map (host: "--allow-host ${escapeShellArg host}") cfg.allowedHosts)}
        '';
        Restart = "always";
        RestartSec = "10s";
        DynamicUser = true;
        StateDirectory = "who-am-i";

        # Security settings from the main branch
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
      };
    };

    # Updated firewall rule to parse the port from the new 'bind' option
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ (toInt (last (splitString ":" cfg.bind))) ];
    };
  };
}
