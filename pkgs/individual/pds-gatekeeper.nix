{ lib
, craneLib
, fetchgit
, pkg-config
, openssl
, sqlite
, zstd
, stdenv
}:

craneLib.buildPackage rec {
  pname = "pds-gatekeeper";
  version = "0.1.2";

  src = fetchgit {
    url = "https://tangled.org/@baileytownsend.dev/pds-gatekeeper";
    rev = "3d3b821be3a57544b67024353c43ba7f391a6ec1";
    hash = "sha256-JdhPDpEXzy6CovNGbIMQzzmRtuJoW5LvydpeDNFFpSs=";
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
    sqlite
    zstd
  ];

  # Build only the main binary
  cargoExtraArgs = "--bin pds_gatekeeper";

  # Copy email templates and other assets
  postInstall = ''
    # Create directories for templates and assets
    mkdir -p $out/share/pds-gatekeeper/email_templates
    
    # Copy email templates
    cp -r email_templates/* $out/share/pds-gatekeeper/email_templates/
    
    # Copy example configurations
    mkdir -p $out/share/pds-gatekeeper/examples
    if [ -d examples ]; then
      cp -r examples/* $out/share/pds-gatekeeper/examples/
    fi
  '';

  # ATProto metadata
  passthru = {
    atproto = {
      type = "application";
      services = [ "pds-gatekeeper" "pds-security" ];
      protocols = [ "com.atproto" ];
      schemaVersion = "1.0";
      
      # Dependencies on other ATProto packages
      atprotoDependencies = {
        # Requires a PDS to work with
      };
      
      # Configuration requirements
      configuration = {
        required = [ "PDS_DATA_DIRECTORY" ];
        optional = [ 
          "PDS_ENV_LOCATION"
          "GATEKEEPER_EMAIL_TEMPLATES_DIRECTORY"
          "GATEKEEPER_TWO_FACTOR_EMAIL_SUBJECT"
          "PDS_BASE_URL"
          "GATEKEEPER_HOST"
          "GATEKEEPER_PORT"
          "GATEKEEPER_CREATE_ACCOUNT_PER_SECOND"
          "GATEKEEPER_CREATE_ACCOUNT_BURST"
        ];
      };
    };
    
    organization = {
      name = "individual";
      displayName = "Individual Developers";
      website = null;
      contact = null;
      maintainer = "baileytownsend.dev";
      repository = "https://tangled.org/@baileytownsend.dev/pds-gatekeeper";
      packageCount = 1;
      atprotoFocus = [ "infrastructure" "tools" ];
    };
  };

  meta = with lib; {
    description = "Security microservice for ATProto PDS with 2FA and rate limiting";
    longDescription = ''
      PDS Gatekeeper is a microservice that adds security features to ATProto PDS
      installations, including two-factor authentication, rate limiting, and
      enhanced account creation controls. It works by intercepting specific PDS
      endpoints through a reverse proxy configuration.
      
      Maintained by baileytownsend.dev
    '';
    homepage = "https://tangled.org/@baileytownsend.dev/pds-gatekeeper";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "pds_gatekeeper";
    
    organizationalContext = {
      organization = "individual";
      displayName = "Individual Developers";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}