# ATproto NUR

Nix User Repository for ATproto Services and Tools

Development is primarily done on [Tangled](https://tangled.org) at [@atproto-nix.org/nur](tangled.sh/@atproto-nix.org/nur) with a Github [mirror](https://github.com/atproto-nix/nur).

[![Cachix Cache](https://img.shields.io/badge/cachix-atproto-blue.svg)](https://atproto.cachix.org)

## Usage

This repository is a Nix Flake. You can add it to your own flake's inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nur.url = "github:atproto-nix/nur";
  };
}
