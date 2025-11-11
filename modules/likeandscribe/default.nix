# likeandscribe ATproto service modules
{ config, lib, pkgs, ... }:

let
  # Import service common utilities
  serviceCommon = import ../../lib/service-common.nix { inherit lib; };
  atprotoCore = import ../../lib/atproto-core.nix { inherit lib pkgs; };

in
{
  # Import all likeandscribe service modules
  imports = [
    ./frontpage.nix
    ./drainpipe.nix
  ];

  # Common configuration for likeandscribe ATproto services
  options.services.likeandscribe = {
    enable = lib.mkEnableOption "likeandscribe ATproto services";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/likeandscribe";
      description = "Base data directory for likeandscribe services";
    };
  };

  config = lib.mkIf config.services.likeandscribe.enable {
    # Create base data directory for likeandscribe services
    systemd.tmpfiles.rules = [
      "d '${config.services.likeandscribe.dataDir}' 0755 root root - -"
    ];
  };
}
