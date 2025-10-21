# @atproto/lexicon - ATproto lexicon schema validation and utilities
{ lib, buildNpmPackage, fetchFromGitHub, ... }:

buildNpmPackage rec {
  pname = "atproto-lexicon";
  version = "0.4.12";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "atproto";
    rev = "c518cf4f62659d9cf585da6f29b67f8a77d0fbc0";
    sha256 = "sha256-0w4l0klh2r91ipdajpq6y6h50vzjkw2zr89hcd6rpgmxs4m42vvx";
  };

  sourceRoot = "${src.name}/packages/lexicon";

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
    mkdir -p $out/lib/node_modules/@atproto/lexicon
    
    # Copy package files
    cp -r dist/* $out/lib/node_modules/@atproto/lexicon/
    cp package.json $out/lib/node_modules/@atproto/lexicon/
    
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