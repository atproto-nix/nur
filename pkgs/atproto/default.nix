# Official AT Protocol implementations
{ lib, pkgs, craneLib, buildGoModule, buildNpmPackage, ... }:

let
  # Import ATproto core libraries
  atprotoCore = import ../../lib/atproto-core.nix { inherit lib pkgs craneLib; };
  packaging = import ../../lib/packaging.nix { inherit lib pkgs craneLib buildGoModule buildNpmPackage; };

  # Organizational metadata for official ATproto packages
  _organizationMeta = {
    name = "atproto";
    description = "Official AT Protocol implementations";
    homepage = "https://atproto.com";
    maintainers = [ "atproto-team" ];
    category = "official";
  };

in
{
  inherit _organizationMeta;
  
  # Official implementations
  # frontpage = pkgs.callPackage ./frontpage.nix { inherit craneLib atprotoCore packaging; };
  
  # Core ATproto TypeScript libraries
  atproto-api = pkgs.callPackage ./atproto-api.nix { };
  atproto-lexicon = pkgs.callPackage ./atproto-lexicon.nix { };
  atproto-xrpc = pkgs.callPackage ./atproto-xrpc.nix { };
  atproto-did = pkgs.callPackage ./atproto-did.nix { };
  atproto-identity = pkgs.callPackage ./atproto-identity.nix { };
  atproto-repo = pkgs.callPackage ./atproto-repo.nix { };
  atproto-syntax = pkgs.callPackage ./atproto-syntax.nix { };
  
  # Future official implementations:
  # lexicons = pkgs.callPackage ./lexicons.nix { inherit atprotoCore packaging; };
}