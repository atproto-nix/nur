{ pkgs, ... }:

{
  imports = [
    ./constellation.nix
    ./spacedust.nix
    ./slingshot.nix
    ./ufos.nix
    ./who-am-i.nix
    ./quasar.nix
    ./pocket.nix
    ./reflector.nix
  ];
}