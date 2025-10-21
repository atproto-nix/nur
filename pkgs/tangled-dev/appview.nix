{ lib
, buildGoModule
, fetchFromGitHub
, pkg-config
, sqlite
, stdenv
}:

buildGoModule rec {
  pname = "tangled-appview";
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
      
      Maintained by Tangled Development (https://tangled.dev)
    '';
    homepage = "https://tangled.dev";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ ];
    mainProgram = "appview";
    
    organizationalContext = {
      organization = "tangled-dev";
      displayName = "Tangled Development";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}