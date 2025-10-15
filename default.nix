{ pkgs, craneLib, rustPlatform, ... }:

{
  microcosm = pkgs.callPackage ./pkgs/microcosm { inherit craneLib; };
  blacksky = pkgs.callPackage ./pkgs/blacksky { inherit craneLib; };
  microcosm-rs = pkgs.callPackage ./pkgs/microcosm-rs { inherit rustPlatform; };
}
