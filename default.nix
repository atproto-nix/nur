{ pkgs, craneLib, ... }:

let
  # Enhanced ATProto library with comprehensive metadata
  atprotoLib = pkgs.callPackage ./lib/atproto.nix {
    inherit craneLib;
    fetchFromTangled = pkgs.fetchFromTangled;
  } // {
    # Add library metadata for easier introspection
    __description = "ATProto Nix packaging and utility library";
    __version = "0.1.0";
  };

  # Import packages with enhanced context
  allPackages = pkgs.callPackage ./pkgs {
    inherit craneLib atprotoLib;
    # Optional: Pass additional context if needed
    __metadataContext = {
      repositoryRoot = ./.;
      generationTimestamp = builtins.currentTime;
    };
  };

  # Robust package and derivation detection
  isValidPackage = pkg:
    (pkg.type or "") == "derivation" ||  # Standard Nix derivation
    (builtins.isAttrs pkg && pkg ? outPath) ||  # Has output path
    (builtins.isAttrs pkg && pkg ? drvPath) ||  # Has derivation path
    # Comprehensive package-like attribute detection
    (builtins.isAttrs pkg && (
      builtins.hasAttr "pname" pkg ||
      builtins.hasAttr "name" pkg ||
      builtins.hasAttr "version" pkg ||
      builtins.hasAttr "meta" pkg
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
