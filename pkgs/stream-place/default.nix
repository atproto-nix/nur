{ pkgs, lib, buildGoModule, ... }:

# Stream.place ATProto packages
# Organization: stream-place
# Website: https://stream.place

let
  # Organizational metadata
  organizationMeta = {
    name = "stream-place";
    displayName = "Stream.place";
    website = "https://stream.place";
    contact = null;
    maintainer = "Stream.place";
    description = "Video infrastructure platform with ATProto integration";
    atprotoFocus = [ "applications" "infrastructure" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    streamplace = pkgs.callPackage ./streamplace.nix { inherit buildGoModule; };
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