# ATProto Nix Ecosystem Documentation

Welcome to the ATProto Nix Ecosystem documentation! This collection provides comprehensive resources for packaging, deploying, and developing ATProto applications using Nix and NixOS.

## Quick Start

### Using Templates

Create a new ATProto service using our templates:

```bash
# Rust service
nix flake init -t github:atproto-nix/nur#rust-atproto

# Node.js service  
nix flake init -t github:atproto-nix/nur#nodejs-atproto

# Go service
nix flake init -t github:atproto-nix/nur#go-atproto
```

### Installing Packages

Add ATProto packages to your system:

```bash
# Install a specific service
nix profile install github:atproto-nix/nur#microcosm-constellation

# Use in NixOS configuration
{
  services.microcosm-constellation.enable = true;
}
```

## Documentation Structure

### For Users

- **[Installation Guide](INSTALLATION.md)** - How to install and use ATProto packages
- **[Configuration Guide](CONFIGURATION.md)** - Configuring ATProto services on NixOS
- **[Service Reference](SERVICES.md)** - Complete reference for all available services

### For Developers

- **[Packaging Guidelines](PACKAGING.md)** - How to package ATProto applications
- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute to the ecosystem
- **[Templates Guide](TEMPLATES.md)** - Using and customizing flake templates
- **[Testing Guide](TESTING.md)** - Testing packages and modules

### For Maintainers

- **[Maintenance Guide](MAINTENANCE.md)** - Maintaining packages and infrastructure
- **[Security Guide](SECURITY.md)** - Security practices and vulnerability handling
- **[Release Guide](RELEASES.md)** - Release processes and versioning

## Available Templates

### Rust ATProto Service

Perfect for building high-performance ATProto services:

- **Features**: Axum web server, structured logging, comprehensive testing
- **Use cases**: PDS implementations, relays, feed generators, labelers
- **Dependencies**: Tokio async runtime, SQLx database support, ATProto libraries

```bash
nix flake init -t github:atproto-nix/nur#rust-atproto
```

### Node.js ATProto Service

Ideal for rapid prototyping and TypeScript development:

- **Features**: Express.js server, XRPC integration, TypeScript support
- **Use cases**: Web applications, API services, development tools
- **Dependencies**: ATProto SDK, Express middleware, Jest testing

```bash
nix flake init -t github:atproto-nix/nur#nodejs-atproto
```

### Go ATProto Service

Great for system services and CLI tools:

- **Features**: Gorilla Mux router, Cobra CLI, structured configuration
- **Use cases**: System utilities, CLI tools, infrastructure services
- **Dependencies**: Standard library focus, minimal external dependencies

```bash
nix flake init -t github:atproto-nix/nur#go-atproto
```

## Package Collections

### Core ATProto (`atproto`)

Fundamental libraries and tools for ATProto development:

- `atproto-lexicon` - Schema definition and validation
- `atproto-crypto` - Cryptographic utilities
- `atproto-common` - Shared utilities and types

### Official Bluesky (`bluesky`)

Official Bluesky applications and services:

- `bluesky-pds` - Personal Data Server
- `bluesky-relay` - ATProto relay service
- `bluesky-feedgen` - Feed generator framework

### Microcosm Collection (`microcosm`)

Rust-based ATProto service suite:

- `microcosm-constellation` - Backlink indexer
- `microcosm-spacedust` - ATProto service component
- `microcosm-slingshot` - ATProto service component
- And more...

### Community Tools (`blacksky`)

Community-maintained ATProto tools and utilities:

- `blacksky-rsky` - Community ATProto tools
- Additional community contributions

## Development Workflow

### 1. Choose Your Stack

Select the appropriate template based on your preferred language and use case:

- **Rust**: High performance, systems programming, memory safety
- **Node.js**: Rapid development, web applications, JavaScript ecosystem
- **Go**: Simple deployment, CLI tools, system services

### 2. Initialize Project

```bash
# Create new project from template
nix flake init -t github:atproto-nix/nur#rust-atproto
cd my-atproto-project

# Enter development environment
nix develop
```

### 3. Customize Template

- Replace placeholder names with your service name
- Update ATProto metadata (services, protocols)
- Implement your ATProto logic
- Add tests and documentation

### 4. Package for Distribution

- Follow packaging guidelines
- Add NixOS module if it's a service
- Create comprehensive tests
- Submit to the repository

## Best Practices

### Security

- **Use dedicated system users** for each service
- **Apply systemd security hardening** by default
- **Validate all configuration** inputs
- **Integrate with secrets management** systems

### Performance

- **Share build artifacts** for multi-package workspaces
- **Use binary caches** for faster builds
- **Minimize closure sizes** by avoiding unnecessary dependencies
- **Enable parallel builds** where possible

### Maintainability

- **Follow consistent patterns** across packages
- **Use helper functions** from the ATProto library
- **Document complex logic** and design decisions
- **Keep packages focused** on single responsibilities

### Testing

- **Comprehensive test coverage** for all packages
- **NixOS VM tests** for service modules
- **Integration tests** for cross-service functionality
- **Performance tests** for critical services

## Community

### Getting Help

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Documentation**: Comprehensive guides and references
- **Examples**: Real-world usage examples and patterns

### Contributing

We welcome contributions of all kinds:

- **New packages**: ATProto applications, libraries, tools
- **Bug fixes**: Improvements to existing packages
- **Documentation**: Guides, examples, and references
- **Templates**: New language support or specialized templates

See our [Contributing Guide](CONTRIBUTING.md) for detailed information.

### Code of Conduct

We follow the [Contributor Covenant](https://www.contributor-covenant.org/) to ensure a welcoming and inclusive community for all contributors.

## Resources

### ATProto Resources

- [ATProto Specification](https://atproto.com/) - Official protocol specification
- [Bluesky Documentation](https://docs.bsky.app/) - Bluesky-specific documentation
- [ATProto GitHub](https://github.com/bluesky-social/atproto) - Reference implementations

### Nix Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/) - Nix package manager
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/) - Nixpkgs collection
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - NixOS operating system

### Development Tools

- [Nix Flakes](https://nixos.wiki/wiki/Flakes) - Modern Nix development
- [Crane](https://github.com/ipetkov/crane) - Rust builds with Nix
- [Dream2nix](https://github.com/nix-community/dream2nix) - Language-agnostic packaging

## License

This documentation and the ATProto Nix ecosystem are licensed under the MIT License. See individual packages for their specific licenses.