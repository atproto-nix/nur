# Rust packaging module
#
# Re-exports all Rust-related functions for easy access

{ lib, pkgs, craneLib, ... }:

let
  crane = import ./crane.nix { inherit lib pkgs craneLib; };
  tools = import ./tools.nix { inherit lib pkgs; };
in

{
  inherit (crane)
    buildRustAtprotoPackage
    buildRustWorkspace
    validateWorkspace;

  inherit (tools)
    createRustVersion
    getRustLdFlags
    validateCargoLock
    extractWorkspaceMembers
    mkTestConfig
    mkBuildConfig
    mkRustMetadata
    detectRustVersion
    isWorkspaceProject
    isVirtualWorkspace;
}
