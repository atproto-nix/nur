{ pkgs, craneLib, ... }:

let
  # Import all packages
  allPackages = pkgs.callPackage ./pkgs { inherit craneLib; };

  # Helper to check if something is a derivation
  isDerivation = pkg:
    (pkg.type or "") == "derivation" ||
    (builtins.isAttrs pkg && pkg ? outPath) ||
    (builtins.isAttrs pkg && pkg ? drvPath);

  # Filter to only derivations
  packages = pkgs.lib.filterAttrs (n: v:
    n != "organizations" &&
    n != "_organizationalMetadata" &&
    isDerivation v
  ) allPackages;

in
packages // {
  # ATProto packaging utilities library
  lib = pkgs.callPackage ./lib/atproto.nix {
    inherit craneLib;
    fetchFromTangled = pkgs.fetchFromTangled;
  };

  # NixOS modules
  modules = import ./modules;

  # Optional: overlays for nixpkgs integration
  overlays = import ./overlay.nix;
}
