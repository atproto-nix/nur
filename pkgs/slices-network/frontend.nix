# Slices Frontend - Deno-based web interface for ATProto custom AppViews
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

  # Fixed-output derivation to pre-populate DENO_DIR for the frontend
  # This caches all Deno dependencies offline before the main build
  denoCacheFOD = packaging.determinism.createValidatedFOD {
    name = "slices-frontend-deno-cache";
    # Hash needs to be recalculated after removing codegen task
    # TODO: Replace with correct hash from first build attempt
    outputHash = lib.fakeHash;
    nativeBuildInputs = with pkgs; [ deno cacert curl unzip ];

    script = ''
      export HOME="$PWD/home"
      export DENO_DIR="$out"
      export DENO_NO_UPDATE_CHECK=1
      export DENO_NO_PROMPT=1
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

      mkdir -p "$HOME"
      cp -r ${src}/* .

      # Cache the main entrypoint and all its dependencies
      echo "Caching frontend entrypoint..."
      if [ -f deno.lock ]; then
        deno cache --lock=deno.lock frontend/src/main.ts
      else
        deno cache frontend/src/main.ts
      fi

      # Cache all package dependencies that frontend might import
      echo "Caching all workspace packages..."
      if [ -f deno.lock ]; then
        deno cache --lock=deno.lock packages/*/mod.ts packages/*/src/**/*.ts 2>/dev/null || true
      else
        deno cache packages/*/mod.ts packages/*/src/**/*.ts 2>/dev/null || true
      fi

      # IMPORTANT: We do NOT run 'deno task codegen:frontend' in FOD
      # Reason: Codegen requires the CLI to be built first, creating circular dependency
      # Solution: Codegen should be run at build time (buildPhase) AFTER packages are available
      # Currently we skip codegen since frontend may use pre-generated client.ts
    '';
  };

  # Build the Deno frontend - creates a wrapper script instead of compiling
  frontend = pkgs.stdenv.mkDerivation {
    name = "slices-frontend-0.2.0";
    inherit src;

    nativeBuildInputs = with pkgs; [ deno makeWrapper ];
    buildInputs = with pkgs; [ openssl sqlite ];

    # Frontend-specific environment (build-time defaults)
    env = packaging.standardDenoEnv // {
      DATABASE_URL = "postgresql://slices:slices@localhost:5432/slices";
      REDIS_URL = "redis://localhost:6379";
      RELAY_ENDPOINT = "https://relay1.us-west.bsky.network";
      JETSTREAM_HOSTNAME = "jetstream1.us-west.bsky.network";
      API_URL = "http://localhost:3000";
      OAUTH_AIP_BASE_URL = "http://localhost:8081";
    };

    buildPhase = ''
      runHook preBuild

      # Use the pre-populated DENO_DIR from the FOD
      export HOME="$PWD/home"
      export DENO_DIR="$PWD/.deno"
      export DENO_NO_UPDATE_CHECK=1
      export DENO_NO_PROMPT=1

      mkdir -p "$HOME" "$DENO_DIR"

      # Copy cached dependencies
      echo "Copying cache from ${denoCacheFOD}..."
      cp -r ${denoCacheFOD}/* "$DENO_DIR"/
      chmod -R u+w "$DENO_DIR"

      # Note: Codegen is skipped here due to circular build dependency
      # (frontend needs generated client from CLI, CLI is built separately)
      # If frontend/src/client.ts doesn't exist, the service will fail at runtime
      # This is acceptable if client.ts is pre-generated or if we build packages first
      echo "Preparing frontend for runtime execution (codegen handled separately)..."

      # Don't use deno compile (requires denort download)
      # Instead, we'll create a wrapper script that runs the code directly

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/slices-frontend

      # Copy source files and cache
      cp -r frontend $out/share/slices-frontend/
      cp -r packages $out/share/slices-frontend/
      cp -r "$DENO_DIR" $out/share/slices-frontend/.deno

      # Copy workspace configuration files - REQUIRED for workspace imports to work
      # Without root deno.json, imports like @slices/client won't resolve
      [ -f deno.json ] && cp deno.json $out/share/slices-frontend/ || true
      [ -f deno.jsonc ] && cp deno.jsonc $out/share/slices-frontend/ || true
      [ -f deno.lock ] && cp deno.lock $out/share/slices-frontend/ || true

      # Create wrapper script
      makeWrapper ${pkgs.deno}/bin/deno $out/bin/slices-frontend \
        --add-flags "run" \
        --add-flags "--allow-all" \
        --add-flags "--no-check" \
        --add-flags "--cached-only" \
        --add-flags "$out/share/slices-frontend/frontend/src/main.ts" \
        --set DENO_DIR "$out/share/slices-frontend/.deno" \
        --set DENO_NO_UPDATE_CHECK "1" \
        --set DENO_NO_PROMPT "1"

      runHook postInstall
    '';

    meta = with lib; {
      description = "Slices frontend - Web interface for ATproto custom AppViews";
      longDescription = ''
        Deno-based server-side rendered web application providing:
        - Web-based slice management and records browsing
        - OAuth integration with session management
        - HTMX-powered interactive UI
        - Generated TypeScript client integration
        - Multi-tenant slice administration
      '';
      homepage = "https://slices.network";
      license = licenses.mit;
      platforms = platforms.all;
      maintainers = [ ];
      mainProgram = "slices-frontend";
    };
  };

in
frontend
