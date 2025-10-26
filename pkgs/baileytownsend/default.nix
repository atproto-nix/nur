# Individual developer ATproto projects
{ lib, pkgs, craneLib, ... }:

let
  # Import ATproto core libraries
  atprotoCore = import ../../lib/atproto-core.nix { inherit lib pkgs craneLib; };
  packaging = import ../../lib/packaging.nix { inherit lib pkgs craneLib; };

  # Organizational metadata for individual developer packages
  _organizationMeta = {
    name = "individual";
    displayName = "baileytownsend";
    website = "https://baileytownsend.dev/";
    contact = null;
    maintainer = "Bailey Townsend";
    description = "ATproto packages by Bailey Townsend's";
    atprotoFocus = [ "tools" "applications" ];
    category = "community";
  };

in
{
  inherit _organizationMeta;
  
  # Individual developer packages
  pds-gatekeeper = pkgs.callPackage ./pds-gatekeeper.nix { 
    inherit craneLib; 
  };
  
  # Additional individual packages will be added here
}
