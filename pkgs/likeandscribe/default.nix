# likeandscribe ATproto packages
{ lib, pkgs, craneLib, buildNpmPackage, fetchFromGitHub, ... }:

let
  # Import packaging utilities
  packaging = pkgs.callPackage ../../lib/packaging { inherit craneLib buildNpmPackage; };
  atprotoCore = import ../../lib/atproto-core.nix { inherit lib pkgs craneLib; };

  # Organizational metadata
  organizationMeta = {
    name = "likeandscribe";
    displayName = "Like & Scribe";
    website = "https://github.com/likeandscribe";
    maintainer = "Like & Scribe";
    description = "ATProto community applications and tools";
  };

in
{
  inherit organizationMeta;

  # Package exports
  frontpage = pkgs.callPackage ./frontpage.nix { inherit lib craneLib buildNpmPackage fetchFromGitHub atprotoCore packaging; };
}
