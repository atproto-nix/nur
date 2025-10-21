{ pkgs, lib, ... }:

# Hyperlink Academy ATProto packages
# Organization: hyperlink-academy
# Website: https://hyperlink.academy
# Contact: contact@leaflet.pub

let
  # Organizational metadata
  organizationMeta = {
    name = "hyperlink-academy";
    displayName = "Hyperlink Academy";
    website = "https://hyperlink.academy";
    contact = "contact@leaflet.pub";
    maintainer = "Learning Futures Inc.";
    description = "Educational technology company building collaborative learning tools on ATProto";
    atprotoFocus = [ "applications" "tools" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    leaflet = pkgs.callPackage ./leaflet.nix { };
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