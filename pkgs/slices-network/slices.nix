{ lib, pkgs, craneLib, buildNpmPackage, ... }:

let
  # Import packaging utilities
  packaging = pkgs.callPackage ../../lib/packaging.nix { inherit craneLib; };
  atprotoCore = pkgs.callPackage ../../lib/atproto-core.nix { inherit craneLib; };

  # Source from Tangled git repository
  src = pkgs.fetchFromTangled {
    domain = "tangled.org";
    owner = "@slices.network";
    repo = "slices";
    rev = "0a876a16d49c596d779d21a80a9ba0822f9d571f";
    sha256 = "0wk6n082w9vdxfp549ylffnz0arwi78rlwai4jhdlvq3cr0547k8";
  };

  # Common environment for all components
  commonEnv = {
    # Database configuration
    DATABASE_URL = "postgresql://slices:slices@localhost:5432/slices";
    REDIS_URL = "redis://localhost:6379";

    # ATproto configuration
    RELAY_ENDPOINT = "https://relay1.us-west.bsky.network";
    JETSTREAM_HOSTNAME = "jetstream1.us-west.bsky.network";

    # Development defaults
    RUST_LOG = "debug";
    PORT = "3000";
    PROCESS_TYPE = "all";
  };

  # Common arguments for the Rust API backend
  apiCommonArgs = {
    pname = "slices-api";
    version = "0.2.0";
    src = src;
    sourceRoot = "${src.name}/api";

    nativeBuildInputs = with pkgs;
      [ pkg-config perl ];

    buildInputs = with pkgs;
      [ openssl postgresql sqlite zstd lz4 cacert ];
  };

  apiEnv = commonEnv // {
    # Rust-specific environment
    SQLX_OFFLINE = "true";
  };

  # Vendor multiple Cargo.lock files
  vendoredCargoDeps = craneLib.vendorMultipleCargoDeps {
    cargoLockList = [
      (src + "/api/Cargo.lock")
      (src + "/crates/slices-lexicon/Cargo.lock")
    ];
  };

  # Build dependencies only for caching
  apiCargoArtifacts = craneLib.buildDepsOnly (apiCommonArgs // {
    cargoVendorDir = vendoredCargoDeps;
    cargoLockContents = builtins.readFile (src + "/api/Cargo.lock");
    env = apiEnv;
  });

  # Build the Rust API backend
  api = packaging.buildRustAtprotoPackage (apiCommonArgs // {
    cargoArtifacts = apiCargoArtifacts;
    cargoVendorDir = vendoredCargoDeps;
    extraEnv = apiEnv;

    # Copy migrations and other runtime assets
    postInstall = ''
      mkdir -p $out/share/slices-api
      if [ -d migrations ]; then
        cp -r migrations $out/share/slices-api/
      fi
      if [ -f schema.sql ]; then
        cp schema.sql $out/share/slices-api/
      fi
    '';

    buildPhase = ''
      runHook preBuild
      cargoBuildLog=$(mktemp cargoBuildLogXXXX.json)
      cargo build --release --message-format json-render-diagnostics >"$cargoBuildLog"
      runHook postBuild
    '';

    meta = with lib;
      {
        description = "Slices API backend - ATproto custom AppView platform";
        longDescription = ''
          Rust-based API backend for Slices, providing:
          - AT Protocol XRPC handlers with dynamic endpoints
          - Lexicon validation for custom schemas
          - Sync engine for bulk data synchronization
          - Jetstream integration for real-time streaming
          - PostgreSQL and Redis integration
          - OAuth integration for AT Protocol authentication
        '';
        homepage = "https://slices.network";
        license = licenses.mit;
        platforms = platforms.linux ++ platforms.darwin;
        maintainers = [ ];
        mainProgram = "slices";
      };
  });

  # Fixed-output derivation to pre-populate DENO_DIR for the frontend
  denoCacheFOD = pkgs.stdenvNoCC.mkDerivation {
    name = "slices-frontend-deno-cache";

    src = src;

    nativeBuildInputs = [ pkgs.deno pkgs.cacert pkgs.curl pkgs.unzip ];

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    # Update this hash after first build with lib.fakeHash
    outputHash = "sha256-VN2pCnjqw8IpguSpBABS2DFU++uEVdwy++ATIghCppk=";

    buildPhase = ''
      export HOME="$PWD/home"
      export DENO_DIR="$PWD/.deno"
      export DENO_NO_UPDATE_CHECK=1
      export DENO_NO_PROMPT=1
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

      mkdir -p "$HOME" "$DENO_DIR"

      # Pre-download the denort binary FIRST
      echo "=== Pre-downloading denort binary ==="
      DENO_VERSION=$(deno --version | head -n1 | awk '{print $2}')
      DENORT_URL="https://dl.deno.land/release/v$DENO_VERSION/denort-x86_64-unknown-linux-gnu.zip"

      mkdir -p "$DENO_DIR/dl"
      cd "$DENO_DIR/dl"

      curl -L "$DENORT_URL" -o denort.zip
      unzip -q denort.zip
      rm denort.zip
      ls -la
      cd -

      # Cache the main entrypoint and all its dependencies
      echo "Caching frontend entrypoint..."
      if [ -f deno.lock ]; then
        deno cache --lock=deno.lock frontend/src/client.ts
      else
        deno cache frontend/src/client.ts
      fi

      # Cache all package dependencies that codegen might need
      echo "Caching all workspace packages..."
      if [ -f deno.lock ]; then
        deno cache --lock=deno.lock packages/*/mod.ts packages/*/src/**/*.ts 2>/dev/null || true
      else
        deno cache packages/*/mod.ts packages/*/src/**/*.ts 2>/dev/null || true
      fi

      # Cache codegen script itself if it exists
      if [ -f tools/codegen.ts ]; then
        echo "Caching codegen tool..."
        deno cache tools/codegen.ts || true
      fi

      # Run codegen task to cache ALL its dependencies (including npm packages like 'marked')
      echo "Running codegen to cache all npm dependencies..."
      if [ -f deno.json ] || [ -f deno.jsonc ]; then
        # Run the task which will download and cache everything
        deno task codegen:frontend || echo "Codegen completed with possible warnings"
      fi
    '';

    installPhase = ''
      mkdir -p $out
      cp -R "$DENO_DIR"/* $out/
      echo "=== Verifying denort was cached ==="
      ls -la $out/dl/ || echo "ERROR: No dl directory!"
    '';
  };

  # Build the Deno frontend - creates a wrapper script instead of compiling
  frontend = pkgs.stdenv.mkDerivation {
    name = "slices-frontend-0.2.0";

    src = src;

    nativeBuildInputs = [ pkgs.deno pkgs.makeWrapper ];

    buildInputs = with pkgs;
      [ openssl sqlite ];

    # Frontend-specific environment
    DATABASE_URL = commonEnv.DATABASE_URL;
    REDIS_URL = commonEnv.REDIS_URL;
    RELAY_ENDPOINT = commonEnv.RELAY_ENDPOINT;
    JETSTREAM_HOSTNAME = commonEnv.JETSTREAM_HOSTNAME;
    API_URL = "http://localhost:3000";
    OAUTH_AIP_BASE_URL = "http://localhost:8081";

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

      # Skip codegen in offline build - it should have been done in FOD
      echo "Skipping codegen (already done in cache phase)..."

      # Don't use deno compile (requires denort download)
      # Instead, we'll create a wrapper script that runs the code directly
      echo "Preparing frontend for runtime execution..."

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/slices-frontend

      # Copy source files and cache
      cp -r frontend $out/share/slices-frontend/
      cp -r packages $out/share/slices-frontend/
      cp -r "$DENO_DIR" $out/share/slices-frontend/.deno
      
      # Copy config files if they exist
      [ -f deno.json ] && cp deno.json $out/share/slices-frontend/ || true
      [ -f deno.jsonc ] && cp deno.jsonc $out/share/slices-frontend/ || true
      [ -f deno.lock ] && cp deno.lock $out/share/slices-frontend/ || true

      # Create wrapper script
      makeWrapper ${pkgs.deno}/bin/deno $out/bin/slices-frontend \
        --add-flags "run" \
        --add-flags "--allow-all" \
        --add-flags "--no-check" \
        --add-flags "--cached-only" \
        --add-flags "$out/share/slices-frontend/frontend/src/client.ts" \
        --set DENO_DIR "$out/share/slices-frontend/.deno" \
        --set DENO_NO_UPDATE_CHECK "1" \
        --set DENO_NO_PROMPT "1"

      runHook postInstall
    '';

    meta = with lib;
      {
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

  # Fixed-output derivation for packages cache
  packagesCacheFOD = pkgs.stdenvNoCC.mkDerivation {
    name = "slices-packages-deno-cache";

    src = src;

    nativeBuildInputs = [ pkgs.deno pkgs.cacert pkgs.curl pkgs.unzip ];

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    # Update this hash after first build with lib.fakeHash
    outputHash = "sha256-l3xu+bikvR9WfDgGTHAYXa/Ow6z6lV300E2b7PsaDn4=";

    buildPhase = ''
      export HOME="$PWD/home"
      export DENO_DIR="$PWD/.deno"
      export DENO_NO_UPDATE_CHECK=1
      export DENO_NO_PROMPT=1
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

      mkdir -p "$HOME" "$DENO_DIR"

      # Pre-download the denort binary for packages
      echo "=== Pre-downloading denort binary for packages ==="
      DENO_VERSION=$(deno --version | head -n1 | awk '{print $2}')
      DENORT_URL="https://dl.deno.land/release/v$DENO_VERSION/denort-x86_64-unknown-linux-gnu.zip"

      mkdir -p "$DENO_DIR/dl"
      cd "$DENO_DIR/dl"

      curl -L "$DENORT_URL" -o denort.zip
      unzip -q denort.zip
      rm denort.zip
      ls -la
      cd -

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

    installPhase = ''
      mkdir -p $out
      cp -R "$DENO_DIR"/* $out/
      echo "=== Verifying denort was cached ==="
      ls -la $out/dl/ || echo "ERROR: No dl directory!"
    '';
  };

  # Build the CLI and client packages using Deno workspace
  packages = pkgs.stdenv.mkDerivation {
    name = "slices-packages-0.2.0";

    src = src;

    nativeBuildInputs = [ pkgs.deno ];

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

      # Verify denort exists
      echo "=== Contents of DENO_DIR ==="
      ls -la "$DENO_DIR"
      echo "=== Contents of dl directory ==="
      ls -lah "$DENO_DIR/dl/" 2>&1 || echo "ERROR: No dl directory found!"

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
      for pkg in cli client codegen lexicon oauth session;
      do
        if [ -d "packages/$pkg" ] && [ -f "packages/$pkg/mod.ts" ]; then
          cat > $out/bin/slices-$pkg <<'WRAPPER_EOF'
#!/bin/sh
export DENO_DIR="CACHE_FOD_PATH"
exec DENO_BIN_PATH run --allow-all --no-check --cached-only OUT_SHARE_PATH/packages/PKG_NAME/mod.ts "$@"
WRAPPER_EOF
          # Replace placeholders
          sed -i "s|CACHE_FOD_PATH|${packagesCacheFOD}|g" $out/bin/slices-$pkg
          sed -i "s|DENO_BIN_PATH|${pkgs.deno}/bin/deno|g" $out/bin/slices-$pkg
          sed -i "s|OUT_SHARE_PATH|$out/share/slices-packages|g" $out/bin/slices-$pkg
          sed -i "s|PKG_NAME|$pkg|g" $out/bin/slices-$pkg
          chmod +x $out/bin/slices-$pkg
        fi
      done

      runHook postInstall
    '';

    meta = with lib;
      {
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

  # Create a combined package that includes all components
  slices = pkgs.runCommand "slices-combined" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  }
    ''
    mkdir -p $out/bin $out/share/slices

    # Copy API backend
    if [ -d "${api}/bin" ]; then
      cp ${api}/bin/* $out/bin/
    fi
    if [ -d "${api}/share" ]; then
      cp -r ${api}/share/* $out/share/slices/
    fi

    # Copy frontend
    if [ -d "${frontend}/bin" ]; then
      cp ${frontend}/bin/slices-frontend $out/bin/
    fi

    # Copy packages
    if [ -d "${packages}/bin" ]; then
      cp ${packages}/bin/* $out/bin/
    fi
    if [ -d "${packages}/share" ]; then
      cp -r ${packages}/share/* $out/share/slices/
    fi

    # Create orchestrator script
    cat > $out/bin/slices-orchestrator <<'EOF'
#!/bin/sh
# Slices multi-component orchestrator

set -e

# Default configuration
API_PORT="''${API_PORT:-3000}"
FRONTEND_PORT="''${FRONTEND_PORT:-8080}"
DATABASE_URL="''${DATABASE_URL:-postgresql://slices:slices@localhost:5432/slices}"
REDIS_URL="''${REDIS_URL:-redis://localhost:6379}"

echo "Starting Slices platform..."
echo "API Port: ''$API_PORT"
echo "Frontend Port: ''$FRONTEND_PORT"
echo "Database: ''$DATABASE_URL"

# Function to cleanup background processes
cleanup() {
    echo "Shutting down Slices platform..."
    jobs -p | xargs -r kill
    exit 0
}

trap cleanup INT TERM

# Start API backend
echo "Starting Slices API backend..."
PORT="''$API_PORT" DATABASE_URL="''$DATABASE_URL" REDIS_URL="''$REDIS_URL" BIN_DIR/slices &

# Wait a moment for API to start
sleep 2

# Start frontend
echo "Starting Slices frontend..."
PORT="''$FRONTEND_PORT" API_URL="http://localhost:''$API_PORT" DATABASE_URL="sqlite:slices-frontend.db" BIN_DIR/slices-frontend &

echo "Slices platform started successfully!"
echo "API: http://localhost:''$API_PORT"
echo "Frontend: http://localhost:''$FRONTEND_PORT"
echo "Press Ctrl+C to stop all services"

# Wait for all background processes
wait
EOF
    # Replace placeholder with actual path
    sed -i "s|BIN_DIR|$out/bin|g" $out/bin/slices-orchestrator
    chmod +x $out/bin/slices-orchestrator
  '';

in
{
  # Export individual components
  inherit api frontend packages;

  # Main combined package
  slices = slices.overrideAttrs (oldAttrs: {
    passthru = (oldAttrs.passthru or {}) // {
      # Expose components for individual use
      components = {
        inherit api frontend packages;
      };

      atproto = atprotoCore.mkAtprotoMetadata {
        category = "application";
        services = [ "appview" "api" "frontend" ];
        protocols = [ "com.atproto" "app.bsky" "network.slices" ];
        dependencies = [ "postgresql" "redis" ];
        tier = 2;
      };

      organization = {
        name = "slices-network";
        displayName = "Slices Network";
        website = "https://slices.network";
        contact = null;
        maintainer = "Slices Network";
        repository = "https://tangled.org/@slices.network/slices";
        packageCount = 3;
        atprotoFocus = [ "applications" "infrastructure" ];
      };
    };

    meta = (oldAttrs.meta or {}) // (with lib; {
      description = "Slices - Custom AppView platform for AT Protocol";
      longDescription = ''
        An open-source platform for building AT Protocol AppViews with custom data
        schemas, automatic SDK generation, and built-in sync capabilities.

        Features:
        - Custom lexicons and data schemas
        - Automatic TypeScript SDK generation
        - Data synchronization from AT Protocol services
        - OAuth integration and multi-tenant architecture
        - Real-time Jetstream integration
        - PostgreSQL and Redis support

        Components:
        - API backend (Rust) - Core AT Protocol integration
        - Frontend (Deno) - Web-based management interface
        - CLI and packages (Deno) - Development tools and client libraries

        Maintained by Slices Network (https://slices.network)
      '';
      homepage = "https://slices.network";
      license = licenses.mit;
      platforms = platforms.linux ++ platforms.darwin;
      maintainers = [ ];

      organizationalContext = {
        organization = "slices-network";
        displayName = "Slices Network";
        needsMigration = false;
        migrationPriority = "low";
      };
    });
  });
}
