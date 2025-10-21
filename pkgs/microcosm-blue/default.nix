{ pkgs, lib, craneLib, ... }:

# Microcosm ATProto packages
# Organization: microcosm-blue
# Website: https://microcosm.blue

let
  # Organizational metadata
  organizationMeta = {
    name = "microcosm-blue";
    displayName = "Microcosm";
    website = null;
    contact = null;
    maintainer = "Microcosm";
    description = "PLC tools and utilities for ATProto ecosystem";
    atprotoFocus = [ "tools" "identity" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    allegedly = pkgs.callPackage ./allegedly.nix { inherit craneLib; };
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