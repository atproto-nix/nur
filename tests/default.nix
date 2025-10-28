{ pkgs }:
{
  constellation = import ./constellation.nix { inherit pkgs; };
  constellation-shell = import ./constellation-shell.nix { inherit pkgs; };
  microcosm-standardized = import ./microcosm-standardized.nix { inherit pkgs; };
  atproto-lib = import ./atproto-lib.nix { inherit pkgs; };
  atproto-core-libs = import ./atproto-core-libs.nix { inherit pkgs; };
  bluesky-packages = import ./bluesky-packages.nix { inherit pkgs; };
  frontpage-packages = import ./frontpage-packages.nix { inherit pkgs; lib = pkgs.lib; };
  frontpage-services = import ./frontpage-services.nix { inherit pkgs; lib = pkgs.lib; };
  indigo-services = import ./indigo-services.nix { inherit pkgs; lib = pkgs.lib; };
  atproto-typescript-libs = import ./atproto-typescript-libs.nix { inherit pkgs; lib = pkgs.lib; };
  third-party-apps-modules = import ./third-party-apps-modules.nix { inherit pkgs; };
  specialized-apps-modules = import ./specialized-apps-modules.nix { inherit pkgs; };
  pds-ecosystem = import ./pds-ecosystem.nix { inherit pkgs; };
  
  # Core library package tests (Task 2.4)
  core-library-build-verification = import ./core-library-build-verification.nix { inherit pkgs; };
  dependency-compatibility = import ./dependency-compatibility.nix { inherit pkgs; };
  security-scanning = import ./security-scanning.nix { inherit pkgs; };
  core-library-validation = import ./core-library-validation.nix { inherit pkgs; };
  
  # NixOS ecosystem integration tests (Task 7.4)
  nixos-ecosystem-integration = import ./nixos-ecosystem-integration.nix { inherit pkgs; };
  
  # Comprehensive CI/CD and maintenance tests (Task 8)
  all-service-modules = import ./all-service-modules.nix { inherit pkgs; };
  automated-security-scanning = import ./automated-security-scanning.nix { inherit pkgs; };
  dependency-update-verification = import ./dependency-update-verification.nix { inherit pkgs; };
  
  # Organizational framework tests
  organizational-framework = import ./organizational-framework.nix { inherit pkgs; lib = pkgs.lib; };
  organizational-modules = import ./organizational-modules.nix { inherit pkgs; };
  backward-compatibility = import ./backward-compatibility.nix { inherit pkgs; };
  module-configuration = import ./module-configuration.nix { inherit pkgs; };
  module-structure-validation = import ./module-structure-validation.nix { inherit pkgs; };
  
  # Service discovery and coordination tests (Task 15)
  service-discovery-coordination = import ./service-discovery-coordination.nix { inherit pkgs; lib = pkgs.lib; };
  
  # Comprehensive CI/CD infrastructure validation (Task 8)
  comprehensive-ci-cd-validation = import ./comprehensive-ci-cd-validation.nix { inherit pkgs; };
}
