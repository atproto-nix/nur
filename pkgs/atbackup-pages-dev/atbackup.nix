{ lib
, stdenv
, fetchFromGitHub
, buildNpmPackage
, nodejs
, yarn
, cargo-tauri
, rustPlatform
, pkg-config
, openssl
, webkitgtk_4_1
, gtk3
, cairo
, gdk-pixbuf
, glib
, dbus
, libsoup
, librsvg
, wrapGAppsHook
}:

let
  # Tauri applications require special handling for desktop integration
  version = "0.1.2";
  
  src = fetchFromGitHub {
    owner = "Turtlepaw";
    repo = "atproto-backup";
    rev = "deb720914f4c36557bcd5ee9af95791e42afd45f";
    sha256 = "0ksqwsqv95lq97rh8z9dc0m1bjzc2fb4yjlksyfx7p49f1slcv8r";
  };

  # Build the frontend first
  frontend = buildNpmPackage {
    pname = "atbackup-frontend";
    inherit version src;
    
    npmDepsHash = lib.fakeHash; # Will be updated during build
    
    nativeBuildInputs = [ nodejs yarn ];
    
    buildPhase = ''
      runHook preBuild
      
      # Use yarn as specified in package.json
      yarn install --frozen-lockfile
      yarn build
      
      runHook postBuild
    '';
    
    installPhase = ''
      runHook preInstall
      
      # Copy built frontend assets
      mkdir -p $out
      cp -r dist/* $out/
      
      runHook postInstall
    '';
  };

in
stdenv.mkDerivation {
  pname = "atbackup";
  inherit version src;

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook
    rustPlatform.cargoSetupHook
    cargo-tauri
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
    dbus
    libsoup
    librsvg
  ];

  # Tauri requires the frontend to be built first
  preBuild = ''
    # Copy frontend build output
    mkdir -p dist
    cp -r ${frontend}/* dist/
    
    # Install Rust dependencies
    export CARGO_HOME=$(mktemp -d cargo-home.XXX)
  '';

  buildPhase = ''
    runHook preBuild
    
    # Build the Tauri application
    yarn tauri build
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    
    # Install the built application
    mkdir -p $out/bin
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons
    
    # Copy the built binary (location depends on Tauri configuration)
    if [ -f src-tauri/target/release/atbackup ]; then
      cp src-tauri/target/release/atbackup $out/bin/
    elif [ -f target/release/atbackup ]; then
      cp target/release/atbackup $out/bin/
    else
      echo "Could not find built Tauri binary"
      exit 1
    fi
    
    # Copy desktop file and icons if they exist
    if [ -f src-tauri/icons/icon.png ]; then
      cp src-tauri/icons/icon.png $out/share/icons/atbackup.png
    fi
    
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
      repository = "https://github.com/Turtlepaw/atproto-backup";
      packageCount = 1;
      atprotoFocus = [ "applications" "tools" ];
    };
  };

  meta = with lib; {
    description = "One-click Bluesky backups desktop application";
    longDescription = ''
      ATBackup is a desktop application built with Tauri that provides
      one-click backup functionality for Bluesky accounts. It allows users
      to easily backup their posts, media, and account data from the ATProto
      network.
      
      Maintained by ATBackup (https://atbackup.pages.dev)
    '';
    homepage = "https://github.com/Turtlepaw/atproto-backup";
    license = licenses.asl20;
    platforms = platforms.linux; # Tauri supports multiple platforms but focus on Linux for NixOS
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