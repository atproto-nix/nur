{ lib
, buildGoModule
, fetchFromTangled
}:

buildGoModule rec {
  pname = "plcbundle";
  version = "0.1.0";

  # Fetch from Tangled git forge
  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@atscan.net";
    repo = "plcbundle";
    rev = "12a52286c0734338fceb29ec548f72521f2340c2";
    hash = "sha256-msSTk797cghWhc1J4If9YwfyMXjapZBIVoMKOD+C6dE=";
  };

  # Vendor hash for Go dependencies
  vendorHash = "sha256-IAYFAsFtAfnBz/U56bQqUZQf8CeohW7fMV6BAxW7SkI=";

  # Build the CLI tool
  subPackages = [ "cmd/plcbundle" ];

  # Build flags with version injection
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  # ATProto metadata
  passthru = {
    atproto = {
      type = "infrastructure";
      services = [ "plcbundle" "archiving" "verification" ];
      protocols = [ "com.atproto" "plc" "did" ];
      schemaVersion = "1.0";

      # Configuration requirements
      configuration = {
        required = [ ];
        optional = [
          "PLC_DIRECTORY_URL"
          "BUNDLE_DIR"
          "HTTP_HOST"
          "HTTP_PORT"
          "LOG_LEVEL"
        ];
      };

      plcbundle = {
        component = "plcbundle";
        description = "Cryptographic archiving and distribution of PLC Directory operations";
        capabilities = [
          "bundle-creation"
          "bundle-verification"
          "chain-integrity"
          "http-serving"
          "websocket-streaming"
          "spam-detection"
          "did-indexing"
        ];
        endpoints = {
          configurable = [ "plc-directory" ];
          defaults = {
            plc-directory = "https://plc.directory";
          };
        };
      };
    };

    organization = {
      name = "plcbundle";
      displayName = "PLC Bundle";
      website = "https://tangled.org/@atscan.net/plcbundle";
      contact = null;
      maintainer = "atscan.net";
      repository = "https://tangled.org/@atscan.net/plcbundle";
      packageCount = 1;
      atprotoFocus = [ "infrastructure" "archiving" "did-operations" ];
    };
  };

  meta = with lib; {
    description = "PLC Bundle - Cryptographic archiving of AT Protocol DID operations";
    longDescription = ''
      plcbundle is a format specification and implementation for archiving AT Protocol's
      DID PLC Directory operations into immutable, cryptographically-chained bundles.

      Key features:
      - Groups 10,000 operations into compressed, immutable files
      - Zstandard (zstd) compression with ~5x compression ratios
      - SHA-256 cryptographic hashing for integrity verification
      - Chainable bundles linking entire operation history
      - Efficient decompression and lazy loading
      - HTTP server for hosting and serving bundles
      - WebSocket streaming for real-time operation updates
      - Built-in spam detection framework
      - DID indexing for efficient searching
      - Reproducible bundles from PLC directory

      The Go implementation provides:
      - CLI tool for all bundle operations (fetch, clone, verify, serve)
      - Library for embedding in Go applications
      - HTTP server with WebSocket support
      - Parallel processing and efficient resource usage
      - Docker-ready deployment
    '';
    homepage = "https://tangled.org/@atscan.net/plcbundle";
    license = licenses.mit;
    platforms = platforms.unix; # Linux + macOS
    maintainers = [ ];
    mainProgram = "plcbundle";

    organizationalContext = {
      organization = "plcbundle";
      displayName = "PLC Bundle";
      needsMigration = false;
      migrationPriority = "high";
    };
  };
}
