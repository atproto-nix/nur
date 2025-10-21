# ATProto NUR Testing Documentation

This document describes the testing infrastructure for the ATProto Nix User Repository, including the core library package tests implemented as part of Task 2.4.

## Test Categories

### Core Library Package Tests (Task 2.4)

The following tests validate core library packages, dependency compatibility, and security scanning:

#### 1. Build Verification Tests (`core-library-build-verification.nix`)

**Purpose**: Verify that all core library packages build correctly and have proper metadata.

**What it tests**:
- All Microcosm packages (constellation, spacedust, ufos, etc.)
- All Blacksky packages (rsky-pds, rsky-relay, etc.)
- All ATProto packages (allegedly, quickdid, etc.)
- Binary availability and execution
- Dependency linking validation
- Basic functionality testing
- File type verification

**Usage**:
```bash
nix build .#tests.x86_64-linux.core-library-build-verification
```

#### 2. Dependency Compatibility Tests (`dependency-compatibility.nix`)

**Purpose**: Validate that ATProto packages are compatible with each other and can coexist.

**What it tests**:
- Protocol compatibility between packages
- Service compatibility and conflict detection
- Dependency resolution validation
- Runtime compatibility verification
- ATProto metadata consistency
- Cross-collection package compatibility

**Usage**:
```bash
nix build .#tests.x86_64-linux.dependency-compatibility
```

#### 3. Security Scanning Tests (`security-scanning.nix`)

**Purpose**: Perform security validation and vulnerability scanning of packaged libraries.

**What it tests**:
- Vulnerability scanning with vulnix
- Binary security analysis with checksec
- Dependency security validation
- File permissions security
- ATProto security metadata validation
- Runtime security validation
- Supply chain security verification

**Usage**:
```bash
nix build .#tests.x86_64-linux.security-scanning
```

#### 4. Core Library Validation (`core-library-validation.nix`)

**Purpose**: Validate ATProto library functions and helper utilities.

**What it tests**:
- ATProto library function availability
- Package metadata schema validation
- Cross-language compatibility
- Service configuration helpers
- Dependency resolution utilities
- Build environment validation

**Usage**:
```bash
nix build .#tests.x86_64-linux.core-library-validation
```

#### 5. Constellation Build Test (`constellation.nix`)

**Purpose**: Specific build verification test for the Constellation service (fixes missing test referenced in tests/default.nix).

**What it tests**:
- Constellation package availability
- Package metadata validation
- Basic functionality verification

**Usage**:
```bash
nix build .#tests.x86_64-linux.constellation
```

### Existing Tests

#### Integration Tests
- `constellation-shell.nix`: NixOS module integration test for Constellation
- `microcosm-standardized.nix`: Standardized Microcosm service tests
- `tier2-modules.nix`: Tier 2 application module tests
- `tier3-modules.nix`: Tier 3 application module tests
- `pds-ecosystem.nix`: PDS ecosystem integration tests

#### Library Tests
- `atproto-lib.nix`: ATProto library function tests
- `atproto-core-libs.nix`: Core ATProto library package tests
- `bluesky-packages.nix`: Bluesky package collection tests

## Running Tests

### Prerequisites

Tests are designed to run on Linux systems using NixOS VM testing infrastructure. They can be built on other platforms but will execute in Linux VMs.

### Individual Tests

Run a specific test:
```bash
nix build .#tests.x86_64-linux.<test-name>
```

### All Tests

List available tests:
```bash
nix eval .#tests.x86_64-linux --apply builtins.attrNames
```

### Test Validation Script

Use the provided script to validate test syntax and availability:
```bash
./scripts/test-core-libraries.sh
```

## Test Structure

### NixOS VM Tests

Most tests use the NixOS testing framework (`nixosTest` or `make-test-python.nix`) which:
- Creates isolated QEMU VMs for testing
- Provides reproducible test environments
- Enables testing of system-level interactions
- Supports parallel test execution

### Test File Structure

```nix
import <nixpkgs/nixos/tests/make-test-python.nix> ({ pkgs, ... }: {
  name = "test-name";
  
  nodes.machine = { config, pkgs, ... }: {
    # Test environment configuration
    environment.systemPackages = [ /* packages to test */ ];
  };
  
  testScript = ''
    # Python test script
    machine.start()
    machine.succeed("test command")
    machine.log("Test completed")
  '';
})
```

## Security Testing

### Vulnerability Scanning

The security scanning tests use several tools:
- **vulnix**: Scans for known vulnerabilities in Nix packages
- **checksec**: Analyzes binary security features
- **binutils**: Provides binary analysis tools

### Security Validation

Tests verify:
- No known vulnerabilities in dependencies
- Proper binary security features (ASLR, stack protection, etc.)
- Correct file permissions and ownership
- Security metadata in ATProto packages
- Runtime security constraints

## Continuous Integration

### Tangled Workflows

Tests are integrated with the existing `.tangled/workflows/build.yml` CI system:

```yaml
- name: Run core library tests
  run: |
    nix build .#tests.x86_64-linux.core-library-build-verification
    nix build .#tests.x86_64-linux.dependency-compatibility
    nix build .#tests.x86_64-linux.security-scanning
```

### Quality Gates

All tests must pass for:
- Package builds
- Dependency compatibility
- Security validation
- Metadata consistency

## Adding New Tests

### Test File Template

```nix
import <nixpkgs/nixos/tests/make-test-python.nix> ({ pkgs, ... }: {
  name = "my-new-test";
  
  nodes.machine = { config, pkgs, ... }: {
    # Configure test environment
  };
  
  testScript = ''
    machine.start()
    # Add test logic
    machine.log("Test completed successfully")
  '';
})
```

### Integration Steps

1. Create test file in `tests/` directory
2. Add test to `tests/default.nix`
3. Update documentation
4. Validate with `./scripts/test-core-libraries.sh`

## Troubleshooting

### Common Issues

1. **Platform Compatibility**: Tests are designed for Linux. Use `x86_64-linux` or `aarch64-linux` targets.

2. **Missing Dependencies**: Ensure all required packages are available in the test environment.

3. **VM Resource Limits**: Large tests may need increased memory or disk space.

### Debug Mode

Run tests with verbose output:
```bash
nix build .#tests.x86_64-linux.<test-name> --show-trace
```

### Test Logs

VM test logs are available in the Nix build output and can help diagnose failures.

## Requirements Compliance

These tests fulfill the requirements from Task 2.4:

- ✅ **Build verification tests**: `core-library-build-verification.nix` tests all core library packages
- ✅ **Dependency compatibility testing**: `dependency-compatibility.nix` validates package compatibility
- ✅ **Security scanning integration**: `security-scanning.nix` provides comprehensive security validation
- ✅ **Fix missing constellation.nix**: Created `constellation.nix` test referenced in `tests/default.nix`

All tests follow the established patterns and integrate with the existing testing infrastructure while providing comprehensive validation of the ATProto package ecosystem.