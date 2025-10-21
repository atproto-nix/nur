#!/usr/bin/env bash

# Organizational Dependency Validation Script
# Validates dependencies and package integrity across the organizational structure

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATION_LOG="$REPO_ROOT/organizational-dependency-validation-$(date +%Y%m%d-%H%M%S).txt"
TEMP_DIR=$(mktemp -d)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$VALIDATION_LOG"
}

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Organizational collections
ORGANIZATIONAL_COLLECTIONS=(
    "hyperlink-academy" "slices-network" "teal-fm" "parakeet-social"
    "stream-place" "yoten-app" "red-dwarf-client" "tangled-dev"
    "smokesignal-events" "microcosm-blue" "witchcraft-systems"
    "atbackup-pages-dev" "bluesky-social" "individual"
)

# Legacy collections
LEGACY_COLLECTIONS=("microcosm" "blacksky" "bluesky" "atproto")

# Validate organizational package structure
validate_organizational_structure() {
    log_info "Validating organizational package structure..."
    
    local packages_dir="$REPO_ROOT/pkgs"
    local structure_errors=()
    
    # Check organizational directories exist
    for org in "${ORGANIZATIONAL_COLLECTIONS[@]}"; do
        local org_dir="$packages_dir/$org"
        
        if [ -d "$org_dir" ]; then
            log_success "Found organizational directory: $org"
            
            # Check for default.nix
            if [ -f "$org_dir/default.nix" ]; then
                log_info "  ✅ Has default.nix"
            else
                log_warning "  ⚠️  Missing default.nix"
                structure_errors+=("$org: missing default.nix")
            fi
            
            # Count packages
            local package_count=$(find "$org_dir" -name "*.nix" -not -name "default.nix" -type f | wc -l)
            log_info "  📦 Contains $package_count package(s)"
            
            if [ "$package_count" -eq 0 ]; then
                log_warning "  ⚠️  No packages found"
                structure_errors+=("$org: no packages")
            fi
        else
            log_error "Missing organizational directory: $org"
            structure_errors+=("$org: directory missing")
        fi
    done
    
    if [ ${#structure_errors[@]} -eq 0 ]; then
        log_success "Organizational structure validation passed"
        return 0
    else
        log_error "Organizational structure validation failed:"
        printf '%s\n' "${structure_errors[@]}" | tee -a "$VALIDATION_LOG"
        return 1
    fi
}

# Validate package dependencies
validate_package_dependencies() {
    log_info "Validating package dependencies..."
    
    local packages_dir="$REPO_ROOT/pkgs"
    local dependency_errors=()
    
    # Check all organizational collections
    for org in "${ORGANIZATIONAL_COLLECTIONS[@]}"; do
        local org_dir="$packages_dir/$org"
        
        if [ -d "$org_dir" ]; then
            log_info "Checking dependencies for $org packages..."
            
            # Find all package files
            while IFS= read -r -d '' nix_file; do
                local package_name=$(basename "$nix_file" .nix)
                
                if [ "$package_name" != "default" ]; then
                    log_info "  Validating $package_name..."
                    
                    # Check if package can be evaluated
                    if ! nix-instantiate --eval --expr "let pkgs = import <nixpkgs> {}; in (import $nix_file { inherit (pkgs) lib stdenv fetchFromGitHub; }).name or \"unknown\"" &>/dev/null; then
                        log_error "    ❌ Package evaluation failed"
                        dependency_errors+=("$org/$package_name: evaluation failed")
                    else
                        log_success "    ✅ Package evaluation passed"
                    fi
                    
                    # Check for common dependency issues
                    if grep -q "fetchFromGitHub" "$nix_file"; then
                        # Check for missing hash
                        if ! grep -q "sha256\|hash" "$nix_file"; then
                            log_error "    ❌ Missing source hash"
                            dependency_errors+=("$org/$package_name: missing source hash")
                        fi
                        
                        # Check for placeholder hash
                        if grep -q "lib\.fake\|0000000000000000000000000000000000000000000000000000" "$nix_file"; then
                            log_error "    ❌ Placeholder hash detected"
                            dependency_errors+=("$org/$package_name: placeholder hash")
                        fi
                    fi
                fi
            done < <(find "$org_dir" -name "*.nix" -type f -print0)
        fi
    done
    
    if [ ${#dependency_errors[@]} -eq 0 ]; then
        log_success "Package dependency validation passed"
        return 0
    else
        log_error "Package dependency validation failed:"
        printf '%s\n' "${dependency_errors[@]}" | tee -a "$VALIDATION_LOG"
        return 1
    fi
}

# Validate organizational metadata
validate_organizational_metadata() {
    log_info "Validating organizational metadata..."
    
    cd "$REPO_ROOT"
    local metadata_errors=()
    
    # Check if packages have organizational metadata
    for org in "${ORGANIZATIONAL_COLLECTIONS[@]}"; do
        local org_dir="pkgs/$org"
        
        if [ -d "$org_dir" ]; then
            log_info "Checking metadata for $org packages..."
            
            # Find all package files
            while IFS= read -r -d '' nix_file; do
                local package_name=$(basename "$nix_file" .nix)
                
                if [ "$package_name" != "default" ]; then
                    # Check for organizational metadata
                    if grep -q "passthru\.organization" "$nix_file"; then
                        log_success "  ✅ $package_name has organizational metadata"
                    else
                        log_warning "  ⚠️  $package_name missing organizational metadata"
                        metadata_errors+=("$org/$package_name: missing organizational metadata")
                    fi
                    
                    # Check for ATProto metadata
                    if grep -q "passthru\.atproto" "$nix_file"; then
                        log_success "  ✅ $package_name has ATProto metadata"
                    else
                        log_warning "  ⚠️  $package_name missing ATProto metadata"
                        metadata_errors+=("$org/$package_name: missing ATProto metadata")
                    fi
                fi
            done < <(find "$org_dir" -name "*.nix" -type f -print0)
        fi
    done
    
    if [ ${#metadata_errors[@]} -eq 0 ]; then
        log_success "Organizational metadata validation passed"
        return 0
    else
        log_warning "Organizational metadata validation completed with warnings:"
        printf '%s\n' "${metadata_errors[@]}" | tee -a "$VALIDATION_LOG"
        return 0  # Warnings don't fail the validation
    fi
}

# Validate flake exports
validate_flake_exports() {
    log_info "Validating flake exports..."
    
    cd "$REPO_ROOT"
    local export_errors=()
    
    # Check if flake can be evaluated
    if ! nix flake show --json > "$TEMP_DIR/flake-outputs.json" 2>/dev/null; then
        log_error "Failed to evaluate flake outputs"
        return 1
    fi
    
    # Check for organizational packages in flake outputs
    for org in "${ORGANIZATIONAL_COLLECTIONS[@]}"; do
        log_info "Checking flake exports for $org..."
        
        # Look for packages with organizational prefix
        local org_packages=$(jq -r ".packages.\"x86_64-linux\" | keys[]" "$TEMP_DIR/flake-outputs.json" 2>/dev/null | grep "^$org-" || true)
        
        if [ -n "$org_packages" ]; then
            local package_count=$(echo "$org_packages" | wc -l)
            log_success "  ✅ Found $package_count exported package(s) for $org"
        else
            log_warning "  ⚠️  No exported packages found for $org"
            export_errors+=("$org: no exported packages")
        fi
    done
    
    if [ ${#export_errors[@]} -eq 0 ]; then
        log_success "Flake export validation passed"
        return 0
    else
        log_warning "Flake export validation completed with warnings:"
        printf '%s\n' "${export_errors[@]}" | tee -a "$VALIDATION_LOG"
        return 0  # Warnings don't fail the validation
    fi
}

# Validate backward compatibility
validate_backward_compatibility() {
    log_info "Validating backward compatibility..."
    
    cd "$REPO_ROOT"
    local compatibility_errors=()
    
    # Test some known old package names
    local old_packages=("leaflet" "slices" "teal" "parakeet" "quickdid" "allegedly")
    
    for old_package in "${old_packages[@]}"; do
        log_info "Testing backward compatibility for: $old_package"
        
        if nix build ".#$old_package" --dry-run &>/dev/null; then
            log_success "  ✅ Backward compatibility working for $old_package"
        else
            log_warning "  ⚠️  Backward compatibility not working for $old_package"
            compatibility_errors+=("$old_package: backward compatibility broken")
        fi
    done
    
    if [ ${#compatibility_errors[@]} -eq 0 ]; then
        log_success "Backward compatibility validation passed"
        return 0
    else
        log_warning "Backward compatibility validation completed with warnings:"
        printf '%s\n' "${compatibility_errors[@]}" | tee -a "$VALIDATION_LOG"
        return 0  # Warnings don't fail the validation
    fi
}

# Generate validation report
generate_validation_report() {
    log_info "Generating organizational dependency validation report..."
    
    local report_file="$REPO_ROOT/organizational-dependency-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# ATProto NUR Organizational Dependency Validation Report

**Generated:** $(date)
**Repository:** ATProto NUR
**Validation Type:** Organizational Structure and Dependencies

## Summary

This report contains the results of validating the organizational structure
and dependencies after the package hierarchy reorganization.

## Organizational Structure

$(if validate_organizational_structure &>/dev/null; then
    echo "✅ **PASSED** - All organizational directories are properly structured"
else
    echo "❌ **FAILED** - Issues found in organizational structure"
fi)

### Organizational Collections Validated
$(for org in "${ORGANIZATIONAL_COLLECTIONS[@]}"; do
    if [ -d "pkgs/$org" ]; then
        echo "- ✅ $org"
    else
        echo "- ❌ $org (missing)"
    fi
done)

## Package Dependencies

$(if validate_package_dependencies &>/dev/null; then
    echo "✅ **PASSED** - All package dependencies are valid"
else
    echo "❌ **FAILED** - Issues found in package dependencies"
fi)

## Organizational Metadata

$(if validate_organizational_metadata &>/dev/null; then
    echo "✅ **PASSED** - Organizational metadata is complete"
else
    echo "⚠️ **WARNINGS** - Some metadata issues found"
fi)

## Flake Exports

$(if validate_flake_exports &>/dev/null; then
    echo "✅ **PASSED** - Flake exports are working correctly"
else
    echo "⚠️ **WARNINGS** - Some export issues found"
fi)

## Backward Compatibility

$(if validate_backward_compatibility &>/dev/null; then
    echo "✅ **PASSED** - Backward compatibility is maintained"
else
    echo "⚠️ **WARNINGS** - Some compatibility issues found"
fi)

## Recommendations

1. **Structure Issues**: Address any missing organizational directories or default.nix files
2. **Dependency Issues**: Fix any packages with evaluation failures or missing hashes
3. **Metadata**: Add missing organizational and ATProto metadata to packages
4. **Exports**: Ensure all organizational packages are properly exported in flake.nix
5. **Compatibility**: Maintain backward compatibility aliases for smooth migration

## Full Validation Log

See \`$(basename "$VALIDATION_LOG")\` for complete validation details.

---
*Report generated by ATProto NUR organizational dependency validation script*
EOF

    log_success "Validation report generated: $report_file"
    
    # Display summary
    echo ""
    echo "=========================================="
    echo "  ORGANIZATIONAL DEPENDENCY VALIDATION"
    echo "=========================================="
    echo ""
    
    if validate_organizational_structure &>/dev/null; then
        echo "🏗️  Organizational structure: PASSED"
    else
        echo "🏗️  Organizational structure: FAILED"
    fi
    
    if validate_package_dependencies &>/dev/null; then
        echo "📦 Package dependencies: PASSED"
    else
        echo "📦 Package dependencies: FAILED"
    fi
    
    if validate_organizational_metadata &>/dev/null; then
        echo "📋 Organizational metadata: PASSED"
    else
        echo "📋 Organizational metadata: WARNINGS"
    fi
    
    if validate_flake_exports &>/dev/null; then
        echo "📤 Flake exports: PASSED"
    else
        echo "📤 Flake exports: WARNINGS"
    fi
    
    if validate_backward_compatibility &>/dev/null; then
        echo "🔄 Backward compatibility: PASSED"
    else
        echo "🔄 Backward compatibility: WARNINGS"
    fi
    
    echo ""
    echo "📄 Full report: $report_file"
    echo "📋 Validation log: $VALIDATION_LOG"
    echo ""
}

# Main execution
main() {
    log_info "Starting ATProto NUR organizational dependency validation"
    log_info "Repository: $REPO_ROOT"
    log_info "Log file: $VALIDATION_LOG"
    
    local validation_passed=true
    
    # Run all validation steps
    if ! validate_organizational_structure; then
        validation_passed=false
    fi
    
    if ! validate_package_dependencies; then
        validation_passed=false
    fi
    
    validate_organizational_metadata  # Warnings only
    validate_flake_exports           # Warnings only
    validate_backward_compatibility  # Warnings only
    
    # Generate final report
    generate_validation_report
    
    if [ "$validation_passed" = true ]; then
        log_success "Organizational dependency validation completed successfully"
        exit 0
    else
        log_error "Organizational dependency validation failed"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi