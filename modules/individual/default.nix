# Individual developer ATproto service modules
{ config, lib, pkgs, ... }:

let
  # Import service common utilities
  serviceCommon = import ../../lib/service-common.nix { inherit lib; };
  atprotoCore = import ../../lib/atproto-core.nix { inherit lib pkgs; };

in
{
  # Import all individual developer service modules
  imports = [
    ./pds-gatekeeper.nix
    # Additional individual service modules will be added here
    # ./quickdid.nix
  ];
  
  # Common configuration for individual developer ATproto services
  options.services.individual = {
    enable = lib.mkEnableOption "Individual developer ATproto services";
    
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/individual";
      description = "Base data directory for individual ATproto services";
    };
  };
  
  config = lib.mkIf config.services.individual.enable {
    # Create base data directory for individual services
    systemd.tmpfiles.rules = [
      "d '${config.services.individual.dataDir}' 0755 root root - -"
    ];
  };
}