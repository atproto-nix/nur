{ pkgs, lib, buildGoModule ? pkgs.buildGoModule, ... }:

# Tangled ATProto packages
# Organization: tangled
# Website: https://tangled.org

let
  # Organizational metadata
  organizationMeta = {
    name = "tangled";
    displayName = "Tangled";
    website = "https://tangled.org";
    contact = null;
    maintainer = "Tangled";
    description = "Git forge and development tools for ATProto ecosystem";
    atprotoFocus = [ "tools" "infrastructure" "applications" ];
    packageCount = 5;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    appview = pkgs.callPackage ./appview.nix { inherit buildGoModule; };
    knot = pkgs.callPackage ./knot.nix { inherit buildGoModule; };
    spindle = pkgs.callPackage ./spindle.nix { inherit buildGoModule; };
    genjwks = pkgs.callPackage ./genjwks.nix { };
    lexgen = pkgs.callPackage ./lexgen.nix { };
  };

  # Enhanced packages with organizational metadata
  enhancedPackages = lib.mapAttrs (name: pkg:
    pkg.overrideAttrs (oldAttrs: {
      passthru = (oldAttrs.passthru or {}) // {
        organization = organizationMeta;
        atproto = (oldAttrs.passthru.atproto or {}) // {
          organization = organizationMeta;
        };
      };
      meta = (oldAttrs.meta or {}) // {
        organizationalContext = {
          organization = organizationMeta.name;
          displayName = organizationMeta.displayName;
        };
      };
    })
  ) packages;

in
enhancedPackages // {
  # Export organizational metadata for external use
  _organizationMeta = organizationMeta;
}