# You can use this file as a nixpkgs overlay. This is useful in the
# case where you don't want to add the whole NUR namespace to your
# configuration.

self: super:
let
  # Use crane from the overlay if available, otherwise fetch it
  craneLib = if super ? crane && super.crane ? lib && super.crane.lib ? ${super.system}
    then super.crane.lib.${super.system}
    else (import (builtins.fetchTarball "https://github.com/ipetkov/crane/archive/master.tar.gz")).mkLib super;
  
  nurAttrs = import ./default.nix { pkgs = super; inherit craneLib; };
  
  # Helper to safely get package collections
  safeGetPackages = collection: 
    if nurAttrs ? ${collection} && nurAttrs.${collection} != null
    then nurAttrs.${collection}
    else {};
  
  # ATProto namespace with all packages and utilities
  atproto = nurAttrs // {
    # Make lib utilities available at top level for convenience
    inherit (nurAttrs) lib;
    
    # Expose individual package collections for easier access
    microcosm = safeGetPackages "microcosm";
    blacksky = safeGetPackages "blacksky";
    bluesky = safeGetPackages "bluesky";
    atproto-core = safeGetPackages "atproto";  # Renamed to avoid conflict with top-level namespace
    
    # Also provide flattened access to all packages with prefixes
    packages = 
      let
        # Check if a package is a valid derivation or ATProto package
        isPackage = pkg: 
          (pkg.type or "" == "derivation") ||  # Regular Nix derivations
          (pkg ? atproto) ||                   # ATProto packages with metadata
          (pkg ? passthru.atproto);            # ATProto packages with passthru metadata
        
        # Filter packages by platform support before prefixing
        filterPlatformSupported = collection: 
          let
            # Check if a package is supported on current platform
            isPlatformSupported = pkg:
              let
                meta = pkg.meta or {};
                platforms = meta.platforms or super.lib.platforms.all;
                badPlatforms = meta.badPlatforms or [];
              in
              (builtins.elem super.system platforms) && !(builtins.elem super.system badPlatforms);
          in
          super.lib.filterAttrs (n: v: 
            (v.type or "" == "derivation" || v ? atproto || v ? passthru.atproto) && 
            isPlatformSupported v
          ) collection;
        
        microcosm = super.lib.mapAttrs' (n: v: super.lib.nameValuePair "microcosm-${n}" v) (filterPlatformSupported (safeGetPackages "microcosm"));
        blacksky = super.lib.mapAttrs' (n: v: super.lib.nameValuePair "blacksky-${n}" v) (filterPlatformSupported (safeGetPackages "blacksky"));
        bluesky = super.lib.mapAttrs' (n: v: super.lib.nameValuePair "bluesky-${n}" v) (filterPlatformSupported (safeGetPackages "bluesky"));
        atproto-core = super.lib.mapAttrs' (n: v: super.lib.nameValuePair "atproto-${n}" v) (filterPlatformSupported (safeGetPackages "atproto"));
      in
      microcosm // blacksky // bluesky // atproto-core;
  };

in
{
  inherit atproto;
}
