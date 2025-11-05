# plcbundle NUR Integration Guide

This document explains how plcbundle integrates into the Tangled NUR (Nix User Repository) and NixOS packaging ecosystem.

## Integration Overview

plcbundle has been added to the Tangled NUR with the following structure:

```
nur/pkgs/plcbundle/
├── default.nix          # Package collection and metadata
├── plcbundle.nix        # Main package derivation
├── README.md            # User-facing documentation
└── INTEGRATION.md       # This file
```

## NixOS Package Design

The package follows NUR best practices:

### 1. Organization Pattern
- **Organization**: `tangled` (existing Tangled infrastructure packages)
- **Package Name**: `plcbundle`
- **Flake Output**: `tangled-plcbundle` (namespace-prefixed)

### 2. Package Type
- **buildGoModule**: Using Nix's native Go build system
- **Source**: Fetched from Tangled git forge using `fetchFromTangled`
- **Binary**: `cmd/plcbundle` subpackage

### 3. Dependencies
The package has minimal dependencies:
- Standard Go toolchain (provided by buildGoModule)
- Go standard library modules (managed via vendorHash)

### 4. Metadata Structure

#### ATProto Metadata
```nix
passthru.atproto = {
  type = "infrastructure";
  services = [ "plcbundle" "archiving" "verification" ];
  protocols = [ "com.atproto" "plc" "did" ];
  capabilities = [
    "bundle-creation"
    "bundle-verification"
    "chain-integrity"
    "http-serving"
    "websocket-streaming"
    "spam-detection"
    "did-indexing"
  ];
}
```

#### Organization Metadata
```nix
passthru.organization = {
  name = "tangled";
  displayName = "Tangled";
  website = "https://tangled.org";
  # ... additional metadata
}
```

## Package Hashes

The package requires two hashes to be computed:

### Source Hash (fetchFromTangled)
```nix
hash = "sha256-...";
```

To compute the correct source hash:
1. Run build with dummy hash
2. Nix will report the actual hash
3. Update the value

### Vendor Hash (Go dependencies)
```nix
vendorHash = "sha256-...";
```

To compute the vendor hash:
1. Ensure `go.mod` and `go.sum` are up-to-date
2. Run build with dummy hash
3. Nix will report the actual hash
4. Update the value

## Building the Package

### Development Build
```bash
cd /path/to/nur
nix build .#tangled-plcbundle --impure -L
```

### Flake Show
```bash
nix flake show .#tangled-plcbundle
```

### Test Installation
```bash
nix profile install .#tangled-plcbundle
plcbundle --version
```

## Integration Points

### 1. Main Package Registry (pkgs/default.nix)
The package is registered in the organizational packages:
```nix
organizationalPackages = {
  plcbundle = pkgs.callPackage ./plcbundle { ... };
  # ...
};
```

### 2. Flake Outputs
Available via:
- `nix.#tangled-plcbundle` (namespaced)
- `nix.organizations.tangled.plcbundle` (organizational access)

### 3. Overlay Integration
The package is automatically included in the NUR overlay for nixpkgs integration.

## ATProto Ecosystem Integration

### Service Discovery
The package exposes ATProto service metadata:
- **Services**: PLC bundle archiving, verification, HTTP serving
- **Protocols**: AT Protocol (com.atproto), PLC operations, DID resolution
- **Capabilities**: Bundle creation, verification, chain integrity, HTTP serving, WebSocket streaming

### Configuration Discovery
Environment variables and configuration options are discoverable:
```nix
configuration = {
  required = [ ];
  optional = [
    "PLC_DIRECTORY_URL"
    "BUNDLE_DIR"
    "HTTP_HOST"
    "HTTP_PORT"
    "LOG_LEVEL"
  ];
};
```

## Version Updates

To update plcbundle to a new version:

1. **Update commit hash** in `plcbundle.nix`:
   ```nix
   rev = "new-commit-hash";
   ```

2. **Update version string** for clarity:
   ```nix
   version = "0.2.0";
   ```

3. **Recompute source hash**:
   ```bash
   nix build --impure 2>&1 | grep "got:" | head -1
   ```

4. **Recompute vendor hash** (if Go deps changed):
   ```bash
   # After source hash is correct, run again for vendor hash
   nix build --impure 2>&1 | grep "got:" | head -1
   ```

5. **Test the build**:
   ```bash
   nix build .#tangled-plcbundle -L
   ```

## Security Considerations

- **Source Verification**: Using `fetchFromTangled` ensures sources come from Tangled.org
- **Hash Verification**: SHA-256 hashes ensure source integrity
- **Reproducibility**: Build is deterministic given same inputs
- **License**: MIT, verified and documented

## Integration with NUR Modules

The package is compatible with:
- NixOS system modules (via overlays)
- Home Manager configurations
- NUR-based deployments
- Flake-based development environments

## Performance Notes

- **Build Time**: ~30-60 seconds (Go compilation)
- **Install Size**: ~15-20 MB (stripped binary + dependencies)
- **Runtime**: Minimal resource usage for CLI, configurable for server mode

## Compatibility

- **NixOS**: 22.11+
- **nixpkgs**: unstable/latest
- **Go**: 1.25+
- **Platforms**: Linux (x86_64, aarch64), macOS (x86_64, aarch64)

## Troubleshooting

### Build Fails with Hash Mismatch
1. Verify commit exists on Tangled.org
2. Clear nix store: `nix store gc`
3. Re-run build with verbose logging: `nix build -L --impure`

### fetchFromTangled Connection Issues
1. Check network connectivity to tangled.org
2. Verify SSH keys if using git protocol
3. Try with `forceFetchGit = true` (slower, but more reliable)

### Vendor Hash Mismatch
1. Verify Go version matches in `go.mod`
2. Update go.sum: `go mod download && go mod tidy`
3. Recompute hash in Nix

## Future Enhancements

- Add NixOS service module for automatic server configuration
- Add systemd timer for automatic bundle fetching
- Add Home Manager module for CLI integration
- Create Docker image package variant
- Add test fixtures and example configurations

## Contributing

To contribute improvements:
1. Update package files as needed
2. Test with `nix build .#tangled-plcbundle`
3. Verify with `nix flake show`
4. Commit with clear messages
5. Submit PR to the NUR repository

## References

- [NixOS Packages Manual](https://nixos.org/manual/nixpkgs/unstable/#sec-using-nix)
- [buildGoModule Documentation](https://nixos.org/manual/nixpkgs/unstable/#go)
- [NUR Documentation](https://nur.nix-community.org/)
- [Tangled.org Git Forge](https://tangled.org)
- [plcbundle Repository](https://tangled.org/@atscan.net/plcbundle)
