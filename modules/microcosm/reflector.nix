# Defines the NixOS module for the Reflector service
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.microcosm-reflector;
in
{
  options.services.microcosm-reflector = {
    enable = mkEnableOption "Reflector service";

    package = mkOption {
      type = types.package;
      default = pkgs.nur.reflector;
      description = "The Reflector package to use.";
    };

    serviceId = mkOption {
      type = types.str;
      description = "The DID document service ID.";
    };

    serviceType = mkOption {
      type = types.str;
      description = "The service type.";
    };

    serviceEndpoint = mkOption {
      type = types.str;
      description = "The HTTPS endpoint for the service.";
    };

    domain = mkOption {
      type = types.str;
      description = "The parent domain.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.microcosm-reflector = {
      description = "Reflector Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/reflector --id ${cfg.serviceId} --type ${cfg.serviceType} --service-endpoint ${cfg.serviceEndpoint} --domain ${cfg.domain}";
        Restart = "always";
        RestartSec = "10s";
        DynamicUser = true;
        StateDirectory = "reflector";

        # Security settings
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
  };
}
