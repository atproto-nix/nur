# Streamplace Build Variants

This directory provides **two complementary build variants** of Streamplace to support different deployment scenarios and preferences.

## Quick Comparison

| Aspect | Source Build | Binary Build |
|--------|------|------|
| **Package** | `streamplace` | `streamplace-binary` |
| **Alias** | `stream-place.source` | `stream-place.binary` |
| **Build Time** | Long (full compilation) | Fast (extraction only) |
| **Customization** | Full (modify source) | Limited (prebuilt) |
| **Reproducibility** | High (from source) | Medium (binary hash-checked) |
| **Debugging** | Native debugging support | Requires symbol debugging |
| **Dependency Control** | Full control | Binary dependencies fixed |
| **Platform Support** | Multi-platform | x86_64-linux only |
| **File Size** | Smaller store path | Precompiled binaries |
| **Use Case** | Development, custom builds | Quick deployment |

## Source Build: `streamplace`

### Files
- **streamplace.nix** - Main source build definition

### When to Use
- Development and customization
- Need to modify code or add features
- Require full debugging capabilities
- Cross-platform deployment (beyond x86_64-linux)
- Need latest development changes

### How to Build
```bash
# Build from source
nix build .#stream-place-streamplace

# Or with alias
nix build .#stream-place.source

# Run directly from source
nix run .#stream-place-streamplace -- --help
```

### Features
- ✅ Full source code compilation
- ✅ Multi-platform support (unix platforms)
- ✅ Build from Tangled.org repository
- ✅ Complete multimedia libraries included
- ✅ GStreamer, FFmpeg, OpenCV integrated
- ✅ PostgreSQL and SQLite support
- ✅ Full debugging support

### Specifications
- **Source**: Tangled.org (@stream.place/streamplace)
- **Latest Commit**: a40860f005ba4da989cfe1a5c39d29fa3564fea6
- **Vendor Hash**: sha256-bElUNlQzk7+NcvZmEeo4P8H6UCrEGG/4VD7E7oIlQ38=
- **Main Binary**: cmd/streamplace
- **Output Binary**: streamplace-server

### Dependencies
**Build Time:**
- pkg-config
- Go compiler

**Runtime:**
- GStreamer plugins (base, good, bad, ugly)
- FFmpeg
- OpenCV
- PostgreSQL
- SQLite
- OpenSSL
- Zstd

## Binary Build: `streamplace-binary`

### Files
- **binary.nix** - Binary release distribution definition

### When to Use
- Production deployments (quick startup)
- CI/CD pipelines needing fast builds
- Limited hardware resources
- x86_64-linux only systems
- Pre-tested release versions

### How to Build
```bash
# Build from binary
nix build .#stream-place-streamplace-binary

# Or with alias
nix build .#stream-place.binary

# Run directly from binary
nix run .#stream-place-streamplace-binary -- --help
```

### Features
- ✅ Prebuilt release binaries
- ✅ x86_64-linux only (official builds)
- ✅ Faster installation
- ✅ Binary verified via SHA256 hash
- ✅ Runtime dependencies managed by Nix
- ✅ AutoPatchelf integration for library compatibility

### Specifications
- **Release Version**: 0.8.9
- **Source**: https://git.stream.place/streamplace/streamplace/releases/v0.8.9
- **Binary Format**: tar.gz (Linux x86_64)
- **Output Binary**: streamplace-server
- **Hash**: sha256-gRvqHdWx3OhWvQKkQUzq5c7Y9mK2bL5nJ8pQ0vW1xR4= (placeholder - update with actual)

### Dependencies
**Build Time:**
- autoPatchelfHook (for library patching)
- glib

**Runtime:**
- GStreamer plugins (base, good, bad)
- FFmpeg
- OpenSSL
- Zstd
- PostgreSQL

## Usage Examples

### Development: Source Build with Custom Configuration
```bash
# Enter development shell with Streamplace source
nix develop .#stream-place-streamplace

# Build with custom Go flags
nix build .#stream-place-streamplace --build-arg goflags="-v"

# Run with debug logging
nix run .#stream-place-streamplace -- --log-level debug
```

### Production: Binary Deployment
```bash
# Install binary variant
nix profile install .#stream-place-streamplace-binary

# Run production instance
streamplace-server \
  --jetstream wss://jetstream.example.com/subscribe \
  --data /var/lib/streamplace \
  --bind 0.0.0.0:8080 \
  --bind-metrics 0.0.0.0:9093
```

### Docker/Container Image
```bash
# Using source build (more flexible)
nix run .#stream-place-streamplace -- --help

# Using binary variant (smaller image)
nix run .#stream-place-streamplace-binary -- --help
```

## Switching Between Variants

### In NixOS Configuration
```nix
# Use source build (default - more features)
environment.systemPackages = with pkgs; [
  stream-place.streamplace  # or stream-place.source
];

# Or use binary build for faster system builds
environment.systemPackages = with pkgs; [
  stream-place.streamplace-binary  # or stream-place.binary
];
```

### In Home Manager
```nix
# Home manager prefers quicker evaluation, so binary is ideal
home.packages = with pkgs; [
  stream-place.streamplace-binary  # Fast installation
];
```

## Updating Binary Builds

When a new Streamplace release is available:

1. **Update version** in `binary.nix`:
   ```nix
   version = "0.9.0";  # New version
   ```

2. **Calculate SHA256 hash**:
   ```bash
   nix-prefetch-url --unpack \
     "https://git.stream.place/streamplace/streamplace/-/releases/v0.9.0/downloads/streamplace-v0.9.0-linux-amd64.tar.gz"
   ```

3. **Update hash** in `binary.nix`:
   ```nix
   sha256 = "sha256-<NEW_HASH>";
   ```

4. **Test build**:
   ```bash
   nix build .#stream-place-streamplace-binary
   ```

5. **Commit changes**

## Performance Considerations

### Source Builds
- **Build Time**: 10-30 minutes (depending on system)
- **CPU Usage**: High during compilation
- **Network**: Fetches latest from Tangled.org
- **Caching**: Excellent (nixpkgs caching + Go module caching)

### Binary Builds
- **Build Time**: 30 seconds (download + extract)
- **CPU Usage**: Low (just extraction)
- **Network**: Single tarball download
- **Disk Space**: Similar to source after store links

## Troubleshooting

### Binary Build Hash Mismatch
```
error: hash mismatch in fixed-output derivation
expected: sha256-...
got:      sha256-...
```

**Solution**: Download the release and verify the hash:
```bash
curl -L "https://git.stream.place/streamplace/streamplace/-/releases/v0.8.9/downloads/streamplace-v0.8.9-linux-amd64.tar.gz" | sha256sum
```

### Binary Missing Runtime Libraries
```
error: /nix/store/.../bin/streamplace-server: error while loading shared libraries: ...
```

**Solution**: Check that all buildInputs are listed in `binary.nix`. The autoPatchelfHook should handle most cases, but complex binaries may need manual intervention.

### Source Build with Multimedia Issues
```
error: GStreamer plugin not found
```

**Solution**: Ensure all GStreamer plugins are listed in `buildInputs`. Update to latest nixpkgs for newest plugin versions:
```bash
nix flake update
```

## Architecture

### Default Package Export
The `default.nix` file exports:
- **streamplace** - Source build (default recommendation)
- **streamplace-binary** - Binary variant
- **source** - Alias for streamplace
- **binary** - Alias for streamplace-binary
- **_organizationMeta** - Organization metadata

### Naming Convention
- Flattened name: `stream-place-streamplace` (source) or `stream-place-streamplace-binary` (binary)
- Organization name: `stream-place`
- Package name: `streamplace` or `streamplace-binary`
- Aliases: `stream-place.source` and `stream-place.binary`

## Contributing

When updating Streamplace:

1. **For source builds**: Update `streamplace.nix`
   - Change `rev` to new commit hash
   - Update `hash` with `nix-prefetch-url --unpack`
   - Update `vendorHash` if Go dependencies changed

2. **For binary builds**: Update `binary.nix`
   - Change `version` to new release
   - Update `sha256` with `nix-prefetch-url --unpack`
   - Verify release URL is correct

3. **Update documentation**: This file

4. **Test both variants**:
   ```bash
   nix build .#stream-place-streamplace
   nix build .#stream-place-streamplace-binary
   ```

## References

- **Streamplace**: https://stream.place
- **Tangled.org**: https://tangled.org/@stream.place/streamplace
- **Git Mirror**: https://git.stream.place/streamplace/streamplace
- **NUR Specification**: https://github.com/nix-community/NUR
- **Nixpkgs Manual**: https://nixos.org/manual/nixpkgs/stable/
