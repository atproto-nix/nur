{ pkgs, lib, fetchFromTangled, ... }:

# Mackuba - ATProto tools and applications
# Organization: mackuba
# Website: https://tangled.org/@mackuba.eu

let
  # Organizational metadata
  organizationMeta = {
    name = "mackuba";
    displayName = "Mackuba (@mackuba.eu)";
    website = "https://tangled.org/@mackuba.eu";
    contact = "@mackuba.eu";
    maintainer = "Kuba Suder (mackuba.eu)";
    description = "ATProto tools and feed generators by @mackuba.eu";
    atprotoFocus = [ "feeds" "tools" "libraries" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    lycan = pkgs.callPackage ./lycan.nix { inherit fetchFromTangled; };
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

  # Create an "all" derivation to build all packages at once
  allPackages = pkgs.symlinkJoin {
    name = "mackuba-all";
    paths = lib.attrValues enhancedPackages;
    meta = {
      description = "All Mackuba packages";
      homepage = "https://tangled.org/@mackuba.eu";
    };
  };

in
enhancedPackages // {
  # Export "all" package to build everything at once
  all = allPackages;

  # Export organizational metadata for external use
  _organizationMeta = organizationMeta;
}
