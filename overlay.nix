# You can use this file as a nixpkgs overlay. This is useful in the
# case where you don't want to add the whole NUR namespace to your
# configuration.

self: super:
let
  craneLib = (import (builtins.fetchTarball "https://github.com/ipetkov/crane/archive/master.tar.gz")).mkLib super;
  nurAttrs = import ./default.nix { pkgs = super; inherit craneLib; };
  
  # ATProto namespace with all packages and utilities
  atproto = nurAttrs // {
    # Make lib utilities available at top level for convenience
    inherit (nurAttrs) lib;
    
    # Expose individual package collections for easier access
    inherit (nurAttrs) microcosm blacksky bluesky;
    
    # Also provide flattened access to all packages with prefixes
    packages = 
      let
        microcosm = super.lib.mapAttrs' (n: v: super.lib.nameValuePair "microcosm-${n}" v) nurAttrs.microcosm;
        blacksky = super.lib.mapAttrs' (n: v: super.lib.nameValuePair "blacksky-${n}" v) nurAttrs.blacksky;
        bluesky = super.lib.mapAttrs' (n: v: super.lib.nameValuePair "bluesky-${n}" v) nurAttrs.bluesky;
      in
      microcosm // blacksky // bluesky;
  };

in
{
  inherit atproto;
}
