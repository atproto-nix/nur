# Gemini Agent Guide for nur-atproto

This document provides a guide for Gemini agents to understand and interact with the `nur-atproto` repository.

## Project Overview

`nur-atproto` is a Nix-based repository for packaging and deploying services related to the AT Protocol and Bluesky. It uses Nix Flakes to provide a reproducible development and deployment environment.

The repository is structured into two main parts:

1.  **Packages (`pkgs`):** Contains Nix package definitions for core components.
2.  **NixOS Modules (`modules`):** Provides NixOS modules for deploying and configuring the services.

## Packages

This repository provides the following packages:

### Microcosm Services

A suite of services that form a personal data server (PDS) or a related AT Protocol service.

-   **`constellation`**: A global atproto backlink index. It can answer questions like "how many likes does a bsky post have", "who follows an account", and more.

    **Usage:**
    -   `--bind`: listen address (default: `0.0.0.0:6789`)
    -   `--bind-metrics`: metrics server listen address (default: `0.0.0.0:8765`)
    -   `--jetstream`: Jetstream server to connect to
    -   `--data`: path to store data on disk
    -   `--backend`: storage backend to use (`memory` or `rocks`)

-   **`pocket`**: A service for storing non-public user data, like application preferences.

    **Usage:**
    -   `--db`: path to the sqlite db file
    -   `--init-db`: initialize the db and exit
    -   `--domain`: domain for serving a did doc

-   **`quasar`**: An indexed replay and fan-out for event stream services (work in progress).

-   **`reflector`**: A tiny did:web service server that maps subdomains to a single service endpoint.

    **Usage:**
    -   `--id`: DID document service ID
    -   `--type`: service type
    -   `--service-endpoint`: HTTPS endpoint for the service
    -   `--domain`: parent domain

-   **`slingshot`**: A fast, eager, production-grade edge cache for atproto records and identities.

    **Usage:**
    -   `--jetstream`: Jetstream server to connect to
    -   `--cache-dir`: path to keep disk caches
    -   `--domain`: domain pointing to this server

-   **`spacedust`**: A global atproto interactions firehose. Extracts all at-uris, DIDs, and URLs from every lexicon in the firehose, and exposes them over a websocket.

    **Usage:**
    -   `--jetstream`: Jetstream server to connect to

-   **`ufos`**: A service that provides timeseries stats and sample records for every collection ever seen in the atproto firehose.

    **Usage:**
    -   `--jetstream`: Jetstream server to connect to
    -   `--data`: location to store persist data to disk

-   **`who-am-i` (deprecated)**: An identity bridge for microcosm demos. It is being retired.

    **Usage:**
    -   `--app-secret`: secret key for cookie-signing (env: `APP_SECRET`)
    -   `--oauth-private-key`: path to at-oauth private key (env: `OAUTH_PRIVATE_KEY`)
    -   `--jwt-private-key`: path to jwt private key
    -   `--base-url`: client-reachable base url (env: `BASE_URL`)
    -   `--bind`: host:port to bind to (env: `BIND`, default: `127.0.0.1:9997`)

### Microcosm Libraries

-   **`links`**: A Rust library for parsing and extracting links (at-uris, DIDs, and URLs) from atproto records.

### Blacksky

A suite of tools related to the AT Protocol ecosystem.

-   `pds`
-   `relay`
-   `feedgen`
-   `satnav`
-   `firehose`
-   `jetstream-subscriber`
-   `labeler`

## NixOS Modules

The `microcosm` modules are designed to be composed together to create a running AT Protocol environment. Each module corresponds to a specific service.

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
**Note:** The `trusted-public-keys` value is a placeholder. I was unable to find the correct public key.

## Interacting with the Project

As a Gemini agent, you can use the Nix command-line interface to work with this repository.

### Building Packages

To build a package, use the `nix build` command with the corresponding flake output. For example, to build the `constellation` package:

```bash
nix build .#constellation
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