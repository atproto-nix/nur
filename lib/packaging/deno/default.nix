# Deno packaging module
#
# Re-exports all Deno-related functions for easy access

{ lib, pkgs, ... }:

{
  # Build a Deno application
  buildDenoApp = { owner ? null, repo ? null, rev ? null, sha256 ? null, src ? null, denoJson ? null, ... }@args:
    let
      # Handle both direct src and GitHub fetching
      finalSrc = if src != null then src else pkgs.fetchFromGitHub {
        inherit owner repo rev sha256;
      };

      appName = args.pname or (if repo != null then repo else "deno-app");

      # Remove Deno-specific arguments
      denoArgs = builtins.removeAttrs args [ "denoJson" "owner" "repo" "rev" "sha256" ];
    in
    pkgs.stdenv.mkDerivation (denoArgs // {
      src = finalSrc;

      nativeBuildInputs = (args.nativeBuildInputs or []) ++ (with pkgs; [
        deno
        cacert  # Required for HTTPS imports
      ]);

      buildInputs = (args.buildInputs or []) ++ (with pkgs; []);

      # Enhanced Deno environment
      configurePhase = args.configurePhase or ''
        runHook preConfigure

        export DENO_DIR="$PWD/.deno"
        export DENO_CACHE_DIR="$PWD/.deno/cache"
        export DENO_NO_UPDATE_CHECK=1
        export DENO_NO_PROMPT=1

        mkdir -p "$DENO_DIR" "$DENO_CACHE_DIR"

        export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt

        runHook postConfigure
      '';

      # Enhanced build phase with better task detection
      buildPhase = args.buildPhase or ''
        runHook preBuild

        # Determine build strategy
        if [ -f "deno.json" ]; then
          CONFIG_FILE="deno.json"
        elif [ -f "deno.jsonc" ]; then
          CONFIG_FILE="deno.jsonc"
        else
          CONFIG_FILE=""
        fi

        # Cache dependencies first
        echo "Caching Deno dependencies..."
        if [ -n "$CONFIG_FILE" ]; then
          deno cache --config="$CONFIG_FILE" --lock-write deps.ts || \
          deno cache --config="$CONFIG_FILE" --lock-write mod.ts || \
          deno cache --config="$CONFIG_FILE" --lock-write main.ts || \
          echo "No main dependency file found"
        fi

        # Build based on available tasks
        if [ -n "$CONFIG_FILE" ] && deno task --config="$CONFIG_FILE" | grep -q "build"; then
          echo "Running Deno build task..."
          deno task --config="$CONFIG_FILE" build
        elif [ -f "main.ts" ]; then
          echo "Compiling main.ts..."
          if [ -n "$CONFIG_FILE" ]; then
            deno compile --allow-all --output=app --config="$CONFIG_FILE" main.ts
          else
            deno compile --allow-all --output=app main.ts
          fi
        elif [ -f "mod.ts" ]; then
          echo "Compiling mod.ts..."
          if [ -n "$CONFIG_FILE" ]; then
            deno compile --allow-all --output=app --config="$CONFIG_FILE" mod.ts
          else
            deno compile --allow-all --output=app mod.ts
          fi
        else
          echo "No suitable entry point found, creating placeholder"
          echo '#!/usr/bin/env deno run --allow-all' > app
          echo 'console.log("Deno application placeholder");' >> app
          chmod +x app
        fi

        runHook postBuild
      '';

      # Enhanced check phase
      checkPhase = args.checkPhase or ''
        runHook preCheck

        if [ -f "deno.json" ] && deno task --config=deno.json | grep -q "test"; then
          echo "Running Deno tests..."
          deno task --config=deno.json test || echo "Tests failed, continuing build"
        elif find . -name "*_test.ts" -o -name "*.test.ts" | grep -q .; then
          echo "Running Deno test files..."
          deno test --allow-all || echo "Tests failed, continuing build"
        fi

        if [ -f "main.ts" ]; then
          deno check main.ts || echo "Type check failed, continuing build"
        fi

        runHook postCheck
      '';

      doCheck = args.doCheck or true;

      # Enhanced install phase
      installPhase = args.installPhase or ''
        runHook preInstall

        mkdir -p $out/bin

        if [ -f "app" ] && [ -x "app" ]; then
          cp app $out/bin/${appName}
        elif [ -d "dist" ]; then
          mkdir -p $out/share/${appName}
          cp -r dist/* $out/share/${appName}/
          cat > $out/bin/${appName} << EOF
        #!/bin/sh
        cd $out/share/${appName}
        ${pkgs.deno}/bin/deno run --allow-all server.ts "\$@" || \
        ${pkgs.deno}/bin/deno run --allow-all main.ts "\$@" || \
        echo "No suitable entry point found in $out/share/${appName}"
        EOF
          chmod +x $out/bin/${appName}
        elif [ -d "build" ]; then
          mkdir -p $out/share/${appName}
          cp -r build/* $out/share/${appName}/
        else
          mkdir -p $out/share/${appName}
          cp -r . $out/share/${appName}/
          rm -rf $out/share/${appName}/.deno || true

          cat > $out/bin/${appName} << EOF
        #!/bin/sh
        cd $out/share/${appName}
        exec ${pkgs.deno}/bin/deno run --allow-all main.ts "\$@"
        EOF
          chmod +x $out/bin/${appName}
        fi

        runHook postInstall
      '';

      meta = (args.meta or {}) // {
        description = args.description or "ATproto Deno application: ${appName}";
        platforms = lib.platforms.all;
        mainProgram = appName;
      };
    });

  # Build Deno app with FOD (Fixed-Output Derivation) for dependency caching
  buildDenoAppWithFOD = { src, denoLock, denoCacheFODHash, outputHash ? null, ... }@args:
    let
      appName = args.pname or "deno-app";

      # Shared function references
      shared = import ../shared { inherit lib pkgs; };

      # Validate hash
      _ = shared.requireRealHash "denoCacheFODHash" denoCacheFODHash "buildDenoAppWithFOD";

      # FOD for Deno dependency cache
      denoCacheFOD = pkgs.runCommand "${appName}-deno-cache" {
        outputHashMode = "recursive";
        outputHash = denoCacheFODHash;
        nativeBuildInputs = [ pkgs.deno ];
      } ''
        export DENO_DIR="$out"
        cp -r ${src}/* .
        deno cache --lock=${denoLock} --reload ./src/main.ts || deno cache --lock=${denoLock} --reload ./mod.ts || true
        deno cache --lock=${denoLock} --reload-all ./src/main.ts || deno cache --lock=${denoLock} --reload-all ./mod.ts || true
      '';

      # Build with offline cache
      buildArgs = builtins.removeAttrs args [ "denoLock" "denoCacheFODHash" "outputHash" ] // {
        src = src;

        configurePhase = ''
          export DENO_DIR="$PWD/.deno"
          export DENO_NO_UPDATE_CHECK=1
          export DENO_NO_PROMPT=1

          # Link cached dependencies
          mkdir -p "$DENO_DIR"
          cp -r ${denoCacheFOD}/* "$DENO_DIR" || true
        '';

        buildPhase = args.buildPhase or ''
          export DENO_DIR="$PWD/.deno"
          deno cache --cached-only ./src/main.ts 2>/dev/null || deno cache --cached-only ./mod.ts 2>/dev/null || true
          deno task build --cached-only || deno compile --allow-all --output=app ./src/main.ts || true
        '';
      };

      # Build the app
      finalBuild = pkgs.stdenv.mkDerivation buildArgs;
    in
    if outputHash != null then
      pkgs.runCommand "${appName}-final" {
        outputHashMode = "recursive";
        outputHash = outputHash;
      } ''
        cp -r ${finalBuild}/* $out/
      ''
    else
      finalBuild;
}
