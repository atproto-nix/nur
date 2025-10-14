{ pkgs, craneLib, ... }:

{
  pds = craneLib.buildPackage rec {
    pname = "rsky-pds";
    version = "0.1.0"; # Placeholder version, should be updated from rsky's Cargo.toml
    src = pkgs.fetchFromGitHub {
      owner = "blacksky-algorithms";
      repo = "rsky";
      rev = "main"; # Placeholder, should be updated to a specific commit or tag
      hash = "sha256-nqBe20MCeNrSVxLVxiYc7iCFaBdf5Vf1p/i0D/aS8oY=";
    };
    cargoHash = "sha256-0000000000000000000000000000000000000000000000000000000000000000=";

    # Build only the rsky-pds binary

    cargoBuildFlags = [ "--package rsky-pds --bin rsky-pds" ];
    cargoInstallFlags = [ "--package rsky-pds --bin rsky-pds" ];

    meta = with pkgs.lib; {
      description = "AT Protocol Personal Data Server (PDS) from rsky";
      homepage = "https://github.com/atproto-nix/nur"; # Placeholder
      license = licenses.mit; # Placeholder
      maintainers = with maintainers; [ ]; # Placeholder
    };
  };

  relay = craneLib.buildPackage rec {
    pname = "rsky-relay";
    version = "0.1.0"; # Placeholder version
    src = pkgs.fetchFromGitHub {
      owner = "blacksky-algorithms";
      repo = "rsky";
      rev = "main"; # Placeholder
      hash = "sha256-nqBe20MCeNrSVxLVxiYc7iCFaBdf5Vf1p/i0D/aS8oY=";
    };
    cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Placeholder

    cargoBuildFlags = [ "--package rsky-relay --bin rsky-relay" ];
    cargoInstallFlags = [ "--package rsky-relay --bin rsky-relay" ];

    meta = with pkgs.lib; {
      description = "AT Protocol Relay from rsky";
      homepage = "https://github.com/atproto-nix/nur";
      license = licenses.mit;
      maintainers = with maintainers; [ ];
    };
  };

  feedgen = craneLib.buildPackage rec {
    pname = "rsky-feedgen";
    version = "0.1.0"; # Placeholder version
    src = pkgs.fetchFromGitHub {
      owner = "blacksky-algorithms";
      repo = "rsky";
      rev = "main"; # Placeholder
      hash = "sha256-nqBe20MCeNrSVxLVxiYc7iCFaBdf5Vf1p/i0D/aS8oY=";
    };
    cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Placeholder

    cargoBuildFlags = [ "--package rsky-feedgen --bin rsky-feedgen" ];
    cargoInstallFlags = [ "--package rsky-feedgen --bin rsky-feedgen" ];

    meta = with pkgs.lib; {
      description = "AT Protocol Feed Generator from rsky";
      homepage = "https://github.com/atproto-nix/nur";
      license = licenses.mit;
      maintainers = with maintainers; [ ];
    };
  };

  satnav = craneLib.buildPackage rec {
    pname = "rsky-satnav";
    version = "0.1.0"; # Placeholder version
    src = pkgs.fetchFromGitHub {
      owner = "blacksky-algorithms";
      repo = "rsky";
      rev = "main"; # Placeholder
      hash = "sha256-nqBe20MCeNrSVxLVxiYc7iCFaBdf5Vf1p/i0D/aS8oY=";
    };
    cargoHash = "sha256-0000000000000000000000000000000000000000000000000000000000000000="; # Placeholder, will be updated by Nix

    cargoBuildFlags = [ "--package rsky-satnav --bin rsky-satnav" ];
    cargoInstallFlags = [ "--package rsky-satnav --bin rsky-satnav" ];

    meta = with pkgs.lib; {
      description = "AT Protocol Satnav from rsky";
      homepage = "https://github.com/atproto-nix/nur";
      license = licenses.mit;
      maintainers = with maintainers; [ ];
    };
  };

  firehose = craneLib.buildPackage rec {
    pname = "rsky-firehose";
    version = "0.2.1"; # Version from Cargo.toml
    src = pkgs.fetchFromGitHub {
      owner = "blacksky-algorithms";
      repo = "rsky";
      rev = "main"; # Placeholder
      hash = "sha256-nqBe20MCeNrSVxLVxiYc7iCFaBdf5Vf1p/i0D/aS8oY=";
    };
    cargoHash = "sha256-0000000000000000000000000000000000000000000000000000000000000000="; # Placeholder

    cargoBuildFlags = [ "--package rsky-firehose --bin rsky-firehose" ];
    cargoInstallFlags = [ "--package rsky-firehose --bin rsky-firehose" ];

    meta = with pkgs.lib; {
      description = "AT Protocol Firehose subscriber from rsky";
      homepage = "https://github.com/atproto-nix/nur";
      license = licenses.mit;
      maintainers = with maintainers; [ ];
    };
  };

  jetstreamSubscriber = craneLib.buildPackage rec {
    pname = "rsky-jetstream-subscriber";
    version = "0.1.0"; # Version from Cargo.toml
    src = pkgs.fetchFromGitHub {
      owner = "blacksky-algorithms";
      repo = "rsky";
      rev = "main"; # Placeholder
      hash = "sha256-nqBe20MCeNrSVxLVxiYc7iCFaBdf5Vf1p/i0D/aS8oY=";
    };
    cargoHash = "sha256-0000000000000000000000000000000000000000000000000000000000000000="; # Placeholder

    cargoBuildFlags = [ "--package rsky-jetstream-subscriber --bin rsky-jetstream-subscriber" ];
    cargoInstallFlags = [ "--package rsky-jetstream-subscriber --bin rsky-jetstream-subscriber" ];

    meta = with pkgs.lib; {
      description = "AT Protocol Jetstream Subscriber from rsky";
      homepage = "https://github.com/atproto-nix/nur";
      license = licenses.mit;
      maintainers = with maintainers; [ ];
    };
  };

  labeler = craneLib.buildPackage rec {
    pname = "rsky-labeler";
    version = "0.1.3"; # Version from Cargo.toml
    src = pkgs.fetchFromGitHub {
      owner = "blacksky-algorithms";
      repo = "rsky";
      rev = "main"; # Placeholder
      hash = "sha256-nqBe20MCeNrSVxLVxiYc7iCFaBdf5Vf1p/i0D/aS8oY=";
    };
    cargoHash = "sha256-0000000000000000000000000000000000000000000000000000000000000000="; # Placeholder

    cargoBuildFlags = [ "--package rsky-labeler --bin rsky-labeler" ];
    cargoInstallFlags = [ "--package rsky-labeler --bin rsky-labeler" ];

    meta = with pkgs.lib; {
      description = "AT Protocol Labeler from rsky";
      homepage = "https://github.com/atproto-nix/nur";
      license = licenses.mit;
      maintainers = with maintainers; [ ];
    };
  };

  # community = pkgs.buildYarnPackage rec {
  #   pname = "blacksky.community";
  #   version = "1.109.0"; # Version from package.json
  #
  #   src = pkgs.fetchFromGitHub {
  #     owner = "blacksky-algorithms";
  #     repo = "blacksky.community";
  #     # TODO: Update 'rev' to a specific commit hash or release tag for reproducible builds.
  #     rev = "main";
  #     # TODO: Update 'hash' to the correct SHA256 hash of the fetched source.
  #     # You can obtain the correct hash by setting it to an empty string, running nix-build,
  #     # and then copying the hash from the error message.
  #     hash = "sha256-W0mXqED9geNKJSPGJhUdJZ2voMOMDCXX1T4zn3GZKlY=";
  #   };
  #
  #   yarnLock = "yarn.lock"; # Specify the yarn.lock file
  #
  #   buildPhase = ''
  #     yarn build-web
  #   '';
  #
  #   installPhase = ''
  #     mkdir -p $out/share/nginx/html
  #     cp -r web-build/* $out/share/nginx/html
  #   '';
  #
  #   meta = with pkgs.lib; {
  #     description = "Blacksky Community Web Client";
  #     # Placeholder, update with actual homepage if available.
  #     homepage = "https://github.com/blacksky-algorithms/blacksky.community";
  #     # Placeholder, add actual maintainers.
  #     maintainers = with maintainers; [ ];
  #   };
  # };
}
