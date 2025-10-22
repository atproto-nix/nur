{ pkgs, craneLib, ... }:

{
  # PDS Gatekeeper - Security microservice for PDS with 2FA and rate limiting
  pds-gatekeeper = pkgs.callPackage ./pds-gatekeeper.nix {
    inherit craneLib;
  };
  
  # Placeholder packages for future Bluesky applications
  # These will be implemented when the actual source repositories are available
  





}
