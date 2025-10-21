{ pkgs, lib, ... }:

# ATBackup ATProto packages
# Organization: atbackup-pages-dev
# Website: https://atbackup.pages.dev

let
  # Organizational metadata
  organizationMeta = {
    name = "atbackup-pages-dev";
    displayName = "ATBackup";
    website = "https://atbackup.pages.dev";
    contact = null;
    maintainer = "ATBackup";
    description = "Backup and archival tools for ATProto data";
    atprotoFocus = [ "tools" "applications" ];
    packageCount = 1;
  };

  # Package naming pattern: use simple names within organization
  packages = {
    atbackup = pkgs.callPackage ./atbackup.nix { };
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