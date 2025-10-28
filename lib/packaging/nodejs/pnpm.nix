# pnpm workspace packaging with FOD support
#
# This module provides specialized builders for pnpm monorepos,
# including support for Fixed-Output Derivations for deterministic builds.
#
# Usage:
#   inherit (packaging.nodejs) buildPnpmWorkspace buildPnpmWithFOD;

{ lib, pkgs, buildNpmPackage, ... }:

let
  shared = import ../shared { inherit lib pkgs; };
in

{
  # Build pnpm workspace with FOD support
  #
  # Handles complex pnpm monorepos with:
  # - Catalog dependencies
  # - Workspace package interdependencies
  # - Shared FOD for all packages
  #
  # Example:
  #   buildPnpmWorkspace {
  #     owner = "org";
  #     repo = "repo";
  #     rev = "abc123...";
  #     sha256 = "sha256-...";
  #     workspaces = [ "packages/app" "packages/lib" ];
  #     sharedNpmDepsHash = "sha256-...";  # MUST be real hash
  #   }
  buildPnpmWorkspace = { owner, repo, rev, sha256, workspaces, ... }@args:
    let
      src = pkgs.fetchFromGitHub {
        inherit owner repo rev sha256;
      };

      workspaceName = args.pname or repo;

      # Validate pnpm-lock.yaml exists
      _ = shared.validatePnpmLock src;

      # Process pnpm catalog dependencies
      processedSrc = pkgs.runCommand "${workspaceName}-processed" {} ''
        cp -r ${src} $out
        chmod -R +w $out

        # Process pnpm-workspace.yaml if it exists
        if [ -f "$out/pnpm-workspace.yaml" ]; then
          echo "Found pnpm workspace configuration"
        fi

        # Process package.json catalog dependencies
        if [ -f "$out/package.json" ]; then
          sed -i 's/"catalog:"/""/g' "$out/package.json" || true
        fi

        # Process workspace package.json files
        for workspace in ${lib.concatStringsSep " " workspaces}; do
          if [ -f "$out/$workspace/package.json" ]; then
            sed -i 's/"catalog:"/""/g' "$out/$workspace/package.json" || true
          fi
        done
      '';

      # Shared pnpm configuration
      sharedPnpmConfig = pkgs.writeText "pnpm-config" ''
        auto-install-peers=true
        shamefully-hoist=true
        strict-peer-dependencies=false
      '';

      # Validate hashes
      _ = shared.requireRealHash "sharedNpmDepsHash" (args.sharedNpmDepsHash or lib.fakeHash) "buildPnpmWorkspace";

      # Build shared node_modules for entire workspace with FOD
      sharedNodeModules = pkgs.runCommand "${workspaceName}-shared-deps" {
        outputHashMode = "recursive";
        outputHash = args.sharedNpmDepsHash or lib.fakeHash;
        nativeBuildInputs = with pkgs; [
          nodejs
          nodePackages.pnpm
          python3
        ];
      } ''
        cp -r ${processedSrc}/* .
        export PNPM_HOME="$PWD/.pnpm"
        export PATH="$PNPM_HOME:$PATH"
        cp ${sharedPnpmConfig} .npmrc
        pnpm install --frozen-lockfile --ignore-scripts
        mkdir -p $out
        cp -r node_modules $out/
        cp -r .pnpm $out/ || true
      '';

      # Build individual workspace
      buildWorkspace = workspace:
        let
          workspaceConfig = (args.workspaceConfigs or {}).${workspace} or {};
        in
        pkgs.buildNpmPackage ({
          src = processedSrc;
          pname = "${workspaceName}-${workspace}";
          version = args.version or "0.1.0";
          sourceRoot = "${processedSrc.name}/${workspace}";
          npmDepsHash = lib.fakeHash;  # Already cached by FOD

          nativeBuildInputs = shared.standardNodeNativeInputs ++ (workspaceConfig.nativeBuildInputs or []) ++ [ pkgs.nodePackages.pnpm ];
          buildInputs = shared.standardNodeBuildInputs ++ (workspaceConfig.buildInputs or []);

          # Enhanced pnpm configuration
          preConfigure = ''
            export PNPM_HOME="$PWD/.pnpm"
            export PATH="$PNPM_HOME:$PATH"
            export NODE_OPTIONS="--max-old-space-size=4096"

            # Link shared dependencies
            if [ -d "${sharedNodeModules}/node_modules" ]; then
              ln -sf ${sharedNodeModules}/node_modules ./node_modules
            fi

            cp ${sharedPnpmConfig} .npmrc
            ${workspaceConfig.preConfigure or ""}
          '';

          # Build phase
          buildPhase = workspaceConfig.buildPhase or ''
            runHook preBuild

            # Install workspace-specific dependencies
            pnpm install --frozen-lockfile

            # Build the workspace
            if [ -f "package.json" ] && grep -q '"build"' package.json; then
              pnpm build
            elif [ -f "turbo.json" ]; then
              pnpm turbo build
            else
              echo "No build script found, skipping build phase"
            fi

            runHook postBuild
          '';

          # Install phase
          installPhase = workspaceConfig.installPhase or ''
            runHook preInstall

            mkdir -p $out

            # Copy built artifacts
            if [ -d "dist" ]; then
              cp -r dist/* $out/
            elif [ -d "build" ]; then
              cp -r build/* $out/
            elif [ -d "out" ]; then
              cp -r out/* $out/
            elif [ -d ".next" ]; then
              cp -r .next $out/
            else
              cp -r . $out/
              rm -rf $out/node_modules $out/.pnpm || true
            fi

            if [ -f "package.json" ]; then
              cp package.json $out/
            fi

            runHook postInstall
          '';

          # Environment for deterministic builds
          env = shared.mkDeterministicNodeEnv {} // (workspaceConfig.env or {});

          # Metadata
          meta = (args.meta or {}) // (workspaceConfig.meta or {}) // {
            description = (args.workspaceDescriptions or {}).${workspace} or workspaceConfig.description or "ATproto Node.js workspace: ${workspace}";
            platforms = lib.platforms.all;
          };
        } // (builtins.removeAttrs workspaceConfig ["nativeBuildInputs" "buildInputs" "meta" "description"]));

      # Validate workspaces
      validateWorkspaces =
        let
          pnpmWorkspaceFile = "${processedSrc}/pnpm-workspace.yaml";
          packageJsonFile = "${processedSrc}/package.json";
        in
        if !(builtins.pathExists pnpmWorkspaceFile || builtins.pathExists packageJsonFile) then
          throw "No pnpm-workspace.yaml or package.json found in ${workspaceName}"
        else
          true;
    in
    assert validateWorkspaces;
    lib.genAttrs workspaces buildWorkspace;
}
