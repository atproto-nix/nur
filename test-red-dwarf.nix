let
  pkgs = import <nixpkgs> {};
  fetchFromTangled = pkgs.callPackage ./lib/fetch-tangled.nix {};
in
pkgs.callPackage ./pkgs/whey-party/red-dwarf.nix {
  inherit fetchFromTangled;
}
