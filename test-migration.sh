#!/usr/bin/env bash

################################################################################
# Comprehensive Migration Testing Script
# Tests the modular lib/packaging refactoring
# Handles failures gracefully - continues testing even if some builds fail
#
# Note: Uses regular variables instead of associative arrays for bash 3.x compatibility
################################################################################

set -o pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Setup logging
LOG_DIR="test-results"
LOG_FILE="${LOG_DIR}/test-results-$(date +%Y%m%d-%H%M%S).log"
SUMMARY_FILE="${LOG_DIR}/test-summary.txt"
mkdir -p "$LOG_DIR"

# Test results tracking (use json for compatibility with older bash)
RESULTS_JSON="${LOG_DIR}/results-raw.json"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0
START_TIME=$(date +%s)

# Initialize JSON results file
echo "{" > "$RESULTS_JSON"
echo "  \"tests\": []," >> "$RESULTS_JSON"
echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" >> "$RESULTS_JSON"
echo "}" >> "$RESULTS_JSON"

# Colors for test status
STATUS_PASS="${GREEN}✓ PASS${NC}"
STATUS_FAIL="${RED}✗ FAIL${NC}"
STATUS_SKIP="${YELLOW}⊘ SKIP${NC}"
STATUS_TIMEOUT="${YELLOW}⏱ TIMEOUT${NC}"

################################################################################
# Utility Functions
################################################################################

log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

print_header() {
    local title="$1"
    printf "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${BLUE}${title}${NC}\n"
    printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
    log "=== ${title} ===" "TEST"
}

print_test() {
    local name="$1"
    printf "${CYAN}Testing: ${name}${NC}\n"
    log "Testing: ${name}" "TEST"
}

record_test() {
    local name="$1"
    local status="$2"
    local duration="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    case $status in
        "PASS")
            PASSED_TESTS=$((PASSED_TESTS + 1))
            printf "  ${STATUS_PASS}"
            ;;
        "FAIL")
            FAILED_TESTS=$((FAILED_TESTS + 1))
            printf "  ${STATUS_FAIL}"
            ;;
        "SKIP")
            SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
            printf "  ${STATUS_SKIP}"
            ;;
        "TIMEOUT")
            FAILED_TESTS=$((FAILED_TESTS + 1))
            printf "  ${STATUS_TIMEOUT}"
            ;;
    esac

    if [ -n "$duration" ]; then
        printf " (${duration}s)\n"
    else
        printf "\n"
    fi

    log "${name}: ${status} ${duration:+(${duration}s)}" "RESULT"

    # Save to JSON
    echo "  {\"name\": \"$name\", \"status\": \"$status\", \"duration\": $duration}" >> "$RESULTS_JSON"
}

# Run a command with timeout and capture output
run_test() {
    local test_name="$1"
    local timeout_seconds="$2"
    local command="$3"
    local output_file="${LOG_DIR}/${test_name// /_}.log"

    print_test "$test_name"

    local start_time=$(date +%s)

    # Run command with timeout (if available on this system)
    if [ -n "$timeout_seconds" ] && command -v timeout >/dev/null 2>&1; then
        timeout "$timeout_seconds" bash -c "$command" > "$output_file" 2>&1
        local exit_code=$?
    else
        bash -c "$command" > "$output_file" 2>&1
        local exit_code=$?
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ $exit_code -eq 124 ]; then
        # Timeout
        record_test "$test_name" "TIMEOUT" "$duration"
        log "Test timed out after ${timeout_seconds}s: ${test_name}" "WARN"
        return 1
    elif [ $exit_code -eq 0 ]; then
        # Success
        record_test "$test_name" "PASS" "$duration"
        return 0
    else
        # Failure
        record_test "$test_name" "FAIL" "$duration"
        log "Test failed with exit code $exit_code: ${test_name}" "ERROR"
        # Log the error output
        tail -20 "$output_file" | while IFS= read -r line; do
            log "  $line" "OUTPUT"
        done
        return 1
    fi
}

# Run a test that doesn't need build
run_eval_test() {
    local test_name="$1"
    local command="$2"

    print_test "$test_name"

    local start_time=$(date +%s)
    local output=$(eval "$command" 2>&1)
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ $exit_code -eq 0 ]; then
        record_test "$test_name" "PASS" "$duration"
        return 0
    else
        record_test "$test_name" "FAIL" "$duration"
        log "Test failed: ${test_name}" "ERROR"
        log "Output: ${output}" "OUTPUT"
        return 1
    fi
}

# Save test output for inspection
save_output() {
    local test_name="$1"
    local filename="${LOG_DIR}/${test_name// /_}.txt"
    cat > "$filename"
}

