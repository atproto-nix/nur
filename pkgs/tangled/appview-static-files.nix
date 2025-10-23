{ lib
, stdenv
, fetchurl
, fetchzip
, tailwindcss
, fetchFromTangled
}:

let
  # Frontend dependencies
  htmx = fetchurl {
    url = "https://unpkg.com/htmx.org@2.0.4/dist/htmx.min.js";
    hash = "sha256-cJnbyFA9ltjwKTH0bP+G1pCvIpMMVnPkTRRLcQ9+YV8=";
  };

  htmx-ws = fetchurl {
    url = "https://cdn.jsdelivr.net/npm/htmx-ext-ws@2.0.2/ws.js";
    hash = "sha256-PLACEHOLDER";  # Will calculate when building
  };

  lucide-icons = fetchzip {
    url = "https://github.com/lucide-icons/lucide/releases/download/0.536.0/lucide-icons-0.536.0.zip";
    hash = "sha256-PLACEHOLDER";  # Will calculate when building
    stripRoot = false;
  };

  inter-fonts = fetchzip {
    url = "https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip";
    hash = "sha256-PLACEHOLDER";  # Will calculate when building
    stripRoot = false;
  };

  ibm-plex-mono = fetchzip {
    url = "https://github.com/IBM/plex/releases/download/v6.4.2/OpenType.zip";
    hash = "sha256-PLACEHOLDER";  # Will calculate when building
    stripRoot = false;
  };

  tangledSrc = fetchFromTangled {
    domain = "tangled.org";
    owner = "@tangled.org";
    repo = "core";
    rev = "54a60448cf5c456650e9954ca9422276c5d73282";
    hash = "sha256-OcTD732dTYT69smyDSI6oi0vXSwnpJfLGxq7MGNqOus=";
  };

in
stdenv.mkDerivation {
  pname = "appview-static-files";
  version = "0.1.0";

  dontUnpack = true;

  nativeBuildInputs = [ tailwindcss ];

  buildPhase = ''
    runHook preBuild

    mkdir -p $out/{fonts,icons}
    cd $out

    # Copy JavaScript dependencies
    cp ${htmx} htmx.min.js
    # TODO: Add htmx-ws when hash is calculated
    # cp ${htmx-ws} htmx-ext-ws.min.js

    # Copy icons
    # TODO: Add lucide icons when hash is calculated
    # cp -rf ${lucide-icons}/*.svg icons/

    # Copy fonts
    # TODO: Add fonts when hashes are calculated
    # cp -f ${inter-fonts}/web/InterVariable*.woff2 fonts/ || true
    # cp -f ${inter-fonts}/web/InterDisplay*.woff2 fonts/ || true
    # cp -f ${inter-fonts}/InterVariable*.ttf fonts/ || true
    # cp -f ${ibm-plex-mono}/fonts/complete/woff2/IBMPlexMono*.woff2 fonts/ || true

    # Build Tailwind CSS
    cd ${tangledSrc}
    ${tailwindcss}/bin/tailwindcss -i input.css -o $out/tw.css

    runHook postBuild
  '';

  meta = with lib; {
    description = "Static files for Tangled AppView (CSS, JS, fonts, icons)";
    homepage = "https://tangled.org";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
