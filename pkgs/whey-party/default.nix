{ pkgs, lib, fetchFromTangled, ... }:

# Whey Party - Bluesky client applications
# Repository: https://tangled.org/@whey.party

let
  pnpm = pkgs.nodePackages.pnpm;

  packages = {
    red-dwarf = pkgs.callPackage ./red-dwarf.nix {
    };
  };

  # Create an "all" derivation to build all packages at once
  allPackages = pkgs.symlinkJoin {
    name = "whey-party-all";
    paths = lib.attrValues packages;
    meta = {
      description = "All Whey Party packages";
      homepage = "https://tangled.org/@whey.party";
    };
  };

in
packages // {
  all = allPackages;
}
