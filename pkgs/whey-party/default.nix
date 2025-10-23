{ pkgs, ... }:

# Whey Party - Bluesky client applications
# Repository: https://tangled.org/@whey.party

{
  red-dwarf = pkgs.callPackage ./red-dwarf.nix { };
}
