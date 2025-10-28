# Common utility functions for packaging
#
# This module provides reusable utility functions that are used across
# different language-specific packaging modules.
#
# Usage:
#   inherit (packaging.shared.utils) mergeEnvs validateMembers;

{ lib, pkgs, ... }:

{
  # Merge environment variables, with right-hand side taking precedence
  #
  # Example:
  #   mergeEnvs { A = "1"; B = "2"; } { B = "3"; C = "4"; }
  #   # Result: { A = "1"; B = "3"; C = "4"; }
  mergeEnvs = base: override:
    base // override;

  # Merge multiple environment sets, right-most takes precedence
  #
  # Example:
  #   mergeEnvsMulti [ env1 env2 env3 ]
  mergeEnvsMulti = lib.foldl' lib.recursiveUpdate {};

  # Merge build inputs safely, avoiding duplicates where possible
  mergeInputs = base: override:
    let
      # Simple deduplication for common tools
      baseNames = lib.map (p: lib.getName p) base;
      overrideNewInputs = lib.filter (p: !(lib.elem (lib.getName p) baseNames)) override;
    in
    base ++ overrideNewInputs;

  # Extract the name from a package
  # Handles both strings and derivations
  extractName = pkg:
    if lib.isString pkg then pkg
    else if lib.isAttrs pkg && pkg ? pname then pkg.pname
    else if lib.isAttrs pkg && pkg ? name then pkg.name
    else throw "Cannot extract name from package: ${toString pkg}";

  # Validate that a list of required items exist
  # Useful for checking workspace members, services, etc.
  #
  # Example:
  #   validateExists "members" cargoToml ["svc1" "svc2"]
  validateExists = itemType: source: items:
    let
      sourceText = toString source;
      checkItem = item:
        if lib.isString source && lib.hasInfix item source then true
        else if lib.isAttrs source && source ? ${item} then true
        else false;
      missingItems = lib.filter (item: !checkItem item) items;
    in
    if missingItems != [] then
      throw "Missing ${itemType} in source: ${lib.concatStringsSep ", " missingItems}"
    else
      true;

  # Create a descriptive error message for missing configuration
  #
  # Example:
  #   requiredField "npmDepsHash" "buildNpmWithFOD"
  requiredField = fieldName: context:
    throw "${context} requires '${fieldName}' to be set. This value must be calculated on a Linux x86_64 system. See docs/JAVASCRIPT_DENO_BUILDS.md for instructions.";

  # Safely get a nested attribute with a default value
  #
  # Example:
  #   safeGetAttr ["config" "build" "target"] {} defaultValue
  safeGetAttr = path: attrs: default:
    let
      getValue = p: a:
        if p == [] then a
        else if lib.isAttrs a && a ? ${lib.head p} then
          getValue (lib.tail p) a.${lib.head p}
        else
          default;
    in
    getValue path attrs;

  # Create a package name with a prefix
  #
  # Example:
  #   mkPackageName "atproto" "api" # → "atproto-api"
  mkPackageName = org: name:
    "${org}-${name}";

  # Create a path-safe name by replacing slashes with dashes
  #
  # Example:
  #   mkPathSafeName "path/to/member" # → "path-to-member"
  mkPathSafeName = path:
    lib.replaceStrings ["/"] ["-"] path;

  # Check if a derivation/package is marked as broken
  isBroken = pkg:
    lib.isAttrs pkg && pkg ? meta && pkg.meta ? broken && pkg.meta.broken;

  # Check if a derivation/package is unsupported on current system
  isUnsupportedSystem = pkg: platforms:
    !(lib.elem pkgs.stdenv.system platforms);
}
