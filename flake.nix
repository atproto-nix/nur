# ==============================================================================
# ATProto NUR (Nix User Repository) - Flake Configuration
# ==============================================================================
#
# BEST PRACTICES GUIDE:
#
# 1. MULTI-SYSTEM SUPPORT
#    - Use forAllSystems to expose packages for all supported platforms
#    - Avoids duplication and ensures consistency across x86_64/aarch64
#
# 2. INPUT MANAGEMENT
#    - Always use inputs.nixpkgs.follows for transitive dependencies
#    - Keeps versions consistent and reduces closure size
#    - crane and rust-overlay follow nixpkgs to avoid version conflicts
#
# 3. OVERLAYS STRATEGY
#    - Apply rust-overlay, deno overlay, and custom overlays consistently
#    - Overlays should modify pkgs, not replace it entirely
#    - Use makeOverridable for custom fetchers (like fetchFromTangled)
#
# 4. PACKAGE CONTEXT
#    - Pass craneLib, atprotoLib, and lib to all package definitions
#    - Enables shared build logic without code duplication
#    - Ensures all packages have access to common utilities
#
# 5. ORGANIZATION PATTERNS
#    - Group related packages in organizational directories (microcosm/, etc.)
#    - Use prefix naming (org-package) for flattened namespace
#    - Maintain both organizational and flattened views
#
# ==============================================================================

{
  description = "ATProto NUR repository - Nix packages and modules for the AT Protocol ecosystem";

  # BEST PRACTICE: Input organization
  # - Core: nixpkgs (base packages)
  # - Language overlays: rust-overlay, deno
  # - Build systems: crane (Rust builds)
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Rust build system for efficient incremental builds
    crane = {
      url = "github:ipetkov/crane/master";
      inputs.nixpkgs.follows = "nixpkgs";  # Pin to same nixpkgs version
    };

    # Rust toolchain management (latest stable)
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";  # Pin to same nixpkgs version
    };

    # Deno runtime for JavaScript/TypeScript projects
    deno = {
      url = "github:nekowinston/nix-deno";
      inputs.nixpkgs.follows = "nixpkgs";  # Pin to same nixpkgs version
    };
  };

  # ===========================================================================
  # OUTPUTS: Package and module definitions for all systems
  # ===========================================================================
  #
  # BEST PRACTICES:
  #
  # 1. SYSTEM ITERATION (forAllSystems)
  #    - Ensures packages are evaluated and built on all supported platforms
  #    - Avoids platform-specific surprises in production
  #
  # 2. OVERLAY APPLICATION
  #    - Apply in order: language overlays first, then custom overlays
  #    - Each overlay can enhance or override previous ones
  #    - fetchFromTangled added for Tangled.org repository access
  #
  # 3. CONTEXT PASSING
  #    - Always pass lib, build tools, and helpers to package sets
  #    - Reduces boilerplate and ensures consistency
  #    - Package definitions can focus on specifics
  #
  # 4. DEFAULT PACKAGE
  #    - Provides convenience target for 'nix build' without arguments
  #    - Typically symlinks all buildable packages for quick testing
  #
  # 5. LEGACY PACKAGES
  #    - Maintains backward compatibility with non-flake usage
  #    - Important for gradual migration to flakes
  #
  # ===========================================================================

  outputs = { self, nixpkgs, crane, rust-overlay, deno }:
    let
      # BEST PRACTICE: Define forAllSystems helper at top level
      # This makes it available to all subsequent let-bindings
      # genAttrs creates an attribute set from a list of system names
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      # BEST PRACTICE: Separate per-system configuration logic
      # This function encapsulates all system-specific setup
      # Reduces duplication and makes testing easier
      preparePackages = system:
        let
          # BEST PRACTICE: Overlays in dependency order
          # 1. Language runtimes (Rust, Deno)
          # 2. Custom utilities (fetchFromTangled)
          # This ensures custom overlays can build on language features
          overlays = [
            rust-overlay.overlays.default
            deno.overlays.default
            (final: prev: {
              # Custom overlay: Add fetchFromTangled to pkgs
              # This makes it available as pkgs.fetchFromTangled everywhere
              fetchFromTangled = final.callPackage ./lib/fetch-tangled.nix { };
            })
          ];

          # BEST PRACTICE: Import nixpkgs once per system
          # Pin version via flake.lock, apply all overlays consistently
          # allowUnfree = true enables proprietary packages when needed
          pkgs = import nixpkgs {
            inherit system;
            overlays = overlays;
            config.allowUnfree = true;
          };

          # BEST PRACTICE: Use stable Rust toolchain
          # - latest.default gives latest stable
          # - Avoids nightly instability
          # - craneLib provides efficient Rust builds with caching
          rustVersion = pkgs.rust-bin.stable.latest.default;
          craneLib = (crane.mkLib pkgs).overrideToolchain rustVersion;

          # BEST PRACTICE: Import with minimal context
          # Gets library utilities and metadata
          nurPackages = import ./default.nix {
            inherit pkgs craneLib;
          };

          # BEST PRACTICE: Pass complete build context to package set
          # Prevents individual packages from reimporting/redefining these
          # Ensures all packages use the same versions
          selectedPackages =
            import ./pkgs/default.nix {
              inherit pkgs craneLib;
              lib = pkgs.lib;                    # Standard library functions
              fetchgit = pkgs.fetchgit;          # Git source fetcher
              buildGoModule = pkgs.buildGoModule; # Go build helper
              buildNpmPackage = pkgs.buildNpmPackage; # Node.js build helper
              atprotoLib = pkgs.callPackage ./lib/atproto.nix { };  # Shared utilities
            };
        in {
          # BEST PRACTICE: Include default package
          # Allows 'nix build' to work without specifying package name
          packages = selectedPackages // {
            default = pkgs.symlinkJoin {
              name = "atproto-nur-all";
              # Combine all packages into single derivation for easy testing
              paths = builtins.attrValues selectedPackages;
              meta = {
                description = "All ATProto NUR packages";
                homepage = "https://github.com/atproto/nur";
              };
            };
          };

          # BEST PRACTICE: Maintain legacyPackages
          # Provides access via:
          #   nix eval '.#legacyPackages.x86_64-linux.package-name'
          # Useful for exploring packages before flakes adoption
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
          "whyrusleeping"
          "witchcraft-systems"
          "likeandscribe"
          "grain-social"
          "atbackup-pages-dev"
          "whey-party"
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
