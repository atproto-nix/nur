### Example Expansion Plan for NUR

This plan outlines the creation of several new examples to showcase the packages and modules available in this repository. The current `red-dwarf-stack.nix` is a great starting point, and these additions will provide a more complete picture for users.

The new examples will be categorized as follows:

1.  **Full Service Stacks:** Demonstrating how to deploy a complete, interconnected set of services for a real-world use case.
2.  **Standalone Service Examples:** Showcasing how to run individual, smaller services with minimal configuration.
3.  **Development Environment Examples:** Providing reproducible development shells for working on the packaged software.
4.  **Package Integration Examples:** Showing how to use packages from this NUR as dependencies in another Nix flake.

---

#### 1. Full Service Stacks

These examples are designed to model production-like deployments.

*   **`pds-stack.nix`**
    *   **Description:** A complete AT Protocol Personal Data Server (PDS) stack. This is the most critical example, as it demonstrates the core functionality of the ecosystem.
    *   **Components:**
        *   **PDS:** `whey-party.red-dwarf`
        *   **BGS (Big Graph Service):** `bluesky.indigo`
        *   **DID Service:** A simple DID resolver like `smokesignal-events.quickdid`.
        *   **Reverse Proxy:** An Nginx or Caddy configuration to route traffic to the appropriate services.
    *   **Goal:** Provide a user with a fully functional, federated PDS setup that they can deploy and use.

*   **`microcosm-stack.nix`**
    *   **Description:** An example deploying the full suite of `microcosm` services. This showcases a more experimental and diverse set of interconnected services.
    *   **Components:**
        *   `microcosm.constellation`
        *   `microcosm.quasar`
        *   `microcosm.reflector`
        *   `microcosm.spacedust`
        *   `microcosm.who-am-i`
    *   **Goal:** Demonstrate the interoperability of the `microcosm` modules and provide a testbed for their interactions.

---

#### 2. Standalone Service Examples

These are minimal, single-purpose examples perfect for new users.

*   **`simple-appview.nix`**
    *   **Description:** A minimal deployment of a single AppView service.
    *   **Component:** `tangled.tangled-appview`
    *   **Goal:** Show the simplest possible way to get an AppView running, which a user could point their client at.

*   **`simple-did-service.nix`**
    *   **Description:** A lightweight example for running a DID utility service.
    *   **Component:** `smokesignal-events.quickdid`
    *   **Goal:** Provide a quick and easy way to run a utility for creating and resolving DIDs, useful for development and testing.

---

#### 3. Development Environment Examples

These examples focus on providing a `devShell` for developers.

*   **`dev-shell-indigo.nix`**
    *   **Description:** A `flake.nix` that provides a development shell for working on `indigo`.
    *   **Components:**
        *   The `indigo` source code.
        *   Required Go toolchain.
        *   Dependent libraries and build tools.
    *   **Goal:** Allow a developer to immediately start building and testing `indigo` without needing to manually install dependencies.

*   **`dev-shell-atproto-rs.nix`**
    *   **Description:** A `flake.nix` providing a shell for a Rust-based AT Protocol project, using libraries from this NUR.
    *   **Components:**
        *   Rust toolchain.
        *   `pkgs.bluesky.atproto-repo`, `pkgs.bluesky.atproto-xrpc`, etc.
    *   **Goal:** Show Rust developers how to set up an environment for building AT Protocol applications using the provided Rust crates.

---

#### 4. Package Integration Examples

This demonstrates how a downstream user would consume packages from this NUR.

*   **`package-usage-example.nix`**
    *   **Description:** A minimal `flake.nix` for a separate project that uses this NUR as an input.
    *   **Components:**
        *   A `flake.nix` with an input for `nur-atproto`.
        *   A `default.nix` that builds a trivial package (e.g., a "hello world" script) that depends on a package from this NUR (e.g., `pkgs.bluesky.atproto-api`).
    *   **Goal:** Provide a clear, copy-pasteable example for users who want to use your packages in their own projects.
