# Technology Stack

## Build System

This repository uses **Nix Flakes** as the primary build and packaging system with the following key components:

- **Nix**: Declarative package management and build system
- **Crane**: Rust-specific build utilities for Cargo-based projects
- **Rust Overlay**: Provides specific Rust toolchain versions
- **Flake Utils**: Cross-platform build support

## Core Dependencies

### Build Tools
- `crane`: Rust package building with Cargo integration
- `rust-overlay`: Rust toolchain management
- `nixpkgs`: Base package collection
- `flake-utils`: Multi-platform support

### Runtime Dependencies
- **Rust Applications**: OpenSSL, zstd, lz4, RocksDB, SQLite, pkg-config
- **System Libraries**: LLVM/Clang for native compilation
- **Database Backends**: PostgreSQL, SQLite, RocksDB support

## Language Support

### Primary Languages
- **Rust**: Primary language for ATproto services (using Crane build system)
- **Go**: Secondary language support for applications like Tangled
- **Node.js/TypeScript**: Web applications and frontend services
- **Deno**: Modern TypeScript runtime support

### Build Patterns
- **Rust**: Use `craneLib.buildPackage` with shared dependency artifacts
- **Node.js**: Use `buildNpmPackage` with proper lockfile handling
- **Go**: Use `buildGoModule` with vendor directory support

## Common Commands

### Development
```bash
# Enter development shell
nix develop

# Build all packages
nix build

# Build specific package
nix build .#constellation

# Run package directly
nix run .#constellation

# Check flake
nix flake check
```

### Testing
```bash
# Run tests
nix build .#tests

# Test specific module
nix build .#tests.constellation-shell
```

### Maintenance
```bash
# Update flake inputs
nix flake update

# Format Nix files
nixpkgs-fmt .

# Check for dead code
deadnix
```

## Package Structure

### Standard Package Template
```nix
{ lib, stdenv, fetchFromGitHub, craneLib, ... }:

craneLib.buildPackage {
  pname = "package-name";
  version = "0.1.0";
  
  src = fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "commit-hash";
    sha256 = "hash";
  };
  
  # Common environment for Rust builds
  env = {
    OPENSSL_NO_VENDOR = "1";
    ZSTD_SYS_USE_PKG_CONFIG = "1";
  };
  
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl zstd ];
}
```

### Module Configuration Pattern
```nix
{ config, lib, pkgs, ... }:

{
  options.services.service-name = {
    enable = mkEnableOption "service description";
    package = mkOption {
      type = types.package;
      default = pkgs.nur.package-name;
    };
    # Service-specific options
  };
  
  config = mkIf cfg.enable {
    # systemd service configuration
    # user/group management
    # security hardening
  };
}
```

## Security Practices

### Service Hardening
- Use dedicated system users and groups
- Apply systemd security restrictions (NoNewPrivileges, ProtectSystem, etc.)
- Implement proper file permissions and directory isolation
- Enable network isolation where appropriate

### Build Security
- Pin exact commit hashes for source fetching
- Use content-addressed derivations
- Validate checksums for all external dependencies
- Apply security patches through overlays when needed