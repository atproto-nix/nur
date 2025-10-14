{ pkgs, craneLib }:

let
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
    BINDGEN_EXTRA_CLANG_ARGS = pkgs.lib.concatStringsSep " " [
        "-I${pkgs.llvmPackages.libclang.lib}/lib/clang/${pkgs.lib.versions.major pkgs.llvmPackages.libclang.version}/include"
        "-I${pkgs.glibc.dev}"
    ];
    ZSTD_SYS_USE_PKG_CONFIG = "1";
    CC = "${pkgs.llvmPackages.clang}/bin/clang";
    CXX = "${pkgs.llvmPackages.clang}/bin/clang++";
    PKG_CONFIG_PATH = "${pkgs.zstd.dev}/lib/pkgconfig:${pkgs.lz4.dev}/lib/pkgconfig";
  };

  nativeInputs = with pkgs;
[
    pkg-config
    perl
  ];

  buildInputs = with pkgs;
[
    zstd
    lz4
    rocksdb
    openssl
    sqlite
  ];
  cargoArtifacts = craneLib.buildDepsOnly {
    inherit src;
    pname = "microcosm-rs-deps";
    version = "0.1.0";
    nativeBuildInputs = nativeInputs;
    buildInputs = buildInputs;
    env = commonEnv;
    tarFlags = "--no-same-owner";
  };

  members = [
    "links"
    "constellation"
    "jetstream"
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
    craneLib.buildPackage {
      inherit src cargoArtifacts;
      pname = packageName;
      version = "0.1.0";
      cargoExtraArgs = "--package ${packageName}";
      nativeBuildInputs = nativeInputs;
      buildInputs = buildInputs;
      tarFlags = "--no-same-owner";
      env = commonEnv;
    };

  packages = pkgs.lib.genAttrs members (member: buildPackage member);

in
packages
