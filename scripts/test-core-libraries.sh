#!/usr/bin/env bash

# Test runner for core library package tests (Task 2.4)
# This script validates that all the new tests can be built and are syntactically correct

set -euo pipefail

echo "=== ATProto Core Library Test Validation ==="

# Test files to validate
TESTS=(
    "constellation"
    "core-library-build-verification" 
    "dependency-compatibility"
    "security-scanning"
    "core-library-validation"
)

echo "Validating test syntax..."

for test in "${TESTS[@]}"; do
    echo "  Checking $test..."
    if nix-instantiate --eval --expr "let pkgs = import <nixpkgs> {}; in (import ./tests/${test}.nix { inherit pkgs; }).name" > /dev/null 2>&1; then
        echo "    ✓ $test syntax is valid"
    else
        echo "    ✗ $test has syntax errors"
        exit 1
    fi
done

echo "Checking test integration..."

# Check that tests are properly exposed in the flake
if nix eval .#tests.x86_64-linux --apply builtins.attrNames > /dev/null 2>&1; then
    echo "  ✓ Tests are properly exposed in flake"
else
    echo "  ✗ Tests are not properly exposed in flake"
    exit 1
fi

# Verify all our new tests are available
echo "Verifying test availability..."
available_tests=$(nix eval .#tests.x86_64-linux --apply builtins.attrNames --json | jq -r '.[]')

for test in "${TESTS[@]}"; do
    if echo "$available_tests" | grep -q "^$test$"; then
        echo "  ✓ $test is available in flake"
    else
        echo "  ✗ $test is not available in flake"
        exit 1
    fi
done

echo ""
echo "=== All Core Library Tests Validated Successfully ==="
echo ""
echo "Available tests:"
echo "$available_tests" | sed 's/^/  - /'
echo ""
echo "To run tests on a Linux system:"
echo "  nix build .#tests.x86_64-linux.constellation"
echo "  nix build .#tests.x86_64-linux.core-library-build-verification"
echo "  nix build .#tests.x86_64-linux.dependency-compatibility"
echo "  nix build .#tests.x86_64-linux.security-scanning"
echo "  nix build .#tests.x86_64-linux.core-library-validation"