{ pkgs, lib, buildGoModule, fetchFromTangled, fetchurl, templ, esbuild, stdenv, autoPatchelfHook, ... }:

let
  # Fetch frontend libraries at build time (outside the sandbox)
  htmx = fetchurl {
    url = "https://cdn.jsdelivr.net/npm/htmx.org@2.0.6/dist/htmx.min.js";
    sha256 = "05jn0kif1ralnbvbgwmf333wl5qfsqdp0m2hlxrmpy1s9znqwxmn";
  };

  lucide = fetchurl {
    url = "https://unpkg.com/lucide@0.525.0/dist/umd/lucide.min.js";
    sha256 = "03adq6md75sg7jph4lnjngppywjsmfvijyj959242kcx84f4p2rf";
  };

  alpinejs = fetchurl {
    url = "https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js";
    sha256 = "01pl6vx48klgdx291v568kagr6j0i9ixgn1n4zyb5rni76vg2hg0";
  };

  # Build a patched version of the standalone Tailwind CSS v4 CLI
  tailwindcss-standalone-v2 = stdenv.mkDerivation {
    name = "tailwindcss-standalone-v2";
    src = let
      base = "https://github.com/tailwindlabs/tailwindcss/releases/latest/download";
      srcAttrs = 
        if stdenv.system == "x86_64-linux" then {
          url = "${base}/tailwindcss-linux-x64";
          sha256 = lib.fakeHash;
        } else if stdenv.system == "aarch64-darwin" then {
          url = "${base}/tailwindcss-macos-arm64";
          sha256 = "sha256-5s1EuBZ/V0bKMuVPahQR3RpsDdFdJqnCc7Oy7Z2H330=";
        } else if stdenv.system == "x86_64-darwin" then {
          url = "${base}/tailwindcss-darwin-x64";
          sha256 = lib.fakeHash;
        } else { # Default to linux-x64 if system not explicitly handled
          url = "${base}/tailwindcss-linux-x64";
          sha256 = "sha256-CeaHamPOsJzNflhn49uystxlw6Ly4v4hDWjqO8BDIFA=";
        };
    in fetchurl srcAttrs;
    dontUnpack = true;
    nativeBuildInputs = [ ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/tailwindcss
      chmod +x $out/bin/tailwindcss
    '';
  };
in

# Yoten - Language learning social platform using ATProto
buildGoModule rec {
  pname = "yoten";
  version = "0.1.0";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@yoten.app";
    repo = "yoten";
    rev = "2de6115fc7b166148b7d9206809e0f4f0c6916d7";
    sha256 = "00lx7pkms1ycrbcmihqc5az98xvw0pb3107b107zikj8i08hygxz";
  };

  vendorHash = "sha256-gjlwSBmyHy0SXTnOi+XNVBKm4t7HWRVNA19Utx3Eh/w=";

  # Build tools needed for frontend assets
  nativeBuildInputs = [ templ esbuild ];

  # Build the main server binary
  subPackages = [ "cmd/server" ];

  # Skip tests for now due to complex dependencies
  doCheck = false;

  # Generate templ templates, build frontend assets, and prepare static files
  preBuild = ''
    # Generate Go code from templ templates
    echo "Generating templ templates..."
    templ generate

    # Create static files directory
    mkdir -p ./static/files

    # Minify JS files using esbuild
    echo "Minifying JavaScript files..."
    for js in ./static/*.js; do
      if [ -f "$js" ]; then
        esbuild "$js" --minify --outfile="./static/files/$(basename "$js")"
      fi
    done

    # Copy pre-fetched frontend libraries
    echo "Copying frontend libraries..."
    cp ${htmx} ./static/files/htmx.min.js
    cp ${lucide} ./static/files/lucide.min.js
    cp ${alpinejs} ./static/files/alpinejs.min.js

    # Build Tailwind CSS using the standalone v4 binary
    echo "Building Tailwind CSS..."
    ${tailwindcss-standalone-v2}/bin/tailwindcss -i ./input.css -o ./static/files/style.css --minify

    echo "Frontend build complete. Static files ready."
  '';

  postInstall = ''
    # Rename binary to yoten
    mv $out/bin/server $out/bin/yoten
  '';
  
  passthru = {
    atproto = {
      type = "application";
      services = [ "yoten" ];
      protocols = [ "com.atproto" "app.bsky" ];
      schemaVersion = "1.0";
      description = "Social platform for tracking language learning progress";
    };
    
    organization = {
      name = "yoten-app";
      displayName = "Yoten App";
      website = "https://yoten.app";
      contact = null;
      maintainer = "Yoten App";
      repository = "https://tangled.org/@yoten.app/yoten";
      packageCount = 1;
      atprotoFocus = [ "applications" ];
    };
  };
  
  meta = with pkgs.lib; {
    description = "Social platform for tracking language learning progress";
    longDescription = ''
      Social platform for tracking language learning progress built on ATProto.

      Built with Go, templ templates, HTMX, Alpine.js, and Tailwind CSS.
      Features include activity tracking, study sessions, notifications, and
      social features like following other learners.

      Maintained by Yoten App (https://yoten.app)
    '';
    homepage = "https://yoten.app";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "yoten";

    organizationalContext = {
      organization = "yoten-app";
      displayName = "Yoten App";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}