# Contributing to ATProto NUR

Thank you for your interest in contributing to the ATProto Nix User Repository! This guide will help you get started with contributing packages, modules, and improvements to the ecosystem.

## Table of Contents

- [Getting Started](#getting-started)
- [Types of Contributions](#types-of-contributions)
- [Development Setup](#development-setup)
- [Package Contribution Workflow](#package-contribution-workflow)
- [Code Standards](#code-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Standards](#documentation-standards)
- [Review Process](#review-process)
- [Community Guidelines](#community-guidelines)

## Getting Started

### Prerequisites

- **Nix**: Install Nix with flakes enabled
- **Git**: For version control
- **GitHub Account**: For submitting pull requests
- **Basic Nix Knowledge**: Understanding of Nix expressions and flakes

### Quick Start

1. **Fork the repository**:
   ```bash
   gh repo fork atproto-nix/nur
   cd nur
   ```

2. **Enter development environment**:
   ```bash
   nix develop
   ```

3. **Explore the codebase**:
   ```bash
   # List available packages
   nix flake show
   
   # Build a package
   nix build .#microcosm-constellation
   
   # Run tests
   nix build .#tests
   ```

## Types of Contributions

### 1. New ATProto Packages

Package new ATProto applications, libraries, or tools:

- **Applications**: PDS, relays, feed generators, labelers
- **Libraries**: Core ATProto libraries, utilities
- **Tools**: CLI tools, development utilities, testing frameworks

### 2. NixOS Modules

Create service modules for ATProto applications:

- Service configuration and management
- Security hardening
- Integration with systemd
- Configuration validation

### 3. Templates and Tooling

Improve developer experience:

- Flake templates for new projects
- Helper functions and utilities
- Development tools and scripts
- Documentation and examples

### 4. Infrastructure Improvements

Enhance the repository infrastructure:

- CI/CD improvements
- Testing infrastructure
- Build optimizations
- Documentation systems

### 5. Bug Fixes and Maintenance

Help maintain existing packages:

- Security updates
- Dependency updates
- Bug fixes
- Performance improvements

## Development Setup

### Environment Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/nur.git
cd nur

# Add upstream remote
git remote add upstream https://github.com/atproto-nix/nur.git

# Enter development shell
nix develop
```

### Development Tools

The development shell provides:

- **Nix tools**: `nix`, `nixpkgs-fmt`, `deadnix`
- **Development utilities**: `curl`, `jq`, `git`
- **Language tools**: Rust, Node.js, Go toolchains
- **Testing tools**: VM test runners, integration test utilities

### Repository Structure

```
.
├── flake.nix              # Main flake definition
├── pkgs/                  # Package definitions (organized by organization)
│   ├── hyperlink-academy/ # Hyperlink Academy projects
│   ├── slices-network/    # Slices Network projects
│   ├── teal-fm/          # Teal.fm projects
│   ├── parakeet-social/  # Parakeet Social projects
│   ├── stream-place/     # Stream.place projects
│   ├── yoten-app/        # Yoten App projects
│   ├── red-dwarf-client/ # Red Dwarf Client projects
│   ├── tangled-dev/      # Tangled Development projects
│   ├── smokesignal-events/ # Smokesignal Events projects
│   ├── microcosm-blue/   # Microcosm Blue projects
│   ├── witchcraft-systems/ # Witchcraft Systems projects
│   ├── atbackup-pages-dev/ # ATBackup Pages Dev projects
│   ├── bluesky-social/   # Official Bluesky Social projects
│   ├── individual/       # Individual developer projects
│   ├── microcosm/        # Microcosm service collection (existing)
│   ├── blacksky/         # Community packages (existing)
│   ├── bluesky/          # Legacy Bluesky packages (existing)
│   └── atproto/          # Legacy ATProto packages (now mostly empty)
├── modules/               # NixOS service modules (organized by organization)
├── lib/                   # Shared utilities and helpers
├── templates/             # Flake templates
├── tests/                 # Integration tests
├── docs/                  # Documentation
└── .tangled/              # CI/CD workflows
```

## Package Contribution Workflow

### 1. Planning

Before starting, consider:

- **Organization**: Which organization owns this project?
- **Scope**: Is this a single package or multiple related packages?
- **Dependencies**: What are the build and runtime dependencies?
- **Integration**: Does it need a NixOS module?
- **Testing**: How will you test the package?
- **Placement**: Should this go in an existing organizational directory or create a new one?
- **Migration**: If this is an existing package, does it need to be moved from a legacy location?

### 2. Using Templates

Start with an appropriate template:

```bash
# For Rust applications
nix flake init -t .#rust-atproto

# For Node.js applications
nix flake init -t .#nodejs-atproto

# For Go applications
nix flake init -t .#go-atproto
```

### 3. Package Development

1. **Create package directory**:
   ```bash
   # For a new organization
   mkdir -p pkgs/your-organization/your-package
   
   # For an existing organization
   mkdir -p pkgs/existing-organization/your-package
   ```

2. **Implement package definition**:
   ```nix
   # pkgs/your-organization/your-package/default.nix
   { lib, fetchFromGitHub, atprotoLib, organizationMeta ? null, ... }:
   
   atprotoLib.mkRustAtprotoService {
     pname = "your-organization-your-package";  # Include organization in name
     version = "1.0.0";
     
     src = fetchFromGitHub {
       owner = "upstream-owner";
       repo = "upstream-repo";
       rev = "v1.0.0";
       hash = "sha256-...";
     };
     
     type = "application";
     services = [ "your-service" ];
     protocols = [ "com.atproto" ];
     
     # Include organizational metadata
     passthru = {
       organization = organizationMeta;
     };
     
     meta = with lib; {
       description = "Your ATProto service";
       homepage = "https://github.com/upstream-owner/upstream-repo";
       license = licenses.mit;
       maintainers = with maintainers; [ your-github-handle ];
       platforms = platforms.linux;
     };
   }
   ```

3. **Add to organizational collection**:
   ```nix
   # pkgs/your-organization/default.nix
   { lib, callPackage, ... }:
   
   let
     organizationMeta = {
       name = "your-organization";
       displayName = "Your Organization";
       website = "https://your-org.com";
       description = "ATProto projects by Your Organization";
     };
   in
   {
     passthru.organization = organizationMeta;
     
     your-package = callPackage ./your-package { 
       inherit organizationMeta;
     };
   }
   ```

4. **Update flake outputs**:
   ```nix
   # In flake.nix
   packages = {
     # ... existing packages
     your-organization-your-package = packages.your-organization.your-package;
     
     # Optionally provide a shorter alias (with deprecation path)
     your-package = packages.your-organization.your-package;
   };
   ```

### 4. Module Development (if needed)

1. **Create module**:
   ```bash
   mkdir -p modules/your-organization
   ```

2. **Implement service module**:
   ```nix
   # modules/your-organization/your-package.nix
   { config, lib, pkgs, ... }:
   
   with lib;
   
   let
     cfg = config.services.your-organization-your-package;
   in {
     options.services.your-organization-your-package = {
       enable = mkEnableOption "Your ATProto service";
       package = mkOption {
         type = types.package;
         default = pkgs.your-organization-your-package;
         description = "Package to use for the service";
       };
       # ... other options
     };
     
     config = mkIf cfg.enable {
       # Service configuration
     };
   }
   ```

3. **Add to module collection**:
   ```nix
   # modules/your-organization/default.nix
   {
     your-package = ./your-package.nix;
   }
   ```

### 5. Testing

1. **Build the package**:
   ```bash
   nix build .#your-organization-your-package
   ```

2. **Test the package**:
   ```bash
   nix run .#your-organization-your-package -- --help
   ```

3. **Create VM test** (for services):
   ```nix
   # tests/your-package.nix
   import <nixpkgs/nixos/tests/make-test-python.nix> ({ pkgs, ... }: {
     name = "your-package-test";
     
     nodes.machine = {
       imports = [ ../modules/your-organization ];
       services.your-organization-your-package.enable = true;
     };
     
     testScript = ''
       machine.start()
       machine.wait_for_unit("your-package.service")
       # Add more tests
     '';
   })
   ```

4. **Run all checks**:
   ```bash
   nix flake check
   ```

### 6. Documentation

1. **Package README**:
   ```markdown
   # Your Package
   
   Description of your package.
   
   ## Installation
   ## Configuration
   ## Usage
   ## Development
   ```

2. **Module documentation**:
   - Document all options
   - Provide examples
   - Include security considerations

## Code Standards

### Nix Code Style

1. **Formatting**: Use `nixpkgs-fmt` for consistent formatting
2. **Naming**: Use kebab-case for package names, camelCase for options
3. **Comments**: Document complex logic and design decisions
4. **Imports**: Order imports logically (lib, pkgs, local)

### Example:

```nix
{ lib
, fetchFromGitHub
, buildGoModule
, atprotoLib
, pkg-config
, sqlite
}:

atprotoLib.mkGoAtprotoApp {
  inherit buildGoModule;
  
  pname = "example-service";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "example";
    repo = "service";
    rev = "v1.0.0";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
  
  vendorHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
  
  # ATProto metadata
  type = "application";
  services = [ "example-service" ];
  protocols = [ "com.atproto" ];
  
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ sqlite ];
  
  meta = with lib; {
    description = "Example ATProto service";
    homepage = "https://github.com/example/service";
    license = licenses.mit;
    maintainers = with maintainers; [ example-maintainer ];
    platforms = platforms.linux;
  };
}
```

### ATProto Metadata Standards

All packages must include proper ATProto metadata:

```nix
passthru.atproto = {
  type = "application"; # or "library", "tool"
  services = [ "service-name" ];
  protocols = [ "com.atproto" ];
  schemaVersion = "1.0";
};
```

## Testing Guidelines

### Package Tests

1. **Build tests**: Ensure packages build successfully
2. **Unit tests**: Run upstream test suites
3. **Integration tests**: Test package functionality
4. **Cross-platform tests**: Test on supported platforms

### Module Tests

1. **Configuration tests**: Test various configurations
2. **Service tests**: Test service startup and operation
3. **Security tests**: Verify security hardening
4. **Integration tests**: Test service interactions

### Test Organization

```
tests/
├── default.nix           # Test collection
├── packages/             # Package-specific tests
│   └── your-package.nix
├── modules/              # Module tests
│   └── your-service.nix
└── integration/          # Cross-service tests
    └── full-stack.nix
```

## Documentation Standards

### Package Documentation

Each package should include:

1. **Clear description** of purpose and functionality
2. **Installation instructions** for different use cases
3. **Configuration examples** with explanations
4. **Usage examples** for common scenarios
5. **Development setup** for contributors

### Module Documentation

Service modules should document:

1. **All configuration options** with types and defaults
2. **Security considerations** and best practices
3. **Example configurations** for different scenarios
4. **Troubleshooting guide** for common issues

### Code Documentation

1. **Complex logic** should be explained with comments
2. **Design decisions** should be documented
3. **TODOs and FIXMEs** should include context
4. **External dependencies** should be explained

## Review Process

### Submission Checklist

Before submitting a pull request:

- [ ] Code follows style guidelines
- [ ] All tests pass (`nix flake check`)
- [ ] Documentation is complete and accurate
- [ ] ATProto metadata is properly configured
- [ ] Security considerations are addressed
- [ ] Performance impact is considered

### Review Criteria

Reviewers will evaluate:

1. **Code Quality**: Style, clarity, maintainability
2. **Functionality**: Correctness and completeness
3. **Security**: Proper hardening and validation
4. **Testing**: Comprehensive test coverage
5. **Documentation**: Clarity and completeness
6. **Integration**: Compatibility with existing packages

### Review Process

1. **Automated checks**: CI runs basic validation
2. **Maintainer review**: Core maintainers review code
3. **Community feedback**: Community members may provide input
4. **Iteration**: Address feedback and update PR
5. **Approval**: Maintainer approves and merges

## Community Guidelines

### Communication

- **Be respectful** and constructive in all interactions
- **Ask questions** when you need clarification
- **Provide context** when reporting issues or requesting features
- **Help others** when you can share knowledge

### Collaboration

- **Credit contributors** appropriately
- **Share knowledge** through documentation and examples
- **Coordinate efforts** to avoid duplicate work
- **Maintain packages** you contribute

### Code of Conduct

We follow the [Contributor Covenant](https://www.contributor-covenant.org/):

- Be welcoming and inclusive
- Respect different viewpoints and experiences
- Accept constructive criticism gracefully
- Focus on what's best for the community

## Getting Help

### Resources

- **Documentation**: Read the packaging guidelines and examples
- **Existing code**: Study similar packages for patterns
- **Community**: Ask questions in discussions or issues
- **Maintainers**: Reach out to maintainers for guidance

### Common Questions

**Q: How do I update package hashes?**
A: Run `nix build` and use the hash from the error message.

**Q: How do I test my package locally?**
A: Use `nix build .#your-package` and `nix run .#your-package`.

**Q: How do I add a new service collection?**
A: Create the directory structure and update flake outputs.

**Q: How do I handle complex build requirements?**
A: Check existing packages for patterns or ask for help.

### Support Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Matrix/Discord**: Real-time community chat (links in README)

## Recognition

Contributors are recognized through:

- **Maintainer attribution** in package metadata
- **Contributor lists** in documentation
- **Community highlights** for significant contributions
- **Commit attribution** in version control

Thank you for contributing to the ATProto Nix ecosystem!