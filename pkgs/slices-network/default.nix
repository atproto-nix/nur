{ pkgs, lib, ... }:

# Slices Network ATProto packages
# Organization: slices-network
# Website: https://slices.network

let
  # Organizational metadata
  organizationMeta = {
    name = "slices-network";
    displayName = "Slices Network";
    website = "https://slices.network";
    contact = null;
    maintainer = "Slices Network";
    description = "Custom AppView platform for ATProto ecosystem";
    atprotoFocus = [ "applications" "infrastructure" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    slices = pkgs.callPackage ./slices.nix { };
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