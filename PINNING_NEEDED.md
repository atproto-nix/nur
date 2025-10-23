# Packages Needing Hash Calculation

**Last Updated:** 2025-10-23 (Post-hash calculation session)
**Status:** Source hashes calculated, npmDepsHash remaining for 2 packages

---

## Summary

✅ **All packages now use specific commit hashes** (no more `rev = "main"`)
✅ **Source hashes calculated for all packages**
⚠️ **2 packages need `npmDepsHash` calculation** (pnpm/yarn based projects)
⚠️ **1 package has security issue** (atbackup - insecure libsoup2 dependency)
📊 **50 total packages** in repository (48 original + 2 likeandscribe exports)

---

## Packages Requiring Hash Calculation (2 remaining)

### Completed Source Hashes ✅

All packages now have proper source hashes calculated!

- ✅ **tangled packages** (knot, appview, spindle) - Fixed in commit `52ec077`
- ✅ **pds-dash** - Fixed in commit `bd53f79` (also converted to Deno-based build)
- ✅ **frontpage** - Source hash fixed in commit `bd53f79`
- ✅ **yoten** - Fixed in previous session with complex build setup
- ✅ **leaflet** - Fixed in Phase 2
- ✅ **slices** - Fixed in Phase 2

### Remaining npmDepsHash Calculations (2 packages)

These packages have source hashes but need `npmDepsHash` for their JavaScript dependencies:

#### 1. `pkgs/likeandscribe/frontpage.nix` - Frontpage monorepo
- **Status:** ⚠️ Source hash complete, needs npmDepsHash
- **Commit:** `5c95747f9d10f40b99d89830afd63d54d9b90665`
- **Source hash:** `sha256-094gxnsicmp6wa5wb89c90zl8s94b4iq3arq91sk8idk0b2pcj8a` ✅
- **Needs:** `npmDepsHash` (pnpm workspace dependencies)
- **Platform:** Node.js (pnpm) + Rust workspace (9 sub-packages)
- **Issue:** Uses pnpm which buildNpmPackage doesn't fully support
- **Note:** May need custom dependency fetching or conversion to stdenv.mkDerivation

#### 2. `pkgs/atbackup-pages-dev/atbackup.nix` - ATProto backup tool
- **Status:** ⚠️ Source hash exists, needs npmDepsHash
- **Commit:** `deb720914f4c36557bcd5ee9af95791e42afd45f`
- **Source hash:** `0ksqwsqv95lq97rh8z9dc0m1bjzc2fb4yjlksyfx7p49f1slcv8r` ✅
- **Needs:** `npmDepsHash` for frontend (uses yarn)
- **Platform:** Tauri desktop application (Rust + JavaScript frontend)
- **Security Issue:** 🔴 Depends on insecure libsoup2 (EOL, unfixed CVEs)
- **Action:** Marked with `knownVulnerabilities`, requires NIXPKGS_ALLOW_INSECURE=1

### Security Issues

#### atbackup - Insecure Dependency
The atbackup package depends on webkitgtk which pulls in libsoup2 (v2.74.3), which is:
- End-of-life (EOL)
- Has 14+ known CVEs with no fixes
- Upstream (Tauri/WebKitGTK) needs to migrate to libsoup3

**Current Status:**
- Package is marked with `knownVulnerabilities`
- Users must explicitly allow insecure packages to build
- Waiting for upstream Tauri to migrate to WebKitGTK with libsoup3 support

**To build anyway:**
```bash
NIXPKGS_ALLOW_INSECURE=1 nix build .#atbackup-pages-dev-atbackup --impure
```

---

## Already Fixed ✅

These packages were fixed in Phases 1-3:

- ✅ `pkgs/hyperlink-academy/leaflet.nix` - pinned to `a1ee677f4499819b303348073a8da50100b9972b` with hash
- ✅ `pkgs/slices-network/slices.nix` - pinned to `0a876a16d49c596d779d21a80a9ba0822f9d571f` with hash
- ✅ `pkgs/yoten-app/yoten.nix` - pinned to `2de6115fc7b166148b7d9206809e0f4f0c6916d7` with complex build fixed
- ✅ All other packages already had correct hashes

**Note:** `yoten-app/yoten` required a complex multi-stage build process:
- templ template generation
- Tailwind CSS v4 standalone binary (with autoPatchelfHook)
- Frontend library fetching (htmx, lucide, alpinejs)
- Static file preparation for Go embed directive

See `pkgs/yoten-app/yoten.nix` for reference implementation of complex builds.

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
  ✅ 48 packages have proper source hashes
  ⚠️  2 packages need npmDepsHash (frontpage, atbackup)
  ⚠️  1 package has security issue (atbackup - insecure libsoup2)

Reproducibility:
  ✅ Commits pinned (reproducible source)
  ⚠️  Hashes needed (for Nix evaluation)
```

---

## After Hash Calculation

## Current Status

**Repository Status: 🟡 98% Production Ready**

```
✅ All 50 packages use specific commits
✅ All 50 packages have source hashes
⚠️  2 packages need npmDepsHash (pnpm/yarn complications)
⚠️  1 package has security vulnerability (atbackup)
✅ 47 packages fully production ready
✅ Ready for binary cache (Cachix) for working packages
```

**Next Steps:**
1. Calculate npmDepsHash for frontpage (may require pnpm-specific solution)
2. Calculate npmDepsHash for atbackup (requires NIXPKGS_ALLOW_INSECURE=1)
3. Wait for upstream Tauri to fix libsoup2 dependency
4. Consider removing atbackup until security issue is resolved

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
