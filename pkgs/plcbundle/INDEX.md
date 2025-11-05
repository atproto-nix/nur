# plcbundle NUR Package - Complete Index

This file provides a comprehensive index of all documentation and files related to plcbundle in the NUR repository.

## Quick Navigation

| Need                           | Document                     | Location                          |
|--------------------------------|------------------------------|-----------------------------------|
| Install and use plcbundle      | README.md                    | `pkgs/plcbundle/README.md`        |
| Build the package              | SETUP.md                     | `pkgs/plcbundle/SETUP.md`         |
| Understand package design      | INTEGRATION.md               | `pkgs/plcbundle/INTEGRATION.md`   |
| Get started (beginner)         | GETTING_STARTED...           | `GETTING_STARTED_WITH_PLCBUNDLE.md` |
| Technical overview             | PLCBUNDLE_INTEGRATION_SUMMARY | `PLCBUNDLE_INTEGRATION_SUMMARY.md` |
| NUR repository guide           | CLAUDE.md                    | `CLAUDE.md` (main NUR repo)      |
| plcbundle development guide    | CLAUDE.md                    | `../plcbundle/CLAUDE.md`         |

## File Structure

```
/Users/jack/Software/nur/
├── CLAUDE.md                              # NUR main guide (updated)
├── PLCBUNDLE_INTEGRATION_SUMMARY.md       # Technical integration overview
├── GETTING_STARTED_WITH_PLCBUNDLE.md      # Beginner's introduction
└── pkgs/plcbundle/
    ├── INDEX.md                           # This file
    ├── default.nix                        # Package organization & metadata
    ├── plcbundle.nix                      # buildGoModule derivation
    ├── README.md                          # User documentation
    ├── INTEGRATION.md                     # Technical architecture
    └── SETUP.md                           # Development & building guide

/Users/jack/Software/plcbundle/
└── CLAUDE.md                              # plcbundle dev guide (updated)
```

## Documentation by Audience

### For End Users
**Goal**: Install and use plcbundle

**Start Here**: `README.md`
- Installation methods (NixOS, Home Manager, nix shell)
- Quick command reference
- Configuration and environment variables
- Docker usage

**Then Read**: `GETTING_STARTED_WITH_PLCBUNDLE.md`
- Four ways to use plcbundle
- Common tasks
- Troubleshooting basics

### For Package Maintainers
**Goal**: Keep the package updated and working

**Start Here**: `INTEGRATION.md`
- Package design patterns
- NixOS packaging best practices
- Version update procedures
- Maintenance checklist

**Then Read**: `SETUP.md` (Maintenance Checklist section)
- Step-by-step update procedure
- Testing after updates
- Commit procedures

**Reference**: `PLCBUNDLE_INTEGRATION_SUMMARY.md`
- Technical decisions explained
- Future enhancement ideas
- Integration validation checklist

### For Developers
**Goal**: Build, debug, and modify the package

**Start Here**: `SETUP.md`
- Hash computation procedures
- Build troubleshooting
- Common workflows
- Development iteration patterns

**Then Read**: `INTEGRATION.md` (Architecture section)
- Package structure
- Build system details
- Dependencies and constraints

**Reference**: `DEFAULT.md` and `plcbundle.nix`
- See implementation details
- Modify as needed

### For NUR Administrators
**Goal**: Integrate plcbundle into CI/CD and distribution

**Start Here**: `PLCBUNDLE_INTEGRATION_SUMMARY.md`
- Complete integration overview
- Validation checklist
- Status and next steps

**Then Read**: `INTEGRATION.md` (Integration Points section)
- How it fits in NUR ecosystem
- Flake outputs and overlays
- ATProto ecosystem integration

## Core Files Explained

### default.nix (Organization Package Collection)
**Purpose**: Define the organization and its packages
**Key Sections**:
- Organization metadata (name, website, maintainer)
- Package references (each package in the org)
- Enhanced packages with metadata injection
- "all" package for building everything at once
- Export of organizational metadata

**When to Edit**: Adding new packages to Tangled organization

### plcbundle.nix (Main Package Derivation)
**Purpose**: Define how to build the plcbundle binary
**Key Sections**:
- Basic metadata (pname, version)
- Source fetching (fetchFromTangled configuration)
- Build configuration (subPackages, ldflags)
- ATProto service metadata
- Organization metadata
- NixOS meta fields and documentation

**When to Edit**: Updating version, dependencies, or build flags

## Documentation Topics

### User Features
- Installation (NixOS, Home Manager, nix shell, Docker)
- CLI command reference
- HTTP server operation
- WebSocket streaming
- Configuration options
- Environment variables

### Technical Architecture
- Package organization patterns
- NixOS packaging conventions
- buildGoModule configuration
- fetchFromTangled integration
- Metadata enrichment patterns
- ATProto service discovery

### Building and Testing
- Hash computation procedures
- Build system operation
- Dependency management
- Performance characteristics
- Troubleshooting strategies

### Integration
- NUR package registry integration
- Flake output configuration
- Overlay integration
- ATProto ecosystem integration
- Future enhancement opportunities

## Key Concepts

### Organization Pattern
plcbundle is part of the Tangled organization, which includes:
- spindle (event processor)
- appview (web interface)
- knot (git server)
- plcbundle (DID operation archiving)

All packages use the same pattern, making maintenance consistent.

### Package Naming
- **Full Name**: `tangled-plcbundle`
- **Binary**: `plcbundle`
- **Nix Store Path**: `~/.nix/store/...-tangled-plcbundle-0.1.0/`

### Build System
Uses Nix's native `buildGoModule` for Go applications:
1. Fetches source with `fetchFromTangled`
2. Downloads Go dependencies via `go mod download`
3. Builds with `go build`
4. Strips with `-s -w` LDFLAGS
5. Outputs to `/nix/store/...-plcbundle/bin/plcbundle`

### Hash Verification
Two hashes ensure reproducibility:
1. `hash`: Source integrity (computed from fetchFromTangled output)
2. `vendorHash`: Dependency integrity (computed from go.sum)

Both use SHA-256 and are verified by Nix during build.

## Common Workflows

### Install and Use
```bash
nix build .#tangled-plcbundle
./result/bin/plcbundle --version
```

### Update Package
1. Get new commit from https://tangled.org/@atscan.net/plcbundle
2. Update `version` and `rev` in plcbundle.nix
3. Compute new `hash` and `vendorHash`
4. Test: `nix build .#tangled-plcbundle -L`
5. Commit with message "plcbundle: update to version X.Y.Z"

### Troubleshoot Build
1. Check error message
2. See SETUP.md troubleshooting section
3. Follow suggested remediation
4. Retest build

### Add to System
In `configuration.nix`:
```nix
environment.systemPackages = [
  pkgs.nur.tangled-plcbundle
];
```

Then: `sudo nixos-rebuild switch`

## References

### External Documentation
- [plcbundle Repository](https://tangled.org/@atscan.net/plcbundle)
- [plcbundle README](https://tangled.org/@atscan.net/plcbundle/raw/main/README.md)
- [plcbundle Specification](https://tangled.org/@atscan.net/plcbundle/raw/main/docs/specification.md)
- [plcbundle CLI Guide](https://tangled.org/@atscan.net/plcbundle/raw/main/docs/cli.md)

### NUR Documentation
- [NUR Documentation](https://nur.nix-community.org/)
- [NUR Package Manual](https://nur.nix-community.org/docs/development/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)

### NixOS/Nixpkgs
- [buildGoModule](https://nixos.org/manual/nixpkgs/unstable/#go)
- [NixOS Packages](https://search.nixos.org/packages)
- [NixOS Options](https://search.nixos.org/options)

## Status and Next Steps

### Current Status
- ✅ Package created
- ✅ Integration complete
- ✅ Documentation comprehensive
- ⏳ Hashes need computation
- ⏳ Build verification pending

### To Complete Integration
1. Compute `hash` and `vendorHash` (see SETUP.md)
2. Verify build succeeds (see SETUP.md)
3. Test CLI functionality (see README.md)
4. Optional: Create NixOS service module (see INTEGRATION.md)

### Support Resources
- **Questions about plcbundle features**: See plcbundle repository docs
- **Questions about building**: See SETUP.md
- **Questions about NUR**: See NUR repository docs
- **Questions about this package**: See appropriate documentation file above

## Document Maintenance

This index is maintained with the plcbundle package.

**Last Updated**: November 4, 2025
**Maintainer**: Tangled
**Status**: Current
**License**: MIT

### Update Procedure
When updating the package:
1. Update relevant documentation files
2. Update this INDEX.md if file structure changes
3. Include documentation changes in git commits
4. Keep cross-references current

---

**Quick Links**:
- [Start Here](GETTING_STARTED_WITH_PLCBUNDLE.md) - For new users
- [Build Guide](SETUP.md) - For developers
- [Integration Details](INTEGRATION.md) - For maintainers
- [User Manual](README.md) - For end users
