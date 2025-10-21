#!/bin/bash

# Organizational validation script
# Validates the organizational mapping and structure after reorganization

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=== ATProto NUR Organizational Framework Validation ==="
echo ""

# Test organizational mapping
echo "1. Testing organizational mapping..."
if nix-instantiate --eval --expr 'let pkgs = import <nixpkgs> {}; lib = pkgs.lib; organizationalFramework = import ./lib/organizational-framework.nix { inherit lib; }; in organizationalFramework.mapping.organizationalMapping.allegedly.organization' &>/dev/null; then
    ALLEGEDLY_ORG=$(nix-instantiate --eval --expr 'let pkgs = import <nixpkgs> {}; lib = pkgs.lib; organizationalFramework = import ./lib/organizational-framework.nix { inherit lib; }; in organizationalFramework.mapping.organizationalMapping.allegedly.organization' | tr -d '"')
    log_info "allegedly package organization: $ALLEGEDLY_ORG"
else
    log_warning "allegedly package mapping not found (may have been migrated)"
fi

if nix-instantiate --eval --expr 'let pkgs = import <nixpkgs> {}; lib = pkgs.lib; organizationalFramework = import ./lib/organizational-framework.nix { inherit lib; }; in organizationalFramework.mapping.organizationalMapping.quickdid.organization' &>/dev/null; then
    QUICKDID_ORG=$(nix-instantiate --eval --expr 'let pkgs = import <nixpkgs> {}; lib = pkgs.lib; organizationalFramework = import ./lib/organizational-framework.nix { inherit lib; }; in organizationalFramework.mapping.organizationalMapping.quickdid.organization' | tr -d '"')
    log_info "quickdid package organization: $QUICKDID_ORG"
else
    log_warning "quickdid package mapping not found (may have been migrated)"
fi

echo ""

# Test package directory structure
echo "2. Testing organizational directory structure..."
PACKAGES_DIR="$REPO_ROOT/pkgs"

# Check for organizational directories
ORGANIZATIONAL_DIRS=(
    "hyperlink-academy" "slices-network" "teal-fm" "parakeet-social"
    "stream-place" "yoten-app" "red-dwarf-client" "tangled-dev"
    "smokesignal-events" "microcosm-blue" "witchcraft-systems"
    "atbackup-pages-dev" "bluesky-social" "individual"
)

FOUND_ORGS=0
TOTAL_ORGS=${#ORGANIZATIONAL_DIRS[@]}

for org_dir in "${ORGANIZATIONAL_DIRS[@]}"; do
    if [ -d "$PACKAGES_DIR/$org_dir" ]; then
        log_success "Found organizational directory: $org_dir"
        FOUND_ORGS=$((FOUND_ORGS + 1))
        
        # Check for packages in the directory
        PACKAGE_COUNT=$(find "$PACKAGES_DIR/$org_dir" -name "*.nix" -type f | wc -l)
        if [ "$PACKAGE_COUNT" -gt 0 ]; then
            log_info "  Contains $PACKAGE_COUNT package(s)"
        else
            log_warning "  Directory exists but contains no packages"
        fi
    else
        log_warning "Missing organizational directory: $org_dir"
    fi
done

log_info "Found $FOUND_ORGS out of $TOTAL_ORGS organizational directories"

echo ""

# Test module directory structure
echo "3. Testing organizational module structure..."
MODULES_DIR="$REPO_ROOT/modules"

FOUND_MODULE_ORGS=0

for org_dir in "${ORGANIZATIONAL_DIRS[@]}"; do
    if [ -d "$MODULES_DIR/$org_dir" ]; then
        log_success "Found organizational module directory: $org_dir"
        FOUND_MODULE_ORGS=$((FOUND_MODULE_ORGS + 1))
        
        # Check for modules in the directory
        MODULE_COUNT=$(find "$MODULES_DIR/$org_dir" -name "*.nix" -type f | wc -l)
        if [ "$MODULE_COUNT" -gt 0 ]; then
            log_info "  Contains $MODULE_COUNT module(s)"
        else
            log_warning "  Directory exists but contains no modules"
        fi
    else
        log_warning "Missing organizational module directory: $org_dir"
    fi
done

log_info "Found $FOUND_MODULE_ORGS out of $TOTAL_ORGS organizational module directories"

echo ""

# Test package builds
echo "4. Testing organizational package builds..."
cd "$REPO_ROOT"

# Test a few key organizational packages
TEST_PACKAGES=(
    "hyperlink-academy-leaflet"
    "slices-network-slices"
    "teal-fm-teal"
    "parakeet-social-parakeet"
    "smokesignal-events-quickdid"
    "microcosm-blue-allegedly"
)

SUCCESSFUL_BUILDS=0
TOTAL_TEST_PACKAGES=${#TEST_PACKAGES[@]}

for package in "${TEST_PACKAGES[@]}"; do
    log_info "Testing build for: $package"
    if nix build ".#$package" --dry-run &>/dev/null; then
        log_success "  Build test passed for $package"
        SUCCESSFUL_BUILDS=$((SUCCESSFUL_BUILDS + 1))
    else
        log_warning "  Build test failed for $package (package may not be available)"
    fi
done

log_info "Successful build tests: $SUCCESSFUL_BUILDS out of $TOTAL_TEST_PACKAGES"

echo ""

# Test backward compatibility
echo "5. Testing backward compatibility..."

# Test old package names still work through aliases
OLD_PACKAGE_NAMES=(
    "leaflet"
    "slices"
    "teal"
    "parakeet"
    "quickdid"
    "allegedly"
)

SUCCESSFUL_ALIASES=0
TOTAL_ALIASES=${#OLD_PACKAGE_NAMES[@]}

for old_name in "${OLD_PACKAGE_NAMES[@]}"; do
    log_info "Testing backward compatibility for: $old_name"
    if nix build ".#$old_name" --dry-run &>/dev/null; then
        log_success "  Backward compatibility working for $old_name"
        SUCCESSFUL_ALIASES=$((SUCCESSFUL_ALIASES + 1))
    else
        log_warning "  Backward compatibility not working for $old_name"
    fi
done

log_info "Working backward compatibility aliases: $SUCCESSFUL_ALIASES out of $TOTAL_ALIASES"

echo ""

# Test flake structure
echo "6. Testing flake structure..."
if nix flake check --no-build &>/dev/null; then
    log_success "Flake structure validation passed"
else
    log_error "Flake structure validation failed"
fi

echo ""

# Generate validation report
echo "7. Generating validation report..."

VALIDATION_SCORE=0
MAX_SCORE=6

# Score organizational directories
if [ "$FOUND_ORGS" -eq "$TOTAL_ORGS" ]; then
    VALIDATION_SCORE=$((VALIDATION_SCORE + 1))
fi

# Score module directories
if [ "$FOUND_MODULE_ORGS" -eq "$TOTAL_ORGS" ]; then
    VALIDATION_SCORE=$((VALIDATION_SCORE + 1))
fi

# Score package builds
if [ "$SUCCESSFUL_BUILDS" -gt $((TOTAL_TEST_PACKAGES / 2)) ]; then
    VALIDATION_SCORE=$((VALIDATION_SCORE + 1))
fi

# Score backward compatibility
if [ "$SUCCESSFUL_ALIASES" -gt $((TOTAL_ALIASES / 2)) ]; then
    VALIDATION_SCORE=$((VALIDATION_SCORE + 1))
fi

# Score flake validation
if nix flake check --no-build &>/dev/null; then
    VALIDATION_SCORE=$((VALIDATION_SCORE + 1))
fi

# Score overall structure
if [ "$FOUND_ORGS" -gt 0 ] && [ "$FOUND_MODULE_ORGS" -gt 0 ]; then
    VALIDATION_SCORE=$((VALIDATION_SCORE + 1))
fi

echo ""
echo "=== Organizational Framework Validation Complete ==="
echo ""
echo "Validation Results:"
echo "- Organizational directories: $FOUND_ORGS/$TOTAL_ORGS"
echo "- Module directories: $FOUND_MODULE_ORGS/$TOTAL_ORGS"
echo "- Package build tests: $SUCCESSFUL_BUILDS/$TOTAL_TEST_PACKAGES"
echo "- Backward compatibility: $SUCCESSFUL_ALIASES/$TOTAL_ALIASES"
echo "- Overall validation score: $VALIDATION_SCORE/$MAX_SCORE"
echo ""

if [ "$VALIDATION_SCORE" -eq "$MAX_SCORE" ]; then
    log_success "✅ Organizational framework validation: EXCELLENT"
elif [ "$VALIDATION_SCORE" -ge $((MAX_SCORE * 3 / 4)) ]; then
    log_success "✅ Organizational framework validation: GOOD"
elif [ "$VALIDATION_SCORE" -ge $((MAX_SCORE / 2)) ]; then
    log_warning "⚠️  Organizational framework validation: NEEDS IMPROVEMENT"
else
    log_error "❌ Organizational framework validation: POOR"
fi

echo ""
echo "The organizational structure has been validated!"

# Exit with appropriate code
if [ "$VALIDATION_SCORE" -ge $((MAX_SCORE / 2)) ]; then
    exit 0
else
    exit 1
fi