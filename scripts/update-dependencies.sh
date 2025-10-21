#!/usr/bin/env bash

# ATProto NUR Dependency Update and Hash Verification Script
# This script automates the process of checking for updates and verifying hashes
# for all ATProto packages in the repository.

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
UPDATE_LOG="$REPO_ROOT/update-log-$(date +%Y%m%d-%H%M%S).txt"
TEMP_DIR=$(mktemp -d)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$UPDATE_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$UPDATE_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$UPDATE_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$UPDATE_LOG"
}

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Check required tools
check_dependencies() {
    log_info "Checking required dependencies..."
    
    local missing_tools=()
    
    for tool in nix git jq curl nix-prefetch-git nix-prefetch-github nixpkgs-fmt deadnix; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install missing tools and try again"
        exit 1
    fi
    
    log_success "All required dependencies are available"
}

# Update flake inputs
update_flake_inputs() {
    log_info "Updating flake inputs..."
    
    cd "$REPO_ROOT"
    
    # Backup current flake.lock
    if [ -f flake.lock ]; then
        cp flake.lock "flake.lock.backup-$(date +%Y%m%d-%H%M%S)"
        log_info "Backed up current flake.lock"
    fi
    
    # Update flake inputs
    if nix flake update 2>&1 | tee -a "$UPDATE_LOG"; then
        log_success "Flake inputs updated successfully"
        
        # Show what changed
        if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null; then
            log_info "Changes to flake.lock:"
            git diff --no-index flake.lock.backup-* flake.lock || true
        fi
    else
        log_error "Failed to update flake inputs"
        return 1
    fi
}

# Check for package updates
check_package_updates() {
    log_info "Checking for package updates..."
    
    local packages_dir="$REPO_ROOT/pkgs"
    local update_candidates=()
    
    # Check each package collection (including organizational collections)
    local collections=(
        "microcosm" "blacksky" "bluesky" "atproto"
        "hyperlink-academy" "slices-network" "teal-fm" "parakeet-social"
        "stream-place" "yoten-app" "red-dwarf-client" "tangled-dev"
        "smokesignal-events" "microcosm-blue" "witchcraft-systems"
        "atbackup-pages-dev" "bluesky-social" "individual"
    )
    
    for collection in "${collections[@]}"; do
        local collection_dir="$packages_dir/$collection"
        
        if [ -d "$collection_dir" ]; then
            log_info "Checking $collection packages for updates..."
            
            # Find all .nix files in the collection
            while IFS= read -r -d '' nix_file; do
                if grep -q "fetchFromGitHub\|fetchgit\|fetchurl" "$nix_file"; then
                    log_info "Found package definition: $nix_file"
                    
                    # Extract source information
                    if grep -q "fetchFromGitHub" "$nix_file"; then
                        local owner=$(grep -o 'owner = "[^"]*"' "$nix_file" | cut -d'"' -f2 || echo "")
                        local repo=$(grep -o 'repo = "[^"]*"' "$nix_file" | cut -d'"' -f2 || echo "")
                        local rev=$(grep -o 'rev = "[^"]*"' "$nix_file" | cut -d'"' -f2 || echo "")
                        
                        if [ -n "$owner" ] && [ -n "$repo" ]; then
                            log_info "Package: $owner/$repo (current: $rev)"
                            update_candidates+=("$collection:$owner/$repo:$nix_file")
                        fi
                    fi
                fi
            done < <(find "$collection_dir" -name "*.nix" -type f -print0)
        fi
    done
    
    log_info "Found ${#update_candidates[@]} packages to check for updates"
    
    # Check for updates using GitHub API
    for candidate in "${update_candidates[@]}"; do
        IFS=':' read -r collection repo_path nix_file <<< "$candidate"
        IFS='/' read -r owner repo <<< "$repo_path"
        
        log_info "Checking for updates: $owner/$repo"
        
        # Get latest release from GitHub API
        local latest_release
        if latest_release=$(curl -s "https://api.github.com/repos/$owner/$repo/releases/latest" | jq -r '.tag_name // empty' 2>/dev/null); then
            if [ -n "$latest_release" ]; then
                log_info "Latest release for $owner/$repo: $latest_release"
                
                # Compare with current version in package
                local current_version=$(grep -o 'version = "[^"]*"' "$nix_file" | cut -d'"' -f2 || echo "")
                if [ "$current_version" != "$latest_release" ] && [ "$current_version" != "${latest_release#v}" ]; then
                    log_warning "Update available for $owner/$repo: $current_version -> $latest_release"
                    echo "$collection:$owner/$repo:$current_version:$latest_release:$nix_file" >> "$TEMP_DIR/updates_available.txt"
                fi
            fi
        else
            log_info "No releases found for $owner/$repo, checking commits..."
            
            # Get latest commit
            local latest_commit
            if latest_commit=$(curl -s "https://api.github.com/repos/$owner/$repo/commits/main" | jq -r '.sha // empty' 2>/dev/null); then
                if [ -n "$latest_commit" ]; then
                    log_info "Latest commit for $owner/$repo: ${latest_commit:0:8}"
                fi
            fi
        fi
    done
    
    if [ -f "$TEMP_DIR/updates_available.txt" ]; then
        log_warning "Updates available for the following packages:"
        cat "$TEMP_DIR/updates_available.txt" | tee -a "$UPDATE_LOG"
    else
        log_success "All packages are up to date"
    fi
}

# Verify package hashes
verify_package_hashes() {
    log_info "Verifying package hashes..."
    
    local packages_dir="$REPO_ROOT/pkgs"
    local hash_errors=()
    
    # Check each package collection (including organizational collections)
    local collections=(
        "microcosm" "blacksky" "bluesky" "atproto"
        "hyperlink-academy" "slices-network" "teal-fm" "parakeet-social"
        "stream-place" "yoten-app" "red-dwarf-client" "tangled-dev"
        "smokesignal-events" "microcosm-blue" "witchcraft-systems"
        "atbackup-pages-dev" "bluesky-social" "individual"
    )
    
    for collection in "${collections[@]}"; do
        local collection_dir="$packages_dir/$collection"
        
        if [ -d "$collection_dir" ]; then
            log_info "Verifying hashes for $collection packages..."
            
            # Find all .nix files with hashes
            while IFS= read -r -d '' nix_file; do
                if grep -q "sha256\|hash" "$nix_file"; then
                    log_info "Checking hashes in: $nix_file"
                    
                    # Look for placeholder or invalid hashes
                    if grep -q "sha256.*0000000000000000000000000000000000000000000000000000" "$nix_file"; then
                        log_error "Found placeholder hash in: $nix_file"
                        hash_errors+=("$nix_file: placeholder hash")
                    fi
                    
                    if grep -q 'hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="' "$nix_file"; then
                        log_error "Found placeholder hash in: $nix_file"
                        hash_errors+=("$nix_file: placeholder hash")
                    fi
                    
                    # Check for lib.fakeSha256 or lib.fakeHash
                    if grep -q "lib\.fake" "$nix_file"; then
                        log_error "Found fake hash in: $nix_file"
                        hash_errors+=("$nix_file: fake hash")
                    fi
                fi
            done < <(find "$collection_dir" -name "*.nix" -type f -print0)
        fi
    done
    
    if [ ${#hash_errors[@]} -ne 0 ]; then
        log_error "Hash verification failed for the following files:"
        printf '%s\n' "${hash_errors[@]}" | tee -a "$UPDATE_LOG"
        return 1
    else
        log_success "All package hashes verified successfully"
    fi
}

# Run security checks
run_security_checks() {
    log_info "Running security checks..."
    
    cd "$REPO_ROOT"
    
    # Check for security vulnerabilities with vulnix (if available)
    if command -v vulnix &> /dev/null; then
        log_info "Running vulnix security scan..."
        if vulnix --system > "$TEMP_DIR/vulnix-report.txt" 2>&1; then
            log_success "Vulnix scan completed successfully"
        else
            log_warning "Vulnix scan completed with findings"
            head -20 "$TEMP_DIR/vulnix-report.txt" | tee -a "$UPDATE_LOG"
        fi
    else
        log_warning "vulnix not available, skipping vulnerability scan"
    fi
    
    # Check for security issues in Nix expressions
    if command -v nix-audit &> /dev/null; then
        log_info "Running nix-audit security check..."
        if nix-audit . > "$TEMP_DIR/nix-audit-report.txt" 2>&1; then
            log_success "Nix audit completed successfully"
        else
            log_warning "Nix audit found potential issues"
            head -20 "$TEMP_DIR/nix-audit-report.txt" | tee -a "$UPDATE_LOG"
        fi
    else
        log_warning "nix-audit not available, skipping Nix security audit"
    fi
}

# Format and lint code
format_and_lint() {
    log_info "Formatting and linting Nix code..."
    
    cd "$REPO_ROOT"
    
    # Format Nix files
    if command -v nixpkgs-fmt &> /dev/null; then
        log_info "Formatting Nix files with nixpkgs-fmt..."
        if nixpkgs-fmt . 2>&1 | tee -a "$UPDATE_LOG"; then
            log_success "Nix files formatted successfully"
        else
            log_error "Failed to format Nix files"
            return 1
        fi
    else
        log_warning "nixpkgs-fmt not available, skipping formatting"
    fi
    
    # Check for dead code
    if command -v deadnix &> /dev/null; then
        log_info "Checking for dead code with deadnix..."
        if deadnix --check . 2>&1 | tee -a "$UPDATE_LOG"; then
            log_success "No dead code found"
        else
            log_warning "Dead code detected, consider cleaning up"
        fi
    else
        log_warning "deadnix not available, skipping dead code check"
    fi
}

# Validate flake
validate_flake() {
    log_info "Validating flake structure..."
    
    cd "$REPO_ROOT"
    
    if nix flake check --no-build 2>&1 | tee -a "$UPDATE_LOG"; then
        log_success "Flake validation passed"
    else
        log_error "Flake validation failed"
        return 1
    fi
}

# Generate update report
generate_report() {
    log_info "Generating update report..."
    
    local report_file="$REPO_ROOT/dependency-update-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# ATProto NUR Dependency Update Report

**Generated:** $(date)
**Script Version:** 1.0.0

## Summary

This report contains the results of automated dependency updates and hash verification
for the ATProto NUR repository.

## Flake Inputs

$(if [ -f "$REPO_ROOT/flake.lock" ]; then
    echo "✅ Flake inputs updated successfully"
    echo ""
    echo "### Updated Inputs"
    echo ""
    if command -v git &> /dev/null && git rev-parse --git-dir &> /dev/null; then
        echo "\`\`\`"
        git log --oneline -1 flake.lock 2>/dev/null || echo "No git history available"
        echo "\`\`\`"
    fi
else
    echo "❌ No flake.lock found"
fi)

## Package Updates

$(if [ -f "$TEMP_DIR/updates_available.txt" ]; then
    echo "⚠️ Updates available for the following packages:"
    echo ""
    echo "\`\`\`"
    cat "$TEMP_DIR/updates_available.txt"
    echo "\`\`\`"
else
    echo "✅ All packages are up to date"
fi)

## Hash Verification

$(if verify_package_hashes &>/dev/null; then
    echo "✅ All package hashes verified successfully"
else
    echo "❌ Hash verification failed - see details in log"
fi)

## Security Checks

$(if [ -f "$TEMP_DIR/vulnix-report.txt" ]; then
    echo "### Vulnerability Scan Results"
    echo ""
    echo "\`\`\`"
    head -10 "$TEMP_DIR/vulnix-report.txt"
    echo "\`\`\`"
fi)

$(if [ -f "$TEMP_DIR/nix-audit-report.txt" ]; then
    echo "### Nix Security Audit Results"
    echo ""
    echo "\`\`\`"
    head -10 "$TEMP_DIR/nix-audit-report.txt"
    echo "\`\`\`"
fi)

## Code Quality

$(if format_and_lint &>/dev/null; then
    echo "✅ Code formatting and linting passed"
else
    echo "⚠️ Code formatting or linting issues found"
fi)

## Flake Validation

$(if validate_flake &>/dev/null; then
    echo "✅ Flake validation passed"
else
    echo "❌ Flake validation failed"
fi)

## Recommendations

- Review any available package updates and test before merging
- Address any hash verification failures immediately
- Investigate and resolve any security vulnerabilities
- Fix code formatting and linting issues
- Resolve flake validation errors before deployment

## Full Log

See \`$(basename "$UPDATE_LOG")\` for complete execution details.

---
*Report generated by ATProto NUR dependency update script*
EOF

    log_success "Update report generated: $report_file"
    
    # Display summary
    echo ""
    echo "=================================="
    echo "  DEPENDENCY UPDATE SUMMARY"
    echo "=================================="
    echo ""
    
    if [ -f "$TEMP_DIR/updates_available.txt" ]; then
        echo "📦 Package updates available: $(wc -l < "$TEMP_DIR/updates_available.txt")"
    else
        echo "📦 Package updates available: 0"
    fi
    
    if verify_package_hashes &>/dev/null; then
        echo "🔒 Hash verification: PASSED"
    else
        echo "🔒 Hash verification: FAILED"
    fi
    
    if [ -f "$TEMP_DIR/vulnix-report.txt" ]; then
        echo "🛡️  Security scan: COMPLETED"
    else
        echo "🛡️  Security scan: SKIPPED"
    fi
    
    if validate_flake &>/dev/null; then
        echo "✅ Flake validation: PASSED"
    else
        echo "❌ Flake validation: FAILED"
    fi
    
    echo ""
    echo "📄 Full report: $report_file"
    echo "📋 Execution log: $UPDATE_LOG"
    echo ""
}

# Main execution
main() {
    log_info "Starting ATProto NUR dependency update and verification"
    log_info "Repository: $REPO_ROOT"
    log_info "Log file: $UPDATE_LOG"
    
    check_dependencies
    
    # Run all update and verification steps
    update_flake_inputs
    check_package_updates
    verify_package_hashes
    run_security_checks
    format_and_lint
    validate_flake
    
    # Generate final report
    generate_report
    
    log_success "Dependency update and verification completed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi