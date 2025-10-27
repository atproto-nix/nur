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

  # Build the Rust API backend
  api = packaging.buildRustAtprotoPackage {
    inherit src;
    pname = "slices-api";
    version = "0.2.0";
    cargoVendorDir = null;
    
    # API is in the /api subdirectory
    sourceRoot = "${src.name}/api";
    
    extraEnv = commonEnv // {
      # Rust-specific environment
      SQLX_OFFLINE = "true";
    };
    
    nativeBuildInputs = with pkgs; [
      pkg-config
      perl
    ];
    
    buildInputs = with pkgs; [
      openssl
      postgresql
      sqlite
      zstd
      lz4
      cacert
    ];
    
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
    
    meta = with lib; {
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
  };

  # Build the Deno frontend
  frontend = packaging.buildDenoApp {
    inherit src;
    pname = "slices-frontend";
    version = "0.2.0";

    buildInputs = with pkgs; [
      openssl
      sqlite
    ];

    buildPhase = ''
      runHook preBuild

      # Set up Deno environment
      export DENO_DIR="$PWD/.deno"
      export DENO_CACHE_DIR="$PWD/.deno/cache"
      export DENO_NO_UPDATE_CHECK=1
      export DENO_NO_PROMPT=1

      mkdir -p "$DENO_DIR" "$DENO_CACHE_DIR"

      # Run codegen:frontend from the root of the workspace
      echo "Running codegen:frontend..."
      deno task codegen:frontend

      # Compile the generated client
      echo "Compiling frontend..."
      deno compile --allow-all --no-check --output=app frontend/src/client.ts

      runHook postBuild
    '';
    
    # Frontend-specific environment
    env = commonEnv // {
      API_URL = "http://localhost:3000";
      OAUTH_AIP_BASE_URL = "http://localhost:8081";
      DATABASE_URL = "sqlite:slices.db";
    };
    
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

  # Build the CLI and client packages using Deno workspace
  packages = packaging.buildDenoApp {
    inherit src;
    pname = "slices-packages";
    version = "0.2.0";
    
    # Build the entire workspace
    buildPhase = ''
      runHook preBuild
      
      # Set up Deno environment
      export DENO_DIR="$PWD/.deno"
      export DENO_CACHE_DIR="$PWD/.deno/cache"
      export DENO_NO_UPDATE_CHECK=1
      export DENO_NO_PROMPT=1
      
      mkdir -p "$DENO_DIR" "$DENO_CACHE_DIR"
      
      # Cache all workspace dependencies
      echo "Caching workspace dependencies..."
      deno cache --config=deno.json packages/*/mod.ts packages/*/src/mod.ts || true
      
      # Build CLI
      echo "Building Slices CLI..."
      deno task build:cli || echo "CLI build failed, continuing"
      
      # Build lexicon package
      echo "Building lexicon package..."
      deno task build:lexicon || echo "Lexicon build failed, continuing"
      
      runHook postBuild
    '';
    
    installPhase = ''
      runHook preInstall
      
      mkdir -p $out/bin $out/share/slices-packages
      
      # Install CLI binary if built
      if [ -f "packages/cli/bin/slices" ]; then
        cp packages/cli/bin/slices $out/bin/
        chmod +x $out/bin/slices
      fi
      
      # Install packages for runtime use
      cp -r packages $out/share/slices-packages/
      
      # Create wrapper scripts for packages
      for pkg in cli client codegen lexicon oauth session; do
        if [ -d "packages/$pkg" ]; then
          cat > $out/bin/slices-$pkg << EOF
#!/bin/sh
cd $out/share/slices-packages/packages/$pkg
exec ${pkgs.deno}/bin/deno run --allow-all mod.ts "\$@"
EOF
          chmod +x $out/bin/slices-$pkg
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

  # Create a combined package that includes all components
  slices = pkgs.runCommand "slices-combined" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
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
    if [ -d "${frontend}/share" ]; then
      cp -r ${frontend}/share/* $out/share/slices/
    fi
    
    # Copy packages
    if [ -d "${packages}/bin" ]; then
      cp ${packages}/bin/* $out/bin/
    fi
    if [ -d "${packages}/share" ]; then
      cp -r ${packages}/share/* $out/share/slices/
    fi
    
    # Create orchestrator script
    cat > $out/bin/slices-orchestrator << 'EOF'
#!/bin/sh
# Slices multi-component orchestrator

set -e

# Default configuration
API_PORT=''${API_PORT:-3000}
FRONTEND_PORT=''${FRONTEND_PORT:-8080}
DATABASE_URL=''${DATABASE_URL:-postgresql://slices:slices@localhost:5432/slices}
REDIS_URL=''${REDIS_URL:-redis://localhost:6379}

echo "Starting Slices platform..."
echo "API Port: $API_PORT"
echo "Frontend Port: $FRONTEND_PORT"
echo "Database: $DATABASE_URL"

# Function to cleanup background processes
cleanup() {
    echo "Shutting down Slices platform..."
    jobs -p | xargs -r kill
    exit 0
}

trap cleanup INT TERM

# Start API backend
echo "Starting Slices API backend..."
PORT=$API_PORT DATABASE_URL="$DATABASE_URL" REDIS_URL="$REDIS_URL" $out/bin/slices &
API_PID=$!

# Wait a moment for API to start
sleep 2

# Start frontend
echo "Starting Slices frontend..."
API_URL="http://localhost:$API_PORT" DATABASE_URL="sqlite:slices-frontend.db" $out/bin/slices-frontend &
FRONTEND_PID=$!

echo "Slices platform started successfully!"
echo "API: http://localhost:$API_PORT"
echo "Frontend: http://localhost:$FRONTEND_PORT"
echo "Press Ctrl+C to stop all services"

# Wait for all background processes
wait
EOF
    chmod +x $out/bin/slices-orchestrator
  '';

in
{
  # Export individual components
  inherit api frontend packages;
  
  # Main combined package
  slices = slices // {
    # Expose components for individual use
    components = {
      inherit api frontend packages;
    };
    
    passthru = {
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
    
    meta = with lib; {
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
    };
  };
}
