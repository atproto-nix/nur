{ pkgs, lib, craneLib, fetchFromTangled, ... }:

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
    packageCount = 4;  # api, frontend, packages, slices
  };

  # Import slices.nix which returns { api, frontend, packages, slices }
  slicesPackages = pkgs.callPackage ./slices.nix { inherit craneLib fetchFromTangled; };

  # Package naming pattern: expose all components individually
  packages = {
    inherit (slicesPackages) api frontend packages slices;
  };

  # Enhanced packages with organizational metadata
  enhancedPackages = lib.mapAttrs (name: pkg:
    if pkg ? overrideAttrs then
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
    else
      # For non-derivation packages, just add the metadata to passthru
      pkg // {
        passthru = (pkg.passthru or {}) // {
          organization = organizationMeta;
          atproto = (pkg.passthru.atproto or {}) // {
            organization = organizationMeta;
          };
        };
      }
  ) packages;

in
enhancedPackages // {
  # Export organizational metadata for external use
  _organizationMeta = organizationMeta;
}
