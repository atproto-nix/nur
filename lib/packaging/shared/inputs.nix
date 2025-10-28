# Standard build inputs for ATProto builds
#
# This module defines native build inputs and build inputs that are commonly
# needed across the ATProto ecosystem for different languages.
#
# Usage:
#   inherit (packaging.shared.inputs) standardNativeInputs standardBuildInputs;

{ lib, pkgs, ... }:

{
  # Standard native build inputs for all ATProto services
  # These are tools needed during the build process
  standardNativeInputs = with pkgs; [
    pkg-config
    perl
  ];

  # Standard build inputs for all ATProto services
  # These are libraries needed to link against
  standardBuildInputs = with pkgs; [
    zstd
    lz4
    rocksdb
    openssl
    sqlite
    postgresql
  ];

  # Rust-specific native inputs
  standardRustNativeInputs = with pkgs; [
    pkg-config
    perl
  ];

  # Rust-specific build inputs
  standardRustBuildInputs = with pkgs; [
    zstd
    lz4
    rocksdb
    openssl
    sqlite
    postgresql
  ];

  # Node.js-specific native inputs
  standardNodeNativeInputs = with pkgs; [
    nodejs
    python3
  ];

  # Node.js-specific build inputs
  standardNodeBuildInputs = with pkgs; [
    openssl
    sqlite
  ];

  # Go-specific native inputs
  standardGoNativeInputs = with pkgs; [
    pkg-config
    git
  ];

  # Go-specific build inputs
  standardGoBuildInputs = with pkgs; [
    openssl
    sqlite
    zlib
  ];

  # Deno-specific native inputs
  standardDenoNativeInputs = with pkgs; [
    deno
    cacert  # Required for HTTPS imports
  ];

  # Deno-specific build inputs (empty for now, can be extended)
  standardDenoBuildInputs = with pkgs; [];

  # Create combined inputs for a language
  #
  # Example:
  #   mkLanguageInputs "rust" { extraNative = [ myTool ]; }
  mkLanguageInputs = language: { extraNative ? [], extraBuild ? [], ... }:
    if language == "rust" then {
      nativeBuildInputs = standardRustNativeInputs ++ extraNative;
      buildInputs = standardRustBuildInputs ++ extraBuild;
    }
    else if language == "nodejs" then {
      nativeBuildInputs = standardNodeNativeInputs ++ extraNative;
      buildInputs = standardNodeBuildInputs ++ extraBuild;
    }
    else if language == "go" then {
      nativeBuildInputs = standardGoNativeInputs ++ extraNative;
      buildInputs = standardGoBuildInputs ++ extraBuild;
    }
    else if language == "deno" then {
      nativeBuildInputs = standardDenoNativeInputs ++ extraNative;
      buildInputs = standardDenoBuildInputs ++ extraBuild;
    }
    else
      throw "Unknown language: ${language}";
}
