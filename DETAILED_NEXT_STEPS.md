# ATProto NUR - Detailed Next Steps Plan

**Created:** 2025-10-23
**Status:** Post-yoten fix, ready for final push to 100% production readiness

---

## Executive Summary

The repository has successfully completed major refactoring (Phases 1-3) and the yoten complex build fix. We're currently at **~92% production ready** with only 3 packages needing hash calculation (down from 6).

**Current State:**
- ✅ 50 total packages (48 original + 2 new from likeandscribe exports)
- ✅ 47 packages fully working with proper hashes
- ⚠️ 3 packages need hash calculation on Linux x86_64
- ✅ All packages pinned to specific commits
- ✅ yoten-app/yoten complex build now working
- ✅ Documentation updated

**What Changed Since Last Plan:**
- ✅ Fixed yoten-app/yoten (was in the "needs fixing" list)
- ✅ Tangled packages (knot, appview, spindle) were already fixed in commit `52ec077`
- ⚠️ Only 3 packages remain: frontpage, pds-dash, atbackup

---

## Immediate Actions (Next 30 Minutes)

### 1. Commit Current Work
**Priority:** 🔴 CRITICAL
**Time:** 5 minutes

```bash
# Stage documentation updates
git add CLAUDE.md PINNING_NEEDED.md README.md

# Stage the fixed yoten package
git add pkgs/yoten-app/yoten.nix

# Check what else changed
git status

# Commit with descriptive message
git commit -m "fix(yoten): Implement complete build with templ + Tailwind CSS v4

- Added templ template generation
- Fetch frontend libraries (htmx, lucide, alpinejs) with fetchurl
- Build Tailwind CSS v4 using standalone binary with autoPatchelfHook
- Create static/files/ directory for Go embed directive
- Fixed all build errors (20MB binary now builds successfully)

Updated documentation:
- CLAUDE.md: Added complex build patterns section
- PINNING_NEEDED.md: Updated package counts and fixed list
- README.md: Added note about yoten fix and complex build reference

Package now fully functional. See pkgs/yoten-app/yoten.nix for reference
implementation of multi-stage builds with frontend tooling."
```

### 2. Update NEXT_STEPS.md
**Priority:** 🔴 CRITICAL
**Time:** 10 minutes

Update the existing NEXT_STEPS.md to reflect:
- Tangled packages are already fixed (commit 52ec077)
- yoten is now fixed
- Only 3 packages need hashes: frontpage, pds-dash, atbackup
- 50 total packages (not 48)

### 3. Clean Up Database Files
**Priority:** 🟡 HIGH
**Time:** 2 minutes

```bash
# These appear to be from yoten test run
rm -f web.db web.db-shm web.db-wal

# Add to .gitignore
echo "*.db" >> .gitignore
echo "*.db-shm" >> .gitignore
echo "*.db-wal" >> .gitignore
```

### 4. Check Repository Health
**Priority:** 🟡 HIGH
**Time:** 5 minutes

```bash
# Verify package count
nix flake show --json 2>/dev/null | jq -r '.packages."x86_64-linux" | keys[]' | wc -l

# List packages that still need hashes
find pkgs -name "*.nix" -type f -exec grep -l "lib.fakeHash" {} \;

# Check flake evaluation
nix flake check --no-build 2>&1 | head -20
```

---

## Short-Term Tasks (This Week)

### Task 1: Calculate Remaining 3 Hashes on Linux
**Priority:** 🔴 CRITICAL (BLOCKS PRODUCTION)
**Time:** 30-45 minutes
**Requires:** Linux x86_64 machine

**Context:** You're already on Linux (based on the build output), so this should be straightforward!

```bash
# 1. likeandscribe-frontpage (needs source + npmDepsHash)
nix build .#likeandscribe-frontpage -L 2>&1 | tee /tmp/frontpage-build.log | grep "got:"
# First error: source hash
# Update pkgs/likeandscribe/frontpage.nix with hash
# Build again to get npmDepsHash error
nix build .#likeandscribe-frontpage -L 2>&1 | grep "got:"
# Update npmDepsHash

# 2. witchcraft-systems-pds-dash (needs source hash only)
nix build .#witchcraft-systems-pds-dash -L 2>&1 | grep "got:"
# Update pkgs/witchcraft-systems/pds-dash.nix

# 3. atbackup-pages-dev-atbackup (needs source hash only)
nix build .#atbackup-pages-dev-atbackup -L 2>&1 | grep "got:"
# Update pkgs/atbackup-pages-dev/atbackup.nix

# Verify all builds succeed
nix build .#likeandscribe-frontpage .#witchcraft-systems-pds-dash .#atbackup-pages-dev-atbackup
```

**Success Criteria:**
- ✅ All 3 packages build without errors
- ✅ No `lib.fakeHash` in any package
- ✅ `nix flake check` passes (may take a while)

### Task 2: Test All Packages Build
**Priority:** 🔴 CRITICAL
**Time:** 1-2 hours (mostly build time)
**Depends on:** Task 1

```bash
# Full repository validation
nix flake check

# Or test by category if that fails
nix build .#microcosm-constellation .#microcosm-slingshot .#microcosm-spacedust
nix build .#blacksky-pds .#blacksky-relay .#blacksky-feedgen
nix build .#yoten-app-yoten .#hyperlink-academy-leaflet .#slices-network-slices
nix build .#likeandscribe-frontpage
nix build .#tangled-knot .#tangled-appview .#tangled-spindle

# Check for any packages that can't be built
nix eval .#packages.x86_64-linux --apply 'pkgs: builtins.attrNames pkgs' --json | \
  jq -r '.[]' | \
  while read pkg; do
    echo "Testing $pkg..."
    nix build ".#$pkg" --dry-run 2>&1 | grep -i "error" || echo "  ✓ $pkg OK"
  done
```

**Success Criteria:**
- ✅ `nix flake check` completes successfully
- ✅ All 50 packages can be built (or at least evaluated)
- ✅ No lib.fakeHash errors

### Task 3: Final Documentation Updates
**Priority:** 🟡 HIGH
**Time:** 30 minutes
**Depends on:** Task 1, 2

Update all documentation to reflect 100% completion:

**PINNING_NEEDED.md:**
```markdown
# ARCHIVE: All Packages Now Have Proper Hashes

**Last Updated:** 2025-10-23
**Status:** ✅ COMPLETE - All 50 packages now have proper hashes

This file is kept for historical reference. All packages originally listed
here have been fixed:

## Fixed Packages

### Tangled Packages (Fixed 2025-10-22)
- ✅ tangled-knot - commit 52ec077
- ✅ tangled-appview - commit 52ec077
- ✅ tangled-spindle - commit 52ec077

### Third-Party Apps (Fixed 2025-10-23)
- ✅ yoten-app/yoten - Fixed complex build (templ + Tailwind CSS v4)
- ✅ hyperlink-academy/leaflet - Fixed Phase 2
- ✅ slices-network/slices - Fixed Phase 2
- ✅ likeandscribe/frontpage - Fixed [DATE]
- ✅ witchcraft-systems/pds-dash - Fixed [DATE]
- ✅ atbackup-pages-dev/atbackup - Fixed [DATE]

All 50 packages in the repository now:
- Use specific commit hashes (no `rev = "main"`)
- Have properly calculated hashes (no `lib.fakeHash`)
- Build successfully on Linux x86_64
- Are ready for production use

See CLAUDE.md for build patterns and best practices.
```

**README.md:**
- Update status from "90% ready" to "100% Production Ready"
- Update package count to 50
- Remove warning about packages needing hashes

**CLAUDE.md:**
- Update repository status section
- Remove "Known Issues" section or mark as resolved
- Add note about 100% hash coverage

### Task 4: Create Final Summary Commit
**Priority:** 🟡 HIGH
**Time:** 10 minutes
**Depends on:** Task 1, 2, 3

```bash
git add pkgs/likeandscribe/frontpage.nix
git add pkgs/witchcraft-systems/pds-dash.nix
git add pkgs/atbackup-pages-dev/atbackup.nix
git add PINNING_NEEDED.md README.md CLAUDE.md

git commit -m "fix: Calculate final 3 package hashes - 100% production ready

Calculated proper hashes for remaining packages:
- likeandscribe-frontpage: source hash + npmDepsHash
- witchcraft-systems-pds-dash: source hash
- atbackup-pages-dev-atbackup: source hash

All 50 packages now:
✅ Pinned to specific commits
✅ Have proper calculated hashes
✅ Build successfully on Linux x86_64
✅ Ready for production deployment

Repository Status: 🟢 100% Production Ready

Tests:
- nix flake check: PASS
- All packages build: PASS
- No lib.fakeHash remaining: PASS

This completes the package hash calculation effort started in Phase 1."
```

---

## Medium-Term Tasks (Next Week)

### Task 5: Push to Remote Repository
**Priority:** 🟡 HIGH
**Time:** 5 minutes
**Depends on:** Task 1-4

```bash
# Check branch and commits
git log --oneline -15

# Push to main (or feat-blsky-bsky-pkgs depending on your workflow)
git push origin main

# Or if working on feature branch
git push origin main:feat-blsky-bsky-pkgs
```

**Note:** Based on git status, `feat-blsky-bsky-pkgs` appears to be the main development branch.

### Task 6: Set Up Binary Cache (Optional)
**Priority:** 🟢 MEDIUM
**Time:** 1-2 hours
**Benefits:** Much faster installation for users

```bash
# 1. Sign up for Cachix (free for open source)
# Visit: https://cachix.org

# 2. Create cache
cachix create atproto-nur

# 3. Get auth token
cachix authtoken <YOUR_TOKEN>

# 4. Build and push all packages
nix build .#microcosm-constellation && cachix push atproto-nur ./result
# ... repeat for key packages, or script it

# 5. Update README with cachix instructions
```

**Automation:** Set up GitHub Actions to push builds to Cachix automatically.

### Task 7: Test NixOS Modules
**Priority:** 🟢 MEDIUM
**Time:** 2-3 hours
**Requires:** NixOS VM or system

Create test configuration:

```nix
# test-vm.nix
{ pkgs, ... }:
{
  imports = [ ./modules/default.nix ];

  # Test various modules
  services.microcosm-constellation = {
    enable = true;
    settings.backend = "memory";
  };

  services.yoten-app.yoten = {
    enable = true;
    port = 8080;
  };

  services.likeandscribe.frontpage = {
    enable = true;
    # ... configuration
  };

  # Test backward compatibility
  services.atproto.frontpage.enable = true;  # Should warn
}
```

Test:
```bash
nixos-rebuild build-vm -I nixos-config=./test-vm.nix
./result/bin/run-*-vm
```

### Task 8: Update CI/CD Workflows
**Priority:** 🟢 MEDIUM
**Time:** 1 hour

Update `.github/workflows/build.yml`:

```yaml
name: Build and Test

on:
  push:
    branches: [ main, feat-blsky-bsky-pkgs ]
  pull_request:

jobs:
  check-no-fake-hashes:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check for lib.fakeHash
        run: |
          if grep -r "lib.fakeHash" pkgs/; then
            echo "Error: Found lib.fakeHash in packages!"
            exit 1
          fi

  build-key-packages:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        package:
          - microcosm-constellation
          - yoten-app-yoten
          - blacksky-pds
          - likeandscribe-frontpage
          - tangled-knot
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v24
      - uses: cachix/cachix-action@v13
        with:
          name: atproto-nur
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
      - name: Build ${{ matrix.package }}
        run: nix build .#${{ matrix.package }}

  flake-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v24
      - name: Check flake
        run: nix flake check --no-build
```

---

## Long-Term Goals (Next Month)

### Goal 1: Community Engagement
**Priority:** 🔵 LOW
**Time:** Ongoing

1. **Announce on ATProto Forums:**
   - Write announcement post
   - Share on Bluesky with #ATProto hashtag
   - Post in relevant Discord servers

2. **Write Blog Post:**
   - "Deploying ATProto Services with NixOS"
   - Include examples and benefits
   - Share on dev.to, Hashnode, etc.

3. **Create Video Walkthrough:**
   - Screen recording of deployment
   - Show NixOS module usage
   - Publish to YouTube

### Goal 2: Upstream Contributions
**Priority:** 🔵 LOW
**Time:** Ongoing

1. **Share with Package Maintainers:**
   - Offer NixOS modules to upstream projects
   - Help improve Nix packaging
   - Contribute back improvements

2. **Submit to nixpkgs:**
   - Consider upstreaming popular packages
   - Follow nixpkgs contribution guidelines
   - Maintain NUR for bleeding-edge versions

### Goal 3: Advanced Automation
**Priority:** 🔵 LOW
**Time:** 1 week

1. **Auto-Update Versions:**
   - Script to check for new releases
   - Automated PR creation
   - Hash calculation in CI

2. **Integration Tests:**
   - Test service interactions
   - Test module dependencies
   - Test cross-platform builds

3. **Documentation Generation:**
   - Auto-generate package list
   - Auto-generate module docs
   - Keep docs in sync with code

---

## Priority-Ordered Action Plan

### Today (Next 2-3 Hours)
1. ✅ Commit yoten fix and docs (5 min)
2. ⚠️ Calculate 3 remaining hashes (30 min)
3. ⚠️ Test all packages build (1 hour)
4. ⚠️ Final documentation updates (20 min)
5. ⚠️ Create 100% ready commit (10 min)
6. ⚠️ Push to remote (5 min)

**End State:** Repository 100% production ready, all packages building

### This Week
7. Test NixOS modules (2 hours)
8. Set up binary cache (2 hours)
9. Update CI/CD workflows (1 hour)
10. Update NEXT_STEPS.md (15 min)

**End State:** Tested, cached, automated

### Next Week
11. Announce to community (2 hours)
12. Write blog post (4 hours)
13. Create video walkthrough (3 hours)

**End State:** Community awareness, adoption

### Next Month
14. Upstream contributions (ongoing)
15. Advanced automation (1 week)
16. Expand test coverage (ongoing)

**End State:** Mature, well-maintained repository

---

## Success Metrics

### Week 1 (This Week)
- ✅ All 50 packages build successfully
- ✅ Zero `lib.fakeHash` in codebase
- ✅ `nix flake check` passes
- ✅ Documentation reflects 100% status
- ✅ Changes pushed to remote

### Week 2 (Next Week)
- ✅ Binary cache operational
- ✅ CI/CD validates all PRs
- ✅ NixOS modules tested
- ✅ Community announcement made

### Month 1
- ✅ 10+ GitHub stars
- ✅ 3+ community contributions
- ✅ Blog post published
- ✅ Video walkthrough created

### Long-Term
- ✅ 100+ users
- ✅ Packages upstreamed to nixpkgs
- ✅ Active community maintenance

---

## Blockers and Dependencies

### Current Blockers
None! You're on Linux x86_64 and can calculate hashes right now.

### Dependencies
- Task 2 depends on Task 1 (need hashes to build)
- Task 3 depends on Task 1, 2 (need completion status)
- Task 4 depends on Task 1, 2, 3 (final commit)
- All other tasks depend on Task 1-4 (production ready)

### External Dependencies
- Cachix account (for Task 6)
- NixOS VM (for Task 7)
- GitHub Actions secrets (for Task 8)

---

## Quick Commands Reference

```bash
# Calculate a single hash
nix build .#PACKAGE -L 2>&1 | grep "got:"

# Test all packages evaluate
nix eval .#packages.x86_64-linux --apply 'pkgs: builtins.length (builtins.attrNames pkgs)'

# Test flake
nix flake check --no-build

# Find remaining fakeHash
find pkgs -name "*.nix" -exec grep -l "lib.fakeHash" {} \;

# Count packages
nix flake show --json 2>/dev/null | jq -r '.packages."x86_64-linux" | length'

# Test a specific package
nix build .#PACKAGE && ./result/bin/BINARY --help
```

---

## Rollback Plan

If something goes wrong:

```bash
# Revert to last known good commit
git log --oneline -10
git reset --hard <COMMIT_SHA>

# Or revert specific commits
git revert <COMMIT_SHA>

# Or create fix commit
# (preferred for public branches)
```

---

## Getting Help

**Hash Calculation Issues:**
- Check build logs: `nix log /nix/store/...-PACKAGE.drv`
- Use MCP-NixOS: "How do I calculate npmDepsHash?"
- NixOS Discourse: https://discourse.nixos.org

**Module Testing Issues:**
- NixOS manual: https://nixos.org/manual/nixos/stable/
- Example modules in nixpkgs
- Ask in #nixos on Matrix

**CI/CD Issues:**
- GitHub Actions docs
- Cachix documentation
- nix-community examples

---

## Status Dashboard

```
Repository: atproto-nix/nur
Branch: main (tracking feat-blsky-bsky-pkgs)
Commits Ahead: 10

Current Status: 🟡 92% Production Ready

Packages:
  ✅ 47 packages fully working
  ⚠️  3 packages need hashes
  📦 50 total packages

Build Status:
  ✅ yoten-app/yoten fixed
  ✅ tangled packages fixed
  ⚠️  frontpage needs hashes
  ⚠️  pds-dash needs hashes
  ⚠️  atbackup needs hashes

Documentation:
  ✅ CLAUDE.md updated
  ✅ PINNING_NEEDED.md updated
  ✅ README.md updated
  ⚠️  NEXT_STEPS.md needs update

Next Action:
  🔴 Calculate 3 remaining hashes
     (30 minutes on Linux x86_64)
```

---

## Conclusion

You're **very close** to 100% production readiness! The hard work (refactoring, complex builds) is done. All that remains is:

1. **30 minutes:** Calculate 3 hashes
2. **1 hour:** Test builds
3. **20 minutes:** Update docs
4. **5 minutes:** Push to remote

Then you'll have a **fully production-ready ATProto NUR** with:
- ✅ 50 working packages
- ✅ 100% module coverage
- ✅ Clean, maintainable codebase
- ✅ Comprehensive documentation
- ✅ No blockers for users

**Recommended Next Command:**
```bash
# Start calculating hashes right now!
nix build .#likeandscribe-frontpage -L 2>&1 | tee /tmp/frontpage.log | grep "got:"
```

Good luck! 🚀
