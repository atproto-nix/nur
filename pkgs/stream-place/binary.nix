{ pkgs, fetchurl, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "streamplace-binary";
  version = "0.8.9";

  src = fetchurl {
    url = "https://git.stream.place/streamplace/streamplace/-/releases/v${version}/downloads/streamplace-v${version}-linux-amd64.tar.gz";
    sha256 = "sha256-gRvqHdWx3OhWvQKkQUzq5c7Y9mK2bL5nJ8pQ0vW1xR4="; # Update with actual hash
  };

  sourceRoot = ".";

  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    glib
  ];

  buildInputs = with pkgs; [
    # Runtime dependencies for the binary
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    ffmpeg
    openssl
    zstd
    postgresql
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp streamplace $out/bin/streamplace-server
    chmod +x $out/bin/streamplace-server
  '';

  passthru = {
    atproto = {
      type = "application";
      variant = "binary";
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
    description = "Streamplace (prebuilt binary) - ATProto-integrated video infrastructure";
    longDescription = ''
      Streamplace binary release of the comprehensive video infrastructure
      platform with deep ATProto integration.

      This is the prebuilt binary variant - for faster installation but
      less flexibility. Use streamplace-source for source builds.

      Features:
      - GStreamer-based video processing pipeline
      - Livepeer integration for video transcoding
      - WebRTC and RTSP support
      - ATProto authentication and identity
      - Multi-modal media support (video, audio, images)
      - C2PA content authenticity support
      - Distributed video infrastructure

      Sponsored by Livepeer Treasury for open video infrastructure.

      Maintained by Stream.place (https://stream.place)

      Note: Complex multimedia dependencies (GStreamer, FFmpeg, OpenCV) may
      require additional system setup.
    '';
    homepage = "https://stream.place";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
    mainProgram = "streamplace-server";

    organizationalContext = {
      organization = "stream-place";
      displayName = "Stream.place";
      variant = "binary";
      needsMigration = false;
      migrationPriority = "medium";
    };
  };
}
