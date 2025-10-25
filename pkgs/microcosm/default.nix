{ pkgs, lib, craneLib, fetchFromTangled ? pkgs.fetchFromTangled, ... }:

# Microcosm ATProto packages
# Organization: microcosm-blue
# Website: https://microcosm.blue

let
  # Organizational metadata
  organizationMeta = {
    name = "microcosm-blue";
    displayName = "Microcosm";
    website = null;
    contact = null;
    maintainer = "Microcosm";
    description = "PLC tools and utilities for ATProto ecosystem";
    atprotoFocus = [ "tools" "identity" ];
    packageCount = 12; # Updated count to include all packages
  };

  src = pkgs.fetchFromGitHub {
    owner = "at-microcosm";
    repo = "microcosm-rs";
    rev = "b0a66a102261d0b4e8a90d34cec3421073a7b728";
    sha256 = "sha256-swdAcsjRWnj9abmnrce5LzeKRK+LHm8RubCEIuk+53c=";
  };

  commonEnv = {
    LIBCLANG_PATH = pkgs.lib.makeLibraryPath [ pkgs.llvmPackages.libclang.lib ];
    OPENSSL_NO_VENDOR = "1";
    OPENSSL_LIB_DIR = "${pkgs.lib.getLib pkgs.openssl}/lib";
    OPENSSL_INCLUDE_DIR = "${pkgs.lib.getDev pkgs.openssl}/include";
    BINDGEN_EXTRA_CLANG_ARGS = pkgs.lib.concatStringsSep " " (
      [
        "-I${pkgs.llvmPackages.libclang.lib}/lib/clang/${pkgs.lib.versions.major pkgs.llvmPackages.libclang.version}/include"
      ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
        "-I${pkgs.glibc.dev}/include"
      ]
    );
    ZSTD_SYS_USE_PKG_CONFIG = "1";
    CC = "${pkgs.llvmPackages.clang}/bin/clang";
    CXX = "${pkgs.llvmPackages.clang}/bin/clang++";
    PKG_CONFIG_PATH = "${pkgs.zstd.dev}/lib/pkgconfig:${pkgs.lz4.dev}/lib/pkgconfig:${pkgs.openssl.dev}/lib/pkgconfig";
  };

  nativeBuildInputs = with pkgs;
    [
      pkg-config
      perl
      llvmPackages.libclang
    ];

  buildInputs = with pkgs;
    [
      zstd
      lz4
      rocksdb
      openssl
      sqlite
      postgresql
    ];

  cargoArtifacts = craneLib.buildDepsOnly {
    inherit src;
    pname = "microcosm-rs-deps";
    version = "0.1.0";
    nativeBuildInputs = nativeBuildInputs;
    buildInputs = buildInputs;
    env = commonEnv;
    tarFlags = "--no-same-owner";
  };

  # Package naming pattern: use simple names within organization
  packages = {
    allegedly = pkgs.callPackage ./allegedly.nix { inherit craneLib fetchFromTangled; };
    links = pkgs.callPackage ./links.nix { inherit craneLib src cargoArtifacts nativeBuildInputs buildInputs commonEnv; tarFlags = "--no-same-owner"; };
    constellation = pkgs.callPackage ./constellation.nix { inherit craneLib src cargoArtifacts nativeBuildInputs buildInputs commonEnv; tarFlags = "--no-same-owner"; };
    jetstream = pkgs.callPackage ./jetstream.nix { inherit craneLib src cargoArtifacts nativeBuildInputs buildInputs commonEnv; tarFlags = "--no-same-owner"; };
    ufos = pkgs.callPackage ./ufos.nix { inherit craneLib src cargoArtifacts nativeBuildInputs buildInputs commonEnv; tarFlags = "--no-same-owner"; };
    ufos-fuzz = pkgs.callPackage ./ufos-fuzz.nix { inherit craneLib src cargoArtifacts nativeBuildInputs buildInputs commonEnv; tarFlags = "--no-same-owner"; };
    spacedust = pkgs.callPackage ./spacedust.nix { inherit craneLib src cargoArtifacts nativeBuildInputs buildInputs commonEnv; tarFlags = "--no-same-owner"; };
    who-am-i = pkgs.callPackage ./who-am-i.nix { inherit craneLib src cargoArtifacts nativeBuildInputs buildInputs commonEnv; tarFlags = "--no-same-owner"; };
    slingshot = pkgs.callPackage ./slingshot.nix { inherit craneLib src cargoArtifacts nativeBuildInputs buildInputs commonEnv; tarFlags = "--no-same-owner"; };
    quasar = pkgs.callPackage ./quasar.nix { inherit craneLib src cargoArtifacts nativeBuildInputs buildInputs commonEnv; tarFlags = "--no-same-owner"; };
    pocket = pkgs.callPackage ./pocket.nix { inherit craneLib src cargoArtifacts nativeBuildInputs buildInputs commonEnv; tarFlags = "--no-same-owner"; };
    reflector = pkgs.callPackage ./reflector.nix { inherit craneLib src cargoArtifacts nativeBuildInputs buildInputs commonEnv; tarFlags = "--no-same-owner"; };
  };

  # Enhanced packages with organizational metadata
  enhancedPackages = lib.mapAttrs (name: pkg:
    pkg.overrideAttrs (oldAttrs: {
      passthru = (oldAttrs.passthru or {}) // {
        organization = organizationMeta;
        atproto = (oldAttrs.passthru.atproto or {}) // {
          organization = organizationMeta;
        };
      };
      meta = (oldAttrs.meta or {}) // {
        organizationalContext = {
          organization = organizationMeta.name;
          displayName = organizationMeta.displayName;
        };
      };
    })
  ) packages;
in
enhancedPackages // {
  # Export organizational metadata for external use
  _organizationMeta = organizationMeta;
}