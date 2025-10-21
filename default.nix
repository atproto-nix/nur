{ pkgs, craneLib, ... }:

{
  # ATProto packaging utilities library
  lib = pkgs.callPackage ./lib/atproto.nix { inherit craneLib; };
  
  # Package collections
  microcosm = pkgs.callPackage ./pkgs/microcosm { inherit craneLib; };
  blacksky = pkgs.callPackage ./pkgs/blacksky { inherit craneLib; };
  bluesky = pkgs.callPackage ./pkgs/bluesky { inherit craneLib; };
}
