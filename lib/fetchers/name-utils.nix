# Helper utilities for generating derivation names from repository information
#
# This module provides utilities for generating consistent, reproducible names
# for fetched repositories based on their repo name and revision information.

{ lib }:

{
  # Generate a derivation name from repository metadata
  # Similar to nixpkgs fetchFromGitHub pattern
  #
  # Arguments:
  #   repo: Repository name (e.g., "my-repo")
  #   rev: Revision identifier, typically commit hash or tag (e.g., "abc123def" or "v1.0.0")
  #   source: Source identifier for debugging (e.g., "tangled", "github")
  #
  # Returns:
  #   A sanitized derivation name combining repo, rev prefix, and source
  #
  # Examples:
  #   repoRevToNameMaybe "spindle" "2e5a4cde" "tangled"
  #   # => "spindle-2e5a4cde-tangled"
  #
  #   repoRevToNameMaybe "core" "v1.0.0" "tangled"
  #   # => "core-v1.0.0-tangled"
  repoRevToNameMaybe = repo: rev: source:
    if repo != null && rev != null then
      let
        # Sanitize repo name (remove special chars, lowercase)
        sanitizedRepo = lib.strings.sanitizeDerivationName repo;
        # Take first 8 chars of rev for brevity if it looks like a hash
        shortRev =
          if lib.stringLength rev > 10 then
            builtins.substring 0 8 rev
          else
            rev;
        # Sanitize revision
        sanitizedRev = lib.strings.sanitizeDerivationName shortRev;
        sanitizedSource = lib.strings.sanitizeDerivationName source;
      in
        "${sanitizedRepo}-${sanitizedRev}-${sanitizedSource}"
    else
      null;
}
