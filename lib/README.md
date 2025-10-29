# ATProto Packaging Utilities Library

This library provides standardized helper functions for packaging AT Protocol applications in Nix. It includes utilities for different language ecosystems, package metadata validation, and service configuration helpers.

**Note:** This library is being modernized. The new modular packaging system is in `lib/packaging/`. Legacy utilities in `lib/atproto.nix` are maintained for backward compatibility.

## Core Functions

### `mkAtprotoPackage`

Creates an ATProto package with standardized metadata.

```nix
mkAtprotoPackage {
  type = "application";  # "application", "library", or "tool"
  services = [ "pds" ];  # List of services provided
  protocols = [ "com.atproto" "app.bsky" ];  # ATProto protocols supported
  
  # Standard package arguments...
  pname = "my-atproto-app";
  version = "1.0.0";
  # ...
}
```

### `mkRustAtprotoService`

Builds Rust ATProto services with standard environment and dependencies.

```nix
mkRustAtprotoService {
  pname = "my-rust-service";
  version = "1.0.0";
  src = fetchFromGitHub { /* ... */ };
  type = "application";
  services = [ "pds" ];
  
  # Additional crane arguments...
}
```

### `mkNodeAtprotoApp`

Builds Node.js ATProto applications with standard configuration.

```nix
mkNodeAtprotoApp {
  buildNpmPackage = pkgs.buildNpmPackage;
  pname = "my-node-app";
  version = "1.0.0";
  src = fetchFromGitHub { /* ... */ };
  npmDepsHash = "sha256-...";
  type = "application";
  services = [ "feedgen" ];
}
```

### `mkGoAtprotoApp`

Builds Go ATProto applications with standard configuration.

```nix
mkGoAtprotoApp {
  buildGoModule = pkgs.buildGoModule;
  pname = "my-go-app";
  version = "1.0.0";
  src = fetchFromGitHub { /* ... */ };
  vendorHash = "sha256-...";
  type = "application";
  services = [ "relay" ];
}
```

### `mkRustWorkspace`

Builds multiple packages from a Rust workspace with shared dependencies.

```nix
mkRustWorkspace {
  src = fetchFromGitHub { /* ... */ };
  members = [ "service-a" "service-b" "tool-c" ];
  pname = "my-workspace";
  version = "1.0.0";
  commonEnv = { /* additional environment variables */ };
}
```

## Service Configuration Helpers

### `mkServiceConfig`

Creates standardized NixOS service configuration with security hardening.

```nix
mkServiceConfig {
  serviceName = "my-atproto-service";
  package = myAtprotoPackage;
  user = "my-service";
  group = "my-service";
  dataDir = "/var/lib/my-service";
}
```

### `mackuba-lycan` module `allowedHosts` option

To configure the allowed hosts for the `mackuba-lycan` service, set the `services.mackuba-lycan.allowedHosts` option in your NixOS configuration. This option expects a list of strings, where each string is an allowed hostname.

```nix
services.mackuba-lycan.allowedHosts = [ "lycan.example.com" "localhost" ];
```

## Validation Utilities

### `validatePackageMetadata`

Validates ATProto package metadata schema.

```nix
validatePackageMetadata myPackage
```

## Standard Environments

The library provides pre-configured environments for common build scenarios:

- `defaultRustEnv`: Standard environment variables for Rust ATProto services
- `defaultRustNativeInputs`: Standard native build inputs for Rust builds
- `defaultRustBuildInputs`: Standard runtime dependencies for Rust ATProto services

## Usage Examples

### Simple Rust Service

```nix
{ pkgs, craneLib, ... }:

let
  atprotoLib = pkgs.callPackage ./lib/atproto.nix { inherit craneLib; };
in
{
  my-pds = atprotoLib.mkRustAtprotoService {
    pname = "my-pds";
    version = "1.0.0";
    src = fetchFromGitHub {
      owner = "my-org";
      repo = "my-pds";
      rev = "v1.0.0";
      hash = "sha256-...";
    };
    type = "application";
    services = [ "pds" ];
    protocols = [ "com.atproto" ];
  };
}
```

### Multi-Package Workspace

```nix
{ pkgs, craneLib, ... }:

let
  atprotoLib = pkgs.callPackage ./lib/atproto.nix { inherit craneLib; };
in
atprotoLib.mkRustWorkspace {
  src = fetchFromGitHub {
    owner = "my-org";
    repo = "atproto-services";
    rev = "v1.0.0";
    hash = "sha256-...";
  };
  members = [ "pds" "relay" "feedgen" ];
  pname = "atproto-services";
  version = "1.0.0";
}
```

## Metadata Schema

All ATProto packages include standardized metadata:

```nix
{
  atproto = {
    type = "application";  # Package type
    services = [ "pds" ];  # Services provided
    protocols = [ "com.atproto" ];  # Protocols supported
    schemaVersion = "1.0";  # Metadata schema version
  };
}
```

This metadata enables automated tooling, dependency resolution, and service discovery within the ATProto ecosystem.