# Research Summary: pds-dash Frontend Dashboard

**Date:** 2025-10-25 10:30:00 (Approximate)

## 1. Introduction
This document summarizes the research conducted on the `pds-dash` frontend dashboard repository. The goal was to understand its purpose, technology stack, project structure, and key configurations.

## 2. Project Overview
`pds-dash` is a frontend dashboard designed to display statistics and information for an ATProto Personal Data Server (PDS). It aims to provide a user-friendly interface for monitoring PDS activity. The project utilizes Svelte for its UI, Vite as a build tool, and Deno for development tooling and task management. It is designed to be configurable for various PDS instances and supports custom theming.

## 3. Key Findings

### 3.1. `README.md`
- **Purpose:** Clearly states `pds-dash` is a frontend dashboard for ATProto PDS statistics.
- **Prerequisites:** Deno is required.
- **Setup:** Clone, copy `config.ts.example` to `config.ts`, edit, and run `deno install`.
- **Development:** `deno task dev` for hot-reloading development server.
- **Building:** `deno task build` for optimized bundle in `dist/`.
- **Deployment:** Mentions `.forgejo/workflows/deploy.yaml` for CI/CD and suggests co-hosting with PDS.
- **Configuration:** `config.ts` is the primary configuration file.
- **Theming:** Themes are in `themes/`, defined by `theme.css`, and selected via `config.ts`.
- **License:** MIT.
- **Reference:** `/Users/jack/Software/nur/pds-dash/README.md`

### 3.2. `package.json`
- **Purpose:** Defines project metadata, dependencies, and build scripts for the frontend.
- **Key Information for Nix Packaging:**
    - `name`: "web"
    - `version`: "0.0.0"
    - `type`: "module" (ES module usage)
    - `scripts.build`: `vite build` (Primary command for production build).
    - `dependencies`: Lists runtime dependencies (e.g., `@atcute/bluesky`, `moment`, `svelte-infinite-loading`). These will need to be provided by Nix.
    - `devDependencies`: Lists development dependencies (e.g., `@sveltejs/vite-plugin-svelte`, `typescript`, `vite`, `svelte-check`). These are crucial for the build process and will also be managed by Nix.
- **Nix Packaging Implication:** The project uses `vite build` for its production build, and all Node.js dependencies (both `dependencies` and `devDependencies`) must be managed by Nix, likely using `buildNpmPackage` or similar.
- **Reference:** `/Users/jack/Software/nur/pds-dash/package.json`

### 3.3. `deno.lock`
- **Purpose:** Manages Deno dependencies, including npm packages, and ensures reproducible builds by pinning exact versions and integrity hashes.
- **Key Information for Nix Packaging:** Contains a detailed manifest of all direct and transitive dependencies, including their versions and integrity checks.
- **Nix Packaging Implication:** This file is critical for ensuring reproducible builds in Nix. Nix's Deno packaging infrastructure will leverage this file to fetch and manage the exact dependency tree, including npm packages, ensuring that the build environment is consistent.
- **Reference:** `/Users/jack/Software/nur/pds-dash/deno.lock`

### 3.4. `vite.config.ts`
- **Purpose:** Configures Vite, the build tool for the frontend.
- **Key Information for Nix Packaging:**
    - **Plugins:** Uses `@sveltejs/vite-plugin-svelte` for Svelte compilation and a custom `themePlugin()` imported from `./theming.ts`.
    - **Build Output:** Vite's default output directory is `dist/`, which is where the optimized bundle will be placed (as confirmed by `README.md`).
- **Nix Packaging Implication:** The Nix build will need to ensure that both the standard Svelte Vite plugin and the custom `theming.ts` plugin are correctly integrated into the `vite build` process. The `dist/` directory will be the primary output of the build.
- **Reference:** `/Users/jack/Software/nur/pds-dash/vite.config.ts`

### 3.5. `svelte.config.js`
- **Purpose:** Configures Svelte-specific aspects of the project.
- **Key Information for Nix Packaging:**
    - `preprocess`: Uses `vitePreprocess()` from `@sveltejs/vite-plugin-svelte`.
- **Nix Packaging Implication:** This indicates a standard Svelte/Vite setup for preprocessing Svelte components. Nix's Node.js/Svelte packaging tools should handle this configuration without requiring special adjustments, provided the `@sveltejs/vite-plugin-svelte` dependency is correctly resolved.
- **Reference:** `/Users/jack/Software/nur/pds-dash/svelte.config.js`

### 3.6. `tsconfig.json`
- **Purpose:** Root TypeScript configuration file, referencing application and Node.js specific configurations.
- **Key Information for Nix Packaging:**
    - References `tsconfig.app.json` (for application code) and `tsconfig.node.json` (for build scripts).
    - **`tsconfig.app.json`:**
        - Extends `@tsconfig/svelte/tsconfig.json`.
        - `compilerOptions`: `target: "ESNext"`, `module: "ESNext"`, `allowJs: true`, `checkJs: true`, `isolatedModules: true`, `moduleDetection: "force"`.
        - `include`: `["src/**/*.ts", "src/**/*.js", "src/**/*.svelte"]`.
    - **`tsconfig.node.json`:**
        - `compilerOptions`: `target: "ES2022"`, `module: "ESNext"`, `moduleResolution: "bundler"`, `noEmit: true`.
        - `include`: `["vite.config.ts"]`.
- **Nix Packaging Implication:** The Nix build environment must provide `@tsconfig/svelte` for `tsconfig.app.json`. The `noEmit: true` in `tsconfig.node.json` indicates that `vite.config.ts` is type-checked but not compiled to JavaScript as part of the build output. The `include` paths define the scope of TypeScript compilation and type-checking.
- **Reference:**
    - `/Users/jack/Software/nur/pds-dash/tsconfig.json`
    - `/Users/jack/Software/nur/pds-dash/tsconfig.app.json`
    - `/Users/jack/Software/nur/pds-dash/tsconfig.node.json`

### 3.7. `src` Directory
- **Purpose:** Contains the main application source code.
- **Contents:**
    - `main.ts`: The primary entry point for the Svelte application.
    - `App.svelte`: The root Svelte component.
    - `app.css`: Global styles for the application.
    - `vite-env.d.ts`: TypeScript declaration file for Vite environment variables.
    - `lib/`: A subdirectory containing reusable components and utilities:
        - `AccountComponent.svelte`: Svelte component for account display.
        - `pdsfetch.ts`: Logic for fetching data from the ATProto PDS.
        - `PostComponent.svelte`: Svelte component for post display.
- **Nix Packaging Implication:** The entire `src` directory, including all its subdirectories and files, must be included as input to the build process. `main.ts` serves as the application's entry point for the Vite build.
- **Reference:** `/Users/jack/Software/nur/pds-dash/src`

### 3.8. `public` Directory
- **Purpose:** Stores static assets served directly by the web server.
- **Contents:** `favicon.ico`.
- **Nix Packaging Implication:** The contents of this directory (e.g., `favicon.ico`) must be copied to the final output directory of the built application, typically the `dist/` folder, to be served alongside the compiled frontend assets.
- **Reference:** `/Users/jack/Software/nur/pds-dash/public`

### 3.9. `config.ts.example`
- **Purpose:** Provides an example application-level configuration.
- **Nix Packaging Implication:** This file should be installed as part of the Nix package, possibly as `config.ts.example`, to serve as a reference for users. For NixOS deployments, a module could be created to generate a `config.ts` file based on NixOS options, allowing users to configure the dashboard declaratively.
- **Reference:** `/Users/jack/Software/nur/pds-dash/config.ts.example`

### 3.10. `themes` Directory
- **Purpose:** Contains definitions for different visual themes for the dashboard.
- **Structure:** Each subdirectory within `themes/` represents a distinct theme, and typically contains a `theme.css` file (e.g., `themes/default/theme.css`, `themes/express/theme.css`, `themes/witchcraft/theme.css`).
- **Nix Packaging Implication:** The entire `themes` directory and all its contents must be included in the final Nix package. The application dynamically loads these themes based on the `config.ts` setting, so they need to be present in the installed package's file system.
- **Reference:** `/Users/jack/Software/nur/pds-dash/themes`

### 3.11. `.forgejo/workflows/deploy.yaml`
- **Purpose:** Defines the CI/CD workflow for deploying the `pds-dash` application.
- **Key Information for Nix Packaging:**
    - **Prerequisites:** The workflow explicitly sets up Node.js (v20) and Deno.
    - **Configuration Handling:** A critical step involves copying `config.ts` from an external `pds-dash-overrides` repository (`cp overrides/config.ts ./config.ts`). This means `config.ts` is not part of the main source and is provided at deployment.
    - **Build Steps:** Executes `deno install` to manage dependencies and `deno task build` to build the project.
    - **Deployment:** Uses SSH and SCP to transfer the built `dist/` directory to a web server.
- **Nix Packaging Implication:**
    - The Nix build environment must provide Node.js (v20 or compatible) and Deno.
    - The Nix package should *not* include a default `config.ts`. Instead, it should be designed to accept `config.ts` as an input or expect it to be generated by a NixOS module at deployment time. The `config.ts.example` should be installed as a reference.
    - The Nix build process will need to execute `deno install` (or equivalent dependency fetching) and `deno task build` to produce the final web assets.
    - The output of the Nix package will be the contents of the `dist/` directory, ready for static serving.
- **Reference:** `/Users/jack/Software/nur/pds-dash/.forgejo/workflows/deploy.yaml`
