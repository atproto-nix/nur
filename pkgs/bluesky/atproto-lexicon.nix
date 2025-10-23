# @atproto/lexicon - ATproto lexicon schema validation and utilities
{ lib, stdenv, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  pname = "atproto-lexicon";
  version = "0.4.12";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "atproto";
    rev = "c518cf4f62659d9cf585da6f29b67f8a77d0fbc0";
    sha256 = "sha256-fW9BKtG9vptNYzCh/AWf8m9QoPEGX6najSFlAekElHA=";
  };

  sourceRoot = "${src.name}/packages/lexicon";

  # No build phase needed - this is a source package
  dontBuild = true;

  # Install the source package
  installPhase = ''
    runHook preInstall
    
    # Create output directory structure
    mkdir -p $out/lib/node_modules/@atproto/lexicon
    
    # Copy all source files
    cp -r . $out/lib/node_modules/@atproto/lexicon/
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "ATproto lexicon schema validation and utilities";
    longDescription = ''
      The @atproto/lexicon package provides schema validation and utilities
      for ATproto lexicons. It includes lexicon parsing, validation, and
      code generation capabilities.
    '';
    homepage = "https://github.com/bluesky-social/atproto/tree/main/packages/lexicon";
    license = licenses.mit;
    maintainers = [ "atproto-team" ];
    platforms = platforms.all;
    
    # ATproto-specific metadata
    atproto = {
      category = "library";
      services = [ "lexicon-validation" ];
      protocols = [ "lexicon" ];
      dependencies = [ ];
      tier = 1;
    };
  };
}