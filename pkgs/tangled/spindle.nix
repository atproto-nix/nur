{ lib
, buildGoApplication
, fetchFromTangled
, pkg-config
, sqlite
, stdenv
}:

let
  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@tangled.org";
    repo = "core";
    rev = "2e5a4cde904d86825cefe5971e68f1bdfb1dd36f";
    hash = "sha256-qDVJ2sEQL0TJbWer6ByhhQrzHE1bZI3U1mmCk0sPZqo=";
  };

  # Read the gomod2nix.toml file from the source
  modules = "${src}/nix/gomod2nix.toml";
in

buildGoApplication rec {
  pname = "spindle";
  version = "0.1.0";

  inherit src modules;

  subPackages = [ "cmd/spindle" ];

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    sqlite
  ];

  # CGO settings for sqlite
  CGO_ENABLED = 1;
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
      type = "infrastructure";
      services = [ "spindle" "event-processor" "ci-cd" ];
      protocols = [ "com.atproto" "jetstream" ];
      schemaVersion = "1.0";
      
      # Configuration requirements
      configuration = {
        required = [ ];
        optional = [ 
          "SPINDLE_DB_PATH"
          "SPINDLE_LISTEN_ADDR"
          "JETSTREAM_ENDPOINT"
          "APPVIEW_ENDPOINT"
          "KNOT_ENDPOINT"
          "NIXERY_ENDPOINT"
        ];
      };
      
      tangled = {
        component = "spindle";
        description = "Event processing and CI/CD component of Tangled with enhanced ATProto integration";
        endpoints = {
          configurable = [ "appview" "knot" "jetstream" "nixery" "atproto" "plc" ];
          defaults = {
            appview = "https://tangled.org";
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
    description = "Tangled Spindle - Event processor and CI/CD with ATProto integration";
    longDescription = ''
      Event processing and CI/CD component of Tangled with ATProto integration.
      Handles continuous integration, deployment workflows, and event processing
      for the Tangled git forge ecosystem.
      
      Key features:
      - Event processing for ATProto and Git events
      - Continuous integration and deployment workflows
      - Integration with Jetstream for real-time events
      - Configurable endpoints for distributed deployment
      - Nixery integration for container builds
      
      Maintained by Tangled (https://tangled.org)
    '';
    homepage = "https://tangled.org";
    license = licenses.mit;
    platforms = platforms.unix;  # Linux + macOS
    maintainers = [ ];
    mainProgram = "spindle";
    
    organizationalContext = {
      organization = "tangled";
      displayName = "Tangled";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}