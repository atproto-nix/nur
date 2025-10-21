{ pkgs, lib, craneLib, ... }:

# Individual Developers ATProto packages
# Organization: individual

let
  # Organizational metadata
  organizationMeta = {
    name = "individual";
    displayName = "Individual Developers";
    website = null;
    contact = null;
    maintainer = "Individual Contributors";
    description = "ATProto packages from individual developers without clear organizational ownership";
    atprotoFocus = [ "tools" "applications" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    pds-gatekeeper = pkgs.callPackage ./pds-gatekeeper.nix { inherit craneLib; };
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