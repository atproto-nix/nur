{
  description = "ATproto NUR repository";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      crane,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (
      system:
      let
        overlays = [
          (import rust-overlay)
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
          pkgs.lib.isDerivation v
        ) nurPackages;

      in
      {
        packages = packages;

        lib = nurPackages.lib or {};

        nixosModules = {
          default = import ./modules;

          # Core service modules
          microcosm = import ./modules/microcosm;
          blacksky = import ./modules/blacksky;
          bluesky-social = import ./modules/bluesky-social;
          atproto = import ./modules/atproto;
          individual = import ./modules/individual;
          microcosm-blue = import ./modules/microcosm-blue;
          smokesignal-events = import ./modules/smokesignal-events;

          # Infrastructure services
          tangled-dev = import ./modules/tangled-dev;

          # Web applications / AppViews
          hyperlink-academy = import ./modules/hyperlink-academy;
          slices-network = import ./modules/slices-network;
          teal-fm = import ./modules/teal-fm;
          parakeet-social = import ./modules/parakeet-social;
          stream-place = import ./modules/stream-place;
          yoten-app = import ./modules/yoten-app;
          red-dwarf-client = import ./modules/red-dwarf-client;
          witchcraft-systems = import ./modules/witchcraft-systems;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            deadnix
            nixpkgs-fmt
          ];
        };
      }
    );
}
