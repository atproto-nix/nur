# Comprehensive Testing Checklist
## Package Migrations & New Modular lib/packaging

**Date**: October 28, 2025
**Status**: Ready for Testing
**Total Packages**: 44 (+ 5 placeholders)

---

## 🎯 Testing Objectives

This checklist covers comprehensive validation of:
1. ✅ **Phase 1 - Modular Architecture**: New lib/packaging structure is complete and working
2. ✅ **Phase 2 - Critical Fixes**: 3 critical issues have been addressed
3. ✅ **Phase 2 - Partial Migration**: Node.js and Deno packages updated where applicable
4. **Phase 3 - Full Evaluation**: All packages should evaluate and build correctly

---

## ⚙️ SETUP (Before Testing)

- [ ] Ensure you're on the `big-refactor` branch
- [ ] Run `git status` - should show modified files from migration
- [ ] Confirm you have access to build on multiple platforms OR document which platform you're testing on

---

## 📋 SECTION 1: Architecture & Structure Tests

### 1.1 - Verify Modular lib/packaging Structure
**Purpose**: Ensure new modular structure is properly organized and evaluates

```bash
# Test: Directory structure created
ls -la lib/packaging/
# Expected: shared/ rust/ nodejs/ go/ deno/ determinism/ default.nix

# Test: All submodules exist
ls -la lib/packaging/shared/
ls -la lib/packaging/rust/
ls -la lib/packaging/nodejs/bundlers/
# Expected: Each has multiple .nix files + default.nix

# Test: Modular library evaluates
nix eval -f lib/packaging/default.nix '1 + 1'
# Expected: Output: 2

# Test: Key modules accessible
nix eval -f lib/packaging/default.nix 'builtins.hasAttr "standardEnv" (import ./lib/packaging { inherit lib pkgs; })'
# Expected: true

# Test: Rust module present
nix eval -f lib/packaging/default.nix 'builtins.hasAttr "rust" (import ./lib/packaging { inherit lib pkgs; craneLib = pkgs.llvmPackages.clang; })'
# Expected: true

# Test: Node.js bundlers present
nix eval -f lib/packaging/default.nix 'builtins.hasAttr "bundlers" (import ./lib/packaging/nodejs { inherit lib pkgs; buildNpmPackage = pkgs.buildNpmPackage; }).nodejs'
# Expected: true
```

**Result**: ✅ PASS / ❌ FAIL
**Notes**: _user to document any issues_

---

### 1.2 - Flake Structure Intact
**Purpose**: Verify flake still evaluates after migration

```bash
# Test: Flake shows all packages
nix flake show 2>&1 | head -30
# Expected: List of packages organized by system

# Test: Flake evaluation succeeds (no syntax errors)
nix flake check
# Expected: All evaluation successful (OK output, no "error:")

# Test: Package count reasonable
nix flake show --json 2>&1 | jq '.packages | keys | length'
# Expected: ~48-49 (should be consistent with before)

# Test: Can build flake outputs
nix eval '.#packages' 2>&1 | head -5
# Expected: No evaluation errors
```

**Result**: ✅ PASS / ❌ FAIL
**Notes**: _user to document if tests fail_

---

## 📦 SECTION 2: Package Build Tests

### 2.1 - Critical Issue Fixes (Should now be fixed)

#### 2.1.1 pds-dash.nix (Deno + Vite)
**What was fixed**: `rev = "main"` → pinned to commit `c348ed5d46a0d95422ea6f4925420be8ff3ce8f0`

```bash
# Test: pds-dash evaluates
nix eval '.#witchcraft-systems-pds-dash' 2>&1 | head -3
# Expected: No "main" in output, shows pinned commit

# Test: pds-dash builds (may take time, Vite build)
timeout 300 nix build .#witchcraft-systems-pds-dash 2>&1 | tail -10
# Expected: "Build succeeded" or similar
# ⏱️ Timeout: 5 minutes (Vite is slow)
# 🚨 If fails: Check if Vite determinism is issue (see JAVASCRIPT_DENO_BUILDS.md)
```

**Result**: ✅ BUILD OK / ⚠️ TIMEOUT / ❌ BUILD FAILED
**Notes**: _document any errors or timeouts_

---

#### 2.1.2 yoten.nix (Go + multi-stage + aarch64-linux)
**What was fixed**: `sha256-REPLACE_WITH_CORRECT_HASH_FOR_AARCH64_LINUX` → `sha256-ln60NPTWocDf2hBt7MZGy3QuBNdFqkhHJgI83Ua6jto=`

```bash
# Test: yoten evaluates
nix eval '.#yoten-app-yoten' 2>&1 | head -3
# Expected: No "REPLACE_WITH" or error messages

# Test: yoten builds on your platform
timeout 300 nix build .#yoten-app-yoten 2>&1 | tail -10
# Expected: "Build succeeded"
# ⏱️ Timeout: 5 minutes
# 📍 Note platform: x86_64-linux / aarch64-linux / x86_64-darwin / aarch64-darwin
# 🚨 If fails: Document which platform fails
```

**Result**: ✅ BUILD OK / ❌ BUILD FAILED
**Platform tested**: _x86_64-linux / aarch64-linux / x86_64-darwin / aarch64-darwin_
**Notes**: _user to document which platform and any errors_

---

#### 2.1.3 frontpage.nix (pnpm monorepo + lib.fakeHash TODO)
**What was done**: Added TODO comment indicating hash needs Linux x86_64 calculation

```bash
# Test: frontpage evaluates
nix eval '.#likeandscribe-frontpage' 2>&1 | head -5
# Expected: Evaluation successful (despite lib.fakeHash)

# Test: Can you see the TODO?
grep -n "TODO: Calculate on Linux" pkgs/likeandscribe/frontpage.nix
# Expected: Line with hash calculation instructions

# Note: frontpage with lib.fakeHash will NOT build
# This is expected - hash needs calculation on Linux x86_64
# If you have Linux x86_64 access, see JAVASCRIPT_DENO_BUILDS.md for instructions
```

**Result**: ✅ EVALUATES / ❌ FAILS
**Notes**: _document if evaluation fails; hash calculation deferred to Linux user_

---

### 2.2 - Rust Packages (Should work unchanged)
**Purpose**: Verify Rust packages still build with workspace caching

#### 2.2.1 Microcosm Workspace (11 packages sharing cargoArtifacts)

```bash
# Test: constellation (representative member)
timeout 600 nix build .#microcosm-constellation 2>&1 | tail -5
# Expected: Build succeeded
# ⏱️ Timeout: 10 minutes (Rust linking is slow)
# This tests the shared cargoArtifacts caching

# Test: Next member should be faster (reuses cargoArtifacts)
timeout 600 nix build .#microcosm-spacedust 2>&1 | tail -5
# Expected: Build succeeded (faster than constellation)

# Test: All 11 Microcosm members present
nix flake show | grep "microcosm-" | wc -l
# Expected: 11
```

**Result**: ✅ BUILDS OK / ⏱️ SLOW / ❌ FAILED
**Time constellation took**: ___ minutes
**Time spacedust took**: ___ minutes (should be less)
**Notes**: _document if any fail_

---

#### 2.2.2 Other Rust Packages

```bash
# Test: allegedly (separate Tangled repo)
timeout 300 nix build .#microcosm-allegedly 2>&1 | tail -3
# Expected: Build succeeded

# Test: quickdid (Smokesignal Events)
timeout 300 nix build .#smokesignal-events-quickdid 2>&1 | tail -3
# Expected: Build succeeded

# Test: parakeet (from GitLab)
timeout 300 nix build .#parakeet-social-parakeet 2>&1 | tail -3
# Expected: Build succeeded
```

**Result**: ✅ ALL BUILD OK / ❌ SOME FAILED
**Failed packages**: _list any_
**Notes**: _document errors if any_

---

### 2.3 - Go Packages (Should work unchanged)

```bash
# Test: tangled appview
timeout 300 nix build .#tangled-appview 2>&1 | tail -3
# Expected: Build succeeded

# Test: tangled knot
timeout 300 nix build .#tangled-knot 2>&1 | tail -3
# Expected: Build succeeded

# Test: streamplace (complex ffmpeg deps)
timeout 300 nix build .#stream-place-streamplace 2>&1 | tail -3
# Expected: Build succeeded (may take longer due to ffmpeg)
```

**Result**: ✅ ALL BUILD OK / ❌ SOME FAILED
**Failed packages**: _list any_
**Notes**: _document any issues_

---

### 2.4 - Node.js / TypeScript Packages

#### 2.4.1 Source-only packages (no build needed)

```bash
# Test: atproto-api (TypeScript source package)
nix build .#atproto-api 2>&1 | tail -3
# Expected: Build succeeded (should be fast, just copying source)

# Test: atproto-xrpc (TypeScript source package)
nix build .#atproto-xrpc 2>&1 | tail -3
# Expected: Build succeeded

# Repeat for remaining: atproto-did, atproto-identity, atproto-repo, atproto-syntax, atproto-lexicon
# These should all be very quick (< 1 minute each)
```

**Result**: ✅ ALL BUILD OK / ❌ SOME FAILED
**Failed packages**: _list any_
**Time taken**: _should be <1 min each_
**Notes**: _if slow, investigate why_

---

#### 2.4.2 npm app packages

```bash
# Test: leaflet (Next.js with complex build)
timeout 300 nix build .#hyperlink-academy-leaflet 2>&1 | tail -5
# Expected: Build succeeded
# ⏱️ Timeout: 5 minutes

# Test: red-dwarf (Vite app)
timeout 300 nix build .#whey-party-red-dwarf 2>&1 | tail -5
# Expected: Build succeeded (or note if Vite is non-deterministic)

# Test: avatar (Wrangler/Cloudflare worker)
timeout 180 nix build .#tangled-avatar 2>&1 | tail -5
# Expected: Build succeeded
```

**Result**: ✅ BUILDS OK / ⚠️ NONDETERMINISTIC / ❌ FAILED
**Notes**: _document any issues or non-determinism warnings_

---

### 2.5 - Deno Package

```bash
# Test: pds-dash (Deno + Vite)
# This should work now with pinned commit
timeout 300 nix build .#witchcraft-systems-pds-dash 2>&1 | tail -10
# Expected: Build succeeded or fails with known Vite non-determinism message
# ⏱️ Timeout: 5 minutes (Vite is slow)
# 📝 Note: May have non-deterministic output (known issue)
```

**Result**: ✅ BUILD OK / ⚠️ VITE NONDETERMINISTIC / ❌ BUILD FAILED
**Notes**: _document status and any warnings_

---

### 2.6 - Placeholder Packages (should evaluate but won't do anything)

```bash
# Test: indigo (Bluesky placeholder)
nix eval '.#bluesky-indigo' 2>&1 | head -3
# Expected: Evaluates to a writeTextFile

# Test: grain (Bluesky placeholder)
nix eval '.#grain-social-grain' 2>&1 | head -3
# Expected: Evaluates  successfully

# Test: teal (Teal.fm placeholder)
nix eval '.#teal-fm-teal' 2>&1 | head -3
# Expected: Evaluates successfully

# Placeholders should not build, just evaluate
```

**Result**: ✅ EVALUATE OK / ❌ EVALUATE FAILED
**Notes**: _document if any fail_

---

## 🔄 SECTION 3: Comprehensive Evaluation

### 3.1 - Full Flake Evaluation

```bash
# Test: nix flake check (evaluates all packages on current system)
timeout 600 nix flake check 2>&1 | tee flake-check-output.txt
# Expected: All checks pass with "OK"
# ⏱️ Timeout: 10 minutes
# This is the gold standard test - all packages must evaluate
```

**Result**: ✅ ALL PASS / ❌ SOME FAILED
**Output saved to**: flake-check-output.txt
**Failed evaluations**: _list any packages that failed_
**Notes**: _critical - document all failures_

---

### 3.2 - Package Count Verification

```bash
# Test: Count all packages listed
nix flake show --json | jq -r '.packages."x86_64-linux" | keys[]' 2>/dev/null | wc -l
# Expected: ~49 packages (44 actual + 5 placeholders)

# Test: List all packages
nix flake show 2>&1 | grep "packages" -A 100 | grep "'" | wc -l
# Expected: ~49

# Test: No old lib/packaging references causing issues
grep -r "lib\.packaging\." pkgs/ 2>/dev/null | head -5
# Expected: No matches (or matches only in comments)

# Test: Check new lib/packaging is accessible
nix eval 'import ./lib/packaging { inherit lib pkgs; }' --apply 'x: "OK"' 2>&1
# Expected: "OK"
```

**Result**: ✅ ALL PASS / ❌ SOME FAILED
**Package count**: _actual number_
**Notes**: _document any discrepancies_

---

## 🧪 SECTION 4: Advanced Testing (Optional)

### 4.1 - Determinism Tests (Only if interested)
**Note**: These are optional and only meaningful if you have access to run builds multiple times on the same system

```bash
# Test: pds-dash determinism (Deno + Vite)
nix build .#witchcraft-systems-pds-dash -o result1 2>&1
sleep 5
nix build .#witchcraft-systems-pds-dash -o result2 2>&1
diff -r result1 result2 > determinism-diff.txt
# Expected: diff is empty (deterministic) OR has expected differences (non-deterministic noted)
```

