# @atproto/repo - ATproto repository and data structure utilities
{ lib, buildNpmPackage, fetchFromGitHub, ... }:

buildNpmPackage rec {
  pname = "atproto-repo";
  version = "0.7.3";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "atproto";
    rev = "c518cf4f62659d9cf585da6f29b67f8a77d0fbc0";
    sha256 = "sha256-0w4l0klh2r91ipdajpq6y6h50vzjkw2zr89hcd6rpgmxs4m42vvx";
  };

  sourceRoot = "${src.name}/packages/repo";

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
    mkdir -p $out/lib/node_modules/@atproto/repo
    
    # Copy package files
    cp -r dist/* $out/lib/node_modules/@atproto/repo/
    cp package.json $out/lib/node_modules/@atproto/repo/
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "ATproto repository and data structure utilities";
    longDescription = ''
      The @atproto/repo package provides utilities for working with ATproto
      repositories and data structures. It includes MST (Merkle Search Tree)
      operations, commit handling, and repository management.
    '';
    homepage = "https://github.com/bluesky-social/atproto/tree/main/packages/repo";
    license = licenses.mit;
    maintainers = [ "atproto-team" ];
    platforms = platforms.all;
    
    # ATproto-specific metadata
    atproto = {
      category = "library";
      services = [ "repository" "data-structures" ];
      protocols = [ "atproto" "car" "cbor" ];
      dependencies = [ ];
      tier = 1;
    };
  };
}