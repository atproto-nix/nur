{ pkgs, lib, ... }:

# Official Bluesky ATProto packages
# Organization: bluesky-social
# Website: https://bsky.social

let
  # Organizational metadata
  organizationMeta = {
    name = "bluesky-social";
    displayName = "Official Bluesky";
    website = "https://bsky.social";
    contact = null;
    maintainer = "Bluesky Social";
    description = "Official Bluesky ATProto implementations and tools";
    atprotoFocus = [ "infrastructure" "servers" "libraries" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    indigo = pkgs.callPackage ./indigo.nix { };
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