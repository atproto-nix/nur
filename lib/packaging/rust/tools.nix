# Rust build utilities and tools
#
# This module provides utility functions for Rust builds that don't fit
# in the main crane builder, including workspace helpers and testing utilities.
#
# Usage:
#   inherit (packaging.rust.tools) createRustVersion validateCargo;

{ lib, pkgs, ... }:

let
  shared = import ../shared { inherit lib pkgs; };
in

{
  # Create version information from git revision
  #
  # Example:
  #   createRustVersion "abc123def..." "1.0.0"
  #   # → { version = "1.0.0"; commit = "abc123def..."; };
  createRustVersion = rev: version:
    {
      inherit version rev;
      short_rev = lib.substring 0 8 rev;
    };

  # Get standard Rust build flags for linking
  #
  # Example:
  #   getRustLdFlags "1.0.0" "abc123def..."
  getRustLdFlags = version: rev:
    [
      "-s" "-w"  # Strip symbols and debug info (smaller binary)
      "-X main.version=${version}"
      "-X main.commit=${rev}"
    ];

  # Check if Cargo.lock is properly committed (important for reproducibility)
  validateCargoLock = src:
    if !(builtins.pathExists "${src}/Cargo.lock") then
      throw "Cargo.lock not found in ${src}. Workspace builds require pinned dependencies."
    else
      true;

  # Extract workspace members from Cargo.toml
  # This is a simplified parser - full TOML parsing would be more robust
  #
  # Example:
  #   extractWorkspaceMembers src
  extractWorkspaceMembers = src:
    let
      cargoToml = builtins.readFile "${src}/Cargo.toml";
      # Look for [workspace] section and members array
      # This is a simplified heuristic and may not work for all formats
      hasWorkspaceSection = lib.hasInfix "[workspace]" cargoToml;
    in
    if hasWorkspaceSection then []  # Would need proper TOML parsing
    else [];

  # Create a test configuration for a workspace member
  #
  # Example:
  #   mkTestConfig {
  #     packageName = "myapp";
  #     doCheck = true;
  #     cargoTestCommand = "cargo test --package myapp";
  #   }
  mkTestConfig = { packageName, doCheck ? true, cargoTestCommand ? null, ... }:
    {
      inherit packageName doCheck;
      cargoTestCommand = cargoTestCommand or "cargo test --package ${packageName} --release";
    };

  # Create a build configuration for a workspace member
  #
  # Example:
  #   mkBuildConfig {
  #     packageName = "myapp";
  #     cargoBuildCommand = "cargo build --package myapp --release --all-features";
  #   }
  mkBuildConfig = { packageName, cargoBuildCommand ? null, ... }:
    {
      inherit packageName;
      cargoBuildCommand = cargoBuildCommand or "cargo build --package ${packageName} --release";
    };

  # Create metadata for a Rust package
  #
  # Example:
  #   mkRustMetadata {
  #     name = "myapp";
  #     description = "My Rust application";
  #     mainProgram = "myapp";
  #   }
  mkRustMetadata = { name, description ? null, mainProgram ? null, ... }:
    {
      description = description or "Rust package: ${name}";
      mainProgram = mainProgram or name;
      platforms = lib.platforms.unix;
    };

  # Detect Rust version from toolchain.toml or rust-toolchain
  detectRustVersion = src:
    if builtins.pathExists "${src}/rust-toolchain.toml" then
      let
        content = builtins.readFile "${src}/rust-toolchain.toml";
      in
      if lib.hasInfix "channel = " content then
        "unknown"  # Would need TOML parsing
      else
        "stable"
    else if builtins.pathExists "${src}/rust-toolchain" then
      builtins.readFile "${src}/rust-toolchain"
    else
      "stable";

  # Check if a Rust project uses workspace layout
  isWorkspaceProject = src:
    builtins.pathExists "${src}/Cargo.toml" && (
      let
        cargoToml = builtins.readFile "${src}/Cargo.toml";
      in
      lib.hasInfix "[workspace]" cargoToml
    );

  # Check if a Rust project uses virtual workspace
  isVirtualWorkspace = src:
    builtins.pathExists "${src}/Cargo.toml" && (
      let
        cargoToml = builtins.readFile "${src}/Cargo.toml";
      in
      lib.hasInfix "[workspace]" cargoToml && !lib.hasInfix "[package]" cargoToml
    );
}
