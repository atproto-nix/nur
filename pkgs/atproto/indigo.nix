{ lib
, buildGoModule
, fetchFromGitHub
, pkg-config
, sqlite
, postgresql
}:

let
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "indigo";
    rev = "1e8718ae9f339b3c745ff0e66f4c59dd98c21d94";
    sha256 = "sha256-/Jk4hAvQZVICTMbb6KRO034lHrg2NlHPfOD+dqV+VN0=";
  };

  # Common build environment for all Indigo services
  commonEnv = {
    CGO_ENABLED = "1";
  };

  # Build individual services from the cmd directory
  buildService = service: buildGoModule {
    pname = "indigo-${service}";
    inherit version src;
    
    vendorHash = null; # Use vendorHash = null for now
    
    subPackages = [ "cmd/${service}" ];
    
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ sqlite postgresql ];
    
    env = commonEnv;
    
    ldflags = [
      "-s"
      "-w"
      "-X main.version=${version}"
    ];

    meta = with lib; {
      description = "Indigo ${service} - ATproto service";
      homepage = "https://github.com/bluesky-social/indigo";
      license = with licenses; [ mit asl20 ]; # Dual licensed
      maintainers = [ maintainers.atproto-team or [] ];
      platforms = platforms.unix;
      
      atproto = {
        category = "infrastructure";
        services = [ service ];
        protocols = [ "xrpc" "atproto" ];
        dependencies = [ "postgresql" "sqlite" ];
        tier = 1;
      };
    };
  };

  # Core services as specified in the task
  services = [
    "relay"
    "rainbow" 
    "palomar"
    "hepa"
  ];

  # Additional services available in Indigo
  additionalServices = [
    "astrolabe"
    "athome"
    "beemo"
    "bigsky"
    "bluepages"
    "collectiondir"
    "fakermaker"
    "goat"
    "gosky"
    "lexgen"
    "netsync"
    "querycheck"
    "sonar"
    "stress"
    "supercollider"
  ];

  # Build core libraries as a single package
  coreLibraries = buildGoModule {
    pname = "indigo-libs";
    inherit version src;
    
    vendorHash = null; # Use vendorHash = null for now
    
    # Build as library package - no main packages
    subPackages = [ ];
    
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ sqlite postgresql ];
    
    env = commonEnv;
    
    # Don't build binaries, just make libraries available
    buildPhase = ''
      runHook preBuild
      go mod download
      runHook postBuild
    '';
    
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/indigo
      cp -r . $out/share/indigo/
      runHook postInstall
    '';

    meta = with lib; {
      description = "Indigo core libraries - ATproto Go implementation";
      longDescription = ''
        Core ATproto libraries including:
        - api: ATproto API definitions and client
        - atproto: Core ATproto protocol implementation
        - lex: Lexicon schema handling
        - xrpc: XRPC protocol implementation
        - did: Decentralized Identifier utilities
        - repo: Repository and MST implementation
        - carstore: CAR file storage
        - events: Event streaming and firehose
      '';
      homepage = "https://github.com/bluesky-social/indigo";
      license = with licenses; [ mit asl20 ];
      maintainers = [ maintainers.atproto-team or [] ];
      platforms = platforms.unix;
      
      atproto = {
        category = "library";
        services = [ ];
        protocols = [ "xrpc" "atproto" "did" ];
        dependencies = [ "postgresql" "sqlite" ];
        tier = 1;
      };
    };
  };

in
# Return a set containing both services and libraries
lib.genAttrs services buildService // {
  inherit coreLibraries;
  
  # Convenience aliases for core services
  inherit (lib.genAttrs services buildService) relay rainbow palomar hepa;
  
  # Additional services available but not in core set
  additional = lib.genAttrs additionalServices buildService;
}