{ pkgs, lib, craneLib, fetchgit, ... }:

# Parakeet Social ATProto packages
# Organization: parakeet-social
# Description: Bluesky AppView implementation

let
  # Organizational metadata
  organizationMeta = {
    name = "parakeet-social";
    displayName = "Parakeet Social";
    website = null;
    contact = null;
    maintainer = "Parakeet Social";
    description = "Bluesky AppView implementation for ATProto ecosystem";
    atprotoFocus = [ "applications" "infrastructure" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    parakeet = pkgs.callPackage ./parakeet.nix { inherit craneLib fetchgit; };
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