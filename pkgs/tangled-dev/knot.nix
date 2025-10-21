{ lib
, buildGoModule
, fetchFromGitHub
, pkg-config
, sqlite
, stdenv
}:

buildGoModule rec {
  pname = "tangled-knot";
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
      
      Maintained by Tangled Development (https://tangled.dev)
    '';
    homepage = "https://tangled.dev";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ ];
    mainProgram = "knot";
    
    organizationalContext = {
      organization = "tangled-dev";
      displayName = "Tangled Development";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}