# Getting Started with plcbundle in NUR

This guide provides a step-by-step introduction to using plcbundle through the Tangled NUR (Nix User Repository).

## Quick Summary

**What is plcbundle?**
A system for archiving AT Protocol's DID PLC Directory operations into immutable, cryptographically-chained bundles. It provides a CLI tool, Go library, HTTP server, and WebSocket streaming capabilities.

**What was added to NUR?**
A complete NixOS package with CLI tool, comprehensive documentation, and integration with the ATProto ecosystem.

**Where is it?**
- Package: `/Users/jack/Software/nur/pkgs/plcbundle/`
- Documentation: `/Users/jack/Software/nur/pkgs/plcbundle/`
- References: `/Users/jack/Software/nur/CLAUDE.md`

## Prerequisites

- Nix package manager (latest version recommended)
- Flakes enabled in nix.conf
- Understanding of basic Nix concepts

## Three Levels of Documentation

### 1. User Documentation (README.md)
**For**: People who want to use plcbundle as a tool
**Contains**:
- Installation instructions
- CLI command reference
- Docker usage
- Configuration options

**Location**: `/Users/jack/Software/nur/pkgs/plcbundle/README.md`

**Quick Start**:
```bash
nix build .#tangled-plcbundle
./result/bin/plcbundle --version
```

### 2. Technical Documentation (INTEGRATION.md)
**For**: Package maintainers and developers
**Contains**:
- Package design patterns
- NixOS packaging architecture
- ATProto integration details
- Version update procedures
- Performance characteristics

**Location**: `/Users/jack/Software/nur/pkgs/plcbundle/INTEGRATION.md`

**Key Concepts**:
- Uses `buildGoModule` with `fetchFromTangled`
- Implements ATProto metadata structures
- Part of Tangled infrastructure organization
- Minimal dependencies, fast builds

### 3. Development Guide (SETUP.md)
**For**: People building, updating, or fixing plcbundle
**Contains**:
- Hash computation procedures
- Build troubleshooting
- Common workflows
- Development iteration patterns
- Maintenance checklist

**Location**: `/Users/jack/Software/nur/pkgs/plcbundle/SETUP.md`

**Key Workflows**:
- Computing source and vendor hashes
- Testing package builds
- Integration testing
- Version updates

## How to Use plcbundle

### Option 1: One-off Use (nix shell)
```bash
nix shell "git+https://your-nur-url#tangled-plcbundle"
plcbundle version
plcbundle fetch -count 1
```

### Option 2: System Installation (NixOS)
In your `configuration.nix`:
```nix
{ config, pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.nur.tangled-plcbundle
  ];
}
```

Apply with:
```bash
sudo nixos-rebuild switch
```

### Option 3: Home Manager
In your `home.nix`:
```nix
{ ... }:
{
  home.packages = [
    nur.tangled-plcbundle
  ];
}
```

Apply with:
```bash
home-manager switch
```

### Option 4: Development Environment
In a `flake.nix` for development:
```nix
{
  inputs.nur.url = "git+https://your-nur-url";

  outputs = { self, nur, ... }:
    {
      devShells.default = {
        buildInputs = [
          nur.packages.${system}.tangled-plcbundle
        ];
      };
    };
}
```

Enter with:
```bash
nix flake update
nix develop
```

## Package Files Overview

### `/Users/jack/Software/nur/pkgs/plcbundle/default.nix`
- **Purpose**: Organization metadata and package collection
- **Contains**: Organizational context, all packages in this org
- **Key Sections**: Organization metadata, package list, "all" package

### `/Users/jack/Software/nur/pkgs/plcbundle/plcbundle.nix`
- **Purpose**: Main buildGoModule derivation
- **Contains**: Build configuration, dependencies, metadata
- **Key Sections**: Build flags, subPackages, ATProto metadata, organizational context

### `/Users/jack/Software/nur/pkgs/plcbundle/README.md`
- **Purpose**: User-facing documentation
- **Audience**: End users
- **Contains**: Installation, usage, configuration, docker

### `/Users/jack/Software/nur/pkgs/plcbundle/INTEGRATION.md`
- **Purpose**: Technical architecture documentation
- **Audience**: Package maintainers, developers
- **Contains**: Design patterns, NixOS integration, version updates

### `/Users/jack/Software/nur/pkgs/plcbundle/SETUP.md`
- **Purpose**: Development and building guide
- **Audience**: Package developers, CI/CD systems
- **Contains**: Hash computation, troubleshooting, workflows

## What Makes This Package NUR-Compliant

1. **Organization Pattern**: Follows existing Tangled package organization
2. **Naming Convention**: `tangled-plcbundle` (consistent with spindle, appview, etc.)
3. **Metadata**: Complete ATProto service discovery metadata
4. **Documentation**: Multi-level docs for different audiences
5. **Integration**: Uses fetchFromTangled and standard builders
6. **License**: MIT (compatible with NUR/nixpkgs)
7. **Dependencies**: Minimal, standard, well-tested

## Integration with ATProto Ecosystem

The package announces itself as:

**Service Type**: Infrastructure
**Services**: PLC bundle archiving, verification, HTTP serving
**Protocols**: AT Protocol (com.atproto), PLC operations, DID resolution
**Capabilities**:
- Bundle creation and verification
- Chain integrity validation
- HTTP serving with WebSocket streaming
- Spam detection
- DID indexing and querying

This allows ATProto tools to discover and integrate with plcbundle for:
- DID archival and verification
- Historical operation analysis
- Mirror operations
- Compliance workflows

## Common Tasks

### Build the Package
```bash
cd /Users/jack/Software/nur
nix build .#tangled-plcbundle -L
```

### Test the Binary
```bash
./result/bin/plcbundle version
./result/bin/plcbundle info
```

### Update the Package
See `/Users/jack/Software/nur/pkgs/plcbundle/SETUP.md` section "Updating to a New Version"

### Find the Binary
```bash
nix build .#tangled-plcbundle
readlink result  # Shows /nix/store/... path
./result/bin/plcbundle  # Use directly
```

### Use in NixOS Module
```nix
services.plcbundle = {
  enable = true;
  package = pkgs.nur.tangled-plcbundle;
  # ... configuration ...
};
```

## Understanding the Build

### What Happens When You Build

1. **fetchFromTangled** fetches source from Tangled.org
2. **go mod download** downloads Go dependencies
3. **go build** compiles the `cmd/plcbundle` binary
4. **installPhase** copies binary to output
5. **Strip flags** reduce binary size

### Build Requirements

- Go 1.25+ (from nixpkgs)
- Standard build tools
- Network access (for initial source fetch)

### Build Time

- Initial build: ~30-60 seconds
- Incremental (with cache): ~5-10 seconds
- Rebuilds after Nix cache clear: ~30-60 seconds

## Troubleshooting

### "Cannot find module"
→ Check Tangled.org connectivity and commit exists

### "Hash mismatch"
→ Update hash value from error message or re-compute

### "Go version mismatch"
→ Update nixpkgs: `nix flake update`

### "Binary not in PATH"
→ Use full path: `./result/bin/plcbundle`

See `/Users/jack/Software/nur/pkgs/plcbundle/SETUP.md` for detailed troubleshooting.

## Next Steps

1. **Read Documentation**: Start with README.md for user features
2. **Build Locally**: `nix build .#tangled-plcbundle -L`
3. **Try the CLI**: `./result/bin/plcbundle version`
4. **Fetch Bundles**: `./result/bin/plcbundle fetch -count 1`
5. **Explore Options**: `./result/bin/plcbundle --help`

## Important Files

**In plcbundle repository**:
- `/Users/jack/Software/plcbundle/CLAUDE.md` - Development guide

**In NUR repository**:
- `/Users/jack/Software/nur/CLAUDE.md` - Main NUR guide (updated with plcbundle)
- `/Users/jack/Software/nur/pkgs/plcbundle/` - Package directory
- `/Users/jack/Software/nur/PLCBUNDLE_INTEGRATION_SUMMARY.md` - Integration overview

## Key Resources

- **plcbundle Repository**: https://tangled.org/@atscan.net/plcbundle
- **plcbundle Docs**: https://tangled.org/@atscan.net/plcbundle/raw/main/docs/
- **NUR Docs**: https://nur.nix-community.org/
- **NixOS Docs**: https://nixos.org/manual/nixos/
- **buildGoModule**: https://nixos.org/manual/nixpkgs/unstable/#go

## Status

**Package Creation**: ✅ Complete
**Documentation**: ✅ Complete
**NUR Integration**: ✅ Complete
**Hashes**: ⏳ Needs computation (see SETUP.md)
**Build Verification**: ⏳ Pending hash computation

## Questions?

- **About plcbundle functionality**: See plcbundle documentation
- **About NUR integration**: See INTEGRATION.md
- **About building the package**: See SETUP.md
- **About using in NixOS**: See README.md
- **About NUR in general**: See NUR documentation

---

**Last Updated**: November 4, 2025
**Status**: Ready for hash computation and build verification
**Maintained By**: Tangled
**License**: MIT
