{ pkgs, lib, buildGoModule, fetchFromTangled, ... }:

buildGoModule rec {
  pname = "cocoon";
  version = "0.1.0";

  src = fetchFromTangled {
    domain = "tangled.sh";
    owner = "@hailey.at";
    repo = "cocoon";
    rev = "5a6fbfab88f0c811b708c08b334cd56716081963";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Temporary - will be replaced with actual hash from build error
  };

  vendorHash = "sha256-1xrrlawk7klfiy0rj04ch1k2191gd2qkvckx3pppgb8mw09wqsg5";

  # Build the main cocoon binary
  subPackages = [ "cmd/cocoon" ];

  # Don't run tests during build
  doCheck = false;

  # Required for building
  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [
    sqlite
  ];

  # Set build flags
  ldflags = [
    "-s"
    "-w"
  ];

  passthru = {
    atproto = {
      type = "infrastructure";
      services = [ "pds" ];
      protocols = [ "com.atproto" ];
      schemaVersion = "1.0";
      description = "Personal Data Server (PDS) implementation in Go";
      status = "active";
    };

    organization = {
      name = "hailey.at";
      displayName = "Hailey (hailey.at)";
      website = "https://tangled.sh/@hailey.at/cocoon";
      contact = "@hailey.at";
      maintainer = "Hailey";
      repository = "https://tangled.sh/@hailey.at/cocoon";
      packageCount = 1;
      atprotoFocus = [ "infrastructure" "pds" ];
    };
  };

  meta = with lib; {
    description = "Cocoon - Personal Data Server (PDS) implementation in Go";
    longDescription = ''
      Cocoon is a Personal Data Server (PDS) implementation in Go for the AT Protocol.
      It allows you to host your own Bluesky/ATProto account and data.

      Features:
      - Full account creation and management
      - Repository operations (create, update, delete records)
      - Identity management (DID, handle resolution)
      - Sync protocol (subscribeRepos for relay)
      - SQLite blockstore
      - Optional S3 storage for blobs/backups
      - Optional SMTP email support
      - Built-in web UI
    '';
    homepage = "https://tangled.sh/@hailey.at/cocoon";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];

    organizationalContext = {
      organization = "hailey.at";
      displayName = "Hailey (hailey.at)";
      needsMigration = false;
      migrationPriority = "n/a";
    };
  };
}
