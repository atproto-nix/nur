{
  description = "ATproto NUR repository";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    rust-overlay.url = "github:oxalica/rust-overlay";
    search.url = "github:NuschtOS/search";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      crane,
      rust-overlay,
      search,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustVersion = pkgs.rust-bin.stable.latest.default;
        craneLib = (crane.mkLib pkgs).overrideToolchain rustVersion;

        nurPackages = import ./default.nix {
          inherit pkgs craneLib;
        };
      in
      {
        packages = nurPackages // {
          default = nurPackages.microcosm.default;
          search = search.packages.${system}.default;
        };
        legacyPackages = nurPackages;
        nixosModules = {
          microcosm = import ./modules/microcosm;
          blacksky = import ./modules/blacksky;
          search = search.nixosModules.default;
        };
        devShells.default = pkgs.mkShell {
          # todo?
        };
      }
    );
}
