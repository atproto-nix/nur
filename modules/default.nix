{ lib, ... }:

let
  # Simply return the module path for NixOS to import
  importModule = name:
    let
      modulePath = ./. + "/${name}";
    in
      if builtins.pathExists modulePath
      then modulePath
      else throw "Module '${name}' not found at ${toString modulePath}";

  # Categorized module names with optional metadata
  moduleCategories = {
    core = [
      "atproto"
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
      # "slices-network"  # TODO: Has infinite recursion issue with nested submodules
      "teal-fm"
      "parakeet-social"
      "yoten-app"
      "red-dwarf-client"
    ];

    misc = [
      "grain-social"
      "mackuba"
      "whey-party"
      "whyrusleeping"
      "likeandscribe"
      "witchcraft-systems"
    ];
  };

  # Flatten and deduplicate module names
  moduleNames = lib.unique (
    builtins.concatLists (builtins.attrValues moduleCategories)
  );

  # Import modules (returns list of paths)
  importedModules = builtins.map importModule moduleNames;

in {
  # Import all module paths
  imports = importedModules;
}
