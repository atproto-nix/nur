{ pkgs, lib, ... }:

# Yoten App ATProto packages
# Organization: yoten-app
# Website: https://yoten.app

let
  # Organizational metadata
  organizationMeta = {
    name = "yoten-app";
    displayName = "Yoten App";
    website = "https://yoten.app";
    contact = null;
    maintainer = "Yoten App";
    description = "Language learning platform built on ATProto";
    atprotoFocus = [ "applications" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    yoten = pkgs.callPackage ./yoten.nix { };
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