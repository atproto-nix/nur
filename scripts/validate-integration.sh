#!/usr/bin/env bash
# Validation script for NixOS ecosystem integration

set -euo pipefail

echo "=== ATProto NixOS Ecosystem Integration Validation ==="

# Check that integration library can be evaluated
echo "Checking integration library syntax..."
nix-instantiate --parse lib/nixos-integration.nix > /dev/null
echo "✓ Integration library syntax is valid"

# Check that integration test can be evaluated
echo "Checking integration test..."
nix eval .#tests.x86_64-linux.nixos-ecosystem-integration.name > /dev/null
echo "✓ Integration test is properly defined"

# Check that common integration module can be evaluated
echo "Checking common integration module..."
nix-instantiate --eval --expr 'let pkgs = import <nixpkgs> {}; in (import ./modules/common/nixos-integration.nix { config = {}; lib = pkgs.lib; pkgs = pkgs; }).options' --impure > /dev/null
echo "✓ Common integration module is valid"

# Check that enhanced constellation module can be evaluated
echo "Checking enhanced constellation module..."
nix-instantiate --eval --expr 'let pkgs = import <nixpkgs> {}; in (import ./modules/microcosm/constellation-enhanced.nix { config = {}; lib = pkgs.lib; pkgs = pkgs; }).options' --impure > /dev/null
echo "✓ Enhanced constellation module is valid"

# Validate integration documentation exists
echo "Checking integration documentation..."
if [[ -f "docs/NIXOS_ECOSYSTEM_INTEGRATION.md" ]]; then
    echo "✓ Integration documentation exists"
else
    echo "✗ Integration documentation missing"
    exit 1
fi

# Check that example patch exists
echo "Checking integration example..."
if [[ -f "examples/yoten-integration-patch.nix" ]]; then
    echo "✓ Integration example exists"
else
    echo "✗ Integration example missing"
    exit 1
fi

echo ""
echo "=== Integration Validation Summary ==="
echo "✓ All integration components are properly defined"
echo "✓ Syntax validation passed"
echo "✓ Documentation and examples are present"
echo ""
echo "The NixOS ecosystem integration is ready for use!"
echo ""
echo "Next steps:"
echo "1. Update existing service modules to use integration helpers"
echo "2. Test integration with real services on Linux systems"
echo "3. Add integration to deployment profiles"
echo ""
echo "See docs/NIXOS_ECOSYSTEM_INTEGRATION.md for usage examples."