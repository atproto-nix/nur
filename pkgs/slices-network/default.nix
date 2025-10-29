{ pkgs, lib, craneLib, fetchFromTangled, ... }:

# Slices Network ATProto packages
# Organization: slices-network
# Website: https://slices.network

let
  # Organizational metadata
  organizationMeta = {
    name = "slices-network";
    displayName = "Slices Network";
    website = "https://slices.network";
    contact = null;
    maintainer = "Slices Network";
    description = "Custom AppView platform for ATProto ecosystem";
    atprotoFocus = [ "applications" "infrastructure" ];
    packageCount = 4; # api, frontend, packages, slices (combined)
  };

  # Import individual components
  api = pkgs.callPackage ./api.nix { inherit craneLib; };
  frontend = pkgs.callPackage ./frontend.nix { };
  packages = pkgs.callPackage ./packages.nix { };

  # Import packaging utilities for metadata
  packaging = pkgs.callPackage ../../lib/packaging { inherit craneLib; };
  atprotoCore = pkgs.callPackage ../../lib/atproto-core.nix { inherit craneLib; };

  # Create a combined package that includes all components
  slicesCombined = pkgs.runCommand "slices-combined" {
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
PORT="''$API_PORT" DATABASE_URL="''$DATABASE_URL" REDIS_URL="''$REDIS_URL" $out/bin/slices &

# Wait a moment for API to start
sleep 2

# Start frontend
echo "Starting Slices frontend..."
PORT="''$FRONTEND_PORT" API_URL="http://localhost:''$API_PORT" DATABASE_URL="sqlite:slices-frontend.db" $out/bin/slices-frontend &

echo "Slices platform started successfully!"
echo "API: http://localhost:''$API_PORT"
echo "Frontend: http://localhost:''$FRONTEND_PORT"
echo "Press Ctrl+C to stop all services"

# Wait for all background processes
wait
EOF
    chmod +x $out/bin/slices-orchestrator
  '';

  # Main combined package with full metadata
  slices = slicesCombined.overrideAttrs (oldAttrs: {
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

      organization = organizationMeta;
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
        organization = organizationMeta.name;
        displayName = organizationMeta.displayName;
        needsMigration = false;
        migrationPriority = "low";
      };
    });
  });

  # Package naming pattern: expose all components individually
  packagesSet = {
    inherit api frontend packages slices;
  };

  # Enhanced packages with organizational metadata
  enhancedPackages = lib.mapAttrs (name: pkg:
    if pkg ? overrideAttrs then
      pkg.overrideAttrs (oldAttrs: {
        passthru = (oldAttrs.passthru or {}) // {
          organization = organizationMeta;
          atproto = (oldAttrs.passthru.atproto or {}) // {
            organization = organizationMeta;
          };
        };
        meta = (oldAttrs.meta or {}) // {
          organizationalContext = {
            organization = organizationMeta.name;
            displayName = organizationMeta.displayName;
          };
        };
      })
    else
      # For non-derivation packages, just add the metadata to passthru
      pkg // {
        passthru = (pkg.passthru or {}) // {
          organization = organizationMeta;
          atproto = (pkg.passthru.atproto or {}) // {
            organization = organizationMeta;
          };
        };
      }
  ) packagesSet;

in
enhancedPackages // {
  # Export organizational metadata for external use
  _organizationMeta = organizationMeta;
}
