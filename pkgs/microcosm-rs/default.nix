{ lib, rustPlatform, fetchFromPath }:

let
  microcosm-rs-src = fetchFromPath {
    path = "/home/jack/Software/microcosm-rs";
  };
in
{
  spacedust = rustPlatform.buildRustPackage rec {
    pname = "spacedust";
    version = "0.1.0"; # This should match the Cargo.toml version

    src = microcosm-rs-src;

    cargoLock = {
      lockFile = "${microcosm-rs-src}/Cargo.lock";
    };

    sourceRoot = "${microcosm-rs-src}/spacedust";

    # TODO: Add any necessary build inputs or features
    # nativeBuildInputs = [ ];
    # buildInputs = [ ];

    meta = with lib; {
      description = "A service for aggregating links in the at-mosphere";
      homepage = "https://github.com/jack/microcosm-rs"; # Placeholder
      license = licenses.mit; # Placeholder
      maintainers = [ ]; # Placeholder
      platforms = platforms.linux;
    };
  };
}
