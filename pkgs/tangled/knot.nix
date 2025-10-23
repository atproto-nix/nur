{ lib
, buildGoModule
, fetchFromTangled
, pkg-config
, sqlite
, stdenv
}:

buildGoModule rec {
  pname = "tangled-knot";
  version = "0.1.0";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@tangled.org";
    repo = "core";
    rev = "54a60448cf5c456650e9954ca9422276c5d73282";
    hash = lib.fakeHash; # Placeholder - needs real hash
  };

  vendorHash = lib.fakeHash; # Placeholder - needs real hash

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    sqlite
  ];

  # Build only the knot binary
  subPackages = [ "cmd/knot" ];

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
      services = [ "knot" "git-server" ];
      protocols = [ "com.atproto" "git" ];
      schemaVersion = "1.0";
      
      # Configuration requirements
      configuration = {
        required = [ 
          "KNOT_SERVER_HOSTNAME"
          "KNOT_SERVER_OWNER"
        ];
        optional = [ 
          "APPVIEW_ENDPOINT"
          "KNOT_REPO_SCAN_PATH"
          "KNOT_REPO_MAIN_BRANCH"
          "KNOT_SERVER_LISTEN_ADDR"
          "KNOT_SERVER_INTERNAL_LISTEN_ADDR"
          "KNOT_SERVER_DB_PATH"
          "KNOT_SERVER_DEV"
        ];
      };
      
      tangled = {
        component = "knot";
        description = "Git server component of Tangled with enhanced ATProto integration";
        endpoints = {
          configurable = [ "appview" "jetstream" "nixery" "atproto" "plc" ];
          defaults = {
            appview = "https://tangled.org";
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
    description = "Tangled Knot - Git server with ATProto integration";
    longDescription = ''
      Git server component of Tangled with ATProto integration.
      Provides Git hosting with ATProto identity integration, allowing
      users to authenticate using their ATProto DIDs and manage repositories
      through the decentralized social network.
      
      Key features:
      - Git repository hosting with ATProto authentication
      - SSH key management through ATProto identity
      - Integration with Tangled AppView for web interface
      - Configurable endpoints for distributed deployment
      
      Maintained by Tangled (https://tangled.org)
    '';
    homepage = "https://tangled.org";
    license = licenses.mit;
    platforms = platforms.unix;  # Linux + macOS
    maintainers = [ ];
    mainProgram = "knot";
    
    organizationalContext = {
      organization = "tangled";
      displayName = "Tangled";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}