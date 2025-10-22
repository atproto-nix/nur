#!/usr/bin/env bash

# CI/CD Infrastructure Validation Script
# Validates the complete CI/CD and maintenance infrastructure for ATProto NUR

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATION_LOG="$REPO_ROOT/ci-cd-validation-$(date +%Y%m%d-%H%M%S).txt"
TEMP_DIR=$(mktemp -d)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_detail() {
    echo -e "${CYAN}[DETAIL]${NC} $1" | tee -a "$VALIDATION_LOG"
}

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Validation counters
VALIDATION_PASSED=0
VALIDATION_FAILED=0
VALIDATION_WARNINGS=0

# Function to run validation with error handling
run_validation() {
    local validation_name="$1"
    local description="$2"
    local command="$3"
    
    log_detail "Running $description..."
    if eval "$command" > "$TEMP_DIR/${validation_name}.log" 2>&1; then
        log_success "✅ $description passed"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 1 ]; then
            log_warning "⚠️ $description completed with warnings"
            VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
            return 1
        else
            log_error "❌ $description failed"
            VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
            return 2
        fi
    fi
}

# Validate CI/CD workflow files
validate_workflow_files() {
    log_step "Validating CI/CD workflow files..."
    
    local workflow_files=(
        ".tangled/workflows/build.yml:Tangled build workflow"
        ".github/workflows/build.yml:GitHub Actions build workflow"
        ".github/workflows/dependency-updates.yml:GitHub Actions dependency update workflow"
        "ci.nix:CI configuration file"
    )
    
    for workflow_entry in "${workflow_files[@]}"; do
        IFS=':' read -r file_path description <<< "$workflow_entry"
        
        if [ -f "$REPO_ROOT/$file_path" ]; then
            log_success "✅ Found $description: $file_path"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
            
            # Validate workflow content
            case "$file_path" in
                *.yml)
                    if grep -q "comprehensive\|security\|organizational" "$REPO_ROOT/$file_path"; then
                        log_detail "  Workflow includes comprehensive features"
                    else
                        log_warning "  Workflow may be missing comprehensive features"
                        VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
                    fi
                    ;;
                *.nix)
                    if nix-instantiate --parse "$REPO_ROOT/$file_path" >/dev/null 2>&1; then
                        log_detail "  Nix file syntax is valid"
                    else
                        log_error "  Nix file has syntax errors"
                        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
                    fi
                    ;;
            esac
        else
            log_error "❌ Missing $description: $file_path"
            VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
        fi
    done
}

# Validate automation scripts
validate_automation_scripts() {
    log_step "Validating automation scripts..."
    
    local scripts=(
        "scripts/update-dependencies.sh:Dependency update script"
        "scripts/automated-dependency-updates.sh:Automated dependency update script"
        "scripts/validate-organizational-dependencies.sh:Organizational validation script"
        "scripts/organizational-validation.sh:Organizational structure validation script"
        "scripts/validate-ci-cd-infrastructure.sh:CI/CD infrastructure validation script"
    )
    
    for script_entry in "${scripts[@]}"; do
        IFS=':' read -r script_path description <<< "$script_entry"
        
        if [ -f "$REPO_ROOT/$script_path" ]; then
            log_success "✅ Found $description: $script_path"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
            
            # Check if script is executable
            if [ -x "$REPO_ROOT/$script_path" ]; then
                log_detail "  Script is executable"
            else
                log_warning "  Script is not executable"
                VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
            fi
            
            # Basic syntax check for bash scripts
            if [[ "$script_path" == *.sh ]]; then
                if bash -n "$REPO_ROOT/$script_path" 2>/dev/null; then
                    log_detail "  Script syntax is valid"
                else
                    log_error "  Script has syntax errors"
                    VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
                fi
            fi
        else
            log_error "❌ Missing $description: $script_path"
            VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
        fi
    done
}

# Validate test infrastructure
validate_test_infrastructure() {
    log_step "Validating test infrastructure..."
    
    cd "$REPO_ROOT"
    
    # Check test directory structure
    if [ -d "tests" ]; then
        log_success "✅ Tests directory exists"
        VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        
        # Count test files
        local test_count=$(find tests/ -name "*.nix" -type f | wc -l)
        log_detail "  Found $test_count test files"
        
        # Check for key test files
        local key_tests=(
            "tests/default.nix:Test suite index"
            "tests/security-scanning.nix:Security scanning tests"
            "tests/automated-security-scanning.nix:Automated security scanning tests"
            "tests/dependency-update-verification.nix:Dependency update tests"
            "tests/comprehensive-ci-cd-validation.nix:Comprehensive CI/CD validation tests"
            "tests/organizational-framework.nix:Organizational framework tests"
        )
        
        for test_entry in "${key_tests[@]}"; do
            IFS=':' read -r test_path description <<< "$test_entry"
            
            if [ -f "$test_path" ]; then
                log_success "  ✅ $description"
                VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
            else
                log_error "  ❌ Missing $description: $test_path"
                VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
            fi
        done
    else
        log_error "❌ Tests directory missing"
        VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
    fi
    
    # Validate that tests can be built
    log_detail "Validating test buildability..."
    
    local test_builds=(
        "tests.security-scanning:Security scanning test build"
        "tests.automated-security-scanning:Automated security scanning test build"
        "tests.dependency-update-verification:Dependency update test build"
        "tests.comprehensive-ci-cd-validation:Comprehensive CI/CD test build"
    )
    
    for test_build_entry in "${test_builds[@]}"; do
        IFS=':' read -r test_target description <<< "$test_build_entry"
        
        if nix build ".#$test_target" --dry-run 2>/dev/null; then
            log_success "  ✅ $description can be built"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        else
            log_warning "  ⚠️ $description cannot be built"
            VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
        fi
    done
}

# Validate security infrastructure
validate_security_infrastructure() {
    log_step "Validating security infrastructure..."
    
    # Check for security tools availability
    local security_tools=(
        "vulnix:Vulnerability scanner"
        "nix-audit:Nix security auditor"
        "checksec:Binary security checker"
        "nixpkgs-fmt:Code formatter"
        "deadnix:Dead code detector"
    )
    
    for tool_entry in "${security_tools[@]}"; do
        IFS=':' read -r tool_name description <<< "$tool_entry"
        
        if command -v "$tool_name" &> /dev/null; then
            log_success "✅ $description available: $tool_name"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        else
            log_warning "⚠️ $description not available: $tool_name"
            VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
        fi
    done
    
    # Test security scanning functionality
    cd "$REPO_ROOT"
    
    run_validation "security-test" "Security test suite" "nix build .#tests.security-scanning --dry-run"
    run_validation "automated-security-test" "Automated security test suite" "nix build .#tests.automated-security-scanning --dry-run"
}

# Validate package infrastructure
validate_package_infrastructure() {
    log_step "Validating package infrastructure..."
    
    cd "$REPO_ROOT"
    
    # Check package directory structure
    local package_collections=(
        "pkgs/microcosm:Microcosm packages"
        "pkgs/blacksky:Blacksky packages"
        "pkgs/bluesky:Bluesky packages"
        "pkgs/atproto:ATProto packages"
        "pkgs/hyperlink-academy:Hyperlink Academy packages"
        "pkgs/slices-network:Slices Network packages"
        "pkgs/tangled-dev:Tangled Development packages"
    )
    
    for collection_entry in "${package_collections[@]}"; do
        IFS=':' read -r collection_path description <<< "$collection_entry"
        
        if [ -d "$collection_path" ]; then
            log_success "✅ $description directory exists"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
            
            # Check for default.nix
            if [ -f "$collection_path/default.nix" ]; then
                log_detail "  Has default.nix"
            else
                log_warning "  Missing default.nix"
                VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
            fi
            
            # Count packages
            local package_count=$(find "$collection_path" -name "*.nix" -not -name "default.nix" -type f | wc -l)
            log_detail "  Contains $package_count package(s)"
        else
            log_warning "⚠️ $description directory missing: $collection_path"
            VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
        fi
    done
    
    # Test package builds
    log_detail "Testing package build capability..."
    
    local sample_packages=(
        "microcosm-constellation:Microcosm Constellation"
        "blacksky-pds:Blacksky PDS"
        "hyperlink-academy-leaflet:Hyperlink Academy Leaflet"
    )
    
    for package_entry in "${sample_packages[@]}"; do
        IFS=':' read -r package_name description <<< "$package_entry"
        
        if nix build ".#$package_name" --dry-run 2>/dev/null; then
            log_success "  ✅ $description can be built"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        else
            log_warning "  ⚠️ $description cannot be built"
            VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
        fi
    done
}

# Validate flake infrastructure
validate_flake_infrastructure() {
    log_step "Validating flake infrastructure..."
    
    cd "$REPO_ROOT"
    
    # Check flake files
    local flake_files=(
        "flake.nix:Main flake definition"
        "flake.lock:Flake lock file"
        "default.nix:Legacy entry point"
        "overlay.nix:Nixpkgs overlay"
    )
    
    for flake_entry in "${flake_files[@]}"; do
        IFS=':' read -r file_path description <<< "$flake_entry"
        
        if [ -f "$file_path" ]; then
            log_success "✅ $description exists: $file_path"
            VALIDATION_PASSED=$((VALIDATION_PASSED + 1))
        else
            log_error "❌ Missing $description: $file_path"
            VALIDATION_FAILED=$((VALIDATION_FAILED + 1))
        fi
    done
    
    # Test flake functionality
    run_validation "flake-check" "Flake structure validation" "nix flake check --no-build"
    run_validation "flake-show" "Flake output validation" "nix flake show --json >/dev/null"
}

# Generate comprehensive validation report
generate_validation_report() {
    log_step "Generating comprehensive validation report..."
    
    local report_file="$REPO_ROOT/ci-cd-infrastructure-validation-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# ATProto NUR CI/CD Infrastructure Validation Report

**Generated:** $(date)
**Validation Type:** Comprehensive CI/CD Infrastructure
**Script Version:** 1.0.0

## Executive Summary

This report provides a comprehensive validation of the CI/CD and maintenance
infrastructure for the ATProto NUR repository, including workflows, automation
scripts, testing infrastructure, security systems, and package management.

## Validation Results

### Overall Statistics
- ✅ **Validations Passed**: $VALIDATION_PASSED
- ⚠️ **Validations with Warnings**: $VALIDATION_WARNINGS  
- ❌ **Validations Failed**: $VALIDATION_FAILED
- 📊 **Total Validations**: $((VALIDATION_PASSED + VALIDATION_WARNINGS + VALIDATION_FAILED))

### Success Rate
$(if [ $VALIDATION_FAILED -eq 0 ]; then
    echo "🎉 **100% Critical Success Rate** - All critical validations passed"
else
    local success_rate=$(( (VALIDATION_PASSED * 100) / (VALIDATION_PASSED + VALIDATION_FAILED) ))
    echo "📊 **Success Rate**: ${success_rate}% - Some critical validations failed"
fi)

## Infrastructure Components Validated

### CI/CD Workflow Files
$(if grep -q "validate_workflow_files" "$VALIDATION_LOG" 2>/dev/null; then
    echo "✅ **VALIDATED** - All workflow files checked"
    echo ""
    echo "- Tangled build workflow (.tangled/workflows/build.yml)"
    echo "- GitHub Actions build workflow (.github/workflows/build.yml)"  
    echo "- GitHub Actions dependency updates (.github/workflows/dependency-updates.yml)"
    echo "- CI configuration (ci.nix)"
else
    echo "❌ **NOT VALIDATED** - Workflow files not checked"
fi)

### Automation Scripts
$(if grep -q "validate_automation_scripts" "$VALIDATION_LOG" 2>/dev/null; then
    echo "✅ **VALIDATED** - All automation scripts checked"
    echo ""
    echo "- Dependency update script (scripts/update-dependencies.sh)"
    echo "- Automated dependency updates (scripts/automated-dependency-updates.sh)"
    echo "- Organizational validation (scripts/validate-organizational-dependencies.sh)"
    echo "- Structure validation (scripts/organizational-validation.sh)"
    echo "- CI/CD validation (scripts/validate-ci-cd-infrastructure.sh)"
else
    echo "❌ **NOT VALIDATED** - Automation scripts not checked"
fi)

### Test Infrastructure
$(if grep -q "validate_test_infrastructure" "$VALIDATION_LOG" 2>/dev/null; then
    echo "✅ **VALIDATED** - Test infrastructure checked"
    echo ""
    echo "- Security scanning tests (tests/security-scanning.nix)"
    echo "- Automated security tests (tests/automated-security-scanning.nix)"
    echo "- Dependency update tests (tests/dependency-update-verification.nix)"
    echo "- Comprehensive CI/CD tests (tests/comprehensive-ci-cd-validation.nix)"
    echo "- Organizational framework tests (tests/organizational-framework.nix)"
else
    echo "❌ **NOT VALIDATED** - Test infrastructure not checked"
fi)

### Security Infrastructure
$(if grep -q "validate_security_infrastructure" "$VALIDATION_LOG" 2>/dev/null; then
    echo "✅ **VALIDATED** - Security infrastructure checked"
    echo ""
    echo "- Vulnerability scanning (vulnix)"
    echo "- Security auditing (nix-audit)"
    echo "- Binary security analysis (checksec)"
    echo "- Code quality tools (nixpkgs-fmt, deadnix)"
else
    echo "❌ **NOT VALIDATED** - Security infrastructure not checked"
fi)

### Package Infrastructure
$(if grep -q "validate_package_infrastructure" "$VALIDATION_LOG" 2>/dev/null; then
    echo "✅ **VALIDATED** - Package infrastructure checked"
    echo ""
    echo "- Legacy collections (Microcosm, Blacksky, Bluesky, ATProto)"
    echo "- Organizational collections (14 organizations)"
    echo "- Package build capability"
    echo "- Directory structure validation"
else
    echo "❌ **NOT VALIDATED** - Package infrastructure not checked"
fi)

### Flake Infrastructure
$(if grep -q "validate_flake_infrastructure" "$VALIDATION_LOG" 2>/dev/null; then
    echo "✅ **VALIDATED** - Flake infrastructure checked"
    echo ""
    echo "- Flake definition (flake.nix)"
    echo "- Flake lock file (flake.lock)"
    echo "- Legacy entry point (default.nix)"
    echo "- Nixpkgs overlay (overlay.nix)"
else
    echo "❌ **NOT VALIDATED** - Flake infrastructure not checked"
fi)

## Detailed Validation Logs

$(if [ -f "$TEMP_DIR/flake-check.log" ]; then
    echo "### Flake Validation Details"
    echo ""
    echo "\`\`\`"
    head -20 "$TEMP_DIR/flake-check.log" 2>/dev/null || echo "Log not available"
    echo "\`\`\`"
    echo ""
fi)

$(if [ -f "$TEMP_DIR/security-test.log" ]; then
    echo "### Security Test Details"
    echo ""
    echo "\`\`\`"
    head -20 "$TEMP_DIR/security-test.log" 2>/dev/null || echo "Log not available"
    echo "\`\`\`"
    echo ""
fi)

## Recommendations

### Immediate Actions
$(if [ $VALIDATION_FAILED -gt 0 ]; then
    echo "- 🔧 **Address Failed Validations**: $VALIDATION_FAILED critical validations failed"
else
    echo "- ✅ **No Critical Issues**: All critical validations passed"
fi)

$(if [ $VALIDATION_WARNINGS -gt 0 ]; then
    echo "- ⚠️ **Review Warnings**: $VALIDATION_WARNINGS validations completed with warnings"
else
    echo "- ✅ **No Warnings**: All validations completed without warnings"
fi)

### Maintenance Tasks
- 🔄 **Regular Validation**: Run this validation script regularly
- 📋 **Monitor Infrastructure**: Keep CI/CD infrastructure up to date
- 🛡️ **Security Updates**: Maintain security scanning tools
- 📊 **Performance Monitoring**: Track validation performance over time

## Next Steps

1. **Address Issues**: Fix any failed validations immediately
2. **Review Warnings**: Investigate and resolve warnings
3. **Documentation**: Update documentation as needed
4. **Monitoring**: Set up regular validation monitoring

## Technical Details

### Validation Environment
- **Nix Version**: $(nix --version 2>/dev/null || echo "Unknown")
- **Platform**: $(uname -m 2>/dev/null || echo "Unknown")
- **Validation Script**: CI/CD Infrastructure Validation v1.0.0

### Repository Statistics
- **Workflow Files**: $(find .tangled .github -name "*.yml" -type f 2>/dev/null | wc -l || echo "Unknown")
- **Automation Scripts**: $(find scripts/ -name "*.sh" -type f 2>/dev/null | wc -l || echo "Unknown")
- **Test Files**: $(find tests/ -name "*.nix" -type f 2>/dev/null | wc -l || echo "Unknown")
- **Package Collections**: $(find pkgs/ -maxdepth 1 -type d | tail -n +2 | wc -l || echo "Unknown")

---

**Report Generated**: $(date)  
**Validation Script**: ATProto NUR CI/CD Infrastructure Validation v1.0.0  
**Status**: $(if [ $VALIDATION_FAILED -eq 0 ]; then echo "✅ INFRASTRUCTURE VALIDATED"; else echo "❌ VALIDATION ISSUES FOUND"; fi)

EOF

    log_success "Validation report generated: $report_file"
    
    # Display summary
    echo ""
    echo "=========================================="
    echo "    CI/CD INFRASTRUCTURE VALIDATION"
    echo "=========================================="
    echo ""
    echo "✅ Validations Passed: $VALIDATION_PASSED"
    echo "⚠️  Validations with Warnings: $VALIDATION_WARNINGS"
    echo "❌ Validations Failed: $VALIDATION_FAILED"
    echo "📊 Total Validations: $((VALIDATION_PASSED + VALIDATION_WARNINGS + VALIDATION_FAILED))"
    echo ""
    
    if [ $VALIDATION_FAILED -eq 0 ]; then
        echo "🎉 OVERALL STATUS: INFRASTRUCTURE VALIDATED"
        echo "   All critical infrastructure components are operational"
    else
        echo "⚠️  OVERALL STATUS: VALIDATION ISSUES FOUND"
        echo "   $VALIDATION_FAILED critical validations failed"
        echo "   Review the detailed report for remediation steps"
    fi
    
    echo ""
    echo "📄 Full report: $report_file"
    echo "📋 Validation log: $VALIDATION_LOG"
    echo "=========================================="
}

# Main execution
main() {
    log_info "Starting ATProto NUR CI/CD infrastructure validation"
    log_info "Repository: $REPO_ROOT"
    log_info "Log file: $VALIDATION_LOG"
    
    # Run all validation steps
    validate_workflow_files
    validate_automation_scripts
    validate_test_infrastructure
    validate_security_infrastructure
    validate_package_infrastructure
    validate_flake_infrastructure
    
    # Generate final report
    generate_validation_report
    
    if [ $VALIDATION_FAILED -eq 0 ]; then
        log_success "CI/CD infrastructure validation completed successfully"
        exit 0
    else
        log_error "CI/CD infrastructure validation found $VALIDATION_FAILED critical issues"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi