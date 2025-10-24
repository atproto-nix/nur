{ lib
, stdenv
, fetchFromTangled
, craneLib
, pkg-config
, openssl
, darwin
}:

let
  version = "unstable-2025-01-23";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@grain.social";
    repo = "grain";
    rev = "643445cfbfca683b3f17f8990f444405cff2165a";
    hash = lib.fakeHash;
    forceFetchGit = true;
  };

  # CLI source from monorepo
  cliSrc = lib.cleanSourceWith {
    src = "${src}/cli";
    filter = craneLib.filterCargoSources;
  };

  commonArgs = {
    pname = "grain-cli";
    inherit version;
    src = cliSrc;

    strictDeps = true;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      openssl
      openssl.dev
    ] ++ lib.optionals stdenv.isDarwin [
      # macOS-specific frameworks required by CLI dependencies
      darwin.apple_sdk.frameworks.Security
      darwin.apple_sdk.frameworks.SystemConfiguration
    ];

    # Environment variables for OpenSSL
    OPENSSL_NO_VENDOR = 1;
    PKG_CONFIG_PATH = "${openssl.dev}/lib/pkgconfig";
  };

  # Build only dependencies (for caching)
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

in
craneLib.buildPackage (commonArgs // {
  inherit cargoArtifacts;

  # Run tests
  doCheck = true;

  CARGO_PROFILE = "release";

  passthru = {
    atproto = {
      type = "cli";
      services = [ ];
      protocols = [ "com.atproto" ];
      schemaVersion = "1.0";
      description = "Grain Social command-line interface for gallery management";

      configuration = {
        required = [ ];
        optional = [ ];
      };
    };

    organization = {
      name = "grain-social";
      displayName = "Grain Social";
      website = "https://grain.social";
      contact = null;
      maintainer = "Chad Miller";
      repository = "https://tangled.org/@grain.social/grain";
      packageCount = 3; # grain (placeholder), darkroom, cli
      atprotoFocus = [ "applications" "media" "social" ];
    };
  };

  meta = with lib; {
    description = "Grain Social CLI - Command-line interface for gallery management";
    longDescription = ''
      Command-line interface for Grain Social, a photo-sharing platform
      built on the AT Protocol.

      Features:
      - Gallery creation and management
      - Photo uploads with metadata
      - Authentication with Bluesky/ATProto accounts
      - Image manipulation and optimization
      - Interactive prompts for easy usage

      Built with Rust using:
      - clap for CLI argument parsing
      - dialoguer for interactive prompts
      - reqwest for HTTP client
      - image crate for photo manipulation
      - tokio for async runtime

      Part of the Grain Social ecosystem by Chad Miller.
    '';
    homepage = "https://grain.social";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "grain";

    organizationalContext = {
      organization = "grain-social";
      displayName = "Grain Social";
      component = "cli";
      needsMigration = false;
      migrationPriority = "low";
    };
  };
})
