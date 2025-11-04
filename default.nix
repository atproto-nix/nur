# ==============================================================================
# ATProto NUR - Default Package Collection
# ==============================================================================
#
# BEST PRACTICES:
#
# 1. FUNCTION SIGNATURE
#    - Receives pkgs (nixpkgs set), craneLib (Rust build system)
#    - Spread operator (...) catches unused parameters gracefully
#    - Allows flexibility when called from different contexts
#
# 2. LIBRARY INITIALIZATION
#    - atprotoLib provides shared build logic and metadata validation
#    - Available to all package definitions without re-importing
#    - Includes helpers for Rust, Go, Node.js, Deno builds
#
# 3. PACKAGE FILTERING
#    - isValidPackage checks multiple derivation formats
#    - Handles standard Nix derivations and ATProto-specific formats
#    - Robust against edge cases and package variations
#
# 4. METADATA CONTEXT
#    - Passes repository root and generation timestamp
#    - Enables packages to reference absolute paths
#    - Useful for debugging and reproducibility tracking
#
# 5. MODULE SAFETY
#    - safeModuleImport handles missing modules gracefully
#    - Returns empty module structure instead of failing
#    - Allows gradual module adoption without breaking everything
#
# ==============================================================================

{ pkgs, craneLib, ... }:

let
  # BEST PRACTICE: Extract and enhance ATProto library
  # - Load base library from lib/atproto.nix
  # - Add metadata for introspection and debugging
  # - Makes it available to all sub-packages via inherit
  atprotoLib = pkgs.callPackage ./lib/atproto.nix {
    inherit craneLib;
    fetchFromTangled = pkgs.fetchFromTangled;
  } // {
    # Metadata aids debugging and system documentation
    __description = "ATProto Nix packaging and utility library";
    __version = "0.1.0";
  };

  # BEST PRACTICE: Import all packages with shared context
  # Ensures consistent build environment and access to utilities
  # This is the main entry point for package aggregation
  allPackages = pkgs.callPackage ./pkgs {
    inherit craneLib atprotoLib;
    # Pass metadata context for per-package introspection
    __metadataContext = {
      repositoryRoot = ./.;  # Enables absolute path references
      generationTimestamp = builtins.currentTime;  # Tracks when built
    };
  };

  # BEST PRACTICE: Comprehensive package detection
  # Different package formats have different properties:
  # - Standard Nix derivations: type == "derivation"
  # - Flake packages: have outPath or drvPath
  # - ATProto packages: have pname/name/version/meta fields
  # This function handles all variations robustly
  isValidPackage = pkg:
    # Check if it's a standard Nix derivation
    (pkg.type or "" == "derivation") ||
    # Check if it has Nix store paths (indicates derivation-like)
    (builtins.isAttrs pkg && pkg ? outPath) ||
    (builtins.isAttrs pkg && pkg ? drvPath) ||
    # Check if it has package metadata fields
    (builtins.isAttrs pkg && (
      builtins.hasAttr "pname" pkg ||  # Package name
      builtins.hasAttr "name" pkg ||   # Alternative name format
      builtins.hasAttr "version" pkg ||  # Version number
      builtins.hasAttr "meta" pkg      # Metadata (description, license, etc.)
    ));

  # Enhanced module import with detailed metadata
  safeModuleImport =
    let
      moduleList = [
        "microcosm"
        "blacksky"
        "bluesky"
        "hyperlink-academy"
        "slices-network"
        "teal-fm"
        "parakeet-social"
        "stream-place"
        "yoten-app"
        "red-dwarf-client"
        "tangled"
        "smokesignal-events"
	"mackuba"
      ];

      importModule = name:
        let
          modulePath = ./modules + "/${name}";
          moduleImport =
            if builtins.pathExists modulePath
            then import modulePath
            else {
              imports = [];
              __description = "Module '${name}' not found";
            };
        in moduleImport // {
          __moduleName = name;
          __importPath = modulePath;
          __importTime = builtins.currentTime;
        };

      importedModules = builtins.listToAttrs
        (builtins.map
          (name: {
            name = name;
            value = importModule name;
          })
          moduleList
        );
    in {
      inherit importedModules;
      imports = builtins.attrValues importedModules;
      __description = "NixOS modules for ATProto ecosystem";
      __moduleCount = builtins.length moduleList;
    };

  # Organizational metadata extraction
  organizationsMetadata = allPackages.organizations or {};

  # Enhanced package filtering
  packages = pkgs.lib.filterAttrs (n: v:
    n != "_organizationalMetadata" &&
    (
      isValidPackage v ||  # Valid package
      n == "x86_64-linux" ||  # System-specific package sets
      n == "modules"  # Always include modules attribute
    )
  ) allPackages;

in {
  # Expose library with additional metadata
  lib = atprotoLib;

  # Safe and descriptive module handling
  modules = safeModuleImport;

  # Transparent overlays for nixpkgs integration
  overlays = import ./overlay.nix;

  # Expose organizational package collections
  organizations = organizationsMetadata;

  # Comprehensive package exposure
  inherit packages;
}
