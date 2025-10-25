{ lib
, buildNpmPackage
, fetchFromTangled
, makeWrapper
, nodejs
, wrangler
}:

buildNpmPackage rec {
  pname = "tangled-avatar";
  version = "0.1.0";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@tangled.org";
    repo = "core";
    rev = "54a60448cf5c456650e9954ca9422276c5d73282";
    hash = "sha256-OcTD732dTYT69smyDSI6oi0vXSwnpJfLGxq7MGNqOus=";
  };

  sourceRoot = "${src.name}/avatar";

  npmDepsHash = "sha256-AI9MJXRtcQ17FLi7Lh8b5Rz7d8QkFFtuF0u0LHXFoR4=";

          nativeBuildInputs = [ makeWrapper ];

          buildInputs = [ wrangler ];

          

          dontNpmBuild = true;  installPhase = ''
    runHook preInstall

    mkdir -p $out/{lib/avatar,bin}

    # Copy the worker source and config
    cp -r src $out/lib/avatar/
    cp wrangler.jsonc $out/lib/avatar/
    cp package.json $out/lib/avatar/
    cp -r node_modules $out/lib/avatar/

    # Create wrapper script for running the worker
    makeWrapper ${nodejs}/bin/node $out/bin/avatar \
      --add-flags "$out/lib/avatar/node_modules/wrangler/bin/wrangler.js" \
      --add-flags "dev" \
      --add-flags "--port 8787" \
      --add-flags "--local-protocol http" \
      --set-default AVATAR_SHARED_SECRET "" \
      --chdir "$out/lib/avatar"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Tangled Avatar Service - Bluesky avatar proxy and cache";
    longDescription = ''
      Avatar service for Tangled that fetches Bluesky avatars and caches them.
      Uses HMAC signatures to verify requests originate from trusted appview.

      Originally a Cloudflare Worker, packaged here for self-hosted deployment
      using Wrangler in development mode.

      Features:
      - Fetches avatars from Bluesky API
      - Generates fallback SVG avatars for users without avatars
      - Resizes images (supports ?size=tiny for 32x32 thumbnails)
      - HMAC signature verification for security
      - Caching support

      Environment variables:
      - AVATAR_SHARED_SECRET: Shared secret for HMAC verification (required)
    '';
    homepage = "https://tangled.org";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "avatar";
  };
}
