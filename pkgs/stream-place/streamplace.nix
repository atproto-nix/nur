{ pkgs, buildGoModule, fetchFromTangled, ... }:

buildGoModule rec {
  pname = "streamplace";
  version = "unstable-2025-01-23";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@stream.place";
    repo = "streamplace";
    rev = "a40860f005ba4da989cfe1a5c39d29fa3564fea6";
    hash = "sha256-wfBeOrDGaY5+lHFGJ4fEUxA4ttMfECM7RByL9SSxF9I=";
    forceFetchGit = true;
  };

  vendorHash = pkgs.lib.fakeHash;
  
  # Complex multimedia dependencies
  nativeBuildInputs = with pkgs; [
    pkg-config
    go
  ];
  
  buildInputs = with pkgs; [
    # Video processing dependencies
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    
    # Multimedia libraries
    ffmpeg
    opencv
    
    # Database and storage
    postgresql
    sqlite
    
    # Networking and crypto
    openssl
    zstd
  ];
  
  # Build only the main server binary for now
  subPackages = [ "cmd/streamplace" ];
  
  # Skip tests due to complex multimedia dependencies
  doCheck = false;
  
  passthru = {
    atproto = {
      type = "application";
      services = [ "streamplace-server" ];
      protocols = [ "com.atproto" "app.bsky" ];
      schemaVersion = "1.0";
      complexity = "high"; # Complex multimedia dependencies
    };
    
    organization = {
      name = "stream-place";
      displayName = "Stream.place";
      website = "https://stream.place";
      contact = null;
      maintainer = "Stream.place";
      repository = "https://tangled.org/@stream.place/streamplace";
      packageCount = 1;
      atprotoFocus = [ "applications" ];
    };
  };
  
  meta = with pkgs.lib; {
    description = "Solving Video for Everybody Forever - ATProto-integrated video infrastructure";
    longDescription = ''
      Streamplace is a comprehensive video infrastructure platform with deep
      ATProto integration. It provides video streaming, processing, and
      distribution capabilities for the Bluesky network.

      Features:
      - GStreamer-based video processing pipeline
      - Livepeer integration for video transcoding
      - WebRTC and RTSP support
      - ATProto authentication and identity
      - Multi-modal media support (video, audio, images)
      - C2PA content authenticity support
      - Distributed video infrastructure

      Built with:
      - Go backend with extensive video libraries
      - GStreamer multimedia framework
      - PostgreSQL database
      - ATProto/Bluesky integration
      - Rust components for performance-critical paths

      Sponsored by Livepeer Treasury for open video infrastructure.

      Maintained by Stream.place (https://stream.place)

      Note: Complex multimedia dependencies (GStreamer, FFmpeg, OpenCV) may
      require additional system setup.
    '';
    homepage = "https://stream.place";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "streamplace";

    organizationalContext = {
      organization = "stream-place";
      displayName = "Stream.place";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}