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

## Continuous Integration (CI)

This repository uses GitHub Actions for Continuous Integration to ensure code quality, correctness, and reproducibility. The CI pipeline performs the following checks on every push and pull request:

*   **NixOS Tests**: All defined NixOS tests are executed to verify that services and modules can be enabled and started correctly within a virtualized NixOS environment.
*   **Code Formatting**: `nixpkgs-fmt` is used to enforce consistent code formatting across all Nix files.
*   **Dead Code Detection**: `deadnix` is used to identify and prevent dead code from accumulating in the Nix expressions.
*   **Cachix Integration**: Build artifacts are cached using [Cachix](https://cachix.org/) to speed up subsequent builds. The cache for this repository is `atproto.cachix.org`.

### Cachix Setup

To enable caching for your builds, you need to set the `CACHIX_SIGNING_KEY` as a secret in your GitHub repository settings. The signing key for `atproto.cachix.org` is:

```
atproto.cachix.org-1:mgH0q9dt3ZI9puHEfIGDnkRBfT80I3vfEh4Wda2B0rk=
```

Please add this value as a secret named `CACHIX_SIGNING_KEY` in your repository settings (Settings -> Secrets and variables -> Actions).

## Running Tests Locally

You can run the NixOS tests locally using the following command:

```bash
nix flake check
```

This command will evaluate and build all checks defined in the `flake.nix`, including the NixOS tests.
