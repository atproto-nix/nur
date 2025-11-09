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

  # Extract notifications subdirectory
  notificationsSrc = lib.cleanSourceWith {
    src = "${src}/notifications";
    filter = path: type: true;
  };

in
stdenv.mkDerivation rec {
  pname = "grain-social-notifications";
  inherit version;
  src = notificationsSrc;

  nativeBuildInputs = [ deno ];

  # Configure Deno cache directory
  DENO_DIR = ".deno_cache";

  buildPhase = ''
    # Cache dependencies
    deno cache --reload main.ts
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{lib/grain-notifications,bin}

    # Copy source and cache
    cp -r . $out/lib/grain-notifications/
    cp -r $DENO_DIR $out/lib/grain-notifications/.deno_cache

    # Create wrapper script
    cat > $out/bin/grain-notifications <<WRAPPER_EOF
#!/bin/sh
# Grain Notifications - Real-time notifications service for Grain Social
#
# This service delivers real-time notifications to users in Grain Social.
# Required environment variables:
# - BFF_JWT_SECRET: Secret key for JWT token signing/verification

cd "\''${RUNTIME_DIRECTORY:-\$HOME/.cache/grain-notifications}"

# Run the notifications service
exec ${deno}/bin/deno run \
  --allow-all \
  --unstable-ffi \
  --env \
  \$out/lib/grain-notifications/main.ts "\$@"
WRAPPER_EOF
    chmod +x $out/bin/grain-notifications

    runHook postInstall
  '';

  meta = with lib; {
    description = "Grain Social Notifications - Real-time notification service";
    longDescription = ''
      Grain Notifications is the real-time notification delivery service
      for Grain Social. It handles:

      - User event notifications (likes, comments, follows)
      - WebSocket connections for real-time delivery
      - Notification persistence and retrieval
      - Integration with the Firehose for event detection
      - Email notification delivery (optional)

      Features:
      - Real-time WebSocket support for instant notifications
      - Multiple notification types (gallery likes, comments, follows, mentions)
      - Configurable notification retention policies
      - Email delivery via SMTP (optional)
      - Redis-backed caching for performance
      - Prometheus metrics endpoint

      Built with Deno and TypeScript using the @bigmoves/bff framework.

      Environment Variables:
      - BFF_JWT_SECRET: JWT secret key (required)
      - BFF_JETSTREAM_URL: Firehose WebSocket URL (optional)
      - NOTIFICATIONS_REDIS_URL: Redis connection URL (optional, for caching)
      - NOTIFICATIONS_EMAIL_ENABLED: Enable email notifications (true/false)
      - NOTIFICATIONS_SMTP_*: SMTP configuration for email (if enabled)
    '';
    homepage = "https://grain.social";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "grain-notifications";
  };
}
