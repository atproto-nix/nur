# Common utility modules for NixOS
{ config, lib, pkgs, ... }:

{
  imports = [
    ./static-site-deploy.nix
    ./nixos-integration.nix
  ];
}
