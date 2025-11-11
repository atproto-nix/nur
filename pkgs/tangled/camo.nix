{ lib
, buildNpmPackage
, fetchFromTangled
, makeWrapper
, nodejs
}:

buildNpmPackage rec {
  pname = "tangled-camo";
  version = "0.1.0";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@tangled.org";
    repo = "core";
    rev = "2e5a4cde904d86825cefe5971e68f1bdfb1dd36f";
    hash = "sha256-qDVJ2sEQL0TJbWer6ByhhQrzHE1bZI3U1mmCk0sPZqo=";
  };

  sourceRoot = "${src.name}/camo";

  npmDepsHash = "sha256-G0KDDl/TtWIVtbWAQ4SzcEXbbA+NvbzW+agFKckosCE=";  # Will calculate when building

  nativeBuildInputs = [ makeWrapper ];

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{lib/camo,bin}

    # Copy the worker source and config
    cp -r src $out/lib/camo/
    cp wrangler.jsonc $out/lib/camo/
    cp package.json $out/lib/camo/
    cp -r node_modules $out/lib/camo/

    # Create wrapper script for running the worker
    makeWrapper ${nodejs}/bin/node $out/bin/camo \
      --add-flags "$out/lib/camo/node_modules/wrangler/bin/wrangler.js" \
      --add-flags "dev" \
      --add-flags "--port 8788" \
      --add-flags "--local-protocol http" \
      --set-default CAMO_SHARED_SECRET "" \
      --chdir "$out/lib/camo"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Tangled Camo Service - Image proxy for anonymized URLs";
    longDescription = ''
      Camo (camouflage) service for Tangled that proxies images with anonymized URLs,
      similar to GitHub's camo service. Uses HMAC signatures for URL verification.

      Originally a Cloudflare Worker, packaged here for self-hosted deployment
      using Wrangler in development mode.

      Features:
      - Proxies images from knot servers via Cloudflare-like edge caching
      - HMAC signature verification for security
      - Hex-encoded URLs to prevent URL manipulation
      - MIME type validation (only allows approved image types)
      - HTTP/HTTPS support with protocol validation
      - Caching support

      URL format: https://camo.example.com/<signature>/<hex-encoded-url>

      Environment variables:
      - CAMO_SHARED_SECRET: Shared secret for HMAC verification (required)
    '';
    homepage = "https://tangled.org";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "camo";
  };
}
