# Vite bundler support for deterministic builds
#
# CRITICAL: Vite generates non-deterministic output. This module provides
# the FOD (Fixed-Output Derivation) pattern needed to make Vite builds reproducible.
#
# See: docs/JAVASCRIPT_DENO_BUILDS.md for detailed explanation
#
# Usage:
#   inherit (packaging.nodejs.bundlers) buildWithViteOffline viteDeterminismEnv;

{ lib, pkgs, ... }:

let
  shared = import ../../shared { inherit lib pkgs; };
in

{
  # Environment variables to minimize Vite non-determinism
  # CRITICAL: These controls are essential for reproducible Vite builds
  viteDeterminismEnv = {
    NODE_ENV = "production";
    VITE_INLINE_ASSETS_THRESHOLD = "0";  # Don't inline assets (hashes vary)
    CI = "true";  # Some tools disable non-deterministic features in CI
    VITE_SKIP_ENV_VALIDATION = "1";
  };

  # Apply Vite-specific determinism controls to build environment
  applyViteDeterminismControls = baseEnv:
    baseEnv // viteDeterminismEnv;

  # Build with Vite in offline mode using FOD
  #
  # Pattern:
  # 1. Create FOD to cache npm dependencies
  # 2. Run Vite build offline with that cache
  # 3. If Vite output is still non-deterministic, wrap in second FOD
  #
  # Example:
  #   buildWithViteOffline {
  #     pname = "myapp";
  #     src = fetchFromGitHub { ... };
  #     npmDepsHash = "sha256-...";  # FOD for npm cache
  #     viteBuildHash = "sha256-..."; # FOD for final output (if non-deterministic)
  #   }
  buildWithViteOffline = { src, npmDepsHash, viteBuildHash ? null, ... }@args:
    let
      # Validate dependencies hash
      _ = shared.requireRealHash "npmDepsHash" npmDepsHash "buildWithViteOffline";

      pname = args.pname or "vite-app";

      # Step 1: Create FOD for npm dependencies
      npmDependencies = pkgs.runCommand "${pname}-npm-deps" {
        outputHashMode = "recursive";
        outputHash = npmDepsHash;
        nativeBuildInputs = with pkgs; [ npm nodejs ];
      } ''
        cp -r ${src}/* .
        npm ci --prefer-offline --no-audit
        mkdir -p $out
        cp -r node_modules $out/
      '';

      # Step 2: Build Vite app with offline npm cache
      viteBuild = pkgs.stdenv.mkDerivation ({
        pname = pname;
        version = args.version or "0.1.0";
        src = src;

        nativeBuildInputs = shared.standardNodeNativeInputs ++ (args.nativeBuildInputs or []);
        buildInputs = shared.standardNodeBuildInputs ++ (args.buildInputs or []);

        # Offline setup using FOD cache
        preBuild = ''
          # Copy cached node_modules
          mkdir -p node_modules
          cp -r ${npmDependencies}/node_modules/* node_modules/

          # Apply determinism controls
          export NODE_ENV=production
          export VITE_INLINE_ASSETS_THRESHOLD=0
          export CI=true
          export VITE_SKIP_ENV_VALIDATION=1

          ${args.preBuild or ""}
        '';

        buildPhase = args.buildPhase or ''
          runHook preBuild
          npm run build || npx vite build
          runHook postBuild
        '';

        installPhase = args.installPhase or ''
          runHook preInstall
          mkdir -p $out
          if [ -d dist ]; then
            cp -r dist/* $out/
          elif [ -d build ]; then
            cp -r build/* $out/
          else
            cp -r . $out/
          fi
          runHook postInstall
        '';

        # Environment controls for determinism
        env = applyViteDeterminismControls (args.env or {});

        # Metadata
        meta = (args.meta or {}) // {
          description = args.description or "Vite application: ${pname}";
          platforms = lib.platforms.all;
        };
      });

      # Step 3: If output is non-deterministic, wrap in FOD
      # This is sometimes necessary if Vite embeds timestamps, hashes, etc.
      finalBuild = if viteBuildHash != null then
        pkgs.runCommand "${pname}-final" {
          outputHashMode = "recursive";
          outputHash = viteBuildHash;
        } ''
          cp -r ${viteBuild}/* $out/
        ''
      else
        viteBuild;
    in
    finalBuild;

  # Test if a build is deterministic
  # Builds twice and checks if outputs differ
  testViteDeterminism = { src, ... }@args:
    pkgs.runCommand "${args.pname or "vite"}-determinism-test" {
      nativeBuildInputs = with pkgs; [ diffutils ];
    } ''
      echo "Building Vite app twice to test determinism..."

      build1=$(mktemp -d)
      build2=$(mktemp -d)

      # Build 1
      cp -r ${src} $build1/src
      cd $build1/src
      npm ci > /dev/null 2>&1
      npm run build > /dev/null 2>&1
      cp -r dist $build1/output1

      # Build 2
      cp -r ${src} $build2/src
      cd $build2/src
      npm ci > /dev/null 2>&1
      npm run build > /dev/null 2>&1
      cp -r dist $build2/output2

      # Compare
      if diff -r $build1/output1 $build2/output2 > $out/diff-report.txt 2>&1; then
        echo "✓ Vite build is deterministic"
        touch $out/deterministic
      else
        echo "✗ Vite build is NON-DETERMINISTIC - see diff-report.txt"
        exit 1
      fi
    '';
}
