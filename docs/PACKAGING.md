# ATProto Nix Packaging Guidelines

This document provides comprehensive guidelines for packaging ATProto applications in the ATProto Nix User Repository (NUR).

## Table of Contents

- [Overview](#overview)
- [Package Structure](#package-structure)
- [Language-Specific Guidelines](#language-specific-guidelines)
- [ATProto Metadata](#atproto-metadata)
- [Security Requirements](#security-requirements)
- [Testing Requirements](#testing-requirements)
- [Documentation Requirements](#documentation-requirements)
- [Contribution Process](#contribution-process)

## Overview

The ATProto NUR provides a standardized way to package and deploy ATProto applications on NixOS. All packages must follow these guidelines to ensure consistency, security, and maintainability.

### Core Principles

1. **Reproducibility**: All builds must be reproducible across different systems
2. **Security**: Security hardening is built into every package by default
3. **Consistency**: All packages follow the same structural patterns
4. **Metadata**: Rich ATProto-specific metadata for tooling and discovery
5. **Testing**: Comprehensive testing at package and integration levels

## Package Structure

### Directory Layout

```
pkgs/
├── atproto/           # Core ATProto libraries and tools
├── bluesky/           # Official Bluesky applications
├── microcosm/         # Microcosm service collection
├── blacksky/          # Community ATProto tools
└── your-collection/   # Your service collection
```

### Package Organization

Each service collection should be organized as:

```
pkgs/your-collection/
├── default.nix        # Collection entry point
├── service-a/         # Individual service packages
│   └── default.nix
├── service-b/
│   └── default.nix
└── lib.nix           # Shared utilities (optional)
```

### Collection Entry Point

```nix
# pkgs/your-collection/default.nix
{ lib, callPackage, ... }:

{
  service-a = callPackage ./service-a { };
  service-b = callPackage ./service-b { };
  
  # Export the collection as a single derivation if needed
  all = lib.buildEnv {
    name = "your-collection";
    paths = [ service-a service-b ];
  };
}
```

## Language-Specific Guidelines

### Rust Applications

Use the `mkRustAtprotoService` helper from `lib/atproto.nix`:

```nix
{ lib, fetchFromGitHub, craneLib, atprotoLib }:

atprotoLib.mkRustAtprotoService {
  pname = "my-rust-service";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "your-org";
    repo = "your-repo";
    rev = "v1.0.0";
    hash = "sha256-..."; # Use nix-prefetch-url to get this
  };
  
  # ATProto metadata
  type = "application";
  services = [ "my-service" ];
  protocols = [ "com.atproto" "app.bsky" ];
  
  # Additional build inputs if needed
  buildInputs = [ /* additional dependencies */ ];
  
  meta = with lib; {
    description = "My ATProto Rust service";
    homepage = "https://github.com/your-org/your-repo";
    license = licenses.mit;
    maintainers = with maintainers; [ your-github-handle ];
    platforms = platforms.linux;
  };
}
```

#### Rust Workspace Handling

For multi-package Rust workspaces, use `mkRustWorkspace`:

```nix
{ lib, fetchFromGitHub, craneLib, atprotoLib }:

let
  src = fetchFromGitHub {
    owner = "your-org";
    repo = "workspace-repo";
    rev = "v1.0.0";
    hash = "sha256-...";
  };
  
  members = [ "service-a" "service-b" "tool-c" ];
  
  packages = atprotoLib.mkRustWorkspace {
    inherit src members;
    version = "1.0.0";
  };
in
packages // {
  # Add ATProto metadata to each package
  service-a = packages.service-a // {
    passthru = packages.service-a.passthru // {
      atproto = {
        type = "application";
        services = [ "service-a" ];
        protocols = [ "com.atproto" ];
      };
    };
  };
  # ... repeat for other packages
}
```

### Node.js Applications

Use the `mkNodeAtprotoApp` helper:

```nix
{ lib, fetchFromGitHub, buildNpmPackage, atprotoLib }:

atprotoLib.mkNodeAtprotoApp {
  inherit buildNpmPackage;
  
  pname = "my-node-service";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "your-org";
    repo = "your-repo";
    rev = "v1.0.0";
    hash = "sha256-...";
  };
  
  npmDepsHash = "sha256-..."; # Run nix build and update when dependencies change
  
  # ATProto metadata
  type = "application";
  services = [ "my-node-service" ];
  protocols = [ "com.atproto" ];
  
  # Build configuration
  buildPhase = ''
    npm run build
  '';
  
  installPhase = ''
    mkdir -p $out/bin $out/lib/node_modules/${pname}
    cp -r dist/* $out/lib/node_modules/${pname}/
    cp package.json $out/lib/node_modules/${pname}/
    
    cat > $out/bin/${pname} << 'EOF'
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.nodejs}/bin/node $out/lib/node_modules/${pname}/index.js "$@"
    EOF
    chmod +x $out/bin/${pname}
  '';
  
  meta = with lib; {
    description = "My ATProto Node.js service";
    homepage = "https://github.com/your-org/your-repo";
    license = licenses.mit;
    maintainers = with maintainers; [ your-github-handle ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
```

### Go Applications

Use the `mkGoAtprotoApp` helper:

```nix
{ lib, fetchFromGitHub, buildGoModule, atprotoLib }:

atprotoLib.mkGoAtprotoApp {
  inherit buildGoModule;
  
  pname = "my-go-service";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "your-org";
    repo = "your-repo";
    rev = "v1.0.0";
    hash = "sha256-...";
  };
  
  vendorHash = "sha256-..."; # Run nix build and update when dependencies change
  
  # ATProto metadata
  type = "application";
  services = [ "my-go-service" ];
  protocols = [ "com.atproto" ];
  
  # Build configuration
  ldflags = [
    "-s" "-w"
    "-X main.version=${version}"
  ];
  
  meta = with lib; {
    description = "My ATProto Go service";
    homepage = "https://github.com/your-org/your-repo";
    license = licenses.mit;
    maintainers = with maintainers; [ your-github-handle ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
```

## ATProto Metadata

All ATProto packages must include standardized metadata in the `passthru.atproto` attribute:

```nix
passthru = {
  atproto = {
    # Required fields
    type = "application" | "library" | "tool";
    services = [ "list-of-service-names" ];
    protocols = [ "com.atproto" "app.bsky" "custom.protocol" ];
    schemaVersion = "1.0";
    
    # Optional fields
    atprotoDependencies = {
      "atproto-lexicon" = "^0.4.0";
      "atproto-crypto" = "^0.3.0";
    };
    
    configuration = {
      required = [ "hostname" "port" ];
      optional = [ "database" "logging" ];
    };
    
    # Service-specific metadata
    endpoints = [ "/xrpc/com.atproto.repo.createRecord" ];
    databases = [ "sqlite" "postgres" ];
    storage = [ "disk" "s3" ];
  };
};
```

### Metadata Fields

- **type**: Package classification (`application`, `library`, `tool`)
- **services**: List of service names provided by this package
- **protocols**: ATProto protocols supported (e.g., `com.atproto`, `app.bsky`)
- **schemaVersion**: Metadata schema version (currently `"1.0"`)
- **atprotoDependencies**: Dependencies on other ATProto packages
- **configuration**: Required and optional configuration parameters
- **endpoints**: XRPC endpoints provided (for applications)
- **databases**: Supported database backends
- **storage**: Supported storage backends

## Security Requirements

### Build Security

1. **Pin exact commit hashes** for all source fetching:
   ```nix
   src = fetchFromGitHub {
     owner = "owner";
     repo = "repo";
     rev = "abc123def456..."; # Full commit hash, not tag
     hash = "sha256-...";
   };
   ```

2. **Validate all checksums** for external dependencies
3. **Use content-addressed derivations** where possible
4. **Apply security patches** through overlays when needed

### Runtime Security

All service modules must implement comprehensive security hardening:

```nix
systemd.services.my-service = {
  serviceConfig = {
    # User isolation
    User = "my-service";
    Group = "my-service";
    DynamicUser = false; # Use dedicated system users
    
    # Security restrictions
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    RestrictSUIDSGID = true;
    RestrictRealtime = true;
    RestrictNamespaces = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    
    # File system access
    ReadWritePaths = [ "/var/lib/my-service" ];
    ReadOnlyPaths = [ "/nix/store" ];
    
    # Network restrictions
    RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
  };
};
```

### Configuration Security

1. **Validate security-sensitive configuration**:
   ```nix
   assertions = [
     {
       assertion = cfg.database.passwordFile != null -> 
                   (lib.hasPrefix "/run/secrets/" cfg.database.passwordFile);
       message = "Database password file should be in /run/secrets/";
     }
   ];
   ```

2. **Use secure defaults** for all configuration options
3. **Integrate with secrets management** systems (sops-nix, agenix)
4. **Provide warnings** for potentially insecure configurations

## Testing Requirements

### Package Tests

Every package must include comprehensive tests:

```nix
# In flake.nix checks
checks = {
  inherit my-package;
  
  # Build tests
  my-package-build = my-package;
  
  # Unit tests (language-specific)
  my-package-test = craneLib.cargoNextest (commonArgs // {
    inherit cargoArtifacts;
    partitions = 1;
    partitionType = "count";
  });
  
  # Integration tests
  my-package-integration = import ./tests/integration.nix {
    inherit pkgs my-package;
  };
};
```

### NixOS VM Tests

Services must include NixOS VM tests:

```nix
# tests/my-service.nix
import <nixpkgs/nixos/tests/make-test-python.nix> ({ pkgs, ... }: {
  name = "my-service-test";
  
  nodes.machine = { config, pkgs, ... }: {
    imports = [ ../modules/my-service ];
    
    services.my-service = {
      enable = true;
      settings = {
        port = 8080;
        host = "localhost";
      };
    };
  };
  
  testScript = ''
    machine.start()
    machine.wait_for_unit("my-service.service")
    machine.wait_for_open_port(8080)
    
    # Test health endpoint
    machine.succeed("curl -f http://localhost:8080/health")
    
    # Test ATProto endpoints
    machine.succeed("""
      curl -f -X POST http://localhost:8080/xrpc/com.atproto.repo.createRecord \
        -H "Content-Type: application/json" \
        -d '{"did": "did:plc:test", "collection": "app.bsky.feed.post"}'
    """)
  '';
})
```

### Test Organization

```
tests/
├── default.nix           # Test collection entry point
├── my-service.nix        # Individual service VM tests
├── integration/          # Cross-service integration tests
│   └── full-stack.nix
└── performance/          # Performance and load tests
    └── benchmark.nix
```

## Documentation Requirements

### Package Documentation

Each package must include:

1. **README.md** with:
   - Clear description of the service/tool
   - Installation instructions
   - Configuration examples
   - Usage examples
   - Development setup

2. **NixOS module documentation** with:
   - All configuration options documented
   - Example configurations
   - Security considerations
   - Troubleshooting guide

### Code Documentation

1. **Nix expressions** must include:
   - Clear comments explaining complex logic
   - Metadata descriptions
   - Build configuration rationale

2. **Module options** must include:
   - Comprehensive descriptions
   - Type information
   - Default values with rationale
   - Example values

Example:

```nix
options.services.my-service = {
  enable = mkEnableOption "My ATProto service";
  
  port = mkOption {
    type = types.port;
    default = 8080;
    description = lib.mdDoc ''
      Port for the service to listen on.
      
      Note: Ports below 1024 require additional privileges.
    '';
    example = 3000;
  };
  
  settings = mkOption {
    type = types.submodule {
      options = {
        logLevel = mkOption {
          type = types.enum [ "trace" "debug" "info" "warn" "error" ];
          default = "info";
          description = lib.mdDoc ''
            Logging level for the service.
            
            - `trace`: Very verbose debugging information
            - `debug`: Debugging information
            - `info`: General information (recommended for production)
            - `warn`: Warning messages only
            - `error`: Error messages only
          '';
        };
      };
    };
    default = {};
    description = lib.mdDoc "Service configuration options";
  };
};
```

## Contribution Process

### 1. Preparation

1. **Fork the repository** and create a feature branch
2. **Use the appropriate template** for your language/framework
3. **Follow the naming conventions** for your service collection

### 2. Development

1. **Implement the package** following these guidelines
2. **Add comprehensive tests** (unit, integration, VM tests)
3. **Create NixOS module** if it's a service
4. **Write documentation** (README, module docs, code comments)

### 3. Quality Assurance

1. **Run all checks**:
   ```bash
   nix flake check
   ```

2. **Test the package**:
   ```bash
   nix build .#your-package
   nix run .#your-package
   ```

3. **Test the module** (if applicable):
   ```bash
   nix build .#nixosConfigurations.test-vm
   ```

4. **Validate metadata**:
   ```bash
   nix eval .#packages.x86_64-linux.your-package.passthru.atproto
   ```

### 4. Submission

1. **Create a pull request** with:
   - Clear description of the package/service
   - Links to upstream project
   - Testing evidence
   - Documentation updates

2. **Address review feedback** promptly
3. **Ensure CI passes** before requesting final review

### 5. Maintenance

1. **Monitor upstream releases** and update packages
2. **Respond to security advisories** promptly
3. **Maintain compatibility** with NixOS releases
4. **Update documentation** as needed

## Best Practices

### Performance

1. **Share build artifacts** for multi-package workspaces
2. **Use binary caches** for common dependencies
3. **Minimize closure size** by avoiding unnecessary dependencies
4. **Enable parallel builds** where possible

### Maintainability

1. **Use helper functions** from `lib/atproto.nix`
2. **Follow consistent patterns** across packages
3. **Document complex build logic**
4. **Keep packages focused** (single responsibility)

### Compatibility

1. **Support multiple NixOS releases** when possible
2. **Test on different architectures** (x86_64-linux, aarch64-linux)
3. **Handle version compatibility** gracefully
4. **Provide migration paths** for breaking changes

## Troubleshooting

### Common Issues

1. **Hash mismatches**: Update hashes when sources change
2. **Build failures**: Check build logs and dependencies
3. **Test failures**: Ensure tests are deterministic
4. **Module conflicts**: Use unique option names

### Getting Help

1. **Check existing packages** for similar patterns
2. **Review the documentation** thoroughly
3. **Ask in discussions** or issues
4. **Join the community** chat channels

## Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [ATProto Specification](https://atproto.com/)
- [ATProto Nix Community](https://github.com/atproto-nix)