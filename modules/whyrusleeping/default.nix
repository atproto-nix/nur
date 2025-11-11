{ config, lib, pkgs, ... }:

{
  imports = [
    ./konbini.nix
    ./konbini-frontend.nix
  ];
}
