{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.grain-social-darkroom;

in
{
  options.services.grain-social-darkroom = {
    enable = mkEnableOption "Grain Social Darkroom image processing service";

    package = mkOption {
      type = types.package;
      default = pkgs.grain-social-darkroom;
      defaultText = literalExpression "pkgs.grain-social-darkroom";
      description = "The Darkroom package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "grain-darkroom";
      description = "User account under which Darkroom runs.";
    };

    group = mkOption {
      type = types.str;
      default = "grain-darkroom";
      description = "Group under which Darkroom runs.";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port for the Darkroom HTTP server.";
    };

    baseUrl = mkOption {
      type = types.str;
      default = "http://localhost:${toString cfg.port}";
      defaultText = literalExpression ''"http://localhost:''${toString cfg.port}"'';
      description = "Base URL where Darkroom is accessible.";
    };

    grainBaseUrl = mkOption {
      type = types.str;
      description = "Base URL of the Grain AppView instance.";
      example = "https://grain.social";
    };

    chromePath = mkOption {
      type = types.path;
      default = "${pkgs.chromium}/bin/chromium";
      defaultText = literalExpression ''"''${pkgs.chromium}/bin/chromium"'';
      readOnly = true;
      description = "Path to Chromium browser executable.";
    };

    chromeDriverPath = mkOption {
      type = types.path;
      default = "${pkgs.chromedriver}/bin/chromedriver";
      defaultText = literalExpression ''"''${pkgs.chromedriver}/bin/chromedriver"'';
      readOnly = true;
      description = "Path to ChromeDriver executable.";
    };

    chromeProfileDir = mkOption {
      type = types.path;
      default = "/var/lib/grain-darkroom/chrome-profile";
      description = "Directory for Chromium profile data.";
    };

    logLevel = mkOption {
      type = types.enum [ "error" "warn" "info" "debug" "trace" ];
      default = "info";
      description = "Rust log level for the service.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the firewall for the Darkroom port.";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional environment variables for Darkroom.";
      example = literalExpression ''
        {
          SOME_CUSTOM_VAR = "value";
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Assertions
    assertions = [
      {
        assertion = cfg.grainBaseUrl != "";
        message = "Darkroom requires grainBaseUrl to be configured.";
      }
    ];

    # User and group configuration
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = "/var/lib/grain-darkroom";
      description = "Grain Darkroom service user";
    };

    users.groups.${cfg.group} = {};

    # Directory management
    systemd.tmpfiles.rules = [
      "d '/var/lib/grain-darkroom' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.chromeProfileDir}' 0755 ${cfg.user} ${cfg.group} - -"
      # Chromium needs writable /tmp
      "d '/tmp/grain-darkroom' 1777 ${cfg.user} ${cfg.group} - -"
    ];

    # systemd service
    systemd.services.grain-darkroom = {
      description = "Grain Social Darkroom - Image Processing Service";
      documentation = [ "https://grain.social" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "/var/lib/grain-darkroom";
        ExecStart = "${cfg.package}/bin/darkroom";
        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening
        # Note: Cannot use DynamicUser because Chromium needs stable profile directory
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = false; # Chromium needs /tmp access
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];

        # File system access
        ReadWritePaths = [
          "/var/lib/grain-darkroom"
          cfg.chromeProfileDir
          "/tmp/grain-darkroom"
        ];
        ReadOnlyPaths = [ "/nix/store" ];

        # Resource limits
        LimitNOFILE = 65536;
      };

      environment = {
        RUST_LOG = cfg.logLevel;
        RUST_BACKTRACE = "1";
        CHROME_PATH = cfg.chromePath;
        CHROMEDRIVER_PATH = cfg.chromeDriverPath;
        BASE_URL = cfg.baseUrl;
        GRAIN_BASE_URL = cfg.grainBaseUrl;
        PORT = toString cfg.port;

        # Font configuration for Chromium rendering
        FONTCONFIG_FILE = cfg.package.makeFontConfig;

        # Chromium profile directory
        CHROME_PROFILE_DIR = cfg.chromeProfileDir;

        # Chromium flags for headless operation
        CHROME_FLAGS = "--headless --disable-gpu --no-sandbox --disable-dev-shm-usage";
      } // cfg.settings;
    };

    # Firewall
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
