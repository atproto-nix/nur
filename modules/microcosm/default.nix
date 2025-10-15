{ pkgs, ... }:

{
  imports = [
    ./constellation.nix
    ./spacedust.nix
    ./slingshot.nix
    ./ufos.nix
    ./who-am-i.nix
    ./pocket.nix
    ./reflector.nix
  ];
}