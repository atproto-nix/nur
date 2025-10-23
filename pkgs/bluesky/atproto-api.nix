# @atproto/api - Core ATproto API client library
{ lib, stdenv, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  pname = "atproto-api";
  version = "0.17.3";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "atproto";
    rev = "c518cf4f62659d9cf585da6f29b67f8a77d0fbc0";
    sha256 = "sha256-fW9BKtG9vptNYzCh/AWf8m9QoPEGX6najSFlAekElHA=";
  };

  sourceRoot = "${src.name}/packages/api";

  # No build phase needed - this is a source package
  dontBuild = true;

  # Install the source package
  installPhase = ''
    runHook preInstall
    
    # Create output directory structure
    mkdir -p $out/lib/node_modules/@atproto/api
    
    # Copy all source files
    cp -r . $out/lib/node_modules/@atproto/api/
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "ATproto API client library for TypeScript/JavaScript";
    longDescription = ''
      The @atproto/api package provides a TypeScript/JavaScript client library
      for interacting with ATproto services. It includes methods for authentication,
      data operations, and protocol-level interactions.
    '';
    homepage = "https://github.com/bluesky-social/atproto/tree/main/packages/api";
    license = licenses.mit;
    maintainers = [ "atproto-team" ];
    platforms = platforms.all;
    
    # ATproto-specific metadata
    atproto = {
      category = "library";
      services = [ "api-client" ];
      protocols = [ "xrpc" "atproto" ];
      dependencies = [ ];
      tier = 1;
    };
  };
}