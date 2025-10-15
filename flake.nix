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
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        nurOverlay = final: prev: {
          nur = import ./default.nix {
            pkgs = final;
            craneLib = (crane.mkLib final).overrideToolchain rustVersion;
          };
        };
        overlays = [
          (import rust-overlay)
          nurOverlay
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustVersion = pkgs.rust-bin.stable.latest.default;
        allPackages = 
          let
            isDerivation = pkg: pkg.type or "" == "derivation";
          in
          pkgs.lib.filterAttrs (n: v: isDerivation v) (pkgs.nur.microcosm // pkgs.nur.blacksky);
      in
      {
        packages = allPackages;
        nixosModules = {
          microcosm = import ./modules/microcosm;
          blacksky = import ./modules/blacksky;
        };
        homeManagerModules = {
          microcosm = import ./modules/microcosm;
          blacksky = import ./modules/blacksky;
        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ deadnix nixpkgs-fmt ];
        };
        tests = import ./tests { inherit pkgs; };
      }
    );
}