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
    hash = "sha256-4gndpcgjVHnzFm3vx3UOHbzVpcGAi3eS/C5nM3aPtEc=";
  };

  htmx-ws = fetchurl {
    url = "https://cdn.jsdelivr.net/npm/htmx-ext-ws@2.0.2/ws.js";
    hash = "sha256-+XnVDV2b+a8RsUFJ7sVNdJMK+jK+ZAH/wmItN6+KEfg=";
  };

  lucide-icons = fetchzip {
    url = "https://github.com/lucide-icons/lucide/releases/download/0.536.0/lucide-icons-0.536.0.zip";
    hash = "sha256-uSf+Uam8wFXLqdntVFnJ0Bc338hGUHI3yyEy6aKqJ2c=";
    stripRoot = false;
  };

  inter-fonts = fetchzip {
    url = "https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip";
    hash = "sha256-5vdKKvHAeZi6igrfpbOdhZlDX2/5+UvzlnCQV6DdqoQ=";
    stripRoot = false;
  };

  ibm-plex-mono = fetchzip {
    url = "https://github.com/IBM/plex/releases/download/@ibm%2Fplex-mono@1.1.0/ibm-plex-mono.zip";
    hash = "sha256-OwUmrPfEehLDz0fl2ChYLK8FQM2p0G1+EMrGsYEq+6g=";
    stripRoot = false;
  };

  tangledSrc = fetchFromTangled {
    domain = "tangled.org";
    owner = "@tangled.org";
    repo = "core";
    rev = "54a60448cf5c456650e9954ca9422276c5d73282";
    hash = "sha256-OcTD732dTYT69smyDSI6oi0vXSwnpJfLGxq7MGNqOus";
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
    cp ${htmx-ws} htmx-ext-ws.min.js
    # Copy icons (find all SVGs in the lucide package)
    find ${lucide-icons} -name "*.svg" -exec cp {} icons/ \;
    # Copy fonts
    find ${inter-fonts} -name "InterVariable*.woff2" -exec cp {} fonts/ \; || true
    find ${inter-fonts} -name "InterDisplay*.woff2" -exec cp {} fonts/ \; || true
    find ${inter-fonts} -name "InterVariable*.ttf" -exec cp {} fonts/ \; || true
    find ${ibm-plex-mono} -name "IBMPlexMono*.woff2" -exec cp {} fonts/ \; || true
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
    maintainers = [ ];
  };
}
