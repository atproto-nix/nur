# JavaScript bundlers module
#
# Re-exports all bundler-specific functions

{ lib, pkgs, ... }:

let
  vite = import ./vite.nix { inherit lib pkgs; };
in

{
  inherit (vite)
    viteDeterminismEnv
    applyViteDeterminismControls
    buildWithViteOffline
    testViteDeterminism;
}
