# NixOS service module for plcbundle
# PLC Bundle - Cryptographic archiving of AT Protocol DID operations
#
# Configuration example:
#
# services.plcbundle-archive = {
#   enable = true;
#   dataDir = "/var/lib/plcbundle";
#   plcDirectoryUrl = "https://plc.directory";
#   bindAddress = "127.0.0.1:8080";
#   logLevel = "info";
#   openFirewall = true;
# };

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.plcbundle-archive;
  plcbundleLib = import ../../lib/plcbundle.nix { inherit lib pkgs; };
  plcbundlePkg = pkgs.plcbundle-plcbundle or pkgs.callPackage ../../pkgs/plcbundle { inherit lib; };
in
{
  options.services.plcbundle-archive = plcbundleLib.mkPlcbundleServiceOptions "archive" {
    # PLC Bundle specific configuration options
    plcDirectoryUrl = mkOption {
      type = types.str;
      default = "https://plc.directory";
      description = ''
        The URL of the PLC (Placeholder) Directory to archive operations from.
        This is the source of DID operations that plcbundle will bundle and archive.
      '';
      example = "https://plc.directory";
    };

    bundleDir = mkOption {
      type = types.path;
      default = "/var/lib/plcbundle-archive/bundles";
      description = ''
        Directory where plcbundle stores the compressed operation bundles.
        These are immutable, cryptographically-chained files.
      '';
    };

    bindAddress = mkOption {
      type = types.str;
      default = "127.0.0.1:8080";
      description = ''
        The address and port to bind the HTTP server to.
        Format: HOST:PORT
      '';
      example = "0.0.0.0:8080";
    };

    maxBundleSize = mkOption {
      type = types.int;
      default = 10000;
      description = ''
        Maximum number of operations per bundle.
        Bundles are created when this size is reached.
      '';
    };

    compressionLevel = mkOption {
      type = types.int;
      default = 19;
      description = ''
        Zstandard compression level (1-22).
        Higher values mean better compression but slower processing.
      '';
    };

    enableWebSocket = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable WebSocket support for real-time operation streaming.
      '';
    };

    enableSpamDetection = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable built-in spam detection framework.
      '';
    };

    enableDidIndexing = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable DID indexing for efficient searching.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Configuration validation
    (plcbundleLib.mkConfigValidation cfg "archive" [
      {
        assertion = cfg.plcDirectoryUrl != "";
        message = "plcDirectoryUrl cannot be empty.";
      }
      {
        assertion = (hasPrefix "http://" cfg.plcDirectoryUrl) || (hasPrefix "https://" cfg.plcDirectoryUrl);
        message = "plcDirectoryUrl must start with http:// or https://.";
      }
      {
        assertion = cfg.bundleDir != "";
        message = "bundleDir cannot be empty.";
      }
      {
        assertion = cfg.maxBundleSize > 0 && cfg.maxBundleSize < 1000000;
        message = "maxBundleSize must be between 1 and 999999.";
      }
      {
        assertion = cfg.compressionLevel >= 1 && cfg.compressionLevel <= 22;
        message = "compressionLevel must be between 1 and 22.";
      }
    ])

    # User and group management
    (plcbundleLib.mkUserConfig cfg)

    # Directory management (data directory and bundle directory)
    (plcbundleLib.mkDirectoryConfig cfg [ cfg.bundleDir ])

    # systemd service configuration
    (plcbundleLib.mkSystemdService cfg "archive" {
      description = "PLC Bundle archiving service - cryptographically archiving AT Protocol DID operations";

      serviceConfig = {
        ExecStart = concatStringsSep " " [
          "${cfg.package}/bin/plcbundle"
          "serve"
          "--host ${elemAt (splitString ":" cfg.bindAddress) 0}"
          "--port ${elemAt (splitString ":" cfg.bindAddress) 1}"
          "--plc ${cfg.plcDirectoryUrl}"
          "--sync"
          (optionalString cfg.enableWebSocket "--websocket")
          (optionalString cfg.enableDidIndexing "--resolver")
        ];

        # Set working directory to bundle directory
        WorkingDirectory = cfg.bundleDir;

        # Allow reading from network and the data directory
        extraReadWritePaths = [ cfg.bundleDir ];

        # Environment variables for plcbundle runtime
        extraEnvironment = [
          "PLC_DIRECTORY_URL=${cfg.plcDirectoryUrl}"
          "BUNDLE_DIR=${cfg.bundleDir}"
          "HTTP_HOST=${elemAt (splitString ":" cfg.bindAddress) 0}"
          "HTTP_PORT=${elemAt (splitString ":" cfg.bindAddress) 1}"
        ];
      };
    })

    # Firewall configuration
    (
      let
        port = toInt (elemAt (splitString ":" cfg.bindAddress) 1);
      in
      plcbundleLib.mkFirewallConfig cfg [ port ]
    )
  ]);
}
