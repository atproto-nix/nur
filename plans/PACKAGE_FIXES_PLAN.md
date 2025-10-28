# Package Fixes Plan - October 2025

This document outlines the action items identified during the October 2025 package review.

## Overview

**Review Date**: October 28, 2025
**Packages Reviewed**: 45 package files across 18 organizations
**Overall Grade**: A-
**Issues Found**: 3 critical, 2 code quality improvements

## Critical Issues (Priority: High)

### 1. Fix pds-dash Unpinned Version

**File**: `pkgs/witchcraft-systems/pds-dash.nix:7`
**Issue**: Uses `rev = "main"` instead of specific commit
**Impact**: Non-reproducible builds, violates repository policy

**Action Steps**:
```bash
# 1. Fetch latest commit from Gitea
curl -sL https://git.witchcraft.systems/api/v1/repos/scientific-witchery/pds-dash/commits/main | jq -r '.[0].sha'

# 2. Update the nix file with the commit hash
# Replace: rev = "main";
# With: rev = "COMMIT_HASH_HERE";

# 3. Update the sha256 hash
nix build .#witchcraft-systems-pds-dash 2>&1 | grep "got:"
# Update the hash in the file

# 4. Test the build
nix build .#witchcraft-systems-pds-dash -L
```

**Estimated Time**: 15 minutes

---

### 2. Calculate frontpage npmDepsHash

**File**: `pkgs/likeandscribe/frontpage.nix:34`
**Issue**: Uses `lib.fakeHash` for npmDepsHash
**Impact**: Package will not build
**Complexity**: HIGH - This is a complex pnpm monorepo with 6 Node.js + 3 Rust packages

**Current Structure**:
- Node.js packages: frontpage, atproto-browser, unravel, frontpage-atproto-client, frontpage-oauth, frontpage-oauth-preview-client
- Rust packages: drainpipe, drainpipe-cli, drainpipe-store

**Action Steps**:

**Option A: Build All Node Packages Together (Recommended)**
```bash
# 1. Attempt build to get correct hash
nix build .#likeandscribe-frontpage 2>&1 | grep "got:"

# 2. Update line 34 in frontpage.nix with the hash
# Replace: npmDepsHash = lib.fakeHash;
# With: npmDepsHash = "sha256-HASH_HERE";

# 3. Test all Node packages
nix build .#likeandscribe-frontpage -L
nix build .#likeandscribe-atproto-browser -L
nix build .#likeandscribe-unravel -L
```

**Option B: Separate Hash Per Package**
If Option A fails (pnpm workspace complexity), each package may need its own hash:
```bash
# Build each package separately to get individual hashes
# This may require restructuring the frontpage.nix file

# For each package in workspaces:
nix build .#likeandscribe-PACKAGE-NAME 2>&1 | grep "got:"
```

**Option C: Use pnpm2nix**
If the workspace structure is too complex:
```bash
# Consider using pnpm2nix for better pnpm workspace support
# This may require adding pnpm2nix as a flake input
```

**Note**: The Rust packages (drainpipe*) use cargoArtifacts and should build correctly once Node packages are fixed.

**Estimated Time**: 1-2 hours (due to complexity)

---

### 3. Clean Up blacksky/rsky Commented Code

**File**: `pkgs/blacksky/rsky/default.nix:189-222`
**Issue**: Large commented block with unpinned version and TODOs
**Impact**: Code cleanliness, potential confusion

**Action Steps**:

**Option A: Remove Completely** (Recommended)
```bash
# If the community package is not needed, remove lines 189-222
# This includes the commented-out buildYarnPackage definition
```

**Option B: Document Intent**
```bash
# If the package is planned for future implementation:
# 1. Remove the commented code
# 2. Create an issue documenting the community package plans
# 3. Add a comment referencing the issue:
#
# NOTE: community package (blacksky.community) not yet implemented.
# See issue #XXX for tracking.
```

**Estimated Time**: 10 minutes

---

## Code Quality Improvements (Priority: Medium)

### 4. Fix yoten aarch64-linux Hash Placeholder

**File**: `pkgs/yoten-app/yoten.nix:37`
**Issue**: Hardcoded error message for aarch64-linux
**Current Code**:
```nix
sha256 = "sha256-REPLACE_WITH_CORRECT_HASH_FOR_AARCH64_LINUX";
```

**Options**:

**Option A: Calculate Actual Hash** (Requires aarch64-linux builder)
```bash
# On aarch64-linux system:
nix build .#yoten-app-yoten 2>&1 | grep "got:"
```

**Option B: Use throw for Unsupported Platform**
```nix
else if stdenv.system == "aarch64-linux" then
  throw "aarch64-linux support not yet implemented for tailwindcss-standalone"
else throw "Unsupported system: ${stdenv.system}";
```

**Option C: Use fetchurl with Dynamic Hash**
```nix
# Let fetchurl fail gracefully and report the correct hash
else if stdenv.system == "aarch64-linux" then {
  url = "${base}/tailwindcss-linux-arm64";
  sha256 = ""; # Will fail with correct hash in error
}
```

**Recommendation**: Option B (most honest about platform support)

**Estimated Time**: 15 minutes

---

### 5. Document Build Helper Patterns

**Purpose**: Ensure future contributors understand the excellent patterns already in place

**Action Steps**:
```bash
# 1. Create docs/BUILD_PATTERNS.md documenting:
#    - mkRustAtprotoService usage
#    - Workspace pattern (microcosm example)
#    - Complex multi-stage builds (yoten example)
#    - Deno builds (pds-dash example)
#
# 2. Add examples for each language ecosystem:
#    - Rust (with workspace)
#    - Node.js (with npmDepsHash)
#    - Go (with vendorHash)
#    - Deno (with node_modules FOD)
```

**Estimated Time**: 1 hour

---

## Summary Timeline

**Immediate (Next Session)**:
1. Fix pds-dash unpinned version (15 min)
2. Clean up rsky commented code (10 min)
3. Fix yoten aarch64 placeholder (15 min)

**Short Term (This Week)**:
4. Calculate frontpage npmDepsHash (1-2 hours)

**Medium Term (Optional)**:
5. Document build patterns (1 hour)

**Total Estimated Time**: 2.5-3.5 hours

---

## CI/CD Improvements (Future)

Consider adding automated checks to prevent similar issues:

```bash
# Add to CI workflow:
1. Detect lib.fakeHash in committed files
2. Detect rev = "main" or rev = "master" patterns
3. Detect TODO markers in uncommented code
4. Run nix flake check on all PRs
5. Run nixpkgs-fmt and deadnix checks
```

---

## Testing Checklist

After fixes, verify:
- [ ] `nix flake check` passes
- [ ] All fixed packages build: `nix build .#PACKAGE-NAME -L`
- [ ] No `lib.fakeHash` in repository: `grep -r "fakeHash" pkgs/`
- [ ] No unpinned versions: `grep -r 'rev = "main"' pkgs/`
- [ ] Run `nixpkgs-fmt` on modified files
- [ ] Update CLAUDE.md to remove fixed issues from Known Issues section

---

## Review Results Summary

**Strengths** ✅:
- Excellent organizational structure (18 organizations)
- Comprehensive build helpers (`lib/atproto.nix`)
- Custom fetcher for Tangled.org working correctly
- Rich metadata (ATProto passthru, organizational context)
- Complex builds handled properly (yoten multi-stage example)
- Consistent naming and structure
- ~5,135 lines of well-organized Nix code

**Issues Found** ⚠️:
- 2 unpinned versions (pds-dash, rsky commented)
- 1 missing hash (frontpage npmDepsHash)
- 2 code quality items (yoten placeholder, rsky cleanup)

**Compliance**: 95% with repository guidelines

**Grade**: A-
