{ pkgs }:
{
  constellation = import ./constellation.nix { inherit pkgs; };
  constellation-shell = import ./constellation-shell.nix { inherit pkgs; };
}
