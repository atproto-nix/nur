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

            # Short aliases for Indigo services (for convenience)
            # Allows: nix build .#indigo-relay instead of .#bluesky-indigo-relay
            indigo = selectedPackages.bluesky-indigo;
            indigo-relay = selectedPackages.bluesky-indigo-relay;
            indigo-bigsky = selectedPackages.bluesky-indigo-bigsky;
            indigo-rainbow = selectedPackages.bluesky-indigo-rainbow;
            indigo-palomar = selectedPackages.bluesky-indigo-palomar;
            indigo-bluepages = selectedPackages.bluesky-indigo-bluepages;
            indigo-collectiondir = selectedPackages.bluesky-indigo-collectiondir;
            indigo-hepa = selectedPackages.bluesky-indigo-hepa;
            indigo-beemo = selectedPackages.bluesky-indigo-beemo;
            indigo-sonar = selectedPackages.bluesky-indigo-sonar;
            indigo-netsync = selectedPackages.bluesky-indigo-netsync;
            indigo-gosky = selectedPackages.bluesky-indigo-gosky;
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

      overlays = {
        default = final: prev: {
          # Nested package sets
          microcosm = {
            who-am-i = self.packages.${final.system}.microcosm-who-am-i;
            ufos = self.packages.${final.system}.microcosm-ufos;
            ufos-fuzz = self.packages.${final.system}.microcosm-ufos-fuzz;
            spacedust = self.packages.${final.system}.microcosm-spacedust;
            slingshot = self.packages.${final.system}.microcosm-slingshot;
            reflector = self.packages.${final.system}.microcosm-reflector;
            quasar = self.packages.${final.system}.microcosm-quasar;
            pocket = self.packages.${final.system}.microcosm-pocket;
            links = self.packages.${final.system}.microcosm-links;
            jetstream = self.packages.${final.system}.microcosm-jetstream;
            constellation = self.packages.${final.system}.microcosm-constellation;
            allegedly = self.packages.${final.system}.microcosm-allegedly;
            default = self.packages.${final.system}.microcosm;
          };
          smokesignal-events = {
            quickdid = self.packages.${final.system}.smokesignal-events-quickdid;
            default = self.packages.${final.system}.smokesignal-events;
          };
          stream-place = {
            streamplace = self.packages.${final.system}.stream-place-streamplace;
            binary = self.packages.${final.system}.stream-place-binary;
            default = self.packages.${final.system}.stream-place;
          };
          tangled = {
            spindle = self.packages.${final.system}.tangled-spindle;
            lexgen = self.packages.${final.system}.tangled-lexgen;
            knot = self.packages.${final.system}.tangled-knot;
            genjwks = self.packages.${final.system}.tangled-genjwks;
            camo = self.packages.${final.system}.tangled-camo;
            avatar = self.packages.${final.system}.tangled-avatar;
            appview = self.packages.${final.system}.tangled-appview;
            appview-static-files = self.packages.${final.system}.tangled-appview-static-files;
            default = self.packages.${final.system}.tangled;
          };
          bluesky = {
            indigo = self.packages.${final.system}.bluesky-indigo;
            indigo-relay = self.packages.${final.system}.bluesky-indigo-relay;
            indigo-bigsky = self.packages.${final.system}.bluesky-indigo-bigsky;
            indigo-rainbow = self.packages.${final.system}.bluesky-indigo-rainbow;
            indigo-palomar = self.packages.${final.system}.bluesky-indigo-palomar;
            indigo-bluepages = self.packages.${final.system}.bluesky-indigo-bluepages;
            indigo-collectiondir = self.packages.${final.system}.bluesky-indigo-collectiondir;
            indigo-hepa = self.packages.${final.system}.bluesky-indigo-hepa;
            indigo-beemo = self.packages.${final.system}.bluesky-indigo-beemo;
            indigo-sonar = self.packages.${final.system}.bluesky-indigo-sonar;
            indigo-netsync = self.packages.${final.system}.bluesky-indigo-netsync;
            indigo-gosky = self.packages.${final.system}.bluesky-indigo-gosky;
            atproto-xrpc = self.packages.${final.system}.bluesky-atproto-xrpc;
            atproto-syntax = self.packages.${final.system}.bluesky-atproto-syntax;
            atproto-repo = self.packages.${final.system}.bluesky-atproto-repo;
            atproto-lexicon = self.packages.${final.system}.bluesky-atproto-lexicon;
            atproto-identity = self.packages.${final.system}.bluesky-atproto-identity;
            atproto-did = self.packages.${final.system}.bluesky-atproto-did;
            atproto-api = self.packages.${final.system}.bluesky-atproto-api;
            default = self.packages.${final.system}.bluesky;
          };
          blacksky = {
            rsky = self.packages.${final.system}.blacksky-rsky;
            relay = self.packages.${final.system}.blacksky-relay;
            pds = self.packages.${final.system}.blacksky-pds;
            feedgen = self.packages.${final.system}.blacksky-feedgen;
            firehose = self.packages.${final.system}.blacksky-firehose;
            labeler = self.packages.${final.system}.blacksky-labeler;
            default = self.packages.${final.system}.blacksky;
          };
          grain-social = {
            grain = self.packages.${final.system}.grain-social-grain;
            darkroom = self.packages.${final.system}.grain-social-darkroom;
            cli = self.packages.${final.system}.grain-social-cli;
            default = self.packages.${final.system}.grain-social;
          };
          hyperlink-academy = {
            leaflet = self.packages.${final.system}.hyperlink-academy-leaflet;
            default = self.packages.${final.system}.hyperlink-academy;
          };
          likeandscribe = {
            frontpage = self.packages.${final.system}.likeandscribe-frontpage;
            default = self.packages.${final.system}.likeandscribe;
          };
          mackuba = {
            lycan = self.packages.${final.system}.mackuba-lycan;
            default = self.packages.${final.system}.mackuba;
          };
          parakeet-social = {
            parakeet = self.packages.${final.system}.parakeet-social-parakeet;
            default = self.packages.${final.system}.parakeet-social;
          };
          plcbundle = {
            plcbundle = self.packages.${final.system}.plcbundle-plcbundle;
            default = self.packages.${final.system}.plcbundle-all;
          };
          slices-network = {
            packages = self.packages.${final.system}.slices-network-packages;
            frontend = self.packages.${final.system}.slices-network-frontend;
            api = self.packages.${final.system}.slices-network-api;
            default = self.packages.${final.system}.slices-network;
          };
          teal-fm = {
            teal = self.packages.${final.system}.teal-fm-teal;
            default = self.packages.${final.system}.teal-fm;
          };
          whey-party = {
            red-dwarf = self.packages.${final.system}.whey-party-red-dwarf;
            default = self.packages.${final.system}.whey-party;
          };
          whyrusleeping = {
            konbini = self.packages.${final.system}.whyrusleeping-konbini;
            default = self.packages.${final.system}.whyrusleeping;
          };
          witchcraft-systems = {
            pds-dash = self.packages.${final.system}.witchcraft-systems-pds-dash;
            pds-dash-themed = self.packages.${final.system}.witchcraft-systems-pds-dash-themed;
            default = self.packages.${final.system}.witchcraft-systems;
          };
          yoten-app = {
            yoten = self.packages.${final.system}.yoten-app-yoten;
            default = self.packages.${final.system}.yoten-app;
          };
          baileytownsend = {
            pds-gatekeeper = self.packages.${final.system}.baileytownsend-pds-gatekeeper;
            default = self.packages.${final.system}.baileytownsend;
          };

          # Flat names for backward compatibility
          microcosm-who-am-i = self.packages.${final.system}.microcosm-who-am-i;
          microcosm-ufos = self.packages.${final.system}.microcosm-ufos;
          microcosm-ufos-fuzz = self.packages.${final.system}.microcosm-ufos-fuzz;
          microcosm-spacedust = self.packages.${final.system}.microcosm-spacedust;
          microcosm-slingshot = self.packages.${final.system}.microcosm-slingshot;
          microcosm-reflector = self.packages.${final.system}.microcosm-reflector;
          microcosm-quasar = self.packages.${final.system}.microcosm-quasar;
          microcosm-pocket = self.packages.${final.system}.microcosm-pocket;
          microcosm-links = self.packages.${final.system}.microcosm-links;
          microcosm-jetstream = self.packages.${final.system}.microcosm-jetstream;
          microcosm-constellation = self.packages.${final.system}.microcosm-constellation;
          microcosm-allegedly = self.packages.${final.system}.microcosm-allegedly;

          smokesignal-events-quickdid = self.packages.${final.system}.smokesignal-events-quickdid;

          stream-place-streamplace = self.packages.${final.system}.stream-place-streamplace;
          stream-place-binary = self.packages.${final.system}.stream-place-binary;

          tangled-spindle = self.packages.${final.system}.tangled-spindle;
          tangled-lexgen = self.packages.${final.system}.tangled-lexgen;
          tangled-knot = self.packages.${final.system}.tangled-knot;
          tangled-genjwks = self.packages.${final.system}.tangled-genjwks;
          tangled-camo = self.packages.${final.system}.tangled-camo;
          tangled-avatar = self.packages.${final.system}.tangled-avatar;
          tangled-appview = self.packages.${final.system}.tangled-appview;
          tangled-appview-static-files = self.packages.${final.system}.tangled-appview-static-files;

          bluesky-indigo = self.packages.${final.system}.bluesky-indigo;
          indigo = self.packages.${final.system}.bluesky-indigo;
          indigo-relay = self.packages.${final.system}.bluesky-indigo-relay;
          indigo-bigsky = self.packages.${final.system}.bluesky-indigo-bigsky;
          indigo-rainbow = self.packages.${final.system}.bluesky-indigo-rainbow;
          indigo-palomar = self.packages.${final.system}.bluesky-indigo-palomar;
          indigo-bluepages = self.packages.${final.system}.bluesky-indigo-bluepages;
          indigo-collectiondir = self.packages.${final.system}.bluesky-indigo-collectiondir;
          indigo-hepa = self.packages.${final.system}.bluesky-indigo-hepa;
          indigo-beemo = self.packages.${final.system}.bluesky-indigo-beemo;
          indigo-sonar = self.packages.${final.system}.bluesky-indigo-sonar;
          indigo-netsync = self.packages.${final.system}.bluesky-indigo-netsync;
          indigo-gosky = self.packages.${final.system}.bluesky-indigo-gosky;
          bluesky-atproto-xrpc = self.packages.${final.system}.bluesky-atproto-xrpc;
          bluesky-atproto-syntax = self.packages.${final.system}.bluesky-atproto-syntax;
          bluesky-atproto-repo = self.packages.${final.system}.bluesky-atproto-repo;
          bluesky-atproto-lexicon = self.packages.${final.system}.bluesky-atproto-lexicon;
          bluesky-atproto-identity = self.packages.${final.system}.bluesky-atproto-identity;
          bluesky-atproto-did = self.packages.${final.system}.bluesky-atproto-did;
          bluesky-atproto-api = self.packages.${final.system}.bluesky-atproto-api;

          blacksky-rsky = self.packages.${final.system}.blacksky-rsky;

          grain-social-grain = self.packages.${final.system}.grain-social-grain;
          grain-social-darkroom = self.packages.${final.system}.grain-social-darkroom;
          grain-social-cli = self.packages.${final.system}.grain-social-cli;

          hyperlink-academy-leaflet = self.packages.${final.system}.hyperlink-academy-leaflet;

          likeandscribe-frontpage = self.packages.${final.system}.likeandscribe-frontpage;

          mackuba-lycan = self.packages.${final.system}.mackuba-lycan;

          parakeet-social-parakeet = self.packages.${final.system}.parakeet-social-parakeet;

          plcbundle-plcbundle = self.packages.${final.system}.plcbundle-plcbundle;

          slices-network-packages = self.packages.${final.system}.slices-network-packages;
          slices-network-frontend = self.packages.${final.system}.slices-network-frontend;
          slices-network-api = self.packages.${final.system}.slices-network-api;

          teal-fm-teal = self.packages.${final.system}.teal-fm-teal;

          whey-party-red-dwarf = self.packages.${final.system}.whey-party-red-dwarf;

          whyrusleeping-konbini = self.packages.${final.system}.whyrusleeping-konbini;

          witchcraft-systems-pds-dash = self.packages.${final.system}.witchcraft-systems-pds-dash;
          witchcraft-systems-pds-dash-themed = self.packages.${final.system}.witchcraft-systems-pds-dash-themed;

          yoten-app-yoten = self.packages.${final.system}.yoten-app-yoten;

          baileytownsend-pds-gatekeeper = self.packages.${final.system}.baileytownsend-pds-gatekeeper;

          # Convenient short aliases for commonly used packages
          quickdid = self.packages.${final.system}.smokesignal-events-quickdid;
          spacedust = self.packages.${final.system}.microcosm-spacedust;
          ufos = self.packages.${final.system}.microcosm-ufos;
          slingshot = self.packages.${final.system}.microcosm-slingshot;
          constellation = self.packages.${final.system}.microcosm-constellation;
          pocket = self.packages.${final.system}.microcosm-pocket;
          lycan = self.packages.${final.system}.mackuba-lycan;
          knot = self.packages.${final.system}.tangled-knot;
          spindle = self.packages.${final.system}.tangled-spindle;
        };
      };


      # Comprehensive NixOS Modules
      nixosModules = let
        # Dynamically discover modules in the ./modules directory
        # This avoids needing to manually update a list when modules are added/removed
        # Look for directories (not .nix files) since modules are organized as subdirectories
        moduleEntries = builtins.readDir ./modules;
        allModuleNames = builtins.filter
          (name: moduleEntries.${name} == "directory")
          (builtins.attrNames moduleEntries);

        # Exclude modules with known issues (e.g., infinite recursion, incomplete packages)
        excludedModules = [ "slices-network" "workerd" ];
        moduleNames = builtins.filter
          (name: !(builtins.elem name excludedModules))
          allModuleNames;

        # Export ALL modules individually (including excluded ones for manual import)
        allModuleImports =
          builtins.listToAttrs
            (builtins.map
              (name: {
                inherit name;
                value = import (./modules + "/${name}");
              })
              allModuleNames
            );

        # Only import non-excluded modules in default
        safeModuleImports = builtins.filter
          (mod: !(builtins.elem mod excludedModules))
          (builtins.map (name: allModuleImports.${name}) moduleNames);

      in allModuleImports // {
        # Comprehensive default module: imports all safe modules + applies overlay
        default = { pkgs, ... }: {
          imports = safeModuleImports;
          nixpkgs.overlays = [ self.overlays.default ];
        };
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


    };
}