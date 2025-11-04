# plcbundle NUR Setup Guide

This guide helps you get started with the plcbundle package in the Tangled NUR repository.

## Quick Start

### Building the Package

```bash
# Navigate to the NUR repository
cd /Users/jack/Software/nur

# Build plcbundle
nix build .#tangled-plcbundle

# Test the binary
./result/bin/plcbundle --version
```

### Installing via Flake

```bash
# In your system flake.nix
inputs.nur.url = "git+https://your-nur-repo";

# In your configuration
environment.systemPackages = [
  nur.packages.${pkgs.system}.tangled-plcbundle
];
```

### Using in nix shell

```bash
cd /path/to/project
nix shell "git+https://your-nur-repo#tangled-plcbundle"
plcbundle fetch -count 1
```

## Package Details

### Name and Identity
- **Organization**: tangled
- **Package Name**: plcbundle
- **Full Flake Name**: `tangled-plcbundle`
- **Main Binary**: `plcbundle`
- **Version**: 0.1.0 (update as needed)

### Source Information
- **Repository**: https://tangled.org/@atscan.net/plcbundle
- **Build System**: buildGoModule (Nix native Go build)
- **Language**: Go 1.25+
- **License**: MIT

### Package Files

```
/Users/jack/Software/nur/pkgs/plcbundle/
├── default.nix          # Organization metadata and package collection
├── plcbundle.nix        # Main package derivation (buildGoModule)
├── README.md            # User documentation
├── INTEGRATION.md       # Technical integration details
└── SETUP.md             # This file
```

## Computing and Updating Hashes

### Initial Hash Setup

When first creating or updating the package, use placeholder hashes:

```nix
hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

### Computing Source Hash

```bash
# Try building with dummy hash
nix build .#tangled-plcbundle 2>&1 | head -50

# You'll see an error like:
# hash mismatch in fixed-output derivation '/nix/store/...':
#   wanted: sha256-AAAA...
#   got:    sha256-XXXX...

# Copy the "got:" value and update plcbundle.nix:
nano /Users/jack/Software/nur/pkgs/plcbundle/plcbundle.nix
# Replace the hash value
```

### Computing Vendor Hash

After the source hash is correct:

```bash
# Build again - it will fail on vendor hash
nix build .#tangled-plcbundle --impure 2>&1 | grep -A 5 "vendorHash"

# Extract the correct hash and update plcbundle.nix
# Then test the build completes successfully
nix build .#tangled-plcbundle -L
```

### Verification

```bash
# After both hashes are set, verify clean build
nix build .#tangled-plcbundle --impure -L
nix flake check

# Test installation
nix profile install .#tangled-plcbundle
plcbundle version
```

## Troubleshooting

### Build Fails: "Cannot find module"

**Issue**: fetchFromTangled cannot access the repository.

**Solution**:
```bash
# Verify commit exists
cd /Users/jack/Software/plcbundle
git rev-parse bad9bb624a6bc1042bd0c699bf14c58c99015d36

# Verify Tangled.org connectivity
curl https://tangled.org/@atscan.net/plcbundle

# Try forcing git fetch
# Edit plcbundle.nix and add:
# forceFetchGit = true;
```

### Build Fails: "Hash mismatch"

**Issue**: The computed hash doesn't match.

**Solution**:
```bash
# Clear Nix cache
nix store gc

# Re-run with new placeholder
# Copy the actual hash from error message
nix build .#tangled-plcbundle 2>&1 | grep "got:"
```

### Build Fails: "Go version mismatch"

**Issue**: Go 1.25+ required but older version available.

**Solution**:
```bash
# Update nixpkgs in flake.lock
nix flake update nixpkgs

# Rebuild
nix build .#tangled-plcbundle -L
```

## Common Workflows

### Updating to a New Version

1. Get the new commit hash:
   ```bash
   cd /Users/jack/Software/plcbundle
   git log --oneline | head -1
   ```

2. Update `plcbundle.nix`:
   ```nix
   version = "0.2.0";  # Update version
   rev = "new-commit-hash";  # Update commit
   hash = "sha256-AAAA...";  # Will compute
   ```

3. Compute hashes and test:
   ```bash
   nix build .#tangled-plcbundle 2>&1 | grep "got:"
   # Update hash, repeat for vendor hash
   nix build .#tangled-plcbundle -L
   ```

4. Commit to NUR:
   ```bash
   cd /Users/jack/Software/nur
   git add pkgs/plcbundle/plcbundle.nix
   git commit -m "plcbundle: update to version 0.2.0"
   ```

### Testing Package Functionality

```bash
# Build and test CLI
nix build .#tangled-plcbundle -L
./result/bin/plcbundle version

# Create test bundle
mkdir -p /tmp/plc_test
./result/bin/plcbundle fetch -plc https://plc.directory -count 1 \
  -bundleDir /tmp/plc_test

# Verify bundle
./result/bin/plcbundle info
```

### Integration Testing with NixOS

```bash
# Build a simple NixOS config for testing
cat > test-config.nix << 'EOF'
{ config, pkgs, ... }: {
  system.stateVersion = "24.05";
  environment.systemPackages = [
    pkgs.nur.tangled-plcbundle
  ];
}
EOF

# Test in VM
nixos-rebuild test --flake .#test-config
```

## Build Performance

- **Build time**: ~30-60 seconds
- **Binary size**: ~15-20 MB (stripped)
- **Dependencies**: Minimal (only standard Go libs)

## Development Workflow

For active development of plcbundle itself:

```bash
# Clone plcbundle repo
cd /Users/jack/Software/plcbundle

# Make changes to Go code
vim cmd/plcbundle/main.go

# Test in NUR
cd /Users/jack/Software/nur
nix build .#tangled-plcbundle -L --impure
./result/bin/plcbundle version
```

The `--impure` flag allows Nix to access your local git repository changes.

## Integration with Flake Registries

To make plcbundle easily discoverable:

```bash
# Register in your local flake registry
nix flake update --registry flake github:your/nur

# Then use directly
nix build github:your/nur#tangled-plcbundle
```

## Maintenance Checklist

When updating plcbundle:

- [ ] Get new commit hash from https://tangled.org/@atscan.net/plcbundle
- [ ] Update `version` in plcbundle.nix
- [ ] Update `rev` in plcbundle.nix
- [ ] Compute new `hash` (source)
- [ ] Compute new `vendorHash` (Go deps)
- [ ] Test build: `nix build .#tangled-plcbundle -L`
- [ ] Test CLI: `./result/bin/plcbundle --version`
- [ ] Verify flake: `nix flake check`
- [ ] Update version in plcbundle/CLAUDE.md if major change
- [ ] Create git commit with clear message
- [ ] Push to NUR repository

## Resources

- **plcbundle Repo**: https://tangled.org/@atscan.net/plcbundle
- **NUR Documentation**: https://nur.nix-community.org/
- **buildGoModule**: https://nixos.org/manual/nixpkgs/unstable/#go
- **Tangled.org**: https://tangled.org
- **NixOS Manual**: https://nixos.org/manual/nixos/

## Support

For issues with:
- **Package building**: See troubleshooting above
- **plcbundle functionality**: See [plcbundle docs](https://tangled.org/@atscan.net/plcbundle/raw/main/README.md)
- **NUR integration**: See [INTEGRATION.md](./INTEGRATION.md)
- **NixOS modules**: See NUR CLAUDE.md

## Next Steps

1. **Compute hashes**: Follow "Computing and Updating Hashes" section
2. **Build locally**: `nix build .#tangled-plcbundle -L`
3. **Test functionality**: Use the "Testing Package Functionality" workflow
4. **Integrate into system**: Add to your NixOS configuration
5. **Update documentation**: Keep this guide current as plcbundle evolves
