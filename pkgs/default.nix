# ==============================================================================
# Package Collection Aggregator - All Organizations
# ==============================================================================
#
# BEST PRACTICES:
#
# 1. ORGANIZATIONAL STRUCTURE
#    - Each organization in separate directory with its own default.nix
#    - Each organization collects related packages
#    - Metadata attached automatically to all packages
#
# 2. CONTEXT PASSING
#    - Pass lib, craneLib, buildGoModule, buildNpmPackage, atprotoLib
#    - Each organization's default.nix receives full context
#    - Reduces boilerplate in package definitions
#
# 3. PACKAGE FILTERING
#    - Filter out non-package attributes (like _organizationMeta)
#    - Check for actual derivations (outPath or drvPath)
#    - Ensures clean package export
#
# 4. NAMESPACE FLATTENING
#    - Convert org/package to org-package naming
#    - Provides flat namespace for flake outputs
#    - Legacy collections (microcosm, blacksky, bluesky) keep old naming
#
# 5. METADATA EXPORT
#    - Export both packages and organizational metadata
#    - Metadata available for tooling without evaluating all packages
#    - Useful for CI and documentation generation
#
# ==============================================================================

{ pkgs, lib, craneLib, fetchgit, buildGoModule ? pkgs.buildGoModule, buildNpmPackage ? pkgs.buildNpmPackage, buildGoApplication ? null, atprotoLib, ... }:

let
  # BEST PRACTICE: Organize packages by category and purpose
  # Each sub-organization in ORGANIZATION/default.nix returns:
  # - Named packages (e.g., { mypackage = {...}; })
  # - _organizationMeta attribute with metadata
  organizationalPackages = {
    # Educational and collaborative platforms
    # Packages for learning, collaboration, and knowledge sharing
    # DISABLED: Depends on incomplete Supabase code
    # hyperlink-academy = pkgs.callPackage ./hyperlink-academy { inherit lib; };

    # Custom AppView and social platforms
    # Alternative social media frontends and social experiences
    slices-network = pkgs.callPackage ./slices-network { inherit lib craneLib; fetchFromTangled = pkgs.fetchFromTangled; };
    teal-fm = pkgs.callPackage ./teal-fm { inherit lib; };
    parakeet-social = pkgs.callPackage ./parakeet-social { inherit lib craneLib fetchgit; };

    # Media and streaming platforms
    # Video, audio, and media delivery services
    stream-place = pkgs.callPackage ./stream-place { inherit lib buildGoModule; fetchFromTangled = pkgs.fetchFromTangled; fetchurl = pkgs.fetchurl; };

    # Language learning and specialized apps
    # Educational tools and specialized applications
    yoten-app = pkgs.callPackage ./yoten-app { inherit lib buildGoModule; fetchFromTangled = pkgs.fetchFromTangled; };

    # Client applications
    # (Space for future client application packages)

    # Development tools and infrastructure
    # Core infrastructure tools, build systems, and development utilities
    tangled = pkgs.callPackage ./tangled { inherit lib buildGoModule; fetchFromTangled = pkgs.fetchFromTangled; };

    # JavaScript/Wasm runtime for Cloudflare Workers self-hosting
    # Cloudflare's open-source workerd runtime for self-hosting Worker-based services
    workerd = pkgs.callPackage ./workerd { inherit lib; };

    # PLC Bundle - DID operation archiving and distribution (atscan.net)
    # Cryptographic archiving of AT Protocol DID operations
    plcbundle = pkgs.callPackage ./plcbundle { inherit lib buildGoModule; fetchFromTangled = pkgs.fetchFromTangled; };

    # Identity and infrastructure services
    smokesignal-events = pkgs.callPackage ./smokesignal-events { inherit lib craneLib; };
    

    
    # System administration and monitoring
    witchcraft-systems = pkgs.callPackage ./witchcraft-systems {
      inherit lib atprotoLib;
    };
    
    # Bluesky client applications
    whey-party = pkgs.callPackage ./whey-party { inherit lib buildNpmPackage; fetchFromTangled = pkgs.fetchFromTangled; };

    # Official Bluesky packages
    bluesky = pkgs.callPackage ./bluesky { inherit lib; };

    # Photo-sharing platforms
    grain-social = pkgs.callPackage ./grain-social { inherit lib craneLib; };

    # Individual developer packages
    baileytownsend = pkgs.callPackage ./baileytownsend { inherit lib craneLib; };
    mackuba = pkgs.callPackage ./mackuba { inherit lib; fetchFromTangled = pkgs.fetchFromTangled; };
    whyrusleeping = pkgs.callPackage ./whyrusleeping { inherit lib; };
    hailey-at = pkgs.callPackage ./hailey-at { inherit lib buildGoModule; fetchFromTangled = pkgs.fetchFromTangled; };

    # New organizational framework packages
    likeandscribe = pkgs.callPackage ./likeandscribe { inherit lib craneLib buildNpmPackage; };

    # Backend-as-a-service platforms
    # DISABLED: Supabase code is incomplete
    # supabase = pkgs.callPackage ./supabase { inherit lib buildNpmPackage; };

    # Legacy package collections (for backward compatibility)
    microcosm = pkgs.callPackage ./microcosm { inherit craneLib; };
    blacksky = pkgs.callPackage ./blacksky { inherit lib craneLib; };
  };

  # BEST PRACTICE: Robust derivation detection
  # Checks multiple properties to identify buildable packages
  # Filters out metadata and non-derivation attributes
  isDerivation = pkg:
    # Standard Nix derivation (has type field)
    (pkg.type or "" == "derivation") ||
    (builtins.isAttrs pkg && pkg ? outPath) ||
    (builtins.isAttrs pkg && pkg ? drvPath);

  # BEST PRACTICE: Flatten organizational packages into unified namespace
  # Converts nested org/package structure to flat org-package naming
  # Legacy organizations keep their existing naming for backward compatibility
  flattenedPackages =
    let
      # BEST PRACTICE: Prefix addition helper
      # Adds organization name prefix to all package names
      # Filters out metadata and non-derivations
      addOrgPrefix = orgName: packages:
        lib.mapAttrs' (pkgName: pkg:
          # Skip metadata and non-derivations
          lib.nameValuePair "${orgName}-${pkgName}" pkg
        ) (lib.filterAttrs (n: v: n != "_organizationMeta" && isDerivation v) packages);

      # BEST PRACTICE: Process each organizational collection
      # Handle legacy collections specially (microcosm, blacksky, bluesky)
      # Use standard org-package naming for new organizations
      orgCollections = lib.mapAttrsToList (orgName: packages:
        if orgName == "microcosm" || orgName == "blacksky" || orgName == "bluesky"
        then
          # Legacy collections keep their existing prefixes for backward compatibility
          lib.mapAttrs' (pkgName: pkg:
            lib.nameValuePair "${orgName}-${pkgName}" pkg
          ) (lib.filterAttrs (n: v: n != "_organizationMeta" && isDerivation v) packages)
        else
          # New organizational collections use consistent org-package naming
          addOrgPrefix orgName packages
      ) organizationalPackages;

    in
    lib.foldl' (acc: collection: acc // collection) {} orgCollections;
in
flattenedPackages
