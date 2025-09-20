{ pkgs, ... }:

{
  imports = [
    ./constellation.nix
    ./spacedust.nix
    ./slingshot.nix
    ./ufos.nix
    ./jetstream.nix
    ./who-am-i.nix
    ./quasar.nix
    ./pocket.nix
    ./reflector.nix
  ];
}
