{ pkgs, lib, buildGoModule, fetchFromTangled, ... }:

let
  organizationMeta = {
    name = "hailey-at";
    displayName = "Hailey (hailey-at)";
    description = "ATProto infrastructure tools by Hailey";
    packageCount = 1;
  };

  packages = {
    cocoon = pkgs.callPackage ./cocoon.nix { inherit buildGoModule fetchFromTangled; };
  };
in
packages // {
  _organizationMeta = organizationMeta;
}
