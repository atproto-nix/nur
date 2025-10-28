# Determinism utilities for reproducible builds
#
# This module provides helpers for creating deterministic, reproducible builds
# using Fixed-Output Derivations (FOD) and environment controls.
#
# See: docs/JAVASCRIPT_DENO_BUILDS.md for detailed explanation of FOD pattern
#
# Usage:
#   inherit (packaging.determinism) buildWithFOD testDeterminism;

{ lib, pkgs, ... }:

{
  # Create a Fixed-Output Derivation (FOD) for dependency caching
  #
  # FOD ensures:
  # 1. All dependencies are fetched offline
  # 2. The output hash must match exactly (reproducibility guarantee)
  # 3. Can be used before non-deterministic builders (Vite, esbuild)
  #
  # Example:
  #   createFOD {
  #     name = "app-deps";
  #     script = ''mkdir -p $out && npm ci'';
  #     outputHash = "sha256-...";
  #   }
  createFOD = { name, script, outputHash, nativeBuildInputs ? [], ... }:
    pkgs.runCommand name {
      outputHashMode = "recursive";
      outputHash = outputHash;
      inherit nativeBuildInputs;
    } script;

  # Create a deterministic Node.js environment with controls
  #
  # Applies environment variables that minimize non-determinism in bundlers
  mkDeterministicNodeEnv = { extraEnv ? {}, ... }:
    {
      NODE_ENV = "production";
      VITE_INLINE_ASSETS_THRESHOLD = "0";  # Don't inline assets
      CI = "true";  # Some tools disable non-determinism in CI
      npm_config_verbose = "true";
    } // extraEnv;

  # Create a deterministic Deno environment
  mkDeterministicDenoEnv = { cacheDir ? "$PWD/.deno", extraEnv ? {}, ... }:
    {
      DENO_DIR = cacheDir;
      DENO_NO_UPDATE_CHECK = "1";
      DENO_NO_PROMPT = "1";
    } // extraEnv;

  # Build a package with offline FOD cache before the main build
  #
  # Pattern:
  # 1. Create FOD to cache dependencies
  # 2. Link cached dependencies in preBuild
  # 3. Run non-deterministic builder offline
  #
  # Example:
  #   buildWithOfflineCache {
  #     pname = "myapp";
  #     src = src;
  #     cacheFODHash = "sha256-...";
  #     buildCommand = "npm run build";
  #   }
  buildWithOfflineCache = { pname, src, cacheFODHash, buildCommand, ... }@args:
    let
      shared = import ../shared { inherit lib pkgs; };

      # Validate hash is real
      _ = shared.requireRealHash "cacheFODHash" cacheFODHash "buildWithOfflineCache";

      # Create dependency cache FOD
      cachedDependencies = pkgs.runCommand "${pname}-deps-fod" {
        outputHashMode = "recursive";
        outputHash = cacheFODHash;
        nativeBuildInputs = with pkgs; [ npm nodejs ];
      } ''
        cp -r ${src}/* .
        npm ci --prefer-offline --no-audit
        mkdir -p $out
        cp -r node_modules $out/
      '';
    in
    pkgs.stdenv.mkDerivation ({
      inherit pname src;
      version = args.version or "0.1.0";

      nativeBuildInputs = (args.nativeBuildInputs or []) ++ (with pkgs; [ npm nodejs ]);

      # Link cached dependencies
      preBuild = ''
        mkdir -p node_modules
        cp -r ${cachedDependencies}/node_modules/* node_modules/

        # Apply determinism controls
        export NODE_ENV=production
        export VITE_INLINE_ASSETS_THRESHOLD=0
        export CI=true

        ${args.preBuild or ""}
      '';

      buildPhase = ''
        runHook preBuild
        ${buildCommand}
        runHook postBuild
      '';

      installPhase = args.installPhase or ''
        mkdir -p $out
        if [ -d dist ]; then
          cp -r dist/* $out/
        elif [ -d build ]; then
          cp -r build/* $out/
        else
          cp -r . $out/
        fi
      '';

      env = args.env or {};

      meta = args.meta or {};
    });

  # Test if a build is deterministic
  # Builds twice and compares outputs
  #
  # Returns a derivation with:
  # - determinism-test passed/failed
  # - diff-report.txt showing differences
  #
  # Example:
  #   testDeterminism {
  #     pname = "myapp";
  #     src = src;
  #     buildCommand = "npm run build";
  #   }
  testDeterminism = { pname, src, buildCommand, ... }@args:
    pkgs.runCommand "${pname}-determinism-test" {
      nativeBuildInputs = with pkgs; [ diffutils npm nodejs ];
    } ''
      echo "Testing determinism of ${pname}..."

      build1=$(mktemp -d)
      build2=$(mktemp -d)

      # Build 1
      cp -r ${src} $build1/src
      cd $build1/src
      npm ci > /dev/null 2>&1
      ${buildCommand} > /dev/null 2>&1
      mkdir -p $build1/output
      if [ -d dist ]; then cp -r dist/* $build1/output/; fi
      if [ -d build ]; then cp -r build/* $build1/output/; fi

      # Build 2
      cp -r ${src} $build2/src
      cd $build2/src
      npm ci > /dev/null 2>&1
      ${buildCommand} > /dev/null 2>&1
      mkdir -p $build2/output
      if [ -d dist ]; then cp -r dist/* $build2/output/; fi
      if [ -d build ]; then cp -r build/* $build2/output/; fi

      # Compare
      mkdir -p $out
      if diff -r $build1/output $build2/output > $out/diff-report.txt 2>&1; then
        echo "✓ Build is deterministic"
        touch $out/determinism-test
      else
        echo "✗ Build is NON-DETERMINISTIC - see diff-report.txt"
        cat $out/diff-report.txt
        exit 1
      fi
    '';

  # Create a validation script for FOD setup
  validateFODSetup = { fodName, cacheHash, outputHash ? null, ... }:
    let
      shared = import ../shared { inherit lib pkgs; };
    in
    if !shared.isRealHash cacheHash then
      throw "${fodName}: cacheHash must be a real hash, not lib.fakeHash"
    else if outputHash != null && !shared.isRealHash outputHash then
      throw "${fodName}: outputHash must be a real hash, not lib.fakeHash"
    else
      true;

  # Create FOD with validation
  createValidatedFOD = { name, script, outputHash, ... }@args:
    let
      shared = import ../shared { inherit lib pkgs; };
      _ = shared.requireRealHash "outputHash" outputHash "createValidatedFOD";
    in
    pkgs.runCommand name {
      outputHashMode = "recursive";
      outputHash = outputHash;
      nativeBuildInputs = args.nativeBuildInputs or [];
    } script;
}
