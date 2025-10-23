# ATProto NUR - Action Items

Quick reference for immediate tasks. See PLAN.md for comprehensive roadmap.

## 🔴 Critical (Do First)

### Fix Build Blockers (2-4 hours)
- [ ] **tangled-dev/appview.nix** - Pin rev + calculate hash + vendorHash
- [ ] **tangled-dev/knot.nix** - Pin rev + calculate hash + vendorHash
- [ ] **tangled-dev/spindle.nix** - Pin rev + calculate hash + vendorHash
- [ ] **atbackup-pages-dev/atbackup.nix** - Replace `lib.fakeHash` with real hash
- [ ] **witchcraft-systems/pds-dash.nix** - Pin rev + calculate hash + npmDepsHash
- [ ] **atproto/frontpage.nix** - Pin rev + calculate hash + npmDepsHash

**How to fix:**
```bash
# 1. Get latest commit
git ls-remote https://github.com/OWNER/REPO HEAD

# 2. Update .nix file with commit hash
# 3. Try to build - it will show correct hash
nix build .#PACKAGE-NAME 2>&1 | grep "got:"

# 4. Update hash in .nix file
# 5. Test build succeeds
```

### Pin for Reproducibility (1-2 hours)
- [ ] **hyperlink-academy/leaflet.nix** - Pin `rev = "main"` to specific commit
- [ ] **slices-network/slices.nix** - Pin `rev = "main"` to specific commit
- [ ] **blacksky/rsky/default.nix** - Review TODO comments and fix

### Fix Broken References (30 min)
- [ ] **modules/default.nix:37** - Remove `../profiles` import (directory doesn't exist)
- [ ] **docs/** - Remove empty directory or add content
- [ ] Test modules load: `nix eval .#nixosModules.default`

## 🟡 High Priority (Do Soon)

### Decide on Placeholders (2-4 hours)
- [ ] **bluesky-social-indigo** - Implement or document as planned?
- [ ] **bluesky-social-grain** - Implement or document as planned?
- [ ] **parakeet-social-parakeet** - Keep/remove/implement?
- [ ] **teal-fm-teal** - Keep/remove/implement?
- [ ] **tangled-dev-genjwks** - Keep/remove/implement?
- [ ] **tangled-dev-lexgen** - Keep/remove/implement?

### Set Up CI/CD (4-6 hours)
- [ ] Create `.github/workflows/build.yml`
- [ ] Build on: push to main, pull requests
- [ ] Matrix: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
- [ ] Run `nix flake check`
- [ ] Build changed packages
- [ ] Push to Cachix

### Populate Cachix Cache (2-4 hours)
- [ ] Verify `atproto.cachix.org` access
- [ ] Build all packages on Linux x86_64 (priority)
- [ ] Build all packages on Darwin aarch64 (priority)
- [ ] Push to cache
- [ ] Update README with correct public key
- [ ] Test cache works for fresh install

## 🟢 Medium Priority (This Month)

### Add Tests (6-10 hours)
- [ ] Smoke test: microcosm-constellation
- [ ] Smoke test: blacksky-pds
- [ ] Smoke test: smokesignal-events-quickdid
- [ ] NixOS module test: basic service configuration
- [ ] Document test execution in README

### Create Examples (6-10 hours)
- [ ] Example: Basic PDS deployment
- [ ] Example: Microcosm service cluster
- [ ] Example: Development environment
- [ ] Add `examples/` directory with working configs

### Improve Documentation (4-6 hours)
- [ ] README: Add troubleshooting section
- [ ] README: Add contribution guidelines
- [ ] README: Create package comparison table (type, language, status, has module)
- [ ] Create CONTRIBUTING.md
- [ ] Update README badges (CI status, cache status)

## 🔵 Low Priority (Future)

### Update Automation (3-6 hours)
- [ ] Script to check upstream versions
- [ ] Document update process
- [ ] Consider automated update PRs

### Package Additions (1-2 hours each)
- [ ] Survey ATProto ecosystem for popular projects
- [ ] Prioritize by usage/maturity
- [ ] Add 5-10 new packages

### Community (Ongoing)
- [ ] Submit to official NUR registry
- [ ] Announce on ATProto/Bluesky communities
- [ ] Set up GitHub Discussions
- [ ] Create contributor recognition

## Quick Commands

```bash
# Check build status
nix flake check

# Build specific package
nix build .#microcosm-constellation -L

# Find unpinned versions
grep -r "rev = \"main\"" pkgs/
grep -r "fakeHash" pkgs/

# Update flake inputs
nix flake update

# Format all nix files
nixpkgs-fmt .

# Push to cachix
nix build .#PACKAGE && cachix push atproto ./result
```

## Progress Tracking

**Last Updated:** 2025-10-22

**Stats:**
- 48 packages total
- 9 packages need pinning
- 6 packages have fakeHash (won't build)
- 6 placeholder packages
- 0 packages in Cachix cache
- 0 CI/CD pipelines configured

**Goal for v1.0:**
- ✅ All packages build successfully
- ✅ All versions pinned
- ✅ Cachix populated
- ✅ CI/CD running
- ✅ 3+ example configs
- ✅ Documentation complete

---

See **PLAN.md** for detailed roadmap and strategy.
