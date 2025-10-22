# Official AT Protocol service modules
{ config, lib, pkgs, ... }:

let
  # Import service common utilities
  serviceCommon = import ../../lib/service-common.nix { inherit lib; };
  atprotoCore = import ../../lib/atproto-core.nix { inherit lib pkgs; };

in
{
  # Import all official ATproto service modules
  imports = [
    ./frontpage.nix
    ./drainpipe.nix
    # Future official service modules:
  ];
  
  # Common configuration for all official ATproto services
  options.services.atproto = {
    enable = lib.mkEnableOption "ATproto services";
    
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/atproto";
      description = "Base data directory for ATproto services";
    };
    
    user = lib.mkOption {
      type = lib.types.str;
      default = "atproto";
      description = "Default user for ATproto services";
    };
    
    group = lib.mkOption {
      type = lib.types.str;
      default = "atproto";
      description = "Default group for ATproto services";
    };
  };
  
  config = lib.mkIf config.services.atproto.enable {
    # Create base user and group for ATproto services
    users.users.${config.services.atproto.user} = {
      isSystemUser = true;
      group = config.services.atproto.group;
      home = config.services.atproto.dataDir;
      createHome = false;
    };
    
    users.groups.${config.services.atproto.group} = {};
    
    # Create base data directory
    systemd.tmpfiles.rules = [
      "d '${config.services.atproto.dataDir}' 0750 ${config.services.atproto.user} ${config.services.atproto.group} - -"
    ];
  };
}