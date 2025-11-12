# Fetchers module
#
# Provides custom source fetchers for various repository systems
# All fetchers are properly scoped with their dependencies

{ lib, fetchgit, fetchzip }:

let
  # Load name utilities for consistent derivation naming
  nameUtils = (import ./name-utils.nix { inherit lib; });

  # Load fetch-tangled with proper dependency injection
  fetchTangledFn = import ./fetch-tangled.nix;
in

{
  # Tangled.org repository fetcher
  # Custom implementation for Tangled.org repositories with @ prefixed owners
  fetchFromTangled = fetchTangledFn {
    inherit lib fetchgit fetchzip;
    inherit (nameUtils) repoRevToNameMaybe;
  };
}
