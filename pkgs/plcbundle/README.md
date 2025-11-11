# plcbundle - NUR Package

PLC Bundle is a system for archiving and distributing AT Protocol's DID PLC Directory operations into immutable, cryptographically-chained bundles. This directory contains the NixOS package for plcbundle.

## Overview

- **Package**: `plcbundle`
- **Organization**: Tangled
- **Type**: Infrastructure / Archiving Tool
- **Main Binary**: `plcbundle` CLI tool
- **Repository**: https://tangled.org/@atscan.net/plcbundle

## Features

- **Bundle Creation**: Groups 10,000 operations into compressed, immutable files
- **Cryptographic Chaining**: SHA-256 hashes linking entire operation history
- **HTTP Server**: Serve bundles over HTTP with optional WebSocket streaming
- **Verification**: Verify bundle integrity and chain validity
- **Cloning**: Download pre-made bundles from remote servers (resumable)
- **Spam Detection**: Built-in and custom JavaScript-based detectors
- **DID Indexing**: Efficient DID-to-bundle lookup
- **Performance**: Parallel processing, efficient compression (~5:1 ratio)

## Installation

### Using NUR in NixOS

Add to your `flake.nix`:

```nix
{
  inputs = {
    nur = {
      url = "git+https://your-nur-repo";
    };
  };

  outputs = { self, nixpkgs, nur }:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nur.overlay ];
      };
    in {
      environment.systemPackages = [
        pkgs.nur.tangled-plcbundle
      ];
    };
}
```

### Home Manager

```nix
home.packages = [
  nur.tangled-plcbundle
];
```

### Using nix shell

```bash
nix shell "git+https://your-nur-repo#tangled-plcbundle"
```

## Usage

### CLI Commands

```bash
# Fetch bundles from PLC directory
plcbundle fetch -count 1

# Clone bundles from remote
plcbundle clone https://plc.example.com

# View bundle information
plcbundle info
plcbundle info --verify

# Verify bundle integrity
plcbundle verify
plcbundle verify -bundle 42

# Run HTTP server
plcbundle serve --host 0.0.0.0 --port 8080

# Run spam detection
plcbundle detector run -detector nostr_crosspost

# Build DID index
plcbundle did-index build
```

For complete CLI documentation, see the [plcbundle CLI guide](https://tangled.org/@atscan.net/plcbundle/raw/main/docs/cli.md).

## Configuration

### Environment Variables

- `PLC_DIRECTORY_URL` - PLC directory URL (default: `https://plc.directory`)
- `BUNDLE_DIR` - Bundle storage directory
- `HTTP_HOST` - HTTP server host (default: `localhost`)
- `HTTP_PORT` - HTTP server port (default: `8080`)
- `LOG_LEVEL` - Logging level

### Docker Usage

The package is also available as a Docker image:

```bash
docker pull atscan/plcbundle:latest

# CLI
docker run --rm -v $(pwd)/data:/data atscan/plcbundle plcbundle info

# Server
docker run -d -p 8080:8080 -v $(pwd)/data:/data atscan/plcbundle plcbundle serve --host 0.0.0.0
```

## Package Metadata

- **Type**: Infrastructure
- **Services**: `plcbundle`, `archiving`, `verification`
- **Protocols**: `com.atproto`, `plc`, `did`
- **License**: MIT
- **Platforms**: Unix (Linux + macOS)

### ATProto Capabilities

- Bundle creation and management
- Bundle verification and chain integrity checks
- HTTP serving of bundles
- WebSocket streaming of operations
- Spam detection for operations
- DID indexing and querying

## Documentation

- [Project README](https://tangled.org/@atscan.net/plcbundle/raw/main/README.md)
- [Technical Specification](https://tangled.org/@atscan.net/plcbundle/raw/main/docs/specification.md)
- [Library Documentation](https://tangled.org/@atscan.net/plcbundle/raw/main/docs/library.md)
- [CLI Guide](https://tangled.org/@atscan.net/plcbundle/raw/main/docs/cli.md)
- [Security Model](https://tangled.org/@atscan.net/plcbundle/raw/main/docs/security.md)

## Building from Source

To build the package locally:

```bash
nix build "git+https://your-nur-repo#tangled-plcbundle"
```

Or with flakes:

```bash
cd /path/to/nur
nix flake show
nix build .#tangled-plcbundle
```

## Computing Hashes

To compute the correct hashes for the package:

```bash
# Compute source hash (using dummy hash first)
nix build --impure -L 2>&1 | grep "hash mismatch"

# Compute vendor hash (after updating go.mod/go.sum)
nix build --impure -L 2>&1 | grep "vendorHash"
```

## Organization Metadata

- **Organization**: Tangled
- **Website**: https://tangled.org
- **Repository**: https://tangled.org/@atscan.net/plcbundle
- **ATProto Focus**: Infrastructure, Archiving, Tools

## Troubleshooting

### Build Failures

If the build fails, ensure:
1. The commit hash is valid and accessible from Tangled.org
2. The `hash` and `vendorHash` are correctly computed
3. Go version 1.25+ is available

### Hash Mismatches

To regenerate hashes:

```bash
# Update go.mod/go.sum from source
cd /path/to/plcbundle
go mod download
go mod tidy
```

Then run `nix build` with the dummy hashes to get the actual values.

## Contributing

To update this package:

1. Update the `version` field when a new release is available
2. Update the `rev` to the new commit hash
3. Re-compute `hash` and `vendorHash`
4. Test the build locally before committing

## License

This package and its configuration follow the same MIT license as plcbundle.
