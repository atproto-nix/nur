{ lib
, craneLib
, fetchFromGitHub
, pkg-config
, openssl
, postgresql
, zstd
, stdenv
}:

craneLib.buildPackage rec {
  pname = "allegedly";
  version = "0.3.3";

  src = fetchFromGitHub {
    owner = "microcosm-cc";
    repo = "allegedly";
    rev = "v${version}";
    hash = lib.fakeHash; # Placeholder - needs real hash
  };

  # Standard Rust environment for ATProto services
  env = {
    OPENSSL_NO_VENDOR = "1";
    ZSTD_SYS_USE_PKG_CONFIG = "1";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
    postgresql
    zstd
  ];

  # Build all binaries (allegedly, backfill, mirror)
  cargoExtraArgs = "--bins";
  
  # ATProto metadata
  passthru = {
    atproto = {
      type = "infrastructure";
      services = [ "plc-server" "plc-mirror" "plc-tools" ];
      protocols = [ "plc" "did:plc" ];
      schemaVersion = "1.0";
      
      # Dependencies on other ATProto packages
      atprotoDependencies = {
        # Can work with any PLC server implementation
      };
      
      # Configuration requirements
      configuration = {
        required = [ ];
        optional = [ 
          "ALLEGEDLY_WRAP_PG"
          "ALLEGEDLY_UPSTREAM"
          "ALLEGEDLY_WRAP"
          "ALLEGEDLY_ACME_DOMAIN"
          "ALLEGEDLY_ACME_CACHE_PATH"
          "ALLEGEDLY_ACME_DIRECTORY_URL"
        ];
      };
    };
    
    organization = {
      name = "microcosm-blue";
      displayName = "Microcosm";
      website = "https://tangled.org/@microcosm.blue/Allegedly";
      contact = null;
      maintainer = "microcosm.blue";
      repository = "https://github.com/microcosm-cc/allegedly";
      packageCount = 1;
      atprotoFocus = [ "infrastructure" "identity" ];
    };
  };

  meta = with lib; {
    description = "Public ledger server tools and services for the PLC (Public Ledger Consortium)";
    longDescription = ''
      Allegedly provides tools and services for working with PLC (Public Ledger Consortium)
      operations in the ATProto ecosystem. It can tail PLC operations, export them to
      bundles, run as a mirror server copying operations from upstream, and provide
      TLS termination with ACME certificate management.
      
      Key features:
      - Tail PLC operations to stdout for monitoring
      - Export PLC operations to weekly gzipped bundles
      - Mirror PLC servers with PostgreSQL backend
      - TLS termination with automatic ACME certificate provisioning
      - Rate limiting and reverse proxy capabilities
      
      Maintained by microcosm.blue
    '';
    homepage = "https://tangled.org/@microcosm.blue/Allegedly";
    license = with licenses; [ mit asl20 ];
    platforms = platforms.linux;
    maintainers = [ ];
    mainProgram = "allegedly";
    
    organizationalContext = {
      organization = "microcosm-blue";
      displayName = "Microcosm";
      needsMigration = false;
      migrationPriority = "high";
    };
  };
}