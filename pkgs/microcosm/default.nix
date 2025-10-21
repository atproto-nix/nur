{ pkgs, craneLib, ... }:

let
  # Import ATProto utilities
  atprotoLib = pkgs.callPackage ../../lib/atproto.nix { inherit craneLib; };
  
  src = pkgs.fetchFromGitHub {
    owner = "at-microcosm";
    repo = "microcosm-rs";
    rev = "b0a66a102261d0b4e8a90d34cec3421073a7b728";
    sha256 = "sha256-swdAcsjRWnj9abmnrce5LzeKRK+LHm8RubCEIuk+53c=";
  };

  commonEnv = {
    # Additional environment variables specific to microcosm
  };
  cargoArtifacts = craneLib.buildDepsOnly {
    inherit src;
    pname = "microcosm-rs-deps";
    version = "0.1.0";
    env = atprotoLib.defaultRustEnv // commonEnv;
    nativeBuildInputs = atprotoLib.defaultRustNativeInputs;
    buildInputs = atprotoLib.defaultRustBuildInputs;
    tarFlags = "--no-same-owner";
  };

  members = [
    "constellation"
    "ufos"
    "ufos/fuzz"
    "spacedust"
    "who-am-i"
    "slingshot"
    "quasar"
    "pocket"
    "reflector"
  ];
  buildPackage = member:
    let
      packageName = if member == "ufos/fuzz" then "ufos-fuzz" else member;
    in
    atprotoLib.mkRustAtprotoService {
      pname = packageName;
      version = "0.1.0";
      inherit src cargoArtifacts;
      cargoExtraArgs = "--package ${packageName}";
      description = "Microcosm ATProto service: ${packageName}";
      longDescription = ''
        ${packageName} is part of the Microcosm ATProto service collection.
        Note: jetstream and links are library-only packages and not included as standalone services.
      '';
      services = [ packageName ];
      env = commonEnv;
    };

  packages = pkgs.lib.genAttrs members (member: buildPackage member);

in
packages
