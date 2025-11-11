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

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@tangled.org";
    repo = "core";
    rev = "2e5a4cde904d86825cefe5971e68f1bdfb1dd36f";
    hash = "sha256-qDVJ2sEQL0TJbWer6ByhhQrzHE1bZI3U1mmCk0sPZqo=";
  };
in

buildGoModule rec {
  pname = "appview";
  version = "0.1.0";

  inherit src;
  vendorHash = "sha256-fM1JAVX94qLCObi7FbgtKjl+pGGmWfbQJc0+IdzO3PQ=";

  subPackages = [ "cmd/appview" ];

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    sqlite
  ];

  # CGO settings for sqlite
  tags = [ "libsqlite3" ];

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
