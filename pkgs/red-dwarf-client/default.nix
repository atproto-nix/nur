{ pkgs, lib, buildNpmPackage, ... }:

# Red Dwarf Client ATProto packages
# Organization: red-dwarf-client
# Description: Constellation-based Bluesky client

let
  # Organizational metadata
  organizationMeta = {
    name = "red-dwarf-client";
    displayName = "Red Dwarf Client";
    website = null;
    contact = null;
    maintainer = "Red Dwarf Client";
    description = "Constellation-based Bluesky client for ATProto";
    atprotoFocus = [ "applications" "clients" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    red-dwarf = pkgs.callPackage ./red-dwarf.nix { inherit buildNpmPackage; };
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