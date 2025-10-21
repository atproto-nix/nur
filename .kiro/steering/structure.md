# Project Structure

## Repository Organization

The repository follows a standard Nix User Repository (NUR) structure with clear separation of concerns:

```
atproto-nur/
├── flake.nix              # Main flake definition and outputs
├── default.nix            # Legacy Nix entry point
├── overlay.nix            # Nixpkgs overlay for integration
├── pkgs/                  # Package definitions
│   ├── microcosm/         # Microcosm-rs service collection
│   ├── blacksky/          # Blacksky community tools
│   └── bluesky/           # Official Bluesky packages
├── modules/               # NixOS service modules
│   ├── microcosm/         # Microcosm service modules
│   └── blacksky/          # Blacksky service modules
├── tests/                 # Integration tests and validation
├── code-references/       # Reference implementations for packaging
└── .tangled/              # CI/CD workflow definitions
```

## Package Organization (`pkgs/`)

### Current Structure
- **`pkgs/microcosm/`**: Multi-service Rust workspace with shared build artifacts
- **`pkgs/blacksky/`**: Community-maintained ATproto tools
- **`pkgs/bluesky/`**: Official Bluesky application packages

### Package Naming Convention
- Use kebab-case for package names
- Prefix with service collection when applicable (e.g., `microcosm-constellation`)
- Include version in package metadata
- Use descriptive names that reflect the service purpose

### Multi-Package Builds
For Rust workspaces like Microcosm:
- Build shared dependency artifacts once with `craneLib.buildDepsOnly`
- Generate individual packages using `pkgs.lib.genAttrs`
- Share common build environment and dependencies
- Handle special cases (like `ufos/fuzz` → `ufos-fuzz`)

## Module Organization (`modules/`)

### Service Module Structure
Each service collection has its own module directory:
```
modules/microcosm/
├── default.nix           # Imports all service modules
├── constellation.nix     # Constellation service configuration
├── spacedust.nix        # Spacedust service configuration
└── ...                  # Other service modules
```

### Module Naming Convention
- Use the same name as the corresponding package
- Prefix with service collection (e.g., `services.microcosm-constellation`)
- Group related services under common namespace

### Module Configuration Pattern
Each module follows a consistent structure:
1. **Options Definition**: Service-specific configuration options
2. **User/Group Management**: Dedicated system users for security
3. **Directory Management**: Using systemd tmpfiles for declarative setup
4. **Service Configuration**: systemd service with security hardening
5. **Runtime Script**: Proper argument construction and execution

## Code References (`code-references/`)

Contains reference implementations of ATproto applications for packaging analysis:
- **Allegedly**: Rust-based PLC tools
- **Leaflet**: TypeScript collaborative writing platform  
- **Slices**: Multi-language custom AppView platform
- **Streamplace**: Complex multimedia streaming infrastructure
- **Tangled-core**: Go-based git forge with existing Nix support

These serve as:
- Packaging targets for future development
- Reference for understanding ATproto application patterns
- Source of packaging complexity analysis

## Testing Structure (`tests/`)

- **Integration Tests**: End-to-end service testing
- **Module Tests**: NixOS module configuration validation
- **Package Tests**: Build verification and dependency checking

## Configuration Files

### Root Level
- **`flake.nix`**: Primary flake definition with inputs, outputs, and package exports
- **`default.nix`**: Legacy entry point calling package collections
- **`overlay.nix`**: Nixpkgs overlay for seamless integration

### Build Configuration
- **Rust**: Shared environment variables for OpenSSL, zstd, LLVM paths
- **Dependencies**: Consistent native and build inputs across packages
- **Security**: Proper hash pinning and source verification

## Development Workflow

### Adding New Packages
1. Create package definition in appropriate `pkgs/` subdirectory
2. Add corresponding NixOS module in `modules/`
3. Update collection's `default.nix` to include new package/module
4. Add integration tests in `tests/`
5. Update flake outputs to expose new packages

### Maintenance Tasks
- Use `nixpkgs-fmt` for consistent formatting
- Run `deadnix` to identify unused code
- Update flake inputs regularly with `nix flake update`
- Validate builds with `nix flake check`

## Security Considerations

### File Permissions
- Service data directories owned by dedicated users
- Read-only access to Nix store
- Restricted write access to service-specific directories

### Service Isolation
- Dedicated system users and groups per service
- systemd security restrictions (NoNewPrivileges, ProtectSystem, etc.)
- Network isolation where appropriate
- Proper capability management