# Test Runner Guide
## Comprehensive Testing for lib/packaging Migration

**Date**: October 28, 2025
**Status**: Ready to Run
**Estimated Time**: 2-4 hours (depending on machine and network)

---

## 🚀 Quick Start

### Option 1: Run Everything (Recommended)
```bash
# Run all tests with comprehensive logging
./test-migration.sh

# Analyze results and generate report
./analyze-test-results.py
```

### Option 2: Run Just Architecture Tests (5 minutes)
```bash
# Quick sanity check that structure is valid
./test-migration.sh 2>&1 | grep "SECTION 1:" -A 50 | head -30
```

### Option 3: Run Specific Build Tests
```bash
# Test just critical packages
timeout 600 nix build .#witchcraft-systems-pds-dash
timeout 600 nix build .#yoten-app-yoten
timeout 600 nix build .#microcosm-constellation
```

---

## 📋 What the Test Scripts Do

### `test-migration.sh` - Main Test Suite
A comprehensive bash script that tests:

**Section 1: Architecture & Structure** (5 min)
- Directory structure exists and is organized correctly
- All modular library files present
- Modules evaluate without errors
- Key attributes accessible

**Section 2: Flake Structure** (3-5 min)
- `nix flake show` works
- `nix flake check` passes (GOLD STANDARD - all packages evaluate)
- Package count is reasonable (~48-49)

**Section 3: Critical Issue Fixes** (20-40 min)
- pds-dash: version is pinned (was `main`)
- yoten: aarch64-linux hash is set (was placeholder)
- frontpage: TODO documented for hash calculation
- All 3 packages build/evaluate correctly

**Section 4: Rust Packages** (20-40 min)
- Microcosm workspace shares artifacts correctly
- Multiple Rust packages build successfully
- Workspace caching works (second build faster than first)

**Section 5: Go Packages** (15-30 min)
- Tangled services (appview, knot, spindle) build
- Other Go packages build correctly
- Complex builds (streamplace with ffmpeg) work

**Section 6: Node.js Packages** (10-20 min)
- TypeScript source-only packages build (fast)
- npm packages with builds work
- Complex builds (leaflet, red-dwarf) build correctly

**Section 7: Deno Packages** (10-20 min)
- pds-dash (Deno + Vite) builds
- May warn about nondeterminism (expected)

**Section 8: Code Quality Validation** (2-5 min)
- No unexpected `lib.fakeHash` entries
- No unpinned versions (e.g., `rev = "main"`)
- No problematic old lib references

**Section 9: Summary** (instant)
- Generate comprehensive test report
- Calculate pass/fail statistics
- Show total time spent

**Total: 2-4 hours** depending on:
- Machine speed (build performance varies significantly)
- Network speed (first time downloads are slower)
- Available disk space
- Platform (Linux is typically faster than macOS)

### `analyze-test-results.py` - Analysis & Reporting
Python script that:
- Parses test logs automatically
- Calculates statistics and pass rates
- Groups results by test category (Rust, Go, Node.js, etc.)
- Identifies slowest tests
- Summarizes errors and warnings
- Generates formatted report
- Exports JSON for further analysis

---

## 📊 Understanding Test Results

### Color Coding
- 🟢 **✓ PASS** - Test succeeded
- 🔴 **✗ FAIL** - Test failed (error in log)
- 🟡 **⏱ TIMEOUT** - Test took too long (exceeded timeout limit)
- 🟡 **⊘ SKIP** - Test was skipped (deliberately)

### Exit Codes
- `0` - All tests passed ✅
- `1` - Some tests failed ❌
- Files in `test-results/` directory for inspection

### Log Files
All test output is saved to:
```
test-results/
├── test-results-YYYYMMDD-HHMMSS.log    # Full test log
├── test-summary.txt                     # Summary statistics
├── analysis-report.txt                  # Detailed analysis
├── results.json                         # Machine-readable results
└── Individual_Test_Name.log            # Per-test logs
```

---

## 🧪 Expected Behaviors

### Should PASS
- All architecture tests
- `nix flake check` (the critical test)
- All critical package fixes (pds-dash, yoten)
- Rust packages (should work unchanged)
- Go packages (should work unchanged)
- Node.js source-only packages (fast)
- Code quality checks

### Might TIMEOUT (but that's OK)
- Large Rust workspace first build (constellation can take 10+ minutes)
- Complex Node.js builds with large dependencies
- Complex Go builds with external dependencies (ffmpeg, gstreamer)

### Might FAIL (investigate)
- pds-dash if there are Vite non-determinism issues (documented in JAVASCRIPT_DENO_BUILDS.md)
- frontpage if you're on non-Linux platform (lib.fakeHash requires calculation)
- Build failures with clear error messages (see analysis report)

### Expected Non-Determinism (NOT a failure)
```
⚠️  Warning: Non-deterministic output detected in Vite build
    This is expected and documented in docs/JAVASCRIPT_DENO_BUILDS.md
    Use FOD pattern for deterministic output
```

---

## 🛠️ Configuration & Timeouts

### Adjust Timeouts
Edit `test-migration.sh` to increase timeouts if builds are slow:

```bash
# Line ~550: Change timeout values (in seconds)
run_test "slow-package-name" 600 "nix build..."  # 10 minutes
```

### Skip Tests
Comment out test sections in `test-migration.sh`:

```bash
# Skip Rust tests (already verified)
# test_section_4_rust_packages

# Skip Go tests (already verified)
# test_section_5_go_packages
```

### Run on Specific System
```bash
# Force x86_64-linux
nix build --system x86_64-linux .#package-name

# Force aarch64-darwin
nix build --system aarch64-darwin .#package-name
```

---

## 📝 Interpreting Results

### If All Tests Pass
```
✓ ALL TESTS PASSED!
```
✅ Migration is successful!

**Next steps:**
1. Review test log for any warnings
2. Note build times for future reference
3. Commit changes with confidence
4. Update CLAUDE.md (optional)

---

### If Some Tests Fail

**Pattern 1: Specific Package Fails**
```
✗ package-name builds  (FAIL)
See test-results/package_name_builds.log for details
```
Check the individual log file for error messages.

**Pattern 2: Timeout (Test took too long)**
```
⏱ package-name builds  (TIMEOUT)
```
Either:
- Increase timeout in test script
- Build manually: `timeout 1200 nix build .#package-name`
- Check if sufficient disk/memory available
- Build on different machine/platform

**Pattern 3: nix flake check fails**
```
✗ nix flake check (all packages evaluate)  (FAIL)
```
This is critical - some packages have evaluation errors.
Check the log for which package fails and why.

**Pattern 4: Architecture test fails**
```
✗ lib/packaging evaluates  (FAIL)
```
The modular structure has issues.
Check: Are all files present? Do they have syntax errors?

---

## 🔍 Detailed Investigation

### View Raw Log
```bash
# See all output from a test
cat test-results/test-results-*.log | grep "FAIL" -A 5 -B 5

# Search for specific error
grep "error:" test-results/test-results-*.log

# Follow package-specific log
tail -50 test-results/witchcraft_systems_pds_dash_builds.log
```

### Re-run Failing Package
```bash
# Build a single package with full output
nix build .#package-name -L 2>&1 | tail -100

# With verbose logging
nix build .#package-name --print-build-logs 2>&1 | tail -100

# Check what went wrong
nix build .#package-name 2>&1 | grep -A 20 "error"
```

### Compare with Reference
```bash
# Get expected behavior for a known-good build
nix build .#atproto-api  # Should be very fast (source-only)

# Compare with slow build
nix build .#microcosm-constellation 2>&1 | tail -20
```

---

## ⏱️ Expected Build Times

### Rough Estimates
```
Architecture tests:        ~5 minutes
Flake structure tests:     ~5 minutes
Critical fixes (3 pkgs):   ~40 minutes
Rust packages (3 tested):  ~60-120 minutes (shared cache after first)
Go packages (4 tested):    ~30-60 minutes
Node.js packages (6):      ~20-40 minutes
Deno packages (1):         ~10-20 minutes
Validation checks:         ~2 minutes
───────────────────────────────────
Total:                     ~2-4 hours
```

**Factors affecting speed:**
- **Machine**: MacBook Air << MacBook Pro << Desktop << Server
- **Network**: First build downloads dependencies (slow), subsequent builds cached (fast)
- **Platform**: aarch64 sometimes slower than x86_64 (binary availability)
- **Disk**: SSD fast, HDD slow, full disk very slow
- **Memory**: Low memory causes swapping (very slow)

### Optimize for Speed
```bash
# Pre-warm nix cache (parallel pre-fetching)
nix flake update --override-input nixpkgs github:NixOS/nixpkgs/nixpkgs-unstable

# Increase max-jobs for parallel builds
export NIX_BUILD_CORES=<number of cores>

# Increase max parallel builds
mkdir -p ~/.config/nix
echo "max-jobs = 4" >> ~/.config/nix/nix.conf

# Run tests with parallelism
nix build .#package1 & nix build .#package2 & nix build .#package3 &
```

---

## 🚨 Troubleshooting

### Test Won't Start
```bash
# Check if Nix is working
nix --version
nix flake show  # Should show packages

# Check working directory
pwd  # Should be /Users/jack/Software/nur

# Make script executable
chmod +x test-migration.sh
./test-migration.sh
```

### Tests Hang (No Output)
```bash
# Kill and check status
Ctrl-C

# Check if nix is stuck
ps aux | grep nix

# Kill stuck processes
killall -9 nix-daemon

# Restart and retry
test-migration.sh
```

### Out of Disk Space
```bash
# Check available space
df -h

# Free up space
nix store gc --max-freed 50G

# Then retry tests
test-migration.sh
```

### Out of Memory
```bash
# Reduce parallel jobs
export NIX_BUILD_CORES=1

# Then retry
test-migration.sh
```

### Network Issues
```bash
# Check internet connectivity
ping github.com

# Restart nix daemon
sudo launchctl stop org.nixos.nix-daemon
sudo launchctl start org.nixos.nix-daemon

# Retry tests
test-migration.sh
```

---

## 📊 Analyzing Results

### Generate Report
```bash
# Automatic analysis
./analyze-test-results.py

# Output files
cat test-results/analysis-report.txt
cat test-results/results.json  # For programmatic analysis
```

### Custom Analysis
```bash
# Extract pass rate
grep "RESULT.*PASS" test-results/test-results-*.log | wc -l

# Find slowest tests
grep "RESULT" test-results/test-results-*.log | sort -t'(' -k2 -rn | head -10

# Find all errors
grep "ERROR" test-results/test-results-*.log

# Find all warnings
grep "WARN" test-results/test-results-*.log
```

---

## ✅ Sign-Off Checklist

After tests complete, verify:

- [ ] All architecture tests pass
- [ ] `nix flake check` passes (critical!)
- [ ] Critical fixes work (pds-dash, yoten)
- [ ] At least one Rust package builds
- [ ] At least one Go package builds
- [ ] At least one Node.js package builds
- [ ] No unexpected `lib.fakeHash` entries
- [ ] No unpinned versions remain
- [ ] Code quality validation passes
- [ ] Less than 10% of tests timeout or fail
- [ ] Test report saved and reviewed

---

## 📞 Help & Support

### Script Issues
- Check if bash/python installed: `which bash python3`
- Check permissions: `ls -la test-migration.sh`
- Check syntax: `bash -n test-migration.sh`

### Build Issues
- Review individual test logs in `test-results/`
- Check `docs/JAVASCRIPT_DENO_BUILDS.md` for JS issues
- Check `docs/MODULAR_PACKAGING_PLAN.md` for architecture questions
- Check `CLAUDE.md` for project guidelines

### Performance Issues
- Check `test-results/analysis-report.txt` for slowest tests
- Consider adjusting timeouts for your machine
- Run tests at different times (less system load)
- Consider parallel test runs

---

## 🎯 Success Criteria

✅ **Migration successful when:**
1. All architecture tests pass
2. `nix flake check` completes without errors
3. All critical fixes verified (pds-dash, yoten)
4. No unexpected evaluation failures
5. Pass rate > 90%
6. No blocking errors in log

✅ **Ready to commit when:**
1. All of above criteria met
2. Test results reviewed and understood
3. Any warnings documented
4. Ready to include in pull request

---

**Good luck with testing! The comprehensive automation should make this smooth.** 🚀

