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
    outputHash = "sha256-0GB33BIOSs721oykIDL//G/2KbhtQEt97Cd+JmO8tIg=";
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

      echo "Building Slices CLI..."
      if [ -f packages/cli/src/main.ts ]; then
        deno compile \
          --allow-all \
          --no-check \
          --cached-only \
          ${lib.optionalString (builtins.pathExists (src + "/deno.lock")) "--lock=deno.lock"} \
          --output=slices-cli \
          packages/cli/src/main.ts || echo "CLI build failed"
      fi

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/slices-packages

      # Install CLI binary if built
      if [ -f slices-cli ]; then
        cp slices-cli $out/bin/slices
        chmod +x $out/bin/slices
      fi

      # Install packages for runtime use
      cp -r packages $out/share/slices-packages/

      # Create wrapper scripts for packages that can be run as scripts
      for pkg in cli client codegen lexicon oauth session; do
        if [ -d "packages/$pkg" ] && [ -f "packages/$pkg/mod.ts" ]; then
          makeWrapper ${pkgs.deno}/bin/deno $out/bin/slices-$pkg \
            --add-flags "run --allow-all --no-check --cached-only" \
            --add-flags "$out/share/slices-packages/packages/$pkg/mod.ts" \
            --set DENO_DIR "${packagesCacheFOD}" \
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
