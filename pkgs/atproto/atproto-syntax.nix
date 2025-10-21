# @atproto/syntax - ATproto syntax validation and parsing utilities
{ lib, buildNpmPackage, fetchFromGitHub, ... }:

buildNpmPackage rec {
  pname = "atproto-syntax";
  version = "0.3.4";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "atproto";
    rev = "c518cf4f62659d9cf585da6f29b67f8a77d0fbc0";
    sha256 = "sha256-0w4l0klh2r91ipdajpq6y6h50vzjkw2zr89hcd6rpgmxs4m42vvx";
  };

  sourceRoot = "${src.name}/packages/syntax";

  npmDepsHash = lib.fakeHash;

  # Don't run build during npm install phase
  dontNpmBuild = true;

  # Build the package
  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';

  # Install the built package
  installPhase = ''
    runHook preInstall
    
    # Create output directory structure
    mkdir -p $out/lib/node_modules/@atproto/syntax
    
    # Copy package files
    cp -r dist/* $out/lib/node_modules/@atproto/syntax/
    cp package.json $out/lib/node_modules/@atproto/syntax/
    
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