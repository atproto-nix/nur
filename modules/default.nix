{ pkgs, ... }:

let
  # Enhanced module import with metadata and error handling
  importModule = name:
    let
      modulePath = ./. + "/${name}";
      moduleImport =
        if builtins.pathExists modulePath
        then import modulePath
        else {
          imports = [];
          __description = "Module '${name}' not found";
        };
    in moduleImport // {
      # Add metadata to each module
      __moduleName = name;
      __importPath = modulePath;
      __importTime = builtins.currentTime;
    };

  # Categorized module names with optional metadata
  moduleCategories = {
    core = [
      "microcosm"
      "blacksky"
      "bluesky"
      "individual"
      "smokesignal-events"
    ];

    infrastructure = [
      "tangled"
      "stream-place"
    ];

    applications = [
      "hyperlink-academy"
      "slices-network"
      "teal-fm"
      "parakeet-social"
      "yoten-app"
      "red-dwarf-client"
    ];

    misc = [
      "atbackup-pages-dev"
      "grain-social"
      "mackuba"
      "whey-party"
      "whyrusleeping"
      "likeandscribe"
      "witchcraft-systems"
    ];
  };

  # Flatten and deduplicate module names
  moduleNames = pkgs.lib.unique (
    builtins.concatLists (builtins.attrValues moduleCategories)
  );

  # Import modules with error handling and metadata
  importedModules = builtins.map importModule moduleNames;

  # Categorized module metadata
  moduleMetadata = {
    categories = moduleCategories;
    total = builtins.length moduleNames;
    imported = builtins.length importedModules;
    availableModules = moduleNames;
  };

in {
  # Enhanced module imports with comprehensive handling
  imports = importedModules;

  # Expose rich module metadata
  __moduleMetadata = moduleMetadata;

  # Dynamic module accessor function
  __functor = _: {
    imports = importedModules;
    inherit moduleMetadata;
  };

  # Attribute-based module access
  core = builtins.filter
    (m: builtins.elem m.__moduleName moduleCategories.core)
    importedModules;

  infrastructure = builtins.filter
    (m: builtins.elem m.__moduleName moduleCategories.infrastructure)
    importedModules;

  applications = builtins.filter
    (m: builtins.elem m.__moduleName moduleCategories.applications)
    importedModules;

  misc = builtins.filter
    (m: builtins.elem m.__moduleName moduleCategories.misc)
    importedModules;
}
