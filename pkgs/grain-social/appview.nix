{ lib, stdenv, fetchFromTangled, deno, nodejs }:

let
  version = "unstable-2025-01-23";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@grain.social";
    repo = "grain";
    rev = "643445cfbfca683b3f17f8990f444405cff2165a";
    hash = "sha256-4gWb3WcWRcIRLTpU/W54NytGhXY6MdVB4hKWrTNdCqM=";
    forceFetchGit = true;
  };

  # Extract appview subdirectory for cleaner source
  appviewSrc = lib.cleanSourceWith {
    src = "${src}/appview";
    filter = path: type: true; # Include all files
  };

in
stdenv.mkDerivation rec {
  pname = "grain-social-appview";
  inherit version;
  src = appviewSrc;

  nativeBuildInputs = [ deno nodejs ];

  # Configure Deno to use system node modules
  DENO_DIR = ".deno_cache";

  buildPhase = ''
    # Cache dependencies from deno.json
    deno cache --reload src/main.tsx

    # Build static assets (tailwind CSS, fonts, static files)
    deno task build
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{lib/grain-appview,bin}

    # Copy entire source and build artifacts
    cp -r . $out/lib/grain-appview/

    # Copy deno cache directory so dependencies are available at runtime
    cp -r $DENO_DIR $out/lib/grain-appview/.deno_cache

    # Create wrapper script
    cat > $out/bin/grain-appview <<WRAPPER_EOF
#!/bin/sh
# Grain AppView - Photo gallery web application
#
# This is a Deno-based web application. It requires:
# - BFF_DATABASE_URL: SQLite database path (or memory :memory:)
# - BFF_PRIVATE_KEY_1, BFF_PRIVATE_KEY_2, BFF_PRIVATE_KEY_3: Service private keys
# - BFF_JETSTREAM_URL: Firehose websocket URL (e.g., wss://jetstream.us-west.bsky.network)
# - PDS_HOST_URL: PDS instance URL (e.g., https://pds.example.com)

# Set up runtime directory for wrangler cache
APPVIEW_HOME="\''${RUNTIME_DIRECTORY:-\$HOME/.cache/grain-appview}"
mkdir -p "\$APPVIEW_HOME"
cd "\$APPVIEW_HOME"

# Execute deno app with cached dependencies
exec ${deno}/bin/deno run \
  --allow-all \
  --unstable-ffi \
  --env \
  \$out/lib/grain-appview/src/main.tsx "\$@"
WRAPPER_EOF
    chmod +x $out/bin/grain-appview

    runHook postInstall
  '';

  meta = with lib; {
    description = "Grain Social AppView - Photo gallery web application";
    longDescription = ''
      Grain AppView is the web interface for Grain Social, a photo-sharing
      platform built on the AT Protocol. It provides:

      - Photo gallery creation and management
      - User profiles and social discovery
      - Photo sharing and curation
      - Integration with Bluesky and AT Protocol services
      - Full-text search of galleries and photos
      - Real-time updates via Firehose

      Built with Deno, TypeScript, Preact, and HTMX.
      Uses SQLite database (can be replicated via LiteFS in production).

      Environment Variables:
      - BFF_DATABASE_URL: SQLite database URL (default: grain.db)
      - BFF_PRIVATE_KEY_*: Service signing keys (at least 1 required)
      - BFF_JETSTREAM_URL: Firehose WebSocket URL
      - PDS_HOST_URL: PDS instance for authentication
      - USE_CDN: Use CDN for static assets (default: true)
      - DENO_TLS_CA_STORE: TLS CA store (system|mozilla, for local dev)
    '';
    homepage = "https://grain.social";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "grain-appview";
  };
}
