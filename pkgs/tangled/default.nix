# ==============================================================================
# Tangled Organization Packages
# ==============================================================================
#
# BEST PRACTICES FOR ORGANIZATION default.nix FILES:
#
# 1. ORGANIZATION METADATA
#    - Define organizationMeta with name, website, description
#    - Include atprotoFocus to indicate ecosystem categories
#    - Helps users understand organization's purpose and scope
#
# 2. PACKAGE COLLECTION
#    - Use simple names within organization (spindle, not tangled-spindle)
#    - Reference individual package .nix files
#    - Pass required context (lib, buildGoModule, etc.)
#
# 3. METADATA ENHANCEMENT
#    - Use lib.mapAttrs to attach organizational metadata to all packages
#    - Enables ecosystem discovery without duplication
#    - Metadata available via passthru and meta fields
#
# 4. ALL PACKAGE EXPORT
#    - Create "all" package with symlinkJoin
#    - Allows building all packages at once: nix build .#org-all
#    - Useful for CI and testing entire organization
#
# 5. ORGANIZATIONAL EXPORT
#    - Export _organizationMeta for tooling
#    - Metadata accessible without evaluating individual packages
#    - Used by NUR aggregator and documentation tools
#
# ==============================================================================

{ pkgs, lib, buildGoModule, ... }:

let
  # BEST PRACTICE: Define comprehensive organizational metadata
  # This information is attached to all packages in the organization
  # Makes organization discoverable and self-documenting
  organizationMeta = {
    name = "tangled";           # Unique identifier
    displayName = "Tangled";    # Human-readable name
    website = "https://tangled.org";  # Organization homepage
    contact = null;             # Contact information (if available)
    maintainer = "Tangled";     # Maintainer name
    description = "Git forge and development tools for ATProto ecosystem";
    atprotoFocus = [ "tools" "infrastructure" "applications" ];
    packageCount = 7;           # Number of packages in organization
  };

  # BEST PRACTICE: Package collection with simple local names
  # Names are prefixed by organization at aggregation layer
  # This allows flexibility and clarity within organization
  packages = {
    appview-static-files = pkgs.callPackage ./appview-static-files.nix { };
    appview = pkgs.callPackage ./appview.nix { inherit buildGoModule; };
    knot = pkgs.callPackage ./knot.nix { inherit buildGoModule; };
    spindle = pkgs.callPackage ./spindle.nix { inherit buildGoModule; };
    avatar = pkgs.callPackage ./avatar.nix { };
    camo = pkgs.callPackage ./camo.nix { };
    genjwks = pkgs.callPackage ./genjwks.nix { };
    lexgen = pkgs.callPackage ./lexgen.nix { };
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
          displayName = organizationMeta.name;
        };
      };
    })
  ) packages;

  # Create an "all" derivation to build all packages at once
  allPackages = pkgs.symlinkJoin {
    name = "tangled-all";
    paths = lib.filter (pkg: pkg != packages.appview-static-files) (lib.attrValues packages);
    meta = {
      description = "All Tangled packages";
      homepage = "https://tangled.org";
    };
  };

in
enhancedPackages // {
  # Export "all" package to build everything at once
  all = allPackages;

  # Export organizational metadata for external use
  _organizationMeta = organizationMeta;
}