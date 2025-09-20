{ pkgs, craneLib }:

let
  src = pkgs.fetchFromGitHub {
    owner = "at-microcosm";
    repo = "microcosm-rs";
    rev = "b0a66a102261d0b4e8a90d34cec3421073a7b728";
    sha256 = "sha256-swdAcsjRWnj9abmnrce5LzeKRK+LHm8RubCEIuk+53c=";
  };

  commonArgs = {
    inherit src;
    pname = "microcosm-rs-deps";
    version = "0.1";
    buildInputs = with pkgs; [
      openssl
      zlib
    ];
    nativeBuildInputs = with pkgs; [
      pkg-config
    ];
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  buildPackage = pname: craneLib.buildPackage (commonArgs // {
    inherit pname;
    cargoArtifacts = cargoArtifacts;
  });

in
{
  constellation = buildPackage "constellation";
  jetstream = buildPackage "jetstream";
  links = buildPackage "links";
  pocket = buildPackage "pocket";
  quasar = buildPackage "quasar";
  reflector = buildPackage "reflector";
  slingshot = buildPackage "slingshot";
  spacedust = buildPackage "spacedust";
  ufos = buildPackage "ufos";
  "who-am-i" = buildPackage "who-am-i";
}
