{ lib
, buildGoModule
, fetchFromGitHub
, buildNpmPackage
, nodejs
, makeWrapper
}:

let
  version = "unstable-2025-01-15";

  src = fetchFromGitHub {
    owner = "whyrusleeping";
    repo = "konbini";
    rev = "a803489e1b7fb366164f2df2e113528b30013358";
    hash = "sha256-Mk31H9ucrmFBmt1clPdp/xjIw+scEIDvaxYWIvWfl4A=";
  };

  # Build the React frontend
  frontend = buildNpmPackage {
    pname = "konbini-frontend";
    inherit version src;

    sourceRoot = "${src.name}/frontend";

    npmDepsHash = "sha256-jqO9ll1KnbqsB9wxxjzVheZ3P+MXk63rRJL7vPdxKLs=";

    nativeBuildInputs = [ nodejs ];

    buildPhase = ''
      runHook preBuild

      # Build React app with react-scripts
      npm run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      # Copy built frontend
      mkdir -p $out
      cp -r build/* $out/

      runHook postInstall
    '';
  };

in
buildGoModule {
  pname = "konbini";
  inherit version src;

  vendorHash = "sha256-sboHNGOy0P1w/LL5OwStrPP0f+kbYcent6FKXOCuX6Y=";

  nativeBuildInputs = [ makeWrapper ];

  # Go build (backend only)
  buildPhase = ''
    runHook preBuild

    go build -o konbini .

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Install backend binary
    mkdir -p $out/bin
    cp konbini $out/bin/

    # Install frontend static files
    mkdir -p $out/share/konbini/frontend
    cp -r ${frontend}/* $out/share/konbini/frontend/

    # Wrap binary to set frontend path
    wrapProgram $out/bin/konbini \
      --set KONBINI_FRONTEND_PATH $out/share/konbini/frontend

    runHook postInstall
  '';

  # ATProto metadata
  passthru = {
    inherit frontend;

    atproto = {
      type = "appview";
      services = [ "konbini" ];
      protocols = [ "com.atproto" "app.bsky" ];
      schemaVersion = "1.0";
      hasWebFrontend = true;
      description = "Friends of Friends Bluesky AppView - partially indexed personal network viewer";

      # Configuration requirements
      configuration = {
        required = [ "DATABASE_URL" "BSKY_HANDLE" "BSKY_PASSWORD" ];
        optional = [ "PORT" "SYNC_CONFIG" ];
      };
    };

    organization = {
      name = "whyrusleeping";
      displayName = "Why (whyrusleeping)";
      website = "https://github.com/whyrusleeping";
      contact = null;
      maintainer = "whyrusleeping";
      repository = "https://github.com/whyrusleeping/konbini";
      packageCount = 1;
      atprotoFocus = [ "appviews" "infrastructure" ];
    };
  };

  meta = with lib; {
    description = "Cozy Bluesky AppView focused on Friends of Friends experience";
    longDescription = ''
      Konbini is a partially indexed Bluesky AppView designed to provide a
      "Friends of Friends" experience to the Bluesky network. Unlike fully
      indexed AppViews, Konbini selectively indexes content based on your
      social graph.

      Features:
      - Partial indexing based on social connections
      - Firehose and Jetstream support
      - Multiple upstream sync backends
      - PostgreSQL database backend
      - React frontend
      - API endpoints compatible with app.bsky.* spec
      - Selective repo backfill support

      Can be used as a custom AppView endpoint for the official Bluesky app
      by configuring a did:web service DID.

      Built with:
      - Go backend (Echo framework)
      - React 19 frontend
      - bluesky-social/indigo libraries
      - PostgreSQL (via pgx/v5)
      - GORM ORM

      By whyrusleeping (Why)
    '';
    homepage = "https://github.com/whyrusleeping/konbini";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = [ ];
    mainProgram = "konbini";

    organizationalContext = {
      organization = "whyrusleeping";
      displayName = "Why (whyrusleeping)";
      needsMigration = false;
      migrationPriority = "low";
    };
  };
}
