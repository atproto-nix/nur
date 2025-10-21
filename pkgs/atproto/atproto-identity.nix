# @atproto/identity - ATproto identity resolution and management
{ lib, stdenv, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  pname = "atproto-identity";
  version = "0.4.8";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "atproto";
    rev = "c518cf4f62659d9cf585da6f29b67f8a77d0fbc0";
    sha256 = "sha256-fW9BKtG9vptNYzCh/AWf8m9QoPEGX6najSFlAekElHA=";
  };

  sourceRoot = "${src.name}/packages/identity";

  # No build phase needed - this is a source package
  dontBuild = true;

  # Install the source package
  installPhase = ''
    runHook preInstall
    
    # Create output directory structure
    mkdir -p $out/lib/node_modules/@atproto/identity
    
    # Copy all source files
    cp -r . $out/lib/node_modules/@atproto/identity/
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "ATproto identity resolution and management utilities";
    longDescription = ''
      The @atproto/identity package provides identity resolution and management
      utilities for ATproto. It includes handle resolution, DID-to-handle mapping,
      and identity verification capabilities.
    '';
    homepage = "https://github.com/bluesky-social/atproto/tree/main/packages/identity";
    license = licenses.mit;
    maintainers = [ "atproto-team" ];
    platforms = platforms.all;
    
    # ATproto-specific metadata
    atproto = {
      category = "library";
      services = [ "identity-resolution" "handle-resolution" ];
      protocols = [ "did" "dns" "http" ];
      dependencies = [ ];
      tier = 1;
    };
  };
}