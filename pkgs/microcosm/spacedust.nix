{ pkgs, craneLib, src, cargoArtifacts, nativeBuildInputs, buildInputs, commonEnv, tarFlags }:

craneLib.buildPackage {
  inherit src cargoArtifacts nativeBuildInputs buildInputs tarFlags;
  env = commonEnv;
  pname = "spacedust";
  version = "0.1.0";
  cargoExtraArgs = "--package spacedust";
}