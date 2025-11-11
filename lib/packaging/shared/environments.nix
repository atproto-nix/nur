# Standard environment configurations for ATProto builds
#
# This module provides environment variables and configurations that are shared
# across multiple languages and build tools in the ATProto ecosystem.
#
# Usage:
#   inherit (packaging.shared.environments) standardEnv standardRustEnv standardNodeEnv;

{ lib, pkgs, ... }:

{
  # Standard environment variables for all ATProto builds
  # Includes OpenSSL, LLVM, and other common dependencies
  standardEnv = {
    LIBCLANG_PATH = lib.makeLibraryPath [ pkgs.llvmPackages.libclang.lib ];
    OPENSSL_NO_VENDOR = "1";
    OPENSSL_LIB_DIR = "${lib.getLib pkgs.openssl}/lib";
    OPENSSL_INCLUDE_DIR = "${lib.getDev pkgs.openssl}/include";
    BINDGEN_EXTRA_CLANG_ARGS = lib.concatStringsSep " " ([
      "-I${pkgs.llvmPackages.libclang.lib}/lib/clang/${lib.versions.major pkgs.llvmPackages.libclang.version}/include"
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      "-I${pkgs.glibc.dev}/include"
    ]);
    ZSTD_SYS_USE_PKG_CONFIG = "1";
    CC = "${pkgs.llvmPackages.clang}/bin/clang";
    CXX = "${pkgs.llvmPackages.clang}/bin/clang++";
    PKG_CONFIG_PATH = "${pkgs.zstd.dev}/lib/pkgconfig:${pkgs.lz4.dev}/lib/pkgconfig";
  };

  # Rust-specific environment (extends standardEnv)
  standardRustEnv = {
    CARGO_INCREMENTAL = "0";
    CARGO_NET_RETRY = "10";
    CARGO_NET_TIMEOUT = "60";
  };

  # Node.js-specific environment for deterministic builds
  # Controls environment-dependent build behavior
  standardNodeEnv = {
    NODE_ENV = "production";
    # Vite-specific determinism controls
    VITE_INLINE_ASSETS_THRESHOLD = "0";  # Don't inline assets (nondeterministic)
    # General CI/build controls
    CI = "true";
    # npm-specific determinism
    npm_config_verbose = "true";
  };

  # Go-specific environment
  standardGoEnv = {
    CGO_ENABLED = "1";
    GOPROXY = "direct";
    GOSUMDB = "off";
    GO111MODULE = "on";
  };

  # Deno-specific environment
  standardDenoEnv = {
    DENO_NO_UPDATE_CHECK = "1";
    DENO_NO_PROMPT = "1";
  };

  # Create deterministic Node.js environment
  # Applies environment variables needed for reproducible JavaScript builds
  mkDeterministicNodeEnv = { extraEnv ? {}, ... }:
    {
      NODE_ENV = "production";
      VITE_INLINE_ASSETS_THRESHOLD = "0";
      CI = "true";
      npm_config_verbose = "true";
    } // extraEnv;

  # Create deterministic Deno environment
  # Applies environment variables needed for reproducible Deno builds
  mkDeterministicDenoEnv = { cacheDir ? "$PWD/.deno", extraEnv ? {}, ... }:
    {
      DENO_DIR = cacheDir;
      DENO_NO_UPDATE_CHECK = "1";
      DENO_NO_PROMPT = "1";
    } // extraEnv;
}
