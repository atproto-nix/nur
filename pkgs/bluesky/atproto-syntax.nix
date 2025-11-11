# @atproto/syntax - ATproto syntax validation and parsing utilities
{ lib, stdenv, fetchFromGitHub, ... }:

stdenv.mkDerivation rec {
  pname = "atproto-syntax";
  version = "0.3.4";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "atproto";
    rev = "c518cf4f62659d9cf585da6f29b67f8a77d0fbc0";
    sha256 = "sha256-fW9BKtG9vptNYzCh/AWf8m9QoPEGX6najSFlAekElHA=";
  };

  sourceRoot = "${src.name}/packages/syntax";

  # No build phase needed - this is a source package
  dontBuild = true;

  # Don't check for broken symlinks since this package has test symlinks
  dontCheckForBrokenSymlinks = true;

  # Install the source package
  installPhase = ''
    runHook preInstall
    
    # Create output directory structure
    mkdir -p $out/lib/node_modules/@atproto/syntax
    
    # Copy all source files
    cp -r . $out/lib/node_modules/@atproto/syntax/
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "ATproto syntax validation and parsing utilities";
    longDescription = ''
      The @atproto/syntax package provides syntax validation and parsing
      utilities for ATproto identifiers and URIs. It includes AT-URI parsing,
      handle validation, and NSID (Namespaced Identifier) utilities.
    '';
    homepage = "https://github.com/bluesky-social/atproto/tree/main/packages/syntax";
    license = licenses.mit;
    maintainers = [ "atproto-team" ];
    platforms = platforms.all;
    
    # ATproto-specific metadata
    atproto = {
      category = "library";
      services = [ "syntax-validation" "uri-parsing" ];
      protocols = [ "atproto" "at-uri" ];
      dependencies = [ ];
      tier = 1;
    };
  };
}