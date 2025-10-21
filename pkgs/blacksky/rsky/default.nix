{ pkgs, craneLib, ... }:

let
  # Import ATProto utilities
  atprotoLib = pkgs.callPackage ../../../lib/atproto.nix { inherit craneLib; };
  
  # Common source for all rsky packages
  rskySrc = pkgs.fetchFromGitHub {
    owner = "blacksky-algorithms";
    repo = "rsky";
    rev = "f84a5975e82bc1403e3c4477ca7ef46611c4eeda";
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
  
  # Helper function to build rsky packages
  mkRskyPackage = { pname, version, package, bin ? package, description, services ? [] }:
    atprotoLib.mkRustAtprotoService {
      inherit pname version;
      src = rskySrc;
      inherit cargoArtifacts;
      
      type = "application";
      inherit services;
      protocols = [ "com.atproto" "app.bsky" ];
      
      cargoExtraArgs = "--package ${package} --bin ${bin}";
      
      meta = with pkgs.lib; {
        inherit description;
        homepage = "https://github.com/blacksky-algorithms/rsky";
        license = licenses.mit;
        platforms = platforms.unix;
        maintainers = [ ];
      };
    };
in
{
  pds = mkRskyPackage {
    pname = "rsky-pds";
    version = "0.1.0";
    package = "rsky-pds";
    description = "AT Protocol Personal Data Server (PDS) from rsky";
    services = [ "pds" ];
  };

  relay = mkRskyPackage {
    pname = "rsky-relay";
    version = "0.1.0";
    package = "rsky-relay";
    description = "AT Protocol Relay from rsky";
    services = [ "relay" ];
  };

  feedgen = mkRskyPackage {
    pname = "rsky-feedgen";
    version = "0.1.0";
    package = "rsky-feedgen";
    description = "AT Protocol Feed Generator from rsky";
    services = [ "feedgen" ];
  };

  satnav = mkRskyPackage {
    pname = "rsky-satnav";
    version = "0.1.0";
    package = "rsky-satnav";
    description = "AT Protocol Satnav from rsky";
    services = [ "satnav" ];
  };

  firehose = mkRskyPackage {
    pname = "rsky-firehose";
    version = "0.2.1";
    package = "rsky-firehose";
    description = "AT Protocol Firehose subscriber from rsky";
    services = [ "firehose" ];
  };

  jetstreamSubscriber = mkRskyPackage {
    pname = "rsky-jetstream-subscriber";
    version = "0.1.0";
    package = "rsky-jetstream-subscriber";
    description = "AT Protocol Jetstream Subscriber from rsky";
    services = [ "jetstream-subscriber" ];
  };

  labeler = mkRskyPackage {
    pname = "rsky-labeler";
    version = "0.1.3";
    package = "rsky-labeler";
    description = "AT Protocol Labeler from rsky";
    services = [ "labeler" ];
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
