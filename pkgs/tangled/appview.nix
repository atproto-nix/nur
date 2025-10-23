{ lib
, buildGoModule
, fetchFromTangled
, pkg-config
, sqlite
, stdenv
, callPackage
}:

let
  appview-static-files = callPackage ./appview-static-files.nix { };
in
buildGoModule rec {
  pname = "tangled-appview";
  version = "0.1.0";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@tangled.org";
    repo = "core";
    rev = "54a60448cf5c456650e9954ca9422276c5d73282";
    hash = "sha256-OcTD732dTYT69smyDSI6oi0vXSwnpJfLGxq7MGNqOus=";
  };

  vendorHash = "sha256-ppAAcayRboFCX1rB6FCYEqJi8crlCHBRuvUoZfmiuYY=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    sqlite
  ];

  # Copy static files before building (needed for Go embed)
  postUnpack = ''
    pushd source
    mkdir -p appview/pages/static
    cp -frv ${appview-static-files}/* appview/pages/static
    popd
  '';

  # Build only the appview binary
  subPackages = [ "cmd/appview" ];

  # Build flags
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  # ATProto metadata
  passthru = {
    atproto = {
      type = "application";
      services = [ "appview" "web-interface" ];
      protocols = [ "com.atproto" "http" ];
      schemaVersion = "1.0";
      
      # Configuration requirements
      configuration = {
        required = [ ];
        optional = [ 
          "TANGLED_DB_PATH"
          "TANGLED_COOKIE_SECRET"
          "TANGLED_HOST"
          "TANGLED_PORT"
          "KNOT_ENDPOINT"
          "JETSTREAM_ENDPOINT"
          "NIXERY_ENDPOINT"
        ];
      };
      
      tangled = {
        component = "appview";
        description = "Web interface for Tangled git forge with enhanced ATProto integration";
        endpoints = {
          configurable = [ "knot" "jetstream" "nixery" "atproto" "plc" ];
          defaults = {
            knot = "https://git.tangled.sh";
            jetstream = "wss://jetstream.tangled.sh";
            nixery = "https://nixery.tangled.sh";
            atproto = "https://bsky.social";
            plc = "https://plc.directory";
          };
        };
      };
    };
    
    organization = {
      name = "tangled";
      displayName = "Tangled";
      website = "https://tangled.org";
      contact = null;
      maintainer = "Tangled";
      repository = "https://tangled.org/@tangled.org/core";
      packageCount = 5;
      atprotoFocus = [ "infrastructure" "tools" ];
    };
  };
  
  meta = with lib; {
    description = "Tangled AppView - Web interface for ATProto git forge";
    longDescription = ''
      Web interface for Tangled git forge with ATProto integration.
      Provides a modern web UI for browsing repositories, managing projects,
      and interacting with the ATProto ecosystem through a Git forge interface.
      
      Key features:
      - Modern web interface for Git repository browsing
      - ATProto identity integration and authentication
      - Project management and collaboration tools
      - Integration with Knot git server and Jetstream events
      - Configurable endpoints for distributed deployment
      
      Maintained by Tangled (https://tangled.org)
    '';
    homepage = "https://tangled.org";
    license = licenses.mit;
    platforms = platforms.unix;  # Linux + macOS
    maintainers = [ ];
    mainProgram = "appview";
    
    organizationalContext = {
      organization = "tangled";
      displayName = "Tangled";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}