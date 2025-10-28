{ pkgs, lib, ... }:

# Teal.fm ATProto packages
# Organization: teal-fm
# Website: https://teal.fm

let
  # Organizational metadata
  organizationMeta = {
    name = "teal-fm";
    displayName = "Teal.fm";
    website = "https://teal.fm";
    contact = null;
    maintainer = "Teal.fm";
    description = "Music social platform built on ATProto";
    atprotoFocus = [ "applications" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    teal = pkgs.callPackage ./teal.nix { };
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