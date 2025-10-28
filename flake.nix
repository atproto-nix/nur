{
  description = "ATProto NUR repository - Nix packages and modules for the AT Protocol ecosystem";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    crane = {
      url = "github:ipetkov/crane/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deno = {
      url = "github:nekowinston/nix-deno";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, crane, rust-overlay, deno }:
    let
      # Helper to generate attributes for all exposed systems
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      # Prepare package configuration for each system
      preparePackages = system:
        let
          # Consistent overlays configuration
          overlays = [
            rust-overlay.overlays.default
            deno.overlays.default
            (final: prev: {
              fetchFromTangled = final.callPackage ./lib/fetch-tangled.nix { };
            })
          ];

          # Standardized package configuration
          pkgs = import nixpkgs {
            inherit system;
            overlays = overlays;
            config.allowUnfree = true;
          };

          # Rust toolchain management
          rustVersion = pkgs.rust-bin.stable.latest.default;
          craneLib = (crane.mkLib pkgs).overrideToolchain rustVersion;

          # Import packages with full context
          nurPackages = import ./default.nix {
            inherit pkgs craneLib;
          };

          # Comprehensive package selection
          selectedPackages =
            # Flatten packages with full organizational context
            import ./pkgs/default.nix {
              inherit pkgs craneLib;
              lib = pkgs.lib;
              fetchgit = pkgs.fetchgit;
              buildGoModule = pkgs.buildGoModule;
              buildNpmPackage = pkgs.buildNpmPackage;
              atprotoLib = pkgs.callPackage ./lib/atproto.nix { };
            };
        in {
          # Comprehensive package listing
          packages = selectedPackages // {
            # Special support for complex systems
            default = pkgs.symlinkJoin {
              name = "atproto-nur-all";
              paths = builtins.attrValues selectedPackages;
              meta = {
                description = "All ATProto NUR packages";
                homepage = "https://github.com/atproto/nur";
              };
            };
          };

          # Legacy package support
          legacyPackages = nurPackages;
        };

    in {
      # Apply package preparation for each system
      packages = forAllSystems (system: (preparePackages system).packages);
      legacyPackages = forAllSystems (system: (preparePackages system).legacyPackages);

      # Comprehensive NixOS Modules
      nixosModules = let
        moduleList = [
          "microcosm"
          "blacksky"
          "bluesky"
          "hyperlink-academy"
          "slices-network"
          "teal-fm"
          "parakeet-social"
          "stream-place"
          "yoten-app"
          "red-dwarf-client"
          "tangled"
          "smokesignal-events"
	  "mackuba"
        ];
        moduleImports =
          builtins.listToAttrs
            (builtins.map
              (name: {
                inherit name;
                value = import (./modules + "/${name}");
              })
              moduleList
            );
      in moduleImports // {
        default = import ./modules;
      };

      # Development Shells
      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; }; in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              deadnix
              nixpkgs-fmt
              crane.cli
              rust-bin.stable.latest.default
              rust-analyzer
            ];
          };
        }
      );

      # Test Checks
      checks = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; }; in {
          microcosm-constellation = pkgs.callPackage ./tests/microcosm-constellation.nix {
            inherit (crane) mkLib;
            craneLib = (crane.mkLib pkgs).overrideToolchain (pkgs.rust-bin.stable.latest.default);
          };
          blacksky-pds = pkgs.callPackage ./tests/blacksky-pds.nix {
            inherit (crane) mkLib;
            craneLib = (crane.mkLib pkgs).overrideToolchain (pkgs.rust-bin.stable.latest.default);
          };
          bluesky-indigo = pkgs.callPackage ./tests/bluesky-indigo.nix { };
        }
      );

      # Global Nix configuration
      nixConfig = {
        extra-substituters = [
          "https://nix-community.cachix.org"
          "https://crane.cachix.org"
          "https://atproto-nix.cachix.org"
        ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk="
          "atproto-nix.cachix.org-1:YOUR_CACHIX_PUBLIC_KEY"
        ];
      };
    };
}