**Result**: ✅ DETERMINISTIC / ⚠️ NON-DETERMINISTIC (EXPECTED) / ❌ INCONSISTENT ERRORS
**Diff saved to**: determinism-diff.txt
**Notes**: _non-determinism in JS builds is expected and documented_

---

### 4.2 - FOD Hash Validation (Only if interested)

```bash
# Test: Check that no packages have lib.fakeHash (except intentional TODOs)
grep -r "lib\.fakeHash" pkgs/ --include="*.nix" 2>/dev/null | grep -v "TODO"
# Expected: Only likeandscribe/frontpage.nix with TODO comment

# Test: Check all version pins (no "main" or "master")
grep -r 'rev = "main"' pkgs/ --include="*.nix" 2>/dev/null
# Expected: No matches (pds-dash should be fixed)
```

**Result**: ✅ CLEAN / ❌ ISSUES FOUND
**Fakeashes found**: _list any unexpected_
**Unpinned revisions**: _list any unexpected_
**Notes**: _document findings_

---

## 📊 SECTION 5: Summary Report

### Test Results Summary

| Category | Test | Result | Notes |
|----------|------|--------|-------|
| Architecture | Modular lib/packaging structure | ✅/❌ | _user to fill_ |
| Flake | flake check (gold standard) | ✅/❌ | _user to fill_ |
| Critical Fixes | pds-dash (version pinned) | ✅/❌ | _user to fill_ |
| Critical Fixes | yoten (aarch64 hash) | ✅/❌ | _user to fill_ |
| Critical Fixes | frontpage (fakeHash TODO) | ✅/❌ | _user to fill_ |
| Rust | Microcosm workspace | ✅/❌ | _user to fill_ |
| Go | tangled services | ✅/❌ | _user to fill_ |
| Node.js | Source packages | ✅/❌ | _user to fill_ |
| Node.js | npm apps | ✅/❌ | _user to fill_ |
| Deno | pds-dash | ✅/❌ | _user to fill_ |
| Determinism | JS/Deno (optional) | ✅/⚠️/❌ | _user to fill_ |

---

### Issues Found

**Critical Issues** (must fix before release):
1. _list any_

**Non-Critical Issues** (document for future):
1. _list any_

**Notes & Observations**:
- _user to document_

---

### Recommended Next Steps

Based on test results:

1. **If all pass**:
   - ✅ Migration successful!
   - Next: Update CLAUDE.md to reference new lib/packaging
   - Commit migration with test results

2. **If some fail**:
   - 📋 Document failed packages
   - 🔍 Investigate patterns (language-specific? platform-specific?)
   - 🛠️ Fix critical issues first
   - 🔄 Re-test before committing

3. **If frontpage hash needed**:
   - 💻 On Linux x86_64 system: `nix build .#likeandscribe-frontpage 2>&1 | grep "got:"`
   - 📝 Copy hash into frontpage.nix
   - ✅ Re-test

---

## 📝 Notes for User

- **Slow builds expected**: Rust workspaces, Go services, JavaScript bundlers can take time
- **Vite non-determinism expected**: pds-dash may show non-deterministic warning (documented in JAVASCRIPT_DENO_BUILDS.md)
- **frontpage hash**: Calculate on Linux x86_64 when you have time (not blocking other tests)
- **Platform differences**: Some hashes (e.g., yoten tailwindcss) are platform-specific - test on your platform
- **Save outputs**: Copy-paste test output into this checklist for documentation

---

## 🚀 Final Validation

Once all tests pass, migration is complete!

**Commit message template**:
```
refactor: Migrate all packages to modular lib/packaging structure

- Fixed critical issues (pds-dash version, yoten aarch64 hash)
- All 44 packages migrate to new lib/packaging/{shared,rust,nodejs,go,deno,determinism}/
- Verified with nix flake check - all packages evaluate successfully
- FOD (Fixed-Output Derivation) pattern ready for JS/Deno builds
- See MIGRATION_CHECKLIST.md for detailed changes
- See docs/MODULAR_PACKAGING_PLAN.md for architecture overview
```

---

**Testing completed**: _user to date and sign off_
**Tested on platform**: x86_64-linux / aarch64-linux / x86_64-darwin / aarch64-darwin (circle one)
**Overall result**: ✅ PASS / ❌ FAIL / ⚠️ PARTIAL

