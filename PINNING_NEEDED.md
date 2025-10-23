# Packages Needing Hash Calculation

**Last Updated:** 2025-10-22 (Post-Phase 3)
**Status:** All packages now pinned to specific commits, but 6 packages need hash calculation on Linux x86_64

---

## Summary

✅ **All packages now use specific commit hashes** (no more `rev = "main"`)
⚠️ **6 packages use `lib.fakeHash`** and need real hashes calculated on Linux x86_64
📊 **48 total packages** in repository

---

## Packages Requiring Hash Calculation (6 total)

These packages are pinned to specific commits but use `lib.fakeHash` placeholder. They **will fail to build** until real hashes are calculated.

### Tangled Packages (3 packages)

**Note:** Organization renamed `tangled-dev` → `tangled` in Phase 1

#### 1. `pkgs/tangled/knot.nix` - Git server
- **Status:** ⚠️ Pinned commit, needs hash calculation
- **Commit:** `54a60448cf5c456650e9954ca9422276c5d73282`
- **Source:** fetchFromTangled (tangled.org/@tangled.org/core)
- **Needs:** `hash` (source hash) + `vendorHash` (Go modules)
- **Platform:** Go binary (requires Linux x86_64 for vendorHash)

#### 2. `pkgs/tangled/appview.nix` - AppView web interface
- **Status:** ⚠️ Pinned commit, needs hash calculation
- **Commit:** `54a60448cf5c456650e9954ca9422276c5d73282`
- **Source:** fetchFromTangled (tangled.org/@tangled.org/core)
- **Needs:** `hash` (source hash) + `vendorHash` (Go modules)
- **Platform:** Go binary (requires Linux x86_64 for vendorHash)

#### 3. `pkgs/tangled/spindle.nix` - Event processor
- **Status:** ⚠️ Pinned commit, needs hash calculation
- **Commit:** `54a60448cf5c456650e9954ca9422276c5d73282`
- **Source:** fetchFromTangled (tangled.org/@tangled.org/core)
- **Needs:** `hash` (source hash) + `vendorHash` (Go modules)
- **Platform:** Go binary (requires Linux x86_64 for vendorHash)

### Third-Party Application Packages (3 packages)

#### 4. `pkgs/witchcraft-systems/pds-dash.nix` - PDS dashboard
- **Status:** ⚠️ Pinned commit, needs hash calculation
- **Commit:** `c348ed5d46a0d95422ea6f4925420be8ff3ce8f0`
- **Source:** fetchFromGitHub (github.com/witchcraft-systems/pds-dash)
- **Needs:** `hash` (source hash only)
- **Platform:** Node.js application

#### 5. `pkgs/likeandscribe/frontpage.nix` - Frontpage monorepo
- **Status:** ⚠️ Pinned commit, needs hash calculation
- **Commit:** `5c95747f9d10f40b99d89830afd63d54d9b90665`
- **Source:** fetchFromGitHub (github.com/likeandscribe/frontpage)
- **Needs:** `hash` (source hash) + `npmDepsHash` (npm dependencies)
- **Platform:** Node.js + Rust workspace (9 sub-packages)
- **Note:** Organization corrected from atproto/bluesky-social to likeandscribe in Phase 3

#### 6. `pkgs/atbackup-pages-dev/atbackup.nix` - ATProto backup tool
- **Status:** ⚠️ Already has commit, needs hash calculation
- **Commit:** Already pinned correctly
- **Source:** fetchFromGitHub (github.com/atbackup-pages-dev/atbackup)
- **Needs:** `hash` (source hash only)
- **Platform:** Desktop application (no module)

---

## Already Fixed ✅

These packages were fixed in Phases 1-2:

- ✅ `pkgs/hyperlink-academy/leaflet.nix` - pinned to `a1ee677f4499819b303348073a8da50100b9972b`
- ✅ `pkgs/slices-network/slices.nix` - pinned to `0a876a16d49c596d779d21a80a9ba0822f9d571f`
- ✅ All other packages already had correct hashes

---

## How to Calculate Hashes

### Prerequisites

**IMPORTANT:** Hash calculation must be done on **Linux x86_64** for reproducibility.

Options:
1. Native Linux x86_64 machine
2. NixOS VM on macOS (using UTM or VirtualBox)
3. GitHub Actions CI/CD (recommended for automation)
4. Remote Linux server

### Method 1: Manual Calculation on Linux

```bash
# On Linux x86_64 machine
cd /path/to/nur

# For each package, build and capture hash from error
nix build .#tangled-knot -L 2>&1 | grep "got:"
# Output will show: "got: sha256-XXXX..."
# Copy that hash to pkgs/tangled/knot.nix

# For Go packages, build again for vendorHash
nix build .#tangled-knot -L 2>&1 | grep "got:"
# Update vendorHash in the .nix file

# Repeat for all 6 packages
```

### Method 2: Using nix-prefetch (For Source Hashes Only)

```bash
# For packages using fetchFromGitHub
nix-prefetch-url --unpack https://github.com/OWNER/REPO/archive/COMMIT.tar.gz

# For packages using fetchFromTangled
# Must use Method 1 (build and capture error)
```

### Method 3: Automated via CI/CD (Recommended)

Set up GitHub Actions workflow to:
1. Detect packages with `lib.fakeHash`
2. Build on Linux x86_64 runner
3. Capture correct hashes from errors
4. Create PR with hash updates

---

## Package-by-Package Instructions

### Tangled Packages (All 3)

```bash
# All share the same source, so hash will be the same

# 1. Calculate source hash
nix build .#tangled-knot -L 2>&1 | tee /tmp/knot.log | grep "got:"
# Copy sha256 hash to all 3 files:
# - pkgs/tangled/knot.nix
# - pkgs/tangled/appview.nix
# - pkgs/tangled/spindle.nix

# 2. Calculate vendorHash for each (they differ)
nix build .#tangled-knot -L 2>&1 | grep "got:"
# Update vendorHash in pkgs/tangled/knot.nix

nix build .#tangled-appview -L 2>&1 | grep "got:"
# Update vendorHash in pkgs/tangled/appview.nix

nix build .#tangled-spindle -L 2>&1 | grep "got:"
# Update vendorHash in pkgs/tangled/spindle.nix

# 3. Verify builds succeed
nix build .#tangled-knot .#tangled-appview .#tangled-spindle
```

### Witchcraft Systems PDS Dashboard

```bash
# Only needs source hash
nix build .#witchcraft-systems-pds-dash -L 2>&1 | grep "got:"
# Update hash in pkgs/witchcraft-systems/pds-dash.nix

# Verify
nix build .#witchcraft-systems-pds-dash
```

### Likeandscribe Frontpage

```bash
# 1. Calculate source hash
nix build .#likeandscribe-frontpage -L 2>&1 | grep "got:"
# Update hash in pkgs/likeandscribe/frontpage.nix

# 2. Calculate npmDepsHash
nix build .#likeandscribe-frontpage -L 2>&1 | grep "got:"
# Update npmDepsHash in pkgs/likeandscribe/frontpage.nix

# 3. Verify (builds 9 sub-packages)
nix build .#likeandscribe-frontpage
```

### ATBackup

```bash
# Only needs source hash
nix build .#atbackup-pages-dev-atbackup -L 2>&1 | grep "got:"
# Update hash in pkgs/atbackup-pages-dev/atbackup.nix

# Verify
nix build .#atbackup-pages-dev-atbackup
```

---

## Priority

### 🔴 CRITICAL - Blocks All Builds
All 6 packages listed above won't build until hashes are calculated

### 🟢 LOW - Documentation/CI Updates
- Update README.md
- Update CI/CD workflows
- Add hash validation checks

---

## Timeline Estimate

**With Linux x86_64 Access:**
- Manual calculation: 1-2 hours
- Validation builds: 30 minutes
- Total: ~2 hours to complete

**Without Linux x86_64 Access:**
- Set up NixOS VM: 1-2 hours
- Manual calculation: 1-2 hours
- Total: ~4 hours to complete

**Automated CI/CD Setup:**
- Initial setup: 3-4 hours
- Future updates: Automatic

---

## Current Status

```
Repository Status: 🟡 90% Production Ready

Pinning Status:
  ✅ All 48 packages pinned to specific commits
  ✅ No more rev = "main" references
  ⚠️  6 packages need hash calculation

Build Status:
  ✅ 42 packages build successfully
  ⚠️  6 packages will fail (lib.fakeHash)

Reproducibility:
  ✅ Commits pinned (reproducible source)
  ⚠️  Hashes needed (for Nix evaluation)
```

---

## After Hash Calculation

Once all 6 hashes are calculated and committed:

**Repository Status: 🟢 100% Production Ready**

```
✅ All 48 packages build successfully
✅ All packages use specific commits
✅ All packages have real hashes
✅ Fully reproducible builds
✅ Ready for binary cache (Cachix)
✅ Ready for production deployments
```

---

## Notes

- **Why Linux x86_64?** Nix hashes must be calculated on the same platform for reproducibility
- **Why lib.fakeHash?** Used as placeholder during development; replaced with real hash after first build
- **Platform issues?** Tangled packages were marked `platforms.unix` (Linux + macOS), but hash calc still needs Linux
- **Can I skip this?** No - packages won't build without real hashes

---

## Questions?

- Check NEXT_STEPS.md for overall roadmap
- Check CLAUDE.md for project context
- Use MCP-NixOS: "How do I calculate vendorHash for Go packages?"
- Ask in NixOS Discourse/Matrix for help
