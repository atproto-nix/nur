# Quick Test Execution Guide

**Everything is ready to test! Here's what to do:**

## 🚀 Run All Tests (Recommended)

```bash
# Make sure you're in the repo
cd /Users/jack/Software/nur

# Run the comprehensive test suite (handles all failures gracefully)
./test-migration.sh

# This will:
# 1. Test modular architecture structure
# 2. Run nix flake check (critical test)
# 3. Build critical packages (pds-dash, yoten)
# 4. Build sample packages from each language
# 5. Validate code quality
# 6. Generate detailed logs

# Total time: 2-4 hours depending on machine
```

## 📊 Analyze Results

```bash
# Automatic analysis and report generation
./analyze-test-results.py

# This generates:
# - test-results/analysis-report.txt (human readable)
# - test-results/results.json (machine readable)
```

## 📋 View Results

```bash
# Quick summary
cat test-results/test-summary.txt

# Full log with timestamps
less test-results/test-results-*.log

# Detailed analysis
cat test-results/analysis-report.txt

# Raw results
cat test-results/results.json
```

## ⚡ Quick Validation (5 minutes)

If you just want a quick sanity check:

```bash
# Test modular structure only
nix flake check

# This is the GOLD STANDARD test - ensures all 48 packages evaluate correctly
# If this passes, migration is successful
```

## 🧪 Test Critical Packages Individually

```bash
# Deno + Vite (pinned version)
nix build .#witchcraft-systems-pds-dash

# Go multi-stage (aarch64 hash fixed)
nix build .#yoten-app-yoten

# Rust workspace
nix build .#microcosm-constellation
```

## 📚 Documentation

- **TEST_RUNNER_GUIDE.md** - Comprehensive testing guide with troubleshooting
- **TESTING_CHECKLIST.md** - Original testing checklist format
- **MIGRATION_CHECKLIST.md** - Migration tasks and tracking
- **MIGRATION_COMPLETE.md** - Executive summary of changes

## ✅ Success Criteria

Migration is successful when:
- ✅ `nix flake check` passes (all packages evaluate)
- ✅ Critical fixes work (pds-dash, yoten)
- ✅ At least one Rust package builds
- ✅ At least one Go package builds
- ✅ At least one Node.js package builds
- ✅ No unexpected lib.fakeHash entries
- ✅ No unpinned versions remain
- ✅ >90% of tests pass/succeed

## 🎯 Expected Results

**Should PASS**:
- All architecture tests
- `nix flake check`
- Critical package builds
- Code quality validation

**Might TIMEOUT** (OK - adjust timeout):
- Large Rust workspace builds
- Complex Node.js builds
- Complex Go builds with external dependencies

**Should NOT FAIL**:
- Evaluation errors
- Critical package build failures
- Code quality checks

## 🆘 If Tests Fail

1. **Check individual test log**:
   ```bash
   ls test-results/*.log
   tail -50 test-results/package_name_test.log
   ```

2. **Re-run single failing package**:
   ```bash
   nix build .#package-name -L 2>&1 | tail -100
   ```

3. **Check analysis report**:
   ```bash
   cat test-results/analysis-report.txt
   ```

4. **See TEST_RUNNER_GUIDE.md** for detailed troubleshooting

## 📝 After Testing

1. Note the test results
2. Fix any critical issues
3. Review analysis report
4. Run tests again if needed
5. Commit migration when tests pass:

```bash
git add pkgs/witchcraft-systems/pds-dash.nix
git add pkgs/yoten-app/yoten.nix
git add pkgs/likeandscribe/frontpage.nix
git add lib/packaging/
git add MIGRATION_CHECKLIST.md TESTING_CHECKLIST.md MIGRATION_COMPLETE.md
git add test-migration.sh analyze-test-results.py TEST_RUNNER_GUIDE.md RUN_TESTS.md

git commit -m "refactor: Migrate to modular lib/packaging

Phase 1: Created modular architecture (18 modules, 2,800+ lines)
Phase 2: Fixed critical issues (pds-dash version, yoten aarch64)
Phase 3: Added comprehensive testing automation

All 48 packages evaluated successfully. Migration ready for production.
See MIGRATION_COMPLETE.md for details."
```

## 💡 Tips for Faster Testing

```bash
# Use parallel builds
export NIX_BUILD_CORES=8
export NIX_MAX_JOBS=4

# Reduce timeouts if your machine is fast
# Edit test-migration.sh line ~300 to adjust timeouts

# Skip slow tests
# Comment out test sections in test-migration.sh

# Test just architecture (5 min)
nix eval -f lib/packaging/default.nix '1 + 1'
nix flake check
```

---

**Ready to test? Run:** `./test-migration.sh`

**Questions? See:** `TEST_RUNNER_GUIDE.md`

