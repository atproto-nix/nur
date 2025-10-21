# @atproto/xrpc - ATproto XRPC client and server utilities
{ lib, stdenv, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  pname = "atproto-xrpc";
  version = "0.6.4";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "atproto";
    rev = "c518cf4f62659d9cf585da6f29b67f8a77d0fbc0";
    sha256 = "sha256-fW9BKtG9vptNYzCh/AWf8m9QoPEGX6najSFlAekElHA=";
  };

  sourceRoot = "${src.name}/packages/xrpc";

  # No build phase needed - this is a source package
  dontBuild = true;

  # Install the source package
  installPhase = ''
    runHook preInstall
    
    # Create output directory structure
    mkdir -p $out/lib/node_modules/@atproto/xrpc
    
    # Copy all source files
    cp -r . $out/lib/node_modules/@atproto/xrpc/
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "ATproto XRPC client and server utilities";
    longDescription = ''
      The @atproto/xrpc package provides XRPC (Cross-Language RPC) client
      and server utilities for ATproto. It handles HTTP-based RPC communication
      with proper authentication and error handling.
    '';
    homepage = "https://github.com/bluesky-social/atproto/tree/main/packages/xrpc";
    license = licenses.mit;
    maintainers = [ "atproto-team" ];
    platforms = platforms.all;
    
    # ATproto-specific metadata
    atproto = {
      category = "library";
      services = [ "xrpc-client" "xrpc-server" ];
      protocols = [ "xrpc" "http" ];
      dependencies = [ ];
      tier = 1;
    };
  };
}