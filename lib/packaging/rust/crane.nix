# Rust packaging via Crane builder
#
# This module provides functions for building Rust packages using Crane,
# optimized for ATProto ecosystem with shared dependency caching
# and multi-package workspace support.
#
# Usage:
#   inherit (packaging.rust) buildRustAtprotoPackage buildRustWorkspace;

{ lib, pkgs, craneLib, ... }:

let
  shared = import ../shared { inherit lib pkgs; };

  # Merge Rust-specific environment and standard ATProto environment
  mkRustEnv = baseEnv: extraEnv:
    shared.standardEnv // shared.standardRustEnv // baseEnv // extraEnv;
in

{
  # Build a single Rust package with ATProto-specific configuration
  #
  # Example:
  #   buildRustAtprotoPackage {
  #     src = fetchFromGitHub { ... };
  #     cargoToml = ./Cargo.toml;  # Optional
  #     extraEnv = { MY_VAR = "value"; };
  #   }
  buildRustAtprotoPackage = { src, cargoToml ? null, extraEnv ? {}, ... }@args:
    let
      # Remove packaging-specific arguments from crane arguments
      craneArgs = builtins.removeAttrs args [ "extraEnv" "cargoToml" ];

      # Merge environments: standard → rust-specific → extra
      finalEnv = mkRustEnv {} extraEnv;

      # Standard configuration
      standardArgs = {
        env = finalEnv;
        nativeBuildInputs = shared.standardRustNativeInputs ++ (args.nativeBuildInputs or []);
        buildInputs = shared.standardRustBuildInputs ++ (args.buildInputs or []);
        tarFlags = "--no-same-owner";
      };

      # Merge all arguments
      finalArgs = standardArgs // craneArgs;
    in
    craneLib.buildPackage finalArgs;

  # Build a Rust workspace with shared dependency caching
  #
  # This function builds a Cargo workspace efficiently by:
  # 1. Computing shared cargoArtifacts once
  # 2. Reusing artifacts across all workspace members
  # 3. Handling multi-package builds with proper caching
  #
  # Example:
  #   buildRustWorkspace {
  #     owner = "atproto";
  #     repo = "atproto";
  #     rev = "abc123def...";
  #     sha256 = "sha256-...";
  #     members = [ "package1" "package2" "package3" ];
  #     memberConfigs = {
  #       "package1" = {
  #         doCheck = true;
  #         cargoTestCommand = "cargo test --package package1 --release";
  #       };
  #     };
  #   }
  buildRustWorkspace = { owner, repo, rev, sha256, members, commonEnv ? {}, ... }@args:
    let
      src = pkgs.fetchFromGitHub {
        inherit owner repo rev sha256;
      };

      workspaceName = args.pname or repo;

      # Validate that all members exist
      validateMembers =
        let
          cargoToml = builtins.readFile "${src}/Cargo.toml";
          missingMembers = lib.filter (member:
            !(lib.hasInfix "\"${member}\"" cargoToml || lib.hasInfix "'${member}'" cargoToml)
          ) members;
        in
        if missingMembers != [] then
          throw "Missing workspace members in ${workspaceName}: ${lib.concatStringsSep ", " missingMembers}"
        else
          true;

      # Shared dependency artifacts - built once, reused for all members
      cargoArtifacts = craneLib.buildDepsOnly {
        inherit src;
        pname = "${workspaceName}-deps";
        version = args.version or "0.1.0";
        env = mkRustEnv commonEnv {
          # Enhanced caching for workspace builds
          CARGO_INCREMENTAL = "0";
          CARGO_NET_RETRY = "10";
          CARGO_NET_TIMEOUT = "60";
        };
        nativeBuildInputs = shared.standardRustNativeInputs ++ (args.commonNativeInputs or []);
        buildInputs = shared.standardRustBuildInputs ++ (args.commonBuildInputs or []);
        tarFlags = "--no-same-owner";

        # Improved dependency resolution
        cargoVendorDir = args.cargoVendorDir or null;
        cargoLock = args.cargoLock or "${src}/Cargo.lock";

        # Enhanced build configuration
        buildPhaseCargoCommand = args.buildPhaseCargoCommand or "cargo build --workspace --release --all-features";

        # Skip tests for dependency builds
        doCheck = false;
      };

      # Build individual workspace member
      buildMember = member:
        let
          # Handle special naming cases and path normalization
          packageName = if lib.hasInfix "/" member then
            lib.replaceStrings ["/"] ["-"] member
          else
            member;

          # Member-specific configuration
          memberConfig = args.memberConfigs.${member} or {};
        in
        craneLib.buildPackage ({
          inherit src cargoArtifacts;
          pname = packageName;
          version = args.version or "0.1.0";
          cargoExtraArgs = "--package ${member}";
          env = mkRustEnv commonEnv (memberConfig.env or {});
          nativeBuildInputs = shared.standardRustNativeInputs ++ (args.commonNativeInputs or []) ++ (memberConfig.nativeBuildInputs or []);
          buildInputs = shared.standardRustBuildInputs ++ (args.commonBuildInputs or []) ++ (memberConfig.buildInputs or []);
          tarFlags = "--no-same-owner";

          # Enhanced build configuration
          cargoTestCommand = memberConfig.cargoTestCommand or "cargo test --package ${member} --release";
          cargoBuildCommand = memberConfig.cargoBuildCommand or "cargo build --package ${member} --release";

          # Better check configuration
          doCheck = memberConfig.doCheck or true;
          checkPhase = memberConfig.checkPhase or null;

          # Enhanced metadata
          meta = (args.meta or {}) // (memberConfig.meta or {}) // {
            description = (args.memberDescriptions or {}).${member} or memberConfig.description or "ATproto service: ${member}";
            mainProgram = memberConfig.mainProgram or packageName;
          };
        } // (builtins.removeAttrs memberConfig ["env" "nativeBuildInputs" "buildInputs" "meta" "description"]));
    in
    assert validateMembers;
    lib.genAttrs members buildMember;

  # Validate workspace structure before building
  # Useful for catching configuration errors early
  validateWorkspace = { src, members, ... }:
    let
      cargoToml = builtins.readFile "${src}/Cargo.toml";
      missingMembers = lib.filter (member:
        !(lib.hasInfix "\"${member}\"" cargoToml || lib.hasInfix "'${member}'" cargoToml)
      ) members;
    in
    if missingMembers != [] then
      throw "Missing workspace members: ${lib.concatStringsSep ", " missingMembers}"
    else
      true;
}
