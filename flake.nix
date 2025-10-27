{
  description = "ATproto NUR repository";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    rust-overlay.url = "github:oxalica/rust-overlay";
    deno = {
      url = "github:nekowinston/nix-deno";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      crane,
      rust-overlay,
      deno,
      ...
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (
      system:
      let
        overlays = [
          (import rust-overlay)
          deno.overlays.default
          (final: prev: {
            fetchFromTangled = final.callPackage ./lib/fetch-tangled.nix { };
          })
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustVersion = pkgs.rust-bin.stable.latest.default;
        craneLib = (crane.mkLib pkgs).overrideToolchain rustVersion;

        nurPackages = import ./default.nix {
          inherit pkgs craneLib;
        };

        # Filter to only packages (exclude lib, modules, etc)
        packages = pkgs.lib.filterAttrs (n: v:
          n != "lib" &&
          n != "modules" &&
          n != "overlays" &&
          n != "organizations" &&
          n != "_organizationalMetadata" &&
          pkgs.lib.isDerivation v
        ) nurPackages;

        # Extract organizational collections for nested access
        organizations = nurPackages.organizations or {};

        ci = import ./ci.nix { inherit pkgs craneLib; };

    in
    {
      nixConfig = {
        extra-substituters = [
          "https://nix-community.cachix.org"
          "https://crane.cachix.org"
        ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "crane.cachix.org-1:8Scfpmn9w+hGdXH/Q9tTLiYAE/2dnJYRJP7kl80GuRk="
        ];
      };
        # Flattened packages (e.g., tangled-knot, tangled-appview)
        packages = packages //
          # Also expose organizational attribute sets (e.g., tangled.knot, tangled.appview)
          (pkgs.lib.mapAttrs (orgName: orgPackages:
            pkgs.lib.filterAttrs (n: v:
              n != "_organizationMeta" && pkgs.lib.isDerivation v
            ) orgPackages
          ) organizations);

        lib = nurPackages.lib or {};

        cacheOutputs = ci.cacheOutputs;



        nixosModules = pkgs.lib.mkIf pkgs.stdenv.isLinux {
          default = import ./modules;

          # Core service modules
          microcosm = import ./modules/microcosm;
          blacksky = import ./modules/blacksky;
          bluesky = import ./modules/bluesky;
          individual = import ./modules/individual;
          microcosm-blue = import ./modules/microcosm-blue;
          smokesignal-events = import ./modules/smokesignal-events;

          # Infrastructure services
          tangled = import ./modules/tangled;

          # Web applications / AppViews
          hyperlink-academy = import ./modules/hyperlink-academy;
          slices-network = import ./modules/slices-network;
          teal-fm = import ./modules/teal-fm;
          parakeet-social = import ./modules/parakeet-social;
          stream-place = import ./modules/stream-place;
          yoten-app = import ./modules/yoten-app;
          red-dwarf-client = import ./modules/red-dwarf-client;
          witchcraft-systems = import ./modules/witchcraft-systems;
          mackuba = import ./modules/mackuba;
          whey-party = import ./modules/whey-party;
          whyrusleeping = import ./modules/whyrusleeping;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            deadnix
            nixpkgs-fmt
          ];
        };

        checks = pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          # Ruby packages
          mackuba-lycan = pkgs.callPackage ./tests/mackuba-lycan.nix { };

          # Rust packages (Microcosm)
          microcosm-constellation = pkgs.callPackage ./tests/microcosm-constellation.nix { inherit craneLib; };

          # Rust packages (Blacksky/rsky)
          blacksky-pds = pkgs.callPackage ./tests/blacksky-pds.nix { inherit craneLib; };

          # Go packages (Bluesky official)
          bluesky-indigo = pkgs.callPackage ./tests/bluesky-indigo.nix { };
        };
      }
    );
}
