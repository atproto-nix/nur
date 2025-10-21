{ pkgs, lib, ... }:

# Witchcraft Systems ATProto packages
# Organization: witchcraft-systems
# Description: PDS management and monitoring tools

let
  # Organizational metadata
  organizationMeta = {
    name = "witchcraft-systems";
    displayName = "Witchcraft Systems";
    website = null;
    contact = null;
    maintainer = "Witchcraft Systems";
    description = "PDS management and monitoring tools for ATProto ecosystem";
    atprotoFocus = [ "tools" "infrastructure" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    pds-dash = pkgs.callPackage ./pds-dash.nix { };
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