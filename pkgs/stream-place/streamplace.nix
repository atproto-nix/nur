{ pkgs, buildGoModule, fetchgit, ... }:

buildGoModule rec {
  pname = "streamplace";
  version = "0.1.0";
  
  src = fetchgit {
    url = "https://tangled.org/@stream.place/streamplace";
    rev = "167ae0c640c8c338393f4c91409d5a0048b82bb6";
    sha256 = "1yahp3qb2rzrrqbkgj6s8kbl9aaxwphagrd0ah4d7928kyfgq2dk";
  };
  
  vendorHash = "sha256-MeKpycGxUnYyGPhkoxH/rgdudBB+zY2YcVpoic8zPXA=";
  
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
  
  passthru.atproto = {
    type = "application";
    services = [ "streamplace-server" ];
    protocols = [ "com.atproto" "app.bsky" ];
    schemaVersion = "1.0";
    complexity = "high"; # Complex multimedia dependencies
  };
  
  meta = with pkgs.lib; {
    description = "Video infrastructure platform with ATProto integration";
    homepage = "https://stream.place";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    # Note: Complex multimedia dependencies may require additional system setup
  };
}