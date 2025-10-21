{ pkgs, craneLib, ... }:

let
  # Import all packages from the new organizational structure
  allPackages = pkgs.callPackage ./pkgs { inherit craneLib; };
  
  # Helper function to check if something is a derivation
  isDerivation = pkg: 
    (pkg.type or "") == "derivation" ||
    (builtins.isAttrs pkg && pkg ? outPath) ||
    (builtins.isAttrs pkg && pkg ? drvPath);
  
  # Filter to only include derivations
  derivationPackages = pkgs.lib.filterAttrs (n: v: isDerivation v) allPackages;
  
in
{
  # ATProto packaging utilities library
  lib = pkgs.callPackage ./lib/atproto.nix { inherit craneLib; };
  
  # Legacy package collections (for backward compatibility)
  microcosm = allPackages.organizations.microcosm or {};
  blacksky = allPackages.organizations.blacksky or {};
  bluesky = allPackages.organizations.bluesky or {};
  atproto = allPackages.organizations.atproto or {};
  
  # New organizational collections
  organizations = allPackages.organizations;
  
  # Organizational metadata (not exported as package)
  # organizationalMetadata = allPackages._organizationalMetadata;
} // derivationPackages
