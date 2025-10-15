{ pkgs }:
{
  constellation = import ./constellation.nix { inherit pkgs; };
  constellation-shell = import ./constellation-shell.nix { inherit pkgs; };
  pocket-shell = import ./pocket-shell.nix { inherit pkgs; };
  reflector-shell = import ./reflector-shell.nix { inherit pkgs; };
  slingshot-shell = import ./slingshot-shell.nix { inherit pkgs; };
  spacedust-shell = import ./spacedust-shell.nix { inherit pkgs; };
  ufos-shell = import ./ufos-shell.nix { inherit pkgs; };
  who-am-i-shell = import ./who-am-i-shell.nix { inherit pkgs; };
}
