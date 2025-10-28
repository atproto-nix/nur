{ pkgs, lib }:

let
  organizationMeta = {
    name = "whyrusleeping";
    displayName = "Why (whyrusleeping)";
    description = "Bluesky AppView and ATProto tools by Why";
    packageCount = 1;
  };

  packages = {
    konbini = pkgs.callPackage ./konbini.nix { };
  };
in
packages // {
  _organizationMeta = organizationMeta;
}
