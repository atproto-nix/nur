{ lib
, buildGoModule
, fetchFromGitHub
, pkg-config
, sqlite
, stdenv
}:

buildGoModule rec {
  pname = "tangled-spindle";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "tangled-dev";
    repo = "tangled-core";
    rev = "main"; # TODO: Pin to specific commit
    hash = lib.fakeHash; # Placeholder - needs real hash
  };

  vendorHash = lib.fakeHash; # Placeholder - needs real hash

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    sqlite
  ];

  # Build only the spindle binary
  subPackages = [ "cmd/spindle" ];

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
      name = "tangled-dev";
      displayName = "Tangled Development";
      website = "https://tangled.dev";
      contact = null;
      maintainer = "Tangled Development";
      repository = "https://github.com/tangled-dev/tangled-core";
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
      
      Maintained by Tangled Development (https://tangled.dev)
    '';
    homepage = "https://tangled.dev";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ ];
    mainProgram = "spindle";
    
    organizationalContext = {
      organization = "tangled-dev";
      displayName = "Tangled Development";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}