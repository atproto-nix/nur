# @atproto/identity - ATproto identity resolution and management
{ lib, buildNpmPackage, fetchFromGitHub, ... }:

buildNpmPackage rec {
  pname = "atproto-identity";
  version = "0.4.8";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "atproto";
    rev = "c518cf4f62659d9cf585da6f29b67f8a77d0fbc0";
    sha256 = "sha256-0w4l0klh2r91ipdajpq6y6h50vzjkw2zr89hcd6rpgmxs4m42vvx";
  };

  sourceRoot = "${src.name}/packages/identity";

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
    mkdir -p $out/lib/node_modules/@atproto/identity
    
    # Copy package files
    cp -r dist/* $out/lib/node_modules/@atproto/identity/
    cp package.json $out/lib/node_modules/@atproto/identity/
    
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