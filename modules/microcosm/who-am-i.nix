# Defines the NixOS module for the Who-Am-I service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-who-am-i;
  microcosmLib = import ../../lib/microcosm.nix { inherit lib; };
in
{
  options.services.microcosm-who-am-i = microcosmLib.mkMicrocosmServiceOptions "Who-Am-I" {
    package = mkOption {
      type = types.package;
      default = pkgs.microcosm."who-am-i";
      description = "The Who-Am-I package to use.";
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
      example = "https://who-am-i.example.com";
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
      default = [];
      description = "The hosts who are allowed to one-click auth.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Configuration validation
    (microcosmLib.mkConfigValidation cfg "Who-Am-I" (
      let
        bindPort = microcosmLib.extractPortFromBind cfg.bind;
      in
      microcosmLib.mkPortValidation bindPort "bind port" ++
      [
        {
          assertion = cfg.appSecret != "";
          message = "App secret cannot be empty.";
        }
        {
          assertion = pathExists cfg.jwtPrivateKey;
          message = "JWT private key file must exist at ${cfg.jwtPrivateKey}.";
        }
        {
          assertion = cfg.oauthPrivateKey != null -> pathExists cfg.oauthPrivateKey;
          message = "OAuth private key file must exist when specified.";
        }
        {
          assertion = hasPrefix "http://" cfg.baseUrl || hasPrefix "https://" cfg.baseUrl;
          message = "Base URL must start with http:// or https://.";
        }
        {
          assertion = length cfg.allowedHosts > 0;
          message = "At least one allowed host must be specified for security.";
        }
      ]
    ))

    # User and group management
    (microcosmLib.mkUserConfig cfg)

    # Directory management
    (microcosmLib.mkDirectoryConfig cfg [])

    # systemd service
    (microcosmLib.mkSystemdService cfg "Who-Am-I" {
      description = "Identity service for ATProto (deprecated)";
      serviceConfig = {
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
      };
    })

    # Firewall configuration
    (microcosmLib.mkFirewallConfig cfg [ (microcosmLib.extractPortFromBind cfg.bind) ])

    # Deprecation and security warnings
    {
      warnings = [
        "The Who-Am-I service is deprecated and should not be used in production environments"
      ] ++ lib.optionals cfg.dev [
        "Who-Am-I development mode is enabled - this should not be used in production"
      ] ++ lib.optionals (cfg.oauthPrivateKey == null) [
        "OAuth private key is not configured - some functionality may be limited"
      ];
    }
  ]);
}
