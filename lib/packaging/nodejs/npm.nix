# npm packaging with FOD support
#
# This module provides npm-specific builders optimized for ATProto
# with support for Fixed-Output Derivations (FOD) for deterministic,
# offline builds.
#
# Usage:
#   inherit (packaging.nodejs) buildNpmWithFOD buildNpmPackage;

{ lib, pkgs, buildNpmPackage, ... }:

let
  shared = import ../shared { inherit lib pkgs; };
in

{
  # Standard npm package builder
  #
  # Example:
  #   buildNpmPackage {
  #     src = fetchFromGitHub { ... };
  #     npmDepsHash = "sha256-...";
  #   }
  buildNpmPackage = { src, packageJson ? null, workspaces ? [], ... }@args:
    let
      # Remove packaging-specific arguments
      npmArgs = builtins.removeAttrs args [ "packageJson" "workspaces" ];

      # Standard Node.js configuration for ATProto
      standardArgs = {
        npmDepsHash = args.npmDepsHash or lib.fakeHash;
        dontNpmBuild = args.dontNpmBuild or false;

        # Standard build inputs for Node.js ATProto apps
        nativeBuildInputs = shared.standardNodeNativeInputs ++ (args.nativeBuildInputs or []);
        buildInputs = shared.standardNodeBuildInputs ++ (args.buildInputs or []);

        # Environment for native modules
        env = shared.standardNodeEnv // (args.env or {});
      };

      # Merge arguments
      finalArgs = standardArgs // npmArgs;
    in
    if workspaces != [] then
      # Handle workspace builds
      let
        buildWorkspace = workspace: buildNpmPackage (finalArgs // {
          pname = "${args.pname or "workspace"}-${workspace}";
          sourceRoot = "${src.name}/${workspace}";
        });
      in
      lib.genAttrs workspaces buildWorkspace
    else
      pkgs.buildNpmPackage finalArgs;

  # Build npm package with FOD (Fixed-Output Derivation)
  #
  # FOD pattern caches npm dependencies offline before the build runs,
  # ensuring deterministic output from non-deterministic builders like Vite.
  #
  # See: docs/JAVASCRIPT_DENO_BUILDS.md for detailed explanation
  #
  # Example:
  #   buildNpmWithFOD {
  #     src = fetchFromGitHub { ... };
  #     npmDepsHash = "sha256-...";  # MUST be real hash
  #     outputHash = "sha256-...";   # For non-deterministic builds
  #   }
  buildNpmWithFOD = { src, npmDepsHash, outputHash ? null, ... }@args:
    let
      # Validate hashes are real (not lib.fakeHash)
      _ = shared.requireRealHash "npmDepsHash" npmDepsHash "buildNpmWithFOD";

      # Create FOD for npm dependencies
      npmCacheFOD = pkgs.runCommand "${args.pname or "npm-deps"}-fod" {
        outputHashMode = "recursive";
        outputHash = npmDepsHash;
        nativeBuildInputs = with pkgs; [ npm nodejs ];
      } ''
        cp -r ${src}/* .
        npm ci --prefer-offline --no-audit
        mkdir -p $out
        cp -r node_modules $out/
      '';

      # Build phase with offline cache
      buildArgs = builtins.removeAttrs args [ "npmDepsHash" "outputHash" ] // {
        src = src;
        dontNpmBuild = false;
        nativeBuildInputs = shared.standardNodeNativeInputs ++ (args.nativeBuildInputs or []);
        buildInputs = shared.standardNodeBuildInputs ++ (args.buildInputs or []);

        # Pre-build: Link cached node_modules
        preBuild = (args.preBuild or "") + ''
          mkdir -p node_modules
          cp -r ${npmCacheFOD}/node_modules/* node_modules/
        '';

        # Environment for deterministic builds
        env = shared.mkDeterministicNodeEnv {} // (args.env or {});
      };

      # If non-deterministic output (from bundlers), wrap in another FOD
      buildPackage = if outputHash != null then
        pkgs.stdenv.mkDerivation (buildArgs // {
          outputHashMode = "recursive";
          outputHash = outputHash;
          buildPhase = args.buildPhase or ''
            npm run build
          '';
          installPhase = args.installPhase or ''
            mkdir -p $out
            cp -r dist/* $out/
          '';
        })
      else
        pkgs.buildNpmPackage buildArgs;
    in
    buildPackage;
}
