{ pkgs, lib, buildGoModule ? pkgs.buildGoModule, ... }:

# PLC Bundle packages
# Organization: plcbundle (atscan.net)
# Website: https://tangled.org/@atscan.net/plcbundle

let
  # Organizational metadata
  organizationMeta = {
    name = "plcbundle";
    displayName = "PLC Bundle";
    website = "https://tangled.org/@atscan.net/plcbundle";
    contact = null;
    maintainer = "atscan.net";
    description = "Cryptographic archiving of AT Protocol DID operations into immutable, chained bundles";
    atprotoFocus = [ "infrastructure" "archiving" "did-operations" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    plcbundle = pkgs.callPackage ./plcbundle.nix { inherit buildGoModule; };
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
    name = "plcbundle-all";
    paths = lib.attrValues packages;
    meta = {
      description = "All PLC Bundle packages";
      homepage = "https://tangled.org/@atscan.net/plcbundle";
    };
  };

in
enhancedPackages // {
  # Export "all" package to build everything at once
  all = allPackages;

  # Export organizational metadata for external use
  _organizationMeta = organizationMeta;
}
