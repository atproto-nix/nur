# Package Migration Checklist - lib/packaging.nix → Modular lib/packaging/

**Status**: 🚀 In Progress
**Goal**: Migrate all 44 packages to use new modular lib/packaging structure
**Total Packages**: 44 package files + 5 placeholders = 49 total

---

## 🎯 Migration Strategy

### Phase 1: Fix Critical Issues (3 packages, ~40 min)
These MUST be fixed before migration:
- [ ] **pds-dash.nix** - Fix `rev = "main"` → pin commit
- [ ] **frontpage.nix** - Fix `npmDepsHash = lib.fakeHash` → calculate real hash
- [ ] **yoten.nix** - Fix aarch64-linux error placeholder

### Phase 2: Migrate by Language (remaining 41 packages)

#### Rust Packages (20 packages, ~30 min)
NO CHANGES NEEDED - Already using Crane correctly
- [ ] Verify all use craneLib patterns (no updates needed)
- [ ] Document as "verified correct"

**Affected packages**: constellation, spacedust, slingshot, jetstream, ufos, ufos-fuzz, quasar, reflector, who-am-i, pocket, links, allegedly, rsky-pds, rsky-relay, rsky-feedgen, darkroom, cli, quickdid, pds-gatekeeper, parakeet

#### Go Packages (6 packages, ~20 min)
NO CHANGES NEEDED - Already using buildGoModule correctly
- [ ] Verify all use buildGoModule with vendorHash
- [ ] Document as "verified correct"

**Affected packages**: appview, knot, spindle, yoten, streamplace, konbini

#### Node.js Packages (13 packages, ~2 hours)
NEEDS MIGRATION - Update to use new FOD helpers
- [ ] **Type A - Source only (7 packages, no build)**: Minimal changes
  - atproto-api, atproto-xrpc, atproto-did, atproto-identity, atproto-repo, atproto-syntax, atproto-lexicon
  - Change: Just update lib reference if they use lib helpers

- [ ] **Type B - Simple npm packages (3 packages)**: Update to buildNpmWithFOD
  - avatar, camo, leaflet
  - Change: Use buildNpmWithFOD with calculated npmDepsHash (if not lib.fakeHash)

- [ ] **Type C - npm with bundler (2 packages)**: Update to buildNpmWithFOD or buildWithViteOffline
  - red-dwarf (Vite), appview-static-files (custom bundling)
  - Change: Use bundler FOD pattern for determinism

- [ ] **Type D - pnpm monorepo (1 package)**: Update to buildPnpmWorkspace
  - frontpage (CRITICAL - has lib.fakeHash)
  - Change: Use buildPnpmWorkspace with FOD, calculate real hash

**Special case**: konbini (Go + Node hybrid) - may need multi-language coordination

#### Deno Packages (1 package, ~30 min)
NEEDS MIGRATION - Use new buildDenoAppWithFOD
- [ ] **pds-dash**: Update to buildDenoAppWithFOD with FOD caching
  - Change: Add denoCacheFODHash, use new Deno FOD pattern

#### Ruby Packages (1 package, ~5 min)
NO CHANGES NEEDED - Ruby bundler approach is separate
- [ ] **lycan**: Verify no lib/packaging usage
  - Change: None needed

#### Placeholder Packages (5 packages, ~5 min)
NO CHANGES NEEDED - Just stubs
- [ ] **indigo, grain, genjwks, lexgen, teal**: Verify no actual build
  - Change: None needed

#### Hybrid Multi-Language Package (1 package, ~20 min)
NEEDS MIGRATION - Update coordination pattern
- [ ] **slices**: Update to use language-specific modules correctly
  - Rust part: Use packaging.rust.buildRustAtprotoPackage
  - Node.js part: Use packaging.nodejs.buildNpmWithFOD
  - Change: Update lib reference, split if needed

---

## 📋 Detailed Migration Tasks

### Critical Fixes (Phase 1)

#### Task 1: pds-dash.nix (Deno + Vite + unpinned version)
**Current state**:
```nix
rev = "main";  # ❌ NOT PINNED
```
**Action**:
1. Get latest commit: `git ls-remote https://github.com/witchcraft-systems/pds-dash refs/heads/main`
2. Replace `rev = "main"` with commit hash
3. Verify with `nix build .#witchcraft-systems-pds-dash`

**Estimated time**: 15 min

---

#### Task 2: frontpage.nix (pnpm monorepo + lib.fakeHash)
**Current state**:
```nix
npmDepsHash = lib.fakeHash;  # ❌ FAKE HASH
```
**Action**:
1. Change `npmDepsHash = lib.fakeHash` to real hash calculation:
   - Run: `nix build .#likeandscribe-frontpage 2>&1 | grep -A2 "got:"`
   - Wait for error with suggested hash
   - Copy hash into npmDepsHash
2. Run build again to verify
3. Test with actual build

**Estimated time**: 1-2 hours (complex monorepo)

---

#### Task 3: yoten.nix (Go + templ + multi-stage build)
**Current state**:
```nix
error "aarch64-linux not yet supported for yoten";
```
**Action**:
1. Either:
   - Calculate proper aarch64-linux hash, OR
   - Replace error with proper derivation
2. Update hashes for aarch64-linux platform
3. Verify build works on target platform

**Estimated time**: 20 min

---

### Node.js Packages (Phase 2)

#### Task 4: Source-only TypeScript packages (7 packages, ~30 min)
**Current pattern**: `stdenv.mkDerivation` with `dontBuild = true`

**Packages affected**:
- atproto-api
- atproto-xrpc
- atproto-did
- atproto-identity
- atproto-repo
- atproto-syntax
- atproto-lexicon

**Action**: No changes needed - these are source-only packages
1. Verify they don't use `lib/packaging` helpers
2. If they do, update the lib reference

**Estimated time**: 5 min (just verification)

---

#### Task 5: Simple npm packages with builds (3 packages, ~45 min)
**Packages affected**:
- avatar.nix
- camo.nix
- leaflet.nix

**Current pattern**: `buildNpmPackage` or custom npm builds

**Action**:
1. Check if they have `npmDepsHash` (not `lib.fakeHash`)
2. If yes, update to: `buildNpmWithFOD`
3. If no, calculate hash first
4. Verify each builds successfully

**Estimated time**: 15 min per package × 3 = 45 min

---

#### Task 6: npm packages with bundlers (2 packages, ~45 min)
**Packages affected**:
- red-dwarf.nix (uses Vite)
- appview-static-files.nix (Tailwind CSS custom build)

**Current pattern**: Custom builds with non-deterministic tools

**Action**:
1. **red-dwarf**: Convert to `buildWithViteOffline` from bundlers module
   - Add npmDepsHash FOD
   - Add viteBuildHash FOD (may be different from npm hash)
2. **appview-static-files**: Update to use buildWithOfflineCache
3. Test for determinism

**Estimated time**: 20 min per package = 40 min

---

#### Task 7: pnpm monorepo (1 package, ~2 hours)
**Package affected**: frontpage.nix

**Current pattern**: Complex pnpm workspace with 6 Node + 3 Rust packages

**Action**:
1. Convert to `buildPnpmWorkspace` helper
2. Calculate `sharedNpmDepsHash` (FOD for all node_modules)
3. Test each workspace package builds
4. Handle Rust packages in same monorepo
5. Test determinism

**Estimated time**: 1.5-2 hours (complex, needs hash calculation on Linux)

---

### Deno Package (Phase 2)

#### Task 8: pds-dash.nix (Deno + Vite + fixed version)
**Current pattern**: FOD for node_modules + Vite build

**Action**:
1. Already partially done in critical fixes
2. Update to use `buildDenoAppWithFOD` from deno module
3. Add `denoCacheFODHash` for Deno dependency caching
4. Keep Vite FOD for non-deterministic output
5. Test for determinism

**Estimated time**: 20 min

---

### Hybrid Multi-Language Package

#### Task 9: slices.nix (Rust API + Deno Frontend)
**Current pattern**: Uses both Rust and Deno/Node builders

**Action**:
1. Keep Rust part: Use `packaging.rust.buildRustAtprotoPackage`
2. Update frontend: Use appropriate Node.js or Deno builder
3. Test both parts build correctly
4. Verify integration

**Estimated time**: 20 min

---

## ✅ Verification Tasks

After all migrations:

- [ ] All 44 packages evaluate without errors
- [ ] No packages use `lib.fakeHash` (except intentional placeholders)
- [ ] All version pins are commit hashes (no "main", "master")
- [ ] All npm/pnpm packages have real npmDepsHash
- [ ] All Go packages have real vendorHash
- [ ] Deno package uses FOD pattern
- [ ] JavaScript packages with bundlers use determinism controls
- [ ] pnpm monorepo properly coordinates workspace builds

---

## 🧪 Testing Checklist (for user to validate)

After migration is complete, user should test:

### Critical Package Builds
- [ ] `nix build .#witchcraft-systems-pds-dash` - Deno + Vite
- [ ] `nix build .#likeandscribe-frontpage` - pnpm monorepo
- [ ] `nix build .#yoten-app-yoten` - Go + multi-stage

### Rust Workspace
- [ ] `nix build .#microcosm-constellation` - Shared workspace member
- [ ] `nix build .#microcosm-spacedust` - Another workspace member
- [ ] All 11 Microcosm packages build correctly

### Node.js
- [ ] `nix build .#hyperlink-academy-leaflet` - Next.js app
- [ ] `nix build .#whey-party-red-dwarf` - Vite app
- [ ] Source packages evaluate correctly

### Go
- [ ] `nix build .#tangled-appview` - Go service
- [ ] `nix build .#yoten-app-yoten` - Multi-stage

### Full flake evaluation
- [ ] `nix flake check` - All packages evaluate
- [ ] `nix flake show` - All packages listed correctly

### Determinism tests (only if you want to validate)
- [ ] Build pds-dash twice: `nix build .#witchcraft-systems-pds-dash -o result1 && nix build .#witchcraft-systems-pds-dash -o result2 && diff -r result1 result2`
- [ ] Build frontpage twice (check determinism of final output)

---

## 📊 Progress Tracking

**Total packages**: 44
**Languages**: Rust (20), Go (6), Node.js (13), Deno (1), Ruby (1), Hybrid (1), Placeholders (5)

**Phase 1 (Critical Fixes)**: 3 packages
- [ ] pds-dash (Deno) - unpinned
- [ ] frontpage (pnpm) - fake hash
- [ ] yoten (Go) - placeholder error

**Phase 2 (Language Migrations)**: 41 packages
- [ ] Rust (20) - verify, no changes
- [ ] Go (6) - verify, no changes
- [ ] Node.js (13) - migrate to FOD
- [ ] Deno (1) - migrate to FOD
- [ ] Ruby (1) - verify, no changes
- [ ] Hybrid (1) - verify/update
- [ ] Placeholders (5) - verify, no changes

---

## 🚀 Next Steps

1. Execute Phase 1 fixes (pds-dash, frontpage, yoten)
2. Execute Phase 2 migrations (language by language)
3. Provide testing checklist to user
4. User validates builds
5. Document any issues found
6. Update CLAUDE.md with new lib/packaging reference
7. Commit migration with summary

**Total estimated execution time**: 4-5 hours
**Total estimated testing time**: 1-2 hours (parallel, user can do while we optimize)

