# Slices API - Rust backend for ATProto custom AppView platform
{ lib, pkgs, craneLib, ... }:

let
  # Import packaging utilities
  packaging = pkgs.callPackage ../../lib/packaging { inherit craneLib; };

  # Source from Tangled
  src = pkgs.fetchFromTangled {
    domain = "tangled.org";
    owner = "@slices.network";
    repo = "slices";
    rev = "0a876a16d49c596d779d21a80a9ba0822f9d571f";
    sha256 = "0wk6n082w9vdxfp549ylffnz0arwi78rlwai4jhdlvq3cr0547k8";
  };

  # CRITICAL: Slices has multiple Cargo.lock files:
  # - /api/Cargo.lock (main API workspace)
  # - /crates/slices-lexicon/Cargo.lock (separate lexicon crate)
  # We must vendor BOTH to handle cross-workspace dependencies
  vendoredCargoDeps = craneLib.vendorMultipleCargoDeps {
    cargoLockList = [
      (src + "/api/Cargo.lock")
      (src + "/crates/slices-lexicon/Cargo.lock")
    ];
  };

  # Common environment for Rust API
  apiEnv = packaging.standardEnv // packaging.standardRustEnv // {
    # Database configuration (build-time defaults)
    DATABASE_URL = "postgresql://slices:slices@localhost:5432/slices";
    REDIS_URL = "redis://localhost:6379";

    # ATproto configuration
    RELAY_ENDPOINT = "https://relay1.us-west.bsky.network";
    JETSTREAM_HOSTNAME = "jetstream1.us-west.bsky.network";

    # Rust-specific
    SQLX_OFFLINE = "true"; # Use offline mode for sqlx queries
    RUST_LOG = "debug";
  };

  # Common arguments for API package
  apiCommonArgs = {
    pname = "slices-api";
    version = "0.2.0";
    src = src;
    sourceRoot = "${src.name}/api";

    # Use vendored multi-lock dependencies
    cargoVendorDir = vendoredCargoDeps;

    # Standard inputs from packaging utilities
    nativeBuildInputs = (with pkgs; [ pkg-config perl ]);
    buildInputs = (with pkgs; [ openssl zstd lz4 postgresql sqlite cacert ]);

    env = apiEnv;
    tarFlags = "--no-same-owner";
  };

  # Build shared cargo artifacts (dependencies only, for caching)
  apiCargoArtifacts = craneLib.buildDepsOnly (apiCommonArgs // {
    cargoLockContents = builtins.readFile (src + "/api/Cargo.lock");
  });

  # Build the actual API package
  api = craneLib.buildPackage (apiCommonArgs // {
    inherit apiCargoArtifacts;

    # Copy migrations and runtime assets
    postInstall = ''
      mkdir -p $out/share/slices-api
      if [ -d migrations ]; then
        cp -r migrations $out/share/slices-api/
      fi
      if [ -f schema.sql ]; then
        cp schema.sql $out/share/slices-api/
      fi
      # Make files writable so the fixup phase can strip references
      chmod -R u+w $out/share/slices-api
    '';

    # Custom build phase to capture logs
    buildPhase = ''
      runHook preBuild
      cargoBuildLog=$(mktemp cargoBuildLogXXXX.json)
      cargo build --release --message-format json-render-diagnostics >"$cargoBuildLog"
      runHook postBuild
    '';

    meta = with lib; {
      description = "Slices API backend - ATproto custom AppView platform";
      longDescription = ''
        Rust-based API backend for Slices, providing:
        - AT Protocol XRPC handlers with dynamic endpoints
        - Lexicon validation for custom schemas
        - Sync engine for bulk data synchronization
        - Jetstream integration for real-time streaming
        - PostgreSQL and Redis integration
        - OAuth integration for AT Protocol authentication
      '';
      homepage = "https://slices.network";
      license = licenses.mit;
      platforms = platforms.linux ++ platforms.darwin;
      maintainers = [ ];
      mainProgram = "slices";
    };
  });

in
api
