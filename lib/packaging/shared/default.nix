# Shared utilities module
#
# Re-exports all shared utilities for easy access
# This is the entry point for the shared module

{ lib, pkgs, ... }:

let
  environments = import ./environments.nix { inherit lib pkgs; };
  inputs = import ./inputs.nix { inherit lib pkgs; };
  utils = import ./utils.nix { inherit lib pkgs; };
  validation = import ./validation.nix { inherit lib pkgs; };
in

{
  inherit (environments)
    standardEnv
    standardRustEnv
    standardNodeEnv
    standardGoEnv
    standardDenoEnv
    mkDeterministicNodeEnv
    mkDeterministicDenoEnv;

  inherit (inputs)
    standardNativeInputs
    standardBuildInputs
    standardRustNativeInputs
    standardRustBuildInputs
    standardNodeNativeInputs
    standardNodeBuildInputs
    standardGoNativeInputs
    standardGoBuildInputs
    standardDenoNativeInputs
    standardDenoBuildInputs
    mkLanguageInputs;

  inherit (utils)
    mergeEnvs
    mergeEnvsMulti
    mergeInputs
    extractName
    validateExists
    requiredField
    safeGetAttr
    mkPackageName
    mkPathSafeName
    isBroken
    isUnsupportedSystem;

  inherit (validation)
    isRealHash
    requireRealHash
    validatePinnedVersion
    validatePackageStructure
    validateHashFormat
    validateCargoLock
    validatePnpmLock
    validateDenoLock
    validateGoMod
    validateFODSetup
    validateRegex
    createValidationReport;
}
