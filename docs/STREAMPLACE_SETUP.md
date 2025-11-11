# Streamplace Dual Build Setup

## Overview

This document describes the complete setup for Streamplace with **dual build variants** in the NUR:

1. **Source Build** (`streamplace`) - Full compilation from Tangled.org
2. **Binary Build** (`streamplace-binary`) - Prebuilt release binaries

Both variants are fully integrated into the NUR package system with automatic organizational metadata, module support, and proper flake exports.

## File Structure

```
pkgs/stream-place/
├── default.nix          # Organization aggregator (exports both variants)
├── streamplace.nix      # Source build definition (buildGoModule)
├── binary.nix           # Binary release definition (stdenv)
└── VARIANTS.md          # Detailed variant documentation
```

## Quick Start

### Building from Source
```bash
# Build the source variant
nix build .#stream-place-streamplace

# Or use the flattened name
nix build .#stream-place.streamplace

# Run directly
nix run .#stream-place-streamplace -- --help
```

### Building from Binary
```bash
# Build the binary variant
nix build .#stream-place-streamplace-binary

# Or use the alias
nix build .#stream-place.binary

# Run directly
nix run .#stream-place-streamplace-binary -- --help
```

## Implementation Details

### Source Build (streamplace.nix)

**Purpose**: Full control and customization for development

**Key Features:**
- Builds from source on Tangled.org
- Multi-platform support (unix)
- Complete debugging capabilities
- Latest development code
- Full multimedia stack included

**Specifications:**
```nix
buildGoModule {
  pname = "streamplace";
  version = "unstable-2025-01-23";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@stream.place";
    repo = "streamplace";
    rev = "a40860f005ba4da989cfe1a5c39d29fa3564fea6";
    hash = "sha256-wfBeOrDGaY5+lHFGJ4fEUxA4ttMfECM7RByL9SSxF9I=";
  };

  vendorHash = "sha256-bElUNlQzk7+NcvZmEeo4P8H6UCrEGG/4VD7E7oIlQ38=";

  subPackages = [ "cmd/streamplace" ];
  doCheck = false;

  installPhase = ''
    mkdir -p $out/bin
    mv $out/bin/streamplace $out/bin/streamplace-server
  '';
}
```

**Build Dependencies:**
- pkg-config (native)
- Go (native)
- GStreamer full suite (runtime)
- FFmpeg, OpenCV (runtime)
- PostgreSQL, SQLite (runtime)
- OpenSSL, Zstd (runtime)

**Metadata:**
- `atproto.variant = "source"`
- `organizationalContext.variant = "source"`
- Includes full organization and service metadata

### Binary Build (binary.nix)

**Purpose**: Fast deployment with prebuilt releases

**Key Features:**
- Uses official release binaries from git.stream.place
- x86_64-linux only
- Faster installation
- Binary verified with SHA256
- AutoPatchelf for library compatibility

**Specifications:**
```nix
stdenv.mkDerivation {
  pname = "streamplace-binary";
  version = "0.8.9";

  src = fetchurl {
    url = "https://git.stream.place/streamplace/streamplace/-/releases/v0.8.9/downloads/streamplace-v0.8.9-linux-amd64.tar.gz";
    sha256 = "sha256-gRvqHdWx3OhWvQKkQUzq5c7Y9mK2bL5nJ8pQ0vW1xR4=";
  };

  nativeBuildInputs = [ autoPatchelfHook glib ];

  installPhase = ''
    mkdir -p $out/bin
    cp streamplace $out/bin/streamplace-server
    chmod +x $out/bin/streamplace-server
  '';
}
```

**Build Dependencies:**
- autoPatchelfHook (native)
- glib (native)
- GStreamer base plugins (runtime)
- FFmpeg (runtime)
- OpenSSL, Zstd (runtime)
- PostgreSQL (runtime)

**Metadata:**
- `atproto.variant = "binary"`
- `organizationalContext.variant = "binary"`
- Includes full organization and service metadata

### Default.nix Organization Aggregator

The `default.nix` file coordinates both variants:

**Structure:**
```nix
{
  # Both variants registered
  streamplace = source build;
  streamplace-binary = binary build;

  # Convenience aliases
  source = streamplace;
  binary = streamplace-binary;

  # Organization metadata (updated for 2 packages)
  _organizationMeta = {
    packageCount = 2;
    # ... other metadata
  };
}
```

**Inheritance:**
- `buildGoModule` - For source variant
- `fetchFromTangled` - For source variant
- `fetchurl` - For binary variant
- `lib` - Utilities and metadata handling
- `autoPatchelfHook` - For binary compatibility

## Usage Examples

### In NixOS Configuration

**Option 1: Source Build (Recommended)**
```nix
# configuration.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    stream-place.streamplace  # or stream-place.source
  ];
}
```

**Option 2: Binary Build (Fast)**
```nix
# configuration.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    stream-place.streamplace-binary  # or stream-place.binary
  ];
}
```

### In Home Manager

```nix
# home.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    stream-place.binary  # Prefer binary for faster eval
  ];
}
```

### In Flakes

```nix
# flake.nix
{
  inputs = {
    nur.url = "github:atproto-nix/nur";
  };

  outputs = { nur, ... }: {
    nixosConfigurations.server = nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          # Use source for development
          environment.systemPackages = [ pkgs.stream-place.source ];

          # Or binary for production
          # environment.systemPackages = [ pkgs.stream-place.binary ];
        })
      ];
    };
  };
}
```

## Package Naming and Discovery

