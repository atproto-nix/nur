# Slices Packages - Deno CLI and client libraries
{ lib, pkgs, ... }:

let
  # Import packaging utilities
  packaging = pkgs.callPackage ../../lib/packaging { };

  # Source from Tangled
  src = pkgs.fetchFromTangled {
    domain = "tangled.org";
    owner = "@slices.network";
    repo = "slices";
    rev = "0a876a16d49c596d779d21a80a9ba0822f9d571f";
    sha256 = "0wk6n082w9vdxfp549ylffnz0arwi78rlwai4jhdlvq3cr0547k8";
  };

  # Fixed-output derivation for packages cache
  packagesCacheFOD = packaging.determinism.createValidatedFOD {
    name = "slices-packages-deno-cache";
    outputHash = "sha256-U0dhXo7O7OX1FCxa5HFGVIZCXPfDrMK+cT1R1veDvpw=";
    nativeBuildInputs = with pkgs; [ deno cacert curl unzip ];

    script = ''
      export HOME="$PWD/home"
      export DENO_DIR="$out"
      export DENO_NO_UPDATE_CHECK=1
      export DENO_NO_PROMPT=1
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

      mkdir -p "$HOME"
      cp -r ${src}/* .

      # Cache workspace dependencies
      echo "Caching packages workspace..."
      if [ -f deno.lock ]; then
        deno cache --lock=deno.lock packages/*/mod.ts packages/*/src/mod.ts 2>/dev/null || true
        deno cache --lock=deno.lock packages/cli/src/main.ts 2>/dev/null || true
      else
        deno cache packages/*/mod.ts packages/*/src/mod.ts 2>/dev/null || true
        deno cache packages/cli/src/main.ts 2>/dev/null || true
      fi
    '';
  };

  # Build the CLI and client packages using Deno workspace
  packages = pkgs.stdenv.mkDerivation {
    name = "slices-packages-0.2.0";
    inherit src;

    nativeBuildInputs = with pkgs; [ deno makeWrapper ];

    buildPhase = ''
      runHook preBuild

      export HOME="$PWD/home"
      export DENO_DIR="$PWD/.deno"
      export DENO_NO_UPDATE_CHECK=1
      export DENO_NO_PROMPT=1

      mkdir -p "$HOME" "$DENO_DIR"

      # Copy cached dependencies
      echo "Copying cache from ${packagesCacheFOD}..."
      cp -rv ${packagesCacheFOD}/* "$DENO_DIR"/
      chmod -R u+w "$DENO_DIR"

      echo "Preparing Slices CLI (will use wrapper script)..."
      # Don't use deno compile - it requires downloading denort binary
      # We'll create a wrapper script in installPhase instead

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/slices-packages

      # Install packages and Deno cache for runtime use
      cp -r packages $out/share/slices-packages/
      cp -r "$DENO_DIR" $out/share/slices-packages/.deno

      # Copy config files if they exist
      [ -f deno.json ] && cp deno.json $out/share/slices-packages/ || true
      [ -f deno.jsonc ] && cp deno.jsonc $out/share/slices-packages/ || true
      [ -f deno.lock ] && cp deno.lock $out/share/slices-packages/ || true

      # Create main slices CLI wrapper
      if [ -f packages/cli/src/main.ts ]; then
        makeWrapper ${pkgs.deno}/bin/deno $out/bin/slices \
          --add-flags "run" \
          --add-flags "--allow-all" \
          --add-flags "--no-check" \
          --add-flags "--cached-only" \
          --add-flags "$out/share/slices-packages/packages/cli/src/main.ts" \
          --set DENO_DIR "$out/share/slices-packages/.deno" \
          --set DENO_NO_UPDATE_CHECK "1" \
          --set DENO_NO_PROMPT "1"
      fi

      # Create wrapper scripts for other packages that can be run as scripts
      for pkg in client codegen lexicon oauth session; do
        if [ -d "packages/$pkg" ] && [ -f "packages/$pkg/mod.ts" ]; then
          makeWrapper ${pkgs.deno}/bin/deno $out/bin/slices-$pkg \
            --add-flags "run --allow-all --no-check --cached-only" \
            --add-flags "$out/share/slices-packages/packages/$pkg/mod.ts" \
            --set DENO_DIR "$out/share/slices-packages/.deno" \
            --set DENO_NO_UPDATE_CHECK "1" \
            --set DENO_NO_PROMPT "1"
        fi
      done

      runHook postInstall
    '';

    meta = with lib; {
      description = "Slices packages - CLI and client libraries for ATproto custom AppViews";
      longDescription = ''
        Deno-based packages providing:
        - CLI for slice management and code generation
        - TypeScript client libraries for API interaction
        - OAuth and session management utilities
        - Lexicon processing and validation tools
        - Code generation for custom schemas
      '';
      homepage = "https://slices.network";
      license = licenses.mit;
      platforms = platforms.all;
      maintainers = [ ];
    };
  };

in
packages
