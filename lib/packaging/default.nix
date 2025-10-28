# Modular ATProto packaging library
#
# This is the main entry point for the modular packaging library.
# It re-exports all language and tool-specific functions organized by module.
#
# Usage:
#   let packaging = import ./lib/packaging { inherit lib pkgs craneLib; };
#   in {
#     myRustApp = packaging.rust.buildRustAtprotoPackage { ... };
#     myNodeApp = packaging.nodejs.buildNpmWithFOD { ... };
#     myViteApp = packaging.nodejs.bundlers.buildWithViteOffline { ... };
#   }

{ lib, pkgs, craneLib ? pkgs.craneLib, buildNpmPackage ? pkgs.buildNpmPackage, buildGoModule ? pkgs.buildGoModule, ... }:

let
  shared = import ./shared { inherit lib pkgs; };
  rust = import ./rust { inherit lib pkgs craneLib; };
  nodejs = import ./nodejs { inherit lib pkgs buildNpmPackage; };
  go = import ./go { inherit lib pkgs buildGoModule; };
  deno = import ./deno { inherit lib pkgs; };
  determinism = import ./determinism { inherit lib pkgs; };
in

{
  # Shared utilities (cross-language)
  inherit (shared)
    standardEnv
    standardRustEnv
    standardNodeEnv
    standardGoEnv
    standardDenoEnv
    mkDeterministicNodeEnv
    mkDeterministicDenoEnv
    standardNativeInputs
    standardBuildInputs
    mkLanguageInputs
    mergeEnvs
    mergeInputs
    validateExists
    requiredField
    safeGetAttr
    mkPackageName
    mkPathSafeName
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
    createValidationReport;

  # Rust (via Crane)
  rust = {
    inherit (rust)
      buildRustAtprotoPackage
      buildRustWorkspace
      validateWorkspace
      createRustVersion
      getRustLdFlags
      extractWorkspaceMembers
      mkTestConfig
      mkBuildConfig
      mkRustMetadata;
  };

  # Node.js ecosystem
  nodejs = {
    inherit (nodejs)
      buildNpmPackage
      buildNpmWithFOD
      buildPnpmWorkspace;

    # JavaScript bundlers (Vite, esbuild, webpack)
    bundlers = nodejs.bundlers;
  };

  # Go ecosystem
  go = {
    inherit (go)
      buildGoAtprotoModule;
  };

  # Deno ecosystem
  deno = {
    inherit (deno)
      buildDenoApp
      buildDenoAppWithFOD;
  };

  # Determinism utilities
  determinism = {
    inherit (determinism)
      createFOD
      mkDeterministicNodeEnv
      mkDeterministicDenoEnv
      buildWithOfflineCache
      testDeterminism
      validateFODSetup
      createValidatedFOD;
  };
}
