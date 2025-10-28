# This function parses a deno.lock file and returns a derivation
# that contains all the remote dependencies.

{ lib, pkgs }:

lockFileContent:

let
  lockFile = builtins.fromJSON lockFileContent;

in
lib.mapAttrs (url: hash: pkgs.fetchurl {
  inherit url;
  sha256 = hash;
}) lockFile.remote
