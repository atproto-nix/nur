# @atproto/did - ATproto DID (Decentralized Identifier) utilities
{ lib, stdenv, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  pname = "atproto-did";
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "atproto";
    rev = "c518cf4f62659d9cf585da6f29b67f8a77d0fbc0";
    sha256 = "sha256-fW9BKtG9vptNYzCh/AWf8m9QoPEGX6najSFlAekElHA=";
  };

  sourceRoot = "${src.name}/packages/did";

  # No build phase needed - this is a source package
  dontBuild = true;

  # Install the source package
  installPhase = ''
    runHook preInstall
    
    # Create output directory structure
    mkdir -p $out/lib/node_modules/@atproto/did
    
    # Copy all source files
    cp -r . $out/lib/node_modules/@atproto/did/
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "ATproto DID (Decentralized Identifier) utilities";
    longDescription = ''
      The @atproto/did package provides utilities for working with Decentralized
      Identifiers (DIDs) in the ATproto ecosystem. It includes DID resolution,
      validation, and document management.
    '';
    homepage = "https://github.com/bluesky-social/atproto/tree/main/packages/did";
    license = licenses.mit;
    maintainers = [ "atproto-team" ];
    platforms = platforms.all;
    
    # ATproto-specific metadata
    atproto = {
      category = "library";
      services = [ "did-resolution" "identity" ];
      protocols = [ "did" "plc" ];
      dependencies = [ ];
      tier = 1;
    };
  };
}