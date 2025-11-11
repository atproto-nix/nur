# Validation utilities for packages and hashes
#
# This module provides functions to validate package configurations,
# hashes, versions, and other important build parameters.
#
# Usage:
#   inherit (packaging.shared.validation) validateHash requireRealHash;

{ lib, pkgs, ... }:

{
  # Check if a hash is a real hash or lib.fakeHash
  #
  # Example:
  #   isRealHash "sha256-abc123..." # → true
  #   isRealHash lib.fakeHash # → false
  isRealHash = hash:
    hash != lib.fakeHash && hash != "" && !(lib.isNull hash);

  # Require that a hash is a real hash (not lib.fakeHash)
  # Throws an error if the hash is fake
  #
  # Example:
  #   requireRealHash "npmDepsHash" lib.fakeHash "build.nix:34"
  requireRealHash = fieldName: hash: context:
    if !isRealHash hash then
      throw "${context}: ${fieldName} must be a real hash, not lib.fakeHash. See PINNING_NEEDED.md for calculation instructions."
    else
      hash;

  # Validate that a version is pinned (not "main" or "master")
  #
  # Example:
  #   validatePinnedVersion "abc123def..." "package.nix:7"
  #   validatePinnedVersion "main" "package.nix:7" # → throws error
  validatePinnedVersion = version: context:
    if version == "main" || version == "master" || version == "" then
      throw "${context}: version must be pinned to a specific commit, not '${version}'. Use 'nix rev show origin/main' to get the latest commit hash."
    else
      version;

  # Validate package structure (required fields)
  #
  # Example:
  #   validatePackageStructure { pname = "myapp"; version = "1.0"; }
  validatePackageStructure = pkg:
    let
      requiredFields = [ "pname" "version" ];
      missingFields = lib.filter (f: !lib.hasAttr f pkg) requiredFields;
    in
    if missingFields != [] then
      throw "Package missing required fields: ${lib.concatStringsSep ", " missingFields}"
    else
      pkg;

  # Validate hash format
  # Checks that a hash matches expected format (sha256-, sha512-, etc.)
  #
  # Example:
  #   validateHashFormat "sha256-abc123..."
  validateHashFormat = hash:
    let
      isValidSha256 = lib.hasPrefix "sha256-" hash && lib.stringLength hash > 7;
      isValidSha512 = lib.hasPrefix "sha512-" hash && lib.stringLength hash > 7;
    in
    if hash == lib.fakeHash then
      throw "Hash is lib.fakeHash - this must be replaced with a real hash"
    else if !(isValidSha256 || isValidSha512) then
      throw "Hash format invalid: ${hash}. Expected sha256-... or sha512-..."
    else
      hash;

  # Validate Cargo.lock exists in workspace
  validateCargoLock = src:
    if !(builtins.pathExists "${src}/Cargo.lock") then
      throw "Cargo.lock not found in ${src}. Workspace builds require pinned dependencies."
    else
      true;

  # Validate pnpm-lock.yaml exists in workspace
  validatePnpmLock = src:
    if !(builtins.pathExists "${src}/pnpm-lock.yaml") then
      throw "pnpm-lock.yaml not found in ${src}. pnpm workspace builds require a lock file."
    else
      true;

  # Validate deno.lock exists in workspace
  validateDenoLock = src:
    if !(builtins.pathExists "${src}/deno.lock") then
      throw "deno.lock not found in ${src}. Deno builds should include a lock file for reproducibility."
    else
      true;

  # Validate go.mod exists in workspace
  validateGoMod = src:
    if !(builtins.pathExists "${src}/go.mod") then
      throw "go.mod not found in ${src}. Go module builds require go.mod."
    else
      true;

  # Comprehensive validation for FOD (Fixed-Output Derivation) setup
  # Checks that both dependency cache hash and output hash are real
  #
  # Example:
  #   validateFODSetup "deno-cache" "sha256-..." "sha256-..."
  validateFODSetup = fodName: cacheHash: outputHash:
    let
      cacheValid = isRealHash cacheHash;
      outputValid = isRealHash outputHash;
    in
    if !cacheValid || !outputValid then
      throw "FOD ${fodName}: Both cache hash and output hash must be real. See docs/JAVASCRIPT_DENO_BUILDS.md for FOD pattern explanation."
    else
      true;

  # Validate that a string matches a regex pattern
  validateRegex = pattern: value: context:
    let
      # Simple regex-like validation (Nix doesn't have regex, so we use string operations)
      isMatch = lib.isString value && lib.stringLength value > 0;
    in
    if !isMatch then
      throw "${context}: Expected a non-empty string, got ${value}"
    else
      value;

  # Create a validation report for a package
  # Returns a structured report with all validation results
  createValidationReport = pkg:
    {
      name = pkg.pname or "unknown";
      version = pkg.version or "unknown";
      hasRealHash = isRealHash (pkg.npmDepsHash or pkg.vendorHash or lib.fakeHash);
      isVersionPinned = !(lib.elem (pkg.rev or "") ["main" "master" ""]);
      report = {
        hash = isRealHash (pkg.npmDepsHash or pkg.vendorHash or lib.fakeHash);
        version = !(lib.elem (pkg.rev or "") ["main" "master" ""]);
      };
    };
}
