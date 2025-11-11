{ pkgs, lib, buildGoModule, fetchFromTangled, fetchurl, ... }:

# Stream.place ATProto packages
# Organization: stream-place
# Website: https://stream.place
#
# Provides both source and binary build variants of Streamplace:
# - streamplace: Source build (recommended for customization)
# - streamplace-binary: Prebuilt binary (recommended for quick installation)

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
    packageCount = 2;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    # Source build variant - full compilation from tangled.org
    streamplace = pkgs.callPackage ./streamplace.nix {
      inherit buildGoModule fetchFromTangled;
    };

    # Binary variant - prebuilt release from git.stream.place
    streamplace-binary = pkgs.callPackage ./binary.nix {
      inherit fetchurl;
    };
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

  # Convenience aliases
  source = packages.streamplace;          # Full source build
  binary = packages.streamplace-binary;   # Prebuilt binary
}