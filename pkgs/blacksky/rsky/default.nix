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

  # Satnav is a Dioxus web app that must be compiled to WASM, not a native binary
  satnav =
    let
      # Custom crane lib with WASM target
      wasmCraneLib = (craneLib.overrideToolchain (pkgs.rust-bin.stable.latest.default.override {
        targets = [ "wasm32-unknown-unknown" ];
      }));

      # Build dependencies for WASM target
      wasmCargoArtifacts = wasmCraneLib.buildDepsOnly {
        src = rskySrc;
        pname = "rsky-satnav-deps";
        version = "0.1.0";

        # Build for WASM target
        cargoExtraArgs = "--target wasm32-unknown-unknown --package rsky-satnav";

        env = atprotoLib.defaultRustEnv // {
          CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
        };

        nativeBuildInputs = atprotoLib.defaultRustNativeInputs;
        buildInputs = atprotoLib.defaultRustBuildInputs;
        tarFlags = "--no-same-owner";
      };

      # Build WASM binary using crane's cargoBuild
      wasmBuild = wasmCraneLib.cargoBuild {
        cargoArtifacts = wasmCargoArtifacts;  # crane expects this exact parameter name
        src = rskySrc;
        pname = "rsky-satnav-wasm";
        version = "0.1.0";

        cargoExtraArgs = "--target wasm32-unknown-unknown --package rsky-satnav";

        env = atprotoLib.defaultRustEnv // {
          CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
        };

        nativeBuildInputs = atprotoLib.defaultRustNativeInputs;
        buildInputs = atprotoLib.defaultRustBuildInputs;
        tarFlags = "--no-same-owner";

        # Don't run tests for WASM
        doCheck = false;

        # Install the WASM file
        installPhaseCommand = ''
          mkdir -p $out
          cp target/wasm32-unknown-unknown/release/rsky-satnav.wasm $out/
        '';
      };
    in
    pkgs.stdenv.mkDerivation {
      pname = "rsky-satnav";
      version = "0.1.0";
      src = rskySrc;

      nativeBuildInputs = with pkgs; [
        # Rust toolchain with WASM target (needed by dx bundle)
        (rust-bin.stable.latest.default.override {
          targets = [ "wasm32-unknown-unknown" ];
        })
        # WASM bindgen CLI - must match project's version (0.2.100)
        wasm-bindgen-cli_0_2_100
        # WASM optimizer
        binaryen
        # Tailwind CSS v4 for styling
        tailwindcss_4
        # Dioxus CLI for bundling
        dioxus-cli
      ];

      buildPhase = ''
        # Navigate to satnav directory
        cd rsky-satnav

        # Compile Tailwind CSS first
        echo "Compiling Tailwind CSS..."
        ${pkgs.tailwindcss_4}/bin/tailwindcss -i input.css -o assets/tailwind.css

        # Run wasm-bindgen on the pre-built WASM binary
        echo "Running wasm-bindgen..."
        mkdir -p dist
        ${pkgs.wasm-bindgen-cli_0_2_100}/bin/wasm-bindgen \
          --target web \
          --out-dir dist \
          --out-name rsky-satnav \
          ${wasmBuild}/rsky-satnav.wasm

        # Optimize WASM with wasm-opt
        echo "Optimizing WASM..."
        ${pkgs.binaryen}/bin/wasm-opt -Oz dist/rsky-satnav_bg.wasm -o dist/rsky-satnav_bg.wasm

        # Copy all assets to dist
        echo "Copying assets..."
        cp -r assets dist/

        # Create a simple index.html that loads the WASM app
        cat > dist/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>rsky-satnav</title>
    <link rel="stylesheet" href="assets/tailwind.css">
    <link rel="stylesheet" href="assets/main.css">
    <link rel="icon" href="assets/favicon.ico">
</head>
<body>
    <div id="main"></div>
    <script type="module">
        import init from './rsky-satnav.js';
        await init();
    </script>
</body>
</html>
EOF
      '';

      installPhase = ''
        # We're already in rsky-satnav directory from buildPhase
        # dx bundle creates output in dist/ directory
        # Install static files to $out/share/rsky-satnav/
        mkdir -p $out/share/rsky-satnav

        # Check if dist directory exists and has content
        if [ -d "dist" ] && [ "$(ls -A dist)" ]; then
          echo "Installing Dioxus bundle output..."
          cp -r dist/* $out/share/rsky-satnav/
        else
          echo "Error: dist directory is missing or empty after dx bundle!"
          echo "Current directory: $(pwd)"
          echo "Contents:"
          ls -laR || true
          exit 1
        fi
      '';

      meta = with pkgs.lib; {
        description = "AT Protocol Satnav - Browser-based CAR file explorer (WASM)";
        homepage = "https://github.com/blacksky-algorithms/rsky";
        license = licenses.asl20;
        platforms = platforms.all;  # Static files work on any platform
        maintainers = [ ];
      };
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
