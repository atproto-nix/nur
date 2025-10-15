{ pkgs, craneLib, ... }:

{
  microcosm = pkgs.callPackage ./pkgs/microcosm { inherit craneLib; };
  blacksky = pkgs.callPackage ./pkgs/blacksky { inherit craneLib; };
}
