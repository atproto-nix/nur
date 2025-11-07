{ lib, stdenv, fetchFromTangled, deno }:

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

  # Extract labeler subdirectory
  labelerSrc = lib.cleanSourceWith {
    src = "${src}/labeler";
    filter = path: type: true;
  };

in
stdenv.mkDerivation rec {
  pname = "grain-social-labeler";
  inherit version;
  src = labelerSrc;

  nativeBuildInputs = [ deno ];

  # Configure Deno cache directory
  DENO_DIR = ".deno_cache";

  buildPhase = ''
    # Cache dependencies
    deno cache --reload main.ts
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{lib/grain-labeler,bin}

    # Copy source and cache
    cp -r . $out/lib/grain-labeler/
    cp -r $DENO_DIR $out/lib/grain-labeler/.deno_cache

    # Create wrapper script
    cat > $out/bin/grain-labeler <<WRAPPER_EOF
#!/bin/sh
# Grain Labeler - Content moderation service for Grain Social
#
# This service handles content labeling and moderation.
# Required environment variables:
# - MOD_SERVICE_PORT: Service port (default: 8080)
# - MOD_SERVICE_DATABASE_URL: SQLite database path (default: labeler.db)
# - MOD_SERVICE_SIGNING_KEY: Private key for signing labels

cd "\''${RUNTIME_DIRECTORY:-\$HOME/.cache/grain-labeler}"

# Run the labeler service
exec ${deno}/bin/deno run \
  --allow-all \
  --unstable-ffi \
  --env \
  \$out/lib/grain-labeler/main.ts "\$@"
WRAPPER_EOF
    chmod +x $out/bin/grain-labeler

    runHook postInstall
  '';

  meta = with lib; {
    description = "Grain Social Labeler - Content moderation service";
    longDescription = ''
      Grain Labeler is the content moderation service for Grain Social.
      It monitors the firehose and applies labels to content based on
      configured rules.

      Features:
      - Real-time content monitoring via Firehose
      - Configurable labeling rules
      - Label signing with private keys
      - SQLite-backed label storage
      - Integration with AT Protocol labeling system

      Built with Deno and TypeScript using the @bigmoves/bff framework.

      Environment Variables:
      - MOD_SERVICE_PORT: Service listening port (default: 8080)
      - MOD_SERVICE_DATABASE_URL: Database connection URL (default: labeler.db)
      - MOD_SERVICE_SIGNING_KEY: Private key for label signatures (required)
      - BFF_JETSTREAM_URL: Firehose URL (optional)
    '';
    homepage = "https://grain.social";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "grain-labeler";
  };
}
