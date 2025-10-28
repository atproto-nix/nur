{ pkgs, craneLib, ... }:

let
  # Import ATProto utilities
  atprotoLib = pkgs.callPackage ../../../lib/atproto.nix { inherit craneLib; };
  
  # Common source for all rsky packages - updated to official repository
  rskySrc = pkgs.fetchFromGitHub {
    owner = "blacksky-algorithms";
    repo = "rsky";
    rev = "f84a5975e82bc1403e3c4477ca7ef46611c4eeda"; # Latest commit from main branch
    hash = "sha256-bM8CT6MLxjeK2vFaj90KeSZPwy0q9OxMzcP3rHEv3Hc=";
  };
  
  # Build shared dependencies once for the entire workspace
  cargoArtifacts = craneLib.buildDepsOnly {
    src = rskySrc;
    pname = "rsky-deps";
    version = "0.1.0";
    env = atprotoLib.defaultRustEnv;
    nativeBuildInputs = atprotoLib.defaultRustNativeInputs;
    buildInputs = atprotoLib.defaultRustBuildInputs;
    tarFlags = "--no-same-owner";
  };
  
  # Helper function to build rsky service packages (applications with binaries)
  mkRskyService = { pname, version, package, bin ? null, description, services ? [] }:
    let
      binaryName = if bin != null then bin else package;
    in
    atprotoLib.mkRustAtprotoService {
      inherit pname version;
      src = rskySrc;
      inherit cargoArtifacts;
      
      type = "application";
      inherit services;
      protocols = [ "com.atproto" "app.bsky" ];
      
      cargoExtraArgs = "--package ${package} --bin ${binaryName}";
      
      meta = with pkgs.lib; {
        inherit description;
        homepage = "https://github.com/blacksky-algorithms/rsky";
        license = licenses.asl20; # Updated to Apache 2.0 as per README
        platforms = platforms.unix;
        maintainers = [ ];
      };
    };
  
  # Helper function to build rsky library packages
  mkRskyLibrary = { pname, version, package, description }:
    craneLib.buildPackage {
      inherit pname version;
      src = rskySrc;
      inherit cargoArtifacts;
      
      cargoExtraArgs = "--package ${package} --lib";
      
      env = atprotoLib.defaultRustEnv;
      nativeBuildInputs = atprotoLib.defaultRustNativeInputs;
      buildInputs = atprotoLib.defaultRustBuildInputs;
      tarFlags = "--no-same-owner";
      
      meta = with pkgs.lib; {
        inherit description;
        homepage = "https://github.com/blacksky-algorithms/rsky";
        license = licenses.asl20;
        platforms = platforms.unix;
        maintainers = [ ];
      };
      
      passthru.atproto = {
        type = "library";
        services = [ ];
        protocols = [ "com.atproto" "app.bsky" ];
        schemaVersion = "1.0";
      };
    };
in
{
  # Service applications (binaries)
  pds = mkRskyService {
    pname = "rsky-pds";
    version = "0.1.1";
    package = "rsky-pds";
    description = "AT Protocol Personal Data Server (PDS) from rsky";
    services = [ "pds" ];
  };

  relay = mkRskyService {
    pname = "rsky-relay";
    version = "0.1.0";
    package = "rsky-relay";
    description = "AT Protocol Relay from rsky";
    services = [ "relay" ];
  };

  feedgen = mkRskyService {
    pname = "rsky-feedgen";
    version = "0.1.0";
    package = "rsky-feedgen";
    description = "AT Protocol Feed Generator from rsky";
    services = [ "feedgen" ];
  };

  satnav = mkRskyService {
    pname = "rsky-satnav";
    version = "0.1.0";
    package = "rsky-satnav";
    description = "AT Protocol Satnav - Structured Archive Traversal, Navigation & Verification";
    services = [ "satnav" ];
  };

  firehose = mkRskyService {
    pname = "rsky-firehose";
    version = "0.2.1";
    package = "rsky-firehose";
    description = "AT Protocol Firehose subscriber from rsky";
    services = [ "firehose" ];
  };

  jetstreamSubscriber = mkRskyService {
    pname = "rsky-jetstream-subscriber";
    version = "0.1.0";
    package = "rsky-jetstream-subscriber";
    bin = "jetstream-subscriber";
    description = "AT Protocol Jetstream Subscriber from rsky";
    services = [ "jetstream-subscriber" ];
  };

  labeler = mkRskyService {
    pname = "rsky-labeler";
    version = "0.1.3";
    package = "rsky-labeler";
    description = "AT Protocol Labeler from rsky";
    services = [ "labeler" ];
  };

  # NOTE: PDS Admin tool is temporarily disabled due to dependency issues
  # It has its own separate workspace with different dependencies not included in main Cargo.lock
  # This will be addressed in a future update when the upstream repository structure is clarified
  # 
  # pdsadmin = ...;

  # Core libraries (for reuse by other packages)
  common = mkRskyLibrary {
    pname = "rsky-common";
    version = "0.1.2";
    package = "rsky-common";
    description = "Common utilities and shared code for rsky";
  };

  crypto = mkRskyLibrary {
    pname = "rsky-crypto";
    version = "0.1.1";
    package = "rsky-crypto";
    description = "Cryptographic signing and key serialization for AT Protocol";
  };

  identity = mkRskyLibrary {
    pname = "rsky-identity";
    version = "0.1.0";
    package = "rsky-identity";
    description = "DID and handle resolution for AT Protocol";
  };

  lexicon = mkRskyLibrary {
    pname = "rsky-lexicon";
    version = "0.2.8";
    package = "rsky-lexicon";
    description = "Schema definition language for AT Protocol";
  };

  repo = mkRskyLibrary {
    pname = "rsky-repo";
    version = "0.0.2";
    package = "rsky-repo";
    description = "Data storage structure including MST for AT Protocol";
  };

  syntax = mkRskyLibrary {
    pname = "rsky-syntax";
    version = "0.1.0";
    package = "rsky-syntax";
    description = "String parsers for AT Protocol identifiers";
  };

  # community = pkgs.buildYarnPackage rec {
  #   pname = "blacksky.community";
  #   version = "1.109.0"; # Version from package.json
  #
  #   src = pkgs.fetchFromGitHub {
  #     owner = "blacksky-algorithms";
  #     repo = "blacksky.community";
  #     # TODO: Update 'rev' to a specific commit hash or release tag for reproducible builds.
  #     rev = "main";
  #     # TODO: Update 'hash' to the correct SHA256 hash of the fetched source.
  #     # You can obtain the correct hash by setting it to an empty string, running nix-build,
  #     # and then copying the hash from the error message.
  #     hash = "sha256-W0mXqED9geNKJSPGJhUdJZ2voMOMDCXX1T4zn3GZKlY=";
  #   };
  #
  #   yarnLock = "yarn.lock"; # Specify the yarn.lock file
  #
  #   buildPhase = ''
  #     yarn build-web
  #   '';
  #
  #   installPhase = ''
  #     mkdir -p $out/share/nginx/html
  #     cp -r web-build/* $out/share/nginx/html
  #   '';
  #
  #   meta = with pkgs.lib; {
  #     description = "Blacksky Community Web Client";
  #     # Placeholder, update with actual homepage if available.
  #     homepage = "https://github.com/blacksky-algorithms/blacksky.community";
  #     # Placeholder, add actual maintainers.
  #     maintainers = with maintainers; [ ];
  #   };
  # };
}
