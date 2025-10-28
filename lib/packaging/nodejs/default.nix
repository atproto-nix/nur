# Node.js packaging module
#
# Re-exports all Node.js-related functions for easy access

{ lib, pkgs, buildNpmPackage ? pkgs.buildNpmPackage, ... }:

let
  npm = import ./npm.nix { inherit lib pkgs buildNpmPackage; };
  pnpm = import ./pnpm.nix { inherit lib pkgs buildNpmPackage; };
  bundlers = import ./bundlers { inherit lib pkgs; };
in

{
  inherit (npm)
    buildNpmPackage
    buildNpmWithFOD;

  inherit (pnpm)
    buildPnpmWorkspace;

  # Bundlers
  bundlers = {
    inherit (bundlers)
      viteDeterminismEnv
      applyViteDeterminismControls
      buildWithViteOffline
      testViteDeterminism;
  };
}