### Flattened Names
- `stream-place-streamplace` - Source variant
- `stream-place-streamplace-binary` - Binary variant

### Aliases
- `stream-place.source` - Shorthand for source build
- `stream-place.binary` - Shorthand for binary build

### Organizational Name
- `stream-place` - The organization containing both variants

### Individual Package Names
- `streamplace` - Source package (within organization)
- `streamplace-binary` - Binary package (within organization)

## Hash Management

### Source Build Hashes

**When to update:**
- New commit pushed to Tangled.org
- Need latest development changes

**How to update:**
```bash
# Get new commit hash
git ls-remote https://tangled.org/@stream.place/streamplace.git HEAD

# Calculate new source hash
nix-prefetch-url --unpack <url> <rev>

# Update both in streamplace.nix:
rev = "new_commit_hash";
hash = "sha256-calculated_hash";
```

**Vendor hash:**
```bash
# If Go dependencies changed
nix build .#stream-place-streamplace 2>&1 | grep "got:"
# Update vendorHash in streamplace.nix
```

### Binary Build Hashes

**When to update:**
- New release published on git.stream.place

**How to update:**
```bash
# Download and verify
nix-prefetch-url --unpack \
  "https://git.stream.place/streamplace/streamplace/-/releases/v0.9.0/downloads/streamplace-v0.9.0-linux-amd64.tar.gz"

# Update version and hash in binary.nix:
version = "0.9.0";
sha256 = "sha256-<new_hash>";
```

## Metadata Handling

Both variants include comprehensive metadata:

### ATProto Passthrough
```nix
atproto = {
  type = "application";
  variant = "source" | "binary";  # Differentiates variants
  services = [ "streamplace-server" ];
  protocols = [ "com.atproto" "app.bsky" ];
  schemaVersion = "1.0";
  complexity = "high";
}
```

### Organization Metadata
```nix
organization = {
  name = "stream-place";
  displayName = "Stream.place";
  website = "https://stream.place";
  packageCount = 2;  # Updated to reflect both variants
  atprotoFocus = [ "applications" "infrastructure" ];
}
```

### Meta Context
```nix
meta = {
  organizationalContext = {
    organization = "stream-place";
    displayName = "Stream.place";
    variant = "source" | "binary";
  };
}
```

## Testing

### Test Both Variants
```bash
# Test source build
nix build .#stream-place-streamplace -L

# Test binary build
nix build .#stream-place-streamplace-binary -L

# Check flake
nix flake check

# Show available packages
nix flake show | grep stream-place
```

### Runtime Testing
```bash
# Source variant
nix run .#stream-place-streamplace -- \
  --help

# Binary variant
nix run .#stream-place-streamplace-binary -- \
  --help

# Test with Jetstream
nix run .#stream-place-streamplace -- \
  --jetstream wss://jetstream.example.com/subscribe \
  --data /tmp/streamplace-test
```

## Troubleshooting

### Flake Evaluation Error
```
error: getting status of '...' : No such file or directory
```

**Solution**: Ensure `fetchurl` is passed to stream-place in pkgs/default.nix:
```nix
stream-place = pkgs.callPackage ./stream-place {
  inherit lib buildGoModule;
  fetchFromTangled = pkgs.fetchFromTangled;
  fetchurl = pkgs.fetchurl;  # ← Must be included
};
```

### Binary Hash Mismatch
```
error: hash mismatch in fixed-output derivation
```

**Solution**: Verify the release file hash:
```bash
sha256sum streamplace-v0.8.9-linux-amd64.tar.gz
```

### Build Failure on Source
```
error: vendorHash mismatch
```

**Solution**: Recalculate vendor hash:
```bash
nix build .#stream-place-streamplace 2>&1 | grep "got:" | cut -d' ' -f3
```

### Library Missing on Binary
```
error: /nix/store/.../bin/streamplace-server: error while loading shared libraries: libgst...
```

**Solution**: Add missing library to `buildInputs` in binary.nix and ensure AutoPatchelf can find it.

## Contributing

### Updating Source Build
1. Find new commit hash
2. Update `rev` and `hash` in streamplace.nix
3. Update `vendorHash` if Go deps changed
4. Test: `nix build .#stream-place-streamplace`
5. Commit with description of changes

### Updating Binary Build
1. Check new release on git.stream.place
2. Calculate new hash with nix-prefetch-url
3. Update `version` and `sha256` in binary.nix
4. Test: `nix build .#stream-place-streamplace-binary`
5. Commit with release version

### Adding New Variants
If new build methods needed (e.g., Docker, container image):
1. Create `container.nix` or similar
2. Update `default.nix` to include new variant
3. Update `VARIANTS.md` with new variant
4. Update organization `packageCount`

## References

- **Project**: https://stream.place
- **Repository**: https://tangled.org/@stream.place/streamplace
- **Releases**: https://git.stream.place/streamplace/streamplace/releases
- **NUR Guide**: https://github.com/nix-community/NUR
- **Nixpkgs Manual**: https://nixos.org/manual/nixpkgs/stable/

## Summary

The Streamplace setup provides:
- ✅ Two complementary build variants
- ✅ Source control and versioning
- ✅ Automatic metadata management
- ✅ Clean flake integration
- ✅ Easy switching between variants
- ✅ Hash verification and reproducibility
- ✅ Comprehensive documentation

Users can choose based on their needs:
- **Development**: Use source build for maximum control
- **Production**: Use binary build for speed
- **CI/CD**: Choose binary for faster pipelines
- **Testing**: Use both for comprehensive coverage
