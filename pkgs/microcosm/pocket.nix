{ pkgs, craneLib, src, cargoArtifacts, nativeBuildInputs, buildInputs, commonEnv, tarFlags }:

craneLib.buildPackage {
  inherit src cargoArtifacts nativeBuildInputs buildInputs tarFlags;
  env = commonEnv;
  pname = "pocket";
  version = "0.1.0";
  cargoExtraArgs = "--package pocket";
}