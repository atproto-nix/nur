{ lib
, stdenv
, fetchFromTangled
, rustPlatform
, buildNpmPackage
, nodejs
, yarn
, pkg-config
, openssl
, webkitgtk_4_1
, gtk3
, cairo
, gdk-pixbuf
, glib
, glib-networking
, dbus
, librsvg
, wrapGAppsHook3
, libsoup_3
}:

let
  version = "0.1.4";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@atbackup.pages.dev";
    repo = "atbackup";
    rev = "deb720914f4c36557bcd5ee9af95791e42afd45f";
    hash = "sha256-0ksqwsqv95lq97rh8z9dc0m1bjzc2fb4yjlksyfx7p49f1slcv8r";
    forceFetchGit = true;
  };

  # Build the frontend with Yarn
  frontend = buildNpmPackage {
    pname = "atbackup-frontend";
    inherit version src;

    npmDepsHash = lib.fakeHash;  # Will calculate this

    nativeBuildInputs = [ nodejs yarn ];

    # Use yarn since this is a Yarn project
    npmConfigHook = yarn;

    buildPhase = ''
      runHook preBuild

      # Build frontend with Vite
      yarn build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      # Copy built frontend to output
      mkdir -p $out
      cp -r dist/* $out/

      runHook postInstall
    '';
  };

in
rustPlatform.buildRustPackage {
  pname = "atbackup";
  inherit version src;

  # Build from src-tauri directory
  sourceRoot = "${src.name}/src-tauri";

  cargoHash = lib.fakeHash;  # Will calculate this

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook3
    nodejs
    yarn
  ];

  buildInputs = [
    openssl
    webkitgtk_4_1
    gtk3
    cairo
    gdk-pixbuf
    glib
    glib-networking
    dbus
    librsvg
    libsoup_3
  ];

  # Tauri needs the frontend built first
  preBuild = ''
    # Copy pre-built frontend into expected location
    mkdir -p ../dist
    cp -r ${frontend}/* ../dist/

    # Tauri expects frontend at ../dist relative to src-tauri
    ls -la ../dist
  '';

  # Tauri build outputs to target/release
  buildPhase = ''
    runHook preBuild

    cargo build --release

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Install the binary
    mkdir -p $out/bin
    cp target/release/atbackup $out/bin/

    # Install desktop file and icons
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor/32x32/apps
    mkdir -p $out/share/icons/hicolor/128x128/apps

    # Copy icons if they exist
    if [ -f icons/32x32.png ]; then
      cp icons/32x32.png $out/share/icons/hicolor/32x32/apps/atbackup.png
    fi
    if [ -f icons/128x128.png ]; then
      cp icons/128x128.png $out/share/icons/hicolor/128x128/apps/atbackup.png
    fi

    # Create desktop file
    cat > $out/share/applications/atbackup.desktop << EOF
[Desktop Entry]
Name=ATBackup
Comment=One-click Bluesky backups
Exec=$out/bin/atbackup
Icon=atbackup
Type=Application
Categories=Network;Utility;
EOF

    runHook postInstall
  '';

  # ATProto metadata
  passthru = {
    atproto = {
      type = "application";
      services = [ "atbackup" ];
      protocols = [ "com.atproto" "app.bsky" ];
      schemaVersion = "1.0";
      hasWebFrontend = true;
      description = "One-click Bluesky backups desktop application";

      # Configuration requirements
      configuration = {
        required = [ ];
        optional = [ "BACKUP_DIRECTORY" "BSKY_HANDLE" "BSKY_PASSWORD" ];
      };
    };

    organization = {
      name = "atbackup-pages-dev";
      displayName = "ATBackup";
      website = "https://atbackup.pages.dev";
      contact = null;
      maintainer = "ATBackup";
      repository = "https://tangled.org/@atbackup.pages.dev/atbackup";
      packageCount = 1;
      atprotoFocus = [ "applications" "tools" ];
    };
  };

  meta = with lib; {
    description = "One-click Bluesky backups desktop application";
    longDescription = ''
      ATBackup is a desktop application built with Tauri v2 that provides
      one-click backup functionality for Bluesky accounts. It allows users
      to easily backup their posts, media, and account data from the ATProto
      network. Backups are saved as CAR files (the standard format used by
      Bluesky).

      Built with:
      - Tauri v2 (Rust + WebKit)
      - React 19
      - @atproto packages
      - atcute (CAR file parsing)
      - shadcn UI components

      Maintained by ATBackup (https://atbackup.pages.dev)
    '';
    homepage = "https://tangled.org/@atbackup.pages.dev/atbackup";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = [ ];
    mainProgram = "atbackup";

    organizationalContext = {
      organization = "atbackup-pages-dev";
      displayName = "ATBackup";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}
