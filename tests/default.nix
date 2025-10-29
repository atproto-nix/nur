{ pkgs }:
{
  # Core package tests
  constellation = import ./constellation.nix { inherit pkgs; };
  constellation-shell = import ./constellation-shell.nix { inherit pkgs; };
  microcosm-constellation = import ./microcosm-constellation.nix { inherit pkgs; };
  microcosm-standardized = import ./microcosm-standardized.nix { inherit pkgs; };

  # Package ecosystem tests
  bluesky-packages = import ./bluesky-packages.nix { inherit pkgs; };
  bluesky-indigo = import ./bluesky-indigo.nix { inherit pkgs; };
  frontpage-packages = import ./frontpage-packages.nix { inherit pkgs; lib = pkgs.lib; };
  mackuba-lycan = import ./mackuba-lycan.nix { inherit pkgs; };

  # Service tests
  blacksky-pds = import ./blacksky-pds.nix { inherit pkgs; };
  frontpage-services = import ./frontpage-services.nix { inherit pkgs; lib = pkgs.lib; };
  indigo-services = import ./indigo-services.nix { inherit pkgs; lib = pkgs.lib; };
  all-service-modules = import ./all-service-modules.nix { inherit pkgs; };
  organizations-services = import ./organizations-services.nix { inherit pkgs; };

  # Infrastructure tests
  pds-ecosystem = import ./pds-ecosystem.nix { inherit pkgs; };
  security-scanning = import ./security-scanning.nix { inherit pkgs; };
  nixos-ecosystem-integration = import ./nixos-ecosystem-integration.nix { inherit pkgs; };
  module-structure-validation = import ./module-structure-validation.nix { inherit pkgs; };
}
