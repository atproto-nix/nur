{
  description = "ATProto Rust application template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    crane.url = "github:ipetkov/crane";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        # Use the rust toolchain from rust-overlay
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rustfmt" "clippy" ];
        };

        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        # ATProto-specific build environment
        commonArgs = {
          src = craneLib.cleanCargoSource ./.;
          
          # Standard ATProto Rust environment
          env = {
            LIBCLANG_PATH = nixpkgs.lib.makeLibraryPath [ pkgs.llvmPackages.libclang.lib ];
            OPENSSL_NO_VENDOR = "1";
            OPENSSL_LIB_DIR = "${nixpkgs.lib.getLib pkgs.openssl}/lib";
            OPENSSL_INCLUDE_DIR = "${nixpkgs.lib.getDev pkgs.openssl}/include";
            BINDGEN_EXTRA_CLANG_ARGS = nixpkgs.lib.concatStringsSep " " ([
              "-I${pkgs.llvmPackages.libclang.lib}/lib/clang/${nixpkgs.lib.versions.major pkgs.llvmPackages.libclang.version}/include"
            ] ++ nixpkgs.lib.optionals pkgs.stdenv.isLinux [
              "-I${pkgs.glibc.dev}/include"
            ]);
            ZSTD_SYS_USE_PKG_CONFIG = "1";
            CC = "${pkgs.llvmPackages.clang}/bin/clang";
            CXX = "${pkgs.llvmPackages.clang}/bin/clang++";
            PKG_CONFIG_PATH = "${pkgs.zstd.dev}/lib/pkgconfig:${pkgs.lz4.dev}/lib/pkgconfig";
          };

          nativeBuildInputs = with pkgs; [
            pkg-config
            perl
          ];

          buildInputs = with pkgs; [
            openssl
            zstd
            lz4
            sqlite
          ];

          # ATProto-specific metadata
          passthru = {
            atproto = {
              type = "application";
              services = [ "my-atproto-service" ]; # Replace with your service name
              protocols = [ "com.atproto" ];
              schemaVersion = "1.0";
            };
          };
        };

        # Build dependencies separately for faster rebuilds
        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        # Build the actual package
        my-atproto-service = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
          
          meta = with nixpkgs.lib; {
            description = "My ATProto Rust service";
            homepage = "https://github.com/your-org/your-repo";
            license = licenses.mit; # or licenses.asl20, etc.
            maintainers = [ ]; # Add your maintainer info
            platforms = platforms.linux;
          };
        });
      in
      {
        packages = {
          default = my-atproto-service;
          inherit my-atproto-service;
        };

        # Development shell with all necessary tools
        devShells.default = craneLib.devShell {
          inputsFrom = [ my-atproto-service ];
          
          packages = with pkgs; [
            # Rust development tools
            rustToolchain
            rust-analyzer
            cargo-watch
            cargo-edit
            
            # ATProto development tools
            curl
            jq
            
            # Database tools (if needed)
            sqlite
            postgresql
          ];

          # Environment variables for development
          env = commonArgs.env // {
            RUST_LOG = "debug";
            RUST_BACKTRACE = "1";
          };
        };

        # Checks for CI/CD
        checks = {
          inherit my-atproto-service;
          
          # Cargo clippy check
          my-atproto-service-clippy = craneLib.cargoClippy (commonArgs // {
            inherit cargoArtifacts;
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          });

          # Cargo format check
          my-atproto-service-fmt = craneLib.cargoFmt {
            inherit (commonArgs) src;
          };

          # Run tests
          my-atproto-service-test = craneLib.cargoNextest (commonArgs // {
            inherit cargoArtifacts;
            partitions = 1;
            partitionType = "count";
          });
        };
      });
}