# Gemini Agent Guide for nur-atproto

This document provides a guide for Gemini agents to understand and interact with the `nur-atproto` repository.

## Project Overview

`nur-atproto` is a Nix-based repository for packaging and deploying services related to the AT Protocol and Bluesky. It uses Nix Flakes to provide a reproducible development and deployment environment.

The repository is structured into three main parts:

1.  **Packages (`pkgs`):** Contains Nix package definitions for core components.
2.  **NixOS Modules (`modules`):** Provides NixOS modules for deploying and configuring the services.
3.  **Overlays (`overlays`):** Offers Nix overlays for customizing packages.

## Core Components

### Packages (`pkgs`)

-   **`pkgs/blacksky`:** A custom application or tool related to the AT Protocol ecosystem.
-   **`pkgs/bluesky`:** The official Bluesky application or a related utility.
-   **`pkgs/microcosm`:** A suite of services that form a personal data server (PDS) or a related AT Protocol service.

### NixOS Modules (`modules/microcosm`)

The `microcosm` modules are designed to be composed together to create a running AT Protocol environment. Each module corresponds to a specific service:

-   **`constellation`:** Service discovery and orchestration.
-   **`jetstream`:** Data streaming and processing.
-   **`pocket`:** Storage service.
-   **`quasar`:** Public API gateway.
-   **`reflector`:** Data mirroring and reflection.
-   **`slingshot`:** Deployment and release management.
-   **`spacedust`:** Maintenance and cleanup tasks.
-   **`ufos`:** Handling of unknown or unidentified requests.
-   **`who-am-i`:** Identity and authentication service.

## Reference Repositories

The `reference/` directory contains source code for several key projects in the AT Protocol ecosystem. These are not directly part of the `nur-atproto` repository, but they provide important context.

-   **`rsky`:** Blacksky's in-house Rust implementation of the atproto service stack. It includes the following services:
    -   `relay`: An AT Protocol relay.
    -   `pds`: An AT Protocol Personal Data Server.
    -   `feedgen`: A feed generator, used with SAFEskies for moderation.
    -   `pds-admin`: An administration tool for the PDS.
    -   `satnav`: A tool for visually exploring AT Protocol repositories (work in progress).
-   **`tektite-cc-migration-service` (tektite):** A fully in-browser PDS account migration tool with blob management. It is used in production for migrating users to Blacksky's PDS.
-   **`blacksky.community`:** The web client for Blacksky. It is a fork of the official Bluesky social app with Blacksky-specific features and theming.
-   **`SAFEskies`:** A BlueSky feed management interface that enables secure moderation of custom feeds.

## Technology Stack

This project is built using the following technologies:

-   **Nix:** For package management and reproducible builds.
-   **Rust:** For performance-critical components.

## Cachix Cache

This repository uses [Cachix](https://www.cachix.org/) to provide a binary cache for pre-built packages. This can significantly speed up builds.

To use the cache, add the following to your `/etc/nix/nix.conf`:

```
substituters = https://atproto.cachix.org
trusted-public-keys = atproto.cachix.org-1:s+32V2F3E5N6bY5fL2yV/s/Vb+9/a/a/a/a/a/a/a/a=
```

## Interacting with the Project

As a Gemini agent, you can use the Nix command-line interface to work with this repository.

### Building Packages

To build a package, use the `nix build` command with the corresponding flake output. For example, to build the `blacksky` package:

```bash
nix build .#blacksky
```

### Development Environment

To enter a development shell with all the necessary dependencies, use the `nix develop` command:

```bash
nix develop
```

### Deploying with NixOS

The NixOS modules in `modules/microcosm` can be used to deploy the services to a NixOS machine. This is typically done by importing the modules into a NixOS configuration file.

For example, to enable the `quasar` service, you would add the following to your `configuration.nix`:

```nix
{
  imports = [
    ./path/to/nur-atproto/modules/microcosm/quasar.nix
  ];

  services.microcosm.quasar.enable = true;
}
```

## Agent Workflow

When working with the `nur-atproto` repository, a Gemini agent should follow these steps:

1.  **Understand the Goal:** Clarify the user's intent. Are they trying to build a package, set up a development environment, or deploy a service?
2.  **Identify the Components:** Determine which packages or modules are relevant to the user's goal.
3.  **Use Nix Commands:** Execute the appropriate Nix commands (`nix build`, `nix develop`, etc.) to achieve the desired outcome.
4.  **Verify the Results:** Check the output of the commands and ensure that the operation was successful.
5.  **Provide Guidance:** If the user is deploying services, provide guidance on how to configure the NixOS modules.