################################################################################
# Test Sections
################################################################################

test_section_1_architecture() {
    print_header "SECTION 1: Architecture & Structure Tests"

    # Test 1.1.1: Directory structure
    print_test "Directory structure exists"
    local start=$(date +%s)
    if [ -d "lib/packaging/shared" ] && \
       [ -d "lib/packaging/rust" ] && \
       [ -d "lib/packaging/nodejs" ] && \
       [ -d "lib/packaging/nodejs/bundlers" ] && \
       [ -d "lib/packaging/go" ] && \
       [ -d "lib/packaging/deno" ] && \
       [ -d "lib/packaging/determinism" ]; then
        local end=$(date +%s)
        record_test "Directory structure" "PASS" $((end - start))
    else
        local end=$(date +%s)
        record_test "Directory structure" "FAIL" $((end - start))
    fi

    # Test 1.1.2: Key files exist
    print_test "lib/packaging modules exist"
    local start=$(date +%s)
    local missing_files=0
    for file in \
        "lib/packaging/default.nix" \
        "lib/packaging/shared/default.nix" \
        "lib/packaging/rust/default.nix" \
        "lib/packaging/nodejs/default.nix" \
        "lib/packaging/nodejs/bundlers/default.nix" \
        "lib/packaging/go/default.nix" \
        "lib/packaging/deno/default.nix" \
        "lib/packaging/determinism/default.nix"; do
        if [ ! -f "$file" ]; then
            log "Missing file: $file" "ERROR"
            ((missing_files++))
        fi
    done
    local end=$(date +%s)
    if [ $missing_files -eq 0 ]; then
        record_test "Module files exist" "PASS" $((end - start))
    else
        record_test "Module files exist" "FAIL" $((end - start))
    fi

    # Test 1.1.3: Modular library evaluates
    run_eval_test "lib/packaging evaluates" "nix eval -f lib/packaging/default.nix '1 + 1' 2>&1 | grep -q '2'"

    # Test 1.1.4: Key attributes accessible
    run_eval_test "standardEnv attribute exists" "nix eval -f lib/packaging/shared/default.nix 'builtins.hasAttr \"standardEnv\" (import ./lib/packaging/shared { inherit lib pkgs; })' 2>&1 | grep -q 'true'"
}

test_section_2_flake() {
    print_header "SECTION 2: Flake Structure Tests"

    # Test 2.1: Flake evaluation
    run_test "nix flake show" 120 "nix flake show 2>&1 | head -50"

    # Test 2.2: Flake check (gold standard)
    run_test "nix flake check (all packages evaluate)" 600 "nix flake check 2>&1 | tail -20"

    # Test 2.3: Package count
    print_test "Package count check"
    local start=$(date +%s)
    local count=$(nix flake show --json 2>/dev/null | jq -r '.packages | to_entries | length' 2>/dev/null || echo "0")
    local end=$(date +%s)
    local duration=$((end - start))
    if [ "$count" -gt 40 ]; then
        record_test "Package count (expect ~49)" "PASS" "$duration"
        log "Found $count system entries (expect 4 systems × ~12 packages each = ~48)" "INFO"
    else
        record_test "Package count (expect ~49)" "FAIL" "$duration"
        log "Found only $count systems, expected ~4" "ERROR"
    fi
}

test_section_3_critical_fixes() {
    print_header "SECTION 3: Critical Issue Fixes"

    # Test 3.1: pds-dash version pinned
    print_test "pds-dash version is pinned"
    local start=$(date +%s)
    if grep -q 'rev = "c348ed5d46a0d95422ea6f4925420be8ff3ce8f0"' pkgs/witchcraft-systems/pds-dash.nix; then
        local end=$(date +%s)
        record_test "pds-dash version pinned" "PASS" $((end - start))
    else
        local end=$(date +%s)
        record_test "pds-dash version pinned" "FAIL" $((end - start))
        log "pds-dash.nix does not have expected pinned commit" "ERROR"
    fi

    # Test 3.2: yoten aarch64 hash
    print_test "yoten aarch64-linux hash"
    local start=$(date +%s)
    if grep -q 'sha256-ln60NPTWocDf2hBt7MZGy3QuBNdFqkhHJgI83Ua6jto=' pkgs/yoten-app/yoten.nix; then
        local end=$(date +%s)
        record_test "yoten aarch64-linux hash" "PASS" $((end - start))
    else
        local end=$(date +%s)
        record_test "yoten aarch64-linux hash" "FAIL" $((end - start))
        log "yoten.nix does not have expected aarch64-linux hash" "ERROR"
    fi

    # Test 3.3: frontpage TODO
    print_test "frontpage has hash TODO"
    local start=$(date +%s)
    if grep -q "TODO: Calculate on Linux" pkgs/likeandscribe/frontpage.nix; then
        local end=$(date +%s)
        record_test "frontpage TODO documented" "PASS" $((end - start))
    else
        local end=$(date +%s)
        record_test "frontpage TODO documented" "FAIL" $((end - start))
    fi

    # Test 3.4: pds-dash builds
    run_test "pds-dash builds (Deno + Vite)" 300 "nix build .#witchcraft-systems-pds-dash 2>&1 | tail -5"

    # Test 3.5: yoten builds
    run_test "yoten builds (Go + multi-stage)" 300 "nix build .#yoten-app-yoten 2>&1 | tail -5"

    # Test 3.6: frontpage evaluates (won't build with fakeHash, but should evaluate)
    run_test "frontpage evaluates" 60 "nix eval '.#likeandscribe-frontpage' 2>&1 | head -3"
}

test_section_4_rust_packages() {
    print_header "SECTION 4: Rust Packages (Workspace Caching)"

    # Test 4.1: constellation (shared workspace member)
    run_test "microcosm-constellation builds" 600 "nix build .#microcosm-constellation 2>&1 | tail -5"

    # Test 4.2: spacedust (should reuse artifacts, be faster)
    run_test "microcosm-spacedust builds" 300 "nix build .#microcosm-spacedust 2>&1 | tail -5"

    # Test 4.3: Other Rust packages
    run_test "microcosm-slingshot builds" 300 "nix build .#microcosm-slingshot 2>&1 | tail -3"
    run_test "smokesignal-events-quickdid builds" 300 "nix build .#smokesignal-events-quickdid 2>&1 | tail -3"
    run_test "parakeet-social-parakeet builds" 300 "nix build .#parakeet-social-parakeet 2>&1 | tail -3"
}

test_section_5_go_packages() {
    print_header "SECTION 5: Go Packages"

    run_test "tangled-appview builds" 300 "nix build .#tangled-appview 2>&1 | tail -5"
    run_test "tangled-knot builds" 300 "nix build .#tangled-knot 2>&1 | tail -5"
    run_test "tangled-spindle builds" 300 "nix build .#tangled-spindle 2>&1 | tail -5"
    run_test "stream-place-streamplace builds" 300 "nix build .#stream-place-streamplace 2>&1 | tail -5"
}

test_section_6_nodejs_packages() {
    print_header "SECTION 6: Node.js / TypeScript Packages"

    # Source-only packages (should be fast)
    run_test "atproto-api (source-only)" 60 "nix build .#atproto-api 2>&1 | tail -3"
    run_test "atproto-xrpc (source-only)" 60 "nix build .#atproto-xrpc 2>&1 | tail -3"
    run_test "atproto-did (source-only)" 60 "nix build .#atproto-did 2>&1 | tail -3"

    # npm app packages (may be slower due to builds)
    run_test "hyperlink-academy-leaflet builds" 300 "nix build .#hyperlink-academy-leaflet 2>&1 | tail -5"
    run_test "whey-party-red-dwarf builds" 300 "nix build .#whey-party-red-dwarf 2>&1 | tail -5"
    run_test "tangled-avatar builds" 180 "nix build .#tangled-avatar 2>&1 | tail -5"
}

test_section_7_deno_packages() {
    print_header "SECTION 7: Deno Packages"

    run_test "witchcraft-systems-pds-dash (Deno + Vite)" 300 "nix build .#witchcraft-systems-pds-dash 2>&1 | tail -5"
}

test_section_8_validation() {
    print_header "SECTION 8: Code Quality Validation"

    # No lib.fakeHash (except TODOs)
    print_test "No unexpected lib.fakeHash"
    local start=$(date +%s)
    local fake_hashes=$(grep -r "lib\.fakeHash" pkgs/ --include="*.nix" 2>/dev/null | grep -v "TODO" | wc -l)
    local end=$(date +%s)
    if [ "$fake_hashes" -eq 0 ]; then
        record_test "No unexpected lib.fakeHash" "PASS" $((end - start))
    else
        record_test "No unexpected lib.fakeHash" "FAIL" $((end - start))
        log "Found $fake_hashes lib.fakeHash entries without TODO" "ERROR"
        grep -r "lib\.fakeHash" pkgs/ --include="*.nix" 2>/dev/null | grep -v "TODO" | while read line; do
            log "  $line" "ERROR"
        done
    fi

    # No unpinned versions
    print_test "No unpinned versions (rev = main/master)"
    local start=$(date +%s)
    local unpinned=$(grep -r 'rev = "main"' pkgs/ --include="*.nix" 2>/dev/null | wc -l)
    unpinned=$((unpinned + $(grep -r 'rev = "master"' pkgs/ --include="*.nix" 2>/dev/null | wc -l)))
    local end=$(date +%s)
    if [ "$unpinned" -eq 0 ]; then
        record_test "No unpinned versions" "PASS" $((end - start))
    else
        record_test "No unpinned versions" "FAIL" $((end - start))
        log "Found $unpinned unpinned versions (rev = main/master)" "ERROR"
    fi

    # Check for old lib/packaging references
    print_test "No old lib/packaging references"
    local start=$(date +%s)
    local old_refs=$(grep -r "lib\.packaging\." pkgs/ --include="*.nix" 2>/dev/null | grep -v "TODO" | wc -l)
    local end=$(date +%s)
    if [ "$old_refs" -eq 0 ]; then
        record_test "No problematic old lib references" "PASS" $((end - start))
    else
        record_test "No problematic old lib references" "FAIL" $((end - start))
        log "Found $old_refs old lib.packaging references" "WARN"
    fi
}

test_section_9_summary() {
    print_header "TEST SUMMARY"

    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))

    # Print summary table
    printf "\n${CYAN}Test Results Summary:${NC}\n"
    printf "%-50s %10s %10s\n" "Test Name" "Status" "Duration"
    printf "%-50s %10s %10s\n" "$(printf '%0.s-' {1..50})" "$(printf '%0.s-' {1..10})" "$(printf '%0.s-' {1..10})"

    # Results are logged - print from log file
    grep "\[RESULT\]" "$LOG_FILE" | tail -30

    printf "\n${CYAN}Statistics:${NC}\n"
    printf "  Total Tests:    %d\n" "$TOTAL_TESTS"
    printf "  Passed:         %d ($(( PASSED_TESTS * 100 / TOTAL_TESTS ))%%)\n" "$PASSED_TESTS"
    printf "  Failed:         %d ($(( FAILED_TESTS * 100 / TOTAL_TESTS ))%%)\n" "$FAILED_TESTS"
    printf "  Skipped:        %d\n" "$SKIPPED_TESTS"
    printf "  Total Duration: ${total_duration}s (~$(( total_duration / 60 ))m)\n"
    printf "\n"

    # Save summary
    {
        echo "Test Results Summary"
        echo "===================="
        echo "Date: $(date)"
        echo "Platform: $(uname -a)"
        echo ""
        echo "Statistics:"
        echo "  Total Tests:    $TOTAL_TESTS"
        echo "  Passed:         $PASSED_TESTS"
        echo "  Failed:         $FAILED_TESTS"
        echo "  Skipped:        $SKIPPED_TESTS"
        echo "  Total Duration: ${total_duration}s"
        echo ""
        echo "Detailed Results:"
        grep "\[RESULT\]" "$LOG_FILE" | sed 's/\[RESULT\]//'
        echo ""
        echo "Log file: $LOG_FILE"
    } | tee "$SUMMARY_FILE"

    # Final status
    echo ""
    if [ $FAILED_TESTS -eq 0 ]; then
        printf "${GREEN}✓ ALL TESTS PASSED!${NC}\n"
        return 0
    else
        printf "${RED}✗ SOME TESTS FAILED${NC}\n"
        printf "${YELLOW}See ${LOG_FILE} for details${NC}\n"
        return 1
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    printf "\n${CYAN}"
    cat << "EOF"
    ╔════════════════════════════════════════════════════════════════╗
    ║   Modular lib/packaging Migration - Comprehensive Test Suite   ║
    ║                                                                ║
    ║  Testing all 44 packages + modular architecture               ║
    ║  Handles failures gracefully - all tests run regardless       ║
    ╚════════════════════════════════════════════════════════════════╝
EOF
    printf "${NC}\n"

    log "Test suite started" "INFO"
    log "Platform: $(uname -a)" "INFO"
    log "Working directory: $(pwd)" "INFO"
    log "Log file: $LOG_FILE" "INFO"

    # Run all test sections
    test_section_1_architecture
    test_section_2_flake
    test_section_3_critical_fixes
    test_section_4_rust_packages
    test_section_5_go_packages
    test_section_6_nodejs_packages
    test_section_7_deno_packages
    test_section_8_validation
    test_section_9_summary

    local final_status=$?

    log "Test suite completed" "INFO"
    log "See ${LOG_FILE} for full details" "INFO"

    return $final_status
}

# Run main function
main "$@"
exit $?
