# lib/packaging.nix Improvements Plan

## Executive Summary

Current `lib/packaging.nix` (944 lines) is comprehensive but has critical gaps for JavaScript/Deno builds with external bundlers. This document outlines a plan to make it better serve the NUR's needs, especially around determinism.

**Current State**: Good foundation for Rust/Go/Node, missing key patterns for Deno + bundlers
**Priority**: HIGH - Blocking pds-dash, slices, frontpage fixes
**Scope**: Add FOD helpers, determinism controls, better error handling

---

## Current Assessment

### ✅ What Works Well

**Structure**:
- Organized by language (Rust, Node, Go, Deno)
- Exports standard env/inputs/outputs
- Good workspace support (Rust, pnpm)
- Multi-language coordination framework

**Strong Points**:
- `standardEnv` well-defined for Rust builds
- Workspace patterns for Cargo and pnpm
- Service configuration for Go modules
- Good attempt at Deno caching

**Usage**:
- 5+ packages use it (hyperlink-academy, baileytownsend, slices, likeandscribe, etc.)
- Light adoption suggests either: (a) not well-known, or (b) doesn't meet all needs

### ❌ Critical Gaps

**JavaScript/Deno Nondeterminism**:
- No FOD (Fixed-Output Derivation) helper for dependency caching
- No determinism controls (NODE_ENV, VITE_INLINE_ASSETS_THRESHOLD)
- `buildDenoApp` uses online caching (no offline support)
- No pattern for "cache deps → offline build"

**Missing Helpers**:
- No `buildDenoAppWithFOD` for dependency caching
- No `buildNpmWithFOD` for offline npm builds
- No bundler determinism wrapper (Vite, esbuild control)
- No pnpm workspace FOD pattern

**Error Handling**:
- Uses `lib.fakeHash` in many places (buildPnpmWorkspace:241, buildNodeAtprotoPackage:159)
- No validation that hashes are real
- No guide on calculating hashes with FOD

**API Issues**:
- Inconsistent parameter handling across builders
- Missing documentation/examples within the code
- Hard to extend for custom patterns

---

## Proposed Improvements

### Phase 1: FOD Helpers (Priority: Critical)

Add deterministic caching patterns for JavaScript/Deno:

**1. `buildDenoAppWithFOD` - Deno + external builders**

```nix
buildDenoAppWithFOD = { src, denoLock ? "deno.lock", denoJson ? "deno.json", entryPoints ? ["src/main.ts"], ... }@args:
let
  denoCacheFOD = pkgs.runCommand "app-deno-cache" {
    outputHashMode = "recursive";
    outputHash = args.denoFODHash or lib.fakeHash;
    nativeBuildInputs = [ pkgs.deno ];
  } ''
    export DENO_DIR="$out"
    cp -r ${src} ./src

    # Pre-cache all entry points
    ${lib.concatMapStringsSep "\n" (ep: ''
      deno cache --lock=./src/${denoLock} --reload ./src/${ep}
    '') entryPoints}
  '';
in
# ... return app with offline build using denoCacheFOD
```

**2. `buildNpmWithFOD` - npm/yarn with offline build**

```nix
buildNpmWithFOD = { src, packageManager ? "npm", determinismEnv ? {}, ... }@args:
let
  npmCacheFOD = pkgs.runCommand "npm-cache" {
    outputHashMode = "recursive";
    outputHash = args.npmFODHash or lib.fakeHash;
    nativeBuildInputs = [ pkgs.nodejs ];
  } ''
    cp -r ${src} .
    npm ci --prefer-offline
    mkdir -p $out
    cp -r node_modules $out/
  '';
in
# ... return package with cached deps and determinism flags
```

**3. `buildPnpmWorkspaceWithFOD` - pnpm workspaces with offline cache**

```nix
buildPnpmWorkspaceWithFOD = { src, workspaces, ... }@args:
let
  pnpmCacheFOD = pkgs.runCommand "pnpm-cache" {
    outputHashMode = "recursive";
    outputHash = args.pnpmFODHash or lib.fakeHash;
    nativeBuildInputs = [ pkgs.nodejs pkgs.nodePackages.pnpm ];
  } ''
    cp -r ${src} .
    pnpm install --frozen-lockfile
    mkdir -p $out
    cp -r node_modules $out/
    cp -r .pnpm-store $out/ || true
  '';
in
# ... return workspace packages with cached deps
```

### Phase 2: Determinism Helpers (Priority: High)

Add environment controls for non-deterministic builders:

**4. `mkDeterministicNodeEnv` - Control bundler output**

```nix
mkDeterministicNodeEnv = { bundler ? "vite", sourceMap ? false, ... }@args:
{
  NODE_ENV = "production";
  CI = "true";
  TZ = "UTC";

  # Bundler-specific
  VITE_INLINE_ASSETS_THRESHOLD = "0";
  VITE_BUILD_SOURCEMAP = if sourceMap then "true" else "false";
  ESBUILD_MINIFY_SYNTAX = "true";
  ESBUILD_DROP_DEBUGGER = "true";
};
```

**5. `applyDeterminismFlags` - Patch vite/esbuild configs**

```nix
applyDeterminismFlags = { src, bundler ? "vite", ... }@args:
if bundler == "vite" then
  pkgs.runCommand "vite-deterministic" {} ''
    cp -r ${src} $out
    cat >> $out/vite.config.ts << 'EOF'
    // Determinism overrides
    export default {
      build: {
        rollupOptions: {
          output: { manualChunks: {} }
        }
      }
    }
    EOF
  ''
else src;
```

### Phase 3: API Improvements (Priority: Medium)

**6. Consistent FOD Hash Handling**

Current problem: `lib.fakeHash` scattered throughout
```nix
# Current (bad)
npmDepsHash = args.npmDepsHash or lib.fakeHash;

# Proposed (good)
npmDepsHash = args.npmDepsHash or (throw "npmDepsHash required - calculate with: nix build ... 2>&1 | grep got:");
```

**7. Better Parameter Organization**

```nix
# Current (mixed concerns)
buildPnpmWorkspace = { owner, repo, rev, sha256, workspaces, ... }@args

# Proposed (separated)
buildPnpmWorkspace = {
  src,
  workspaces,
  npmDepsHash,  # Required, must be real
  determinism ? true,
  bundler ? null,
  ...
}@args
```

**8. Documentation and Examples**

Add inline examples:
```nix
# Example: Deterministic Deno + Vite build
#
# app = packaging.buildDenoAppWithFOD {
#   src = fetchFromTangled { ... };
#   denoLock = "deno.lock";
#   denoFODHash = "sha256-...";
#   determinism = true;
#   bundler = "vite";
# };
```

### Phase 4: New Helper Functions (Priority: Medium)

**9. `buildJSBundle` - Universal JS bundler wrapper**

Handles Vite, esbuild, etc. with determinism:
```nix
buildJSBundle = { src, bundler, deterministic ? true, outputDir ? "dist", ... }@args:
# Wraps bundler invocation with:
# - Environment controls
# - Config patching
# - Determinism validation
```

**10. `buildDenoWithFallback` - Deno + offline graceful degradation**

```nix
buildDenoWithFallback = { src, entryPoints, fallbackCommand ? null, ... }@args:
# Try cached build, fallback to online if needed
```

**11. `validateBuildDeterminism` - Build output verification**

```nix
validateBuildDeterminism = { derivation, expectedHash ? null, ... }@args:
# Build twice, compare outputs
# Report non-deterministic files
# Suggest fixes
```

---

## Implementation Strategy

### Step 1: Add FOD Helpers (Week 1)
- [ ] Implement `buildDenoAppWithFOD`
- [ ] Implement `buildNpmWithFOD`
- [ ] Implement `buildPnpmWorkspaceWithFOD`
- [ ] Write detailed examples for each

### Step 2: Update buildDenoApp (Week 1)
- [ ] Add optional FOD support to existing `buildDenoApp`
- [ ] Document how to migrate old usage
- [ ] Add deprecation warning for non-FOD usage

### Step 3: Add Determinism Helpers (Week 2)
- [ ] Implement `mkDeterministicNodeEnv`
- [ ] Implement `applyDeterminismFlags`
- [ ] Test with pds-dash, slices, frontpage

### Step 4: Improve buildPnpmWorkspace (Week 2)
- [ ] Add `pnpmFODHash` parameter (required)
- [ ] Replace `lib.fakeHash` with proper validation
- [ ] Add determinism controls

### Step 5: Add Validation and Docs (Week 3)
- [ ] Implement `validateBuildDeterminism`
- [ ] Add inline examples for all new functions
- [ ] Create migration guide from old patterns

### Step 6: Update Example Packages (Week 3)
- [ ] Migrate pds-dash to use new FOD pattern
- [ ] Migrate slices to use new FOD pattern
- [ ] Migrate frontpage to use new FOD pattern
- [ ] Verify all builds are deterministic

---

## Code Organization

```
lib/packaging.nix
├── Standard Environments (existing)
│   ├── standardEnv
│   ├── standardNativeInputs
│   └── standardBuildInputs
│
├── Language Builders (existing, enhanced)
│   ├── buildRustAtprotoPackage
│   ├── buildRustWorkspace
│   ├── buildNodeAtprotoPackage
│   ├── buildPnpmWorkspace (IMPROVED)
│   ├── buildGoAtprotoModule
│   └── buildDenoApp (IMPROVED)
│
├── NEW: Deterministic Builders
│   ├── buildDenoAppWithFOD
│   ├── buildNpmWithFOD
│   ├── buildPnpmWorkspaceWithFOD
│   ├── buildJSBundle
│   └── buildDenoWithFallback
│
├── NEW: Determinism Utilities
│   ├── mkDeterministicNodeEnv
│   ├── mkDeterministicRustEnv
│   ├── applyDeterminismFlags
│   └── validateBuildDeterminism
│
├── Multi-Language (existing)
│   ├── buildMultiLanguageProject
│   └── coordinateBuildOrder
│
└── Shared Utilities (existing)
    ├── createSharedDependencies
    └── monitorBuildPerformance
```

---

## Breaking Changes

None intentional. All new functions are additive. Existing functions remain compatible.

**Deprecations (future)**:
- `buildDenoApp` without FOD (will warn in logs)
- `buildPnpmWorkspace` with `lib.fakeHash` (will error)

---

## Testing Plan

**Unit Tests** (using nix-unit or similar):
```bash
# Test FOD hash calculation
nix eval '.#test-deno-fod-hash'

# Test determinism validation
nix build .#slices 2>&1 | grep "deterministic"

# Test environment application
nix eval '.#test-deterministic-env' | grep NODE_ENV
```

**Integration Tests**:
```bash
# Build pds-dash, verify determinism
nix build .#pds-dash -o result1
nix build .#pds-dash -o result2
diff -r result1 result2  # Should be empty

# Build slices with new pattern
nix build .#slices-network-slices -L 2>&1 | grep "cached-only"
```

---

## Documentation Updates

Update `CLAUDE.md`:
```markdown
### JavaScript and Deno with Determinism

Use FOD helpers for reliable, offline builds:

- `buildDenoAppWithFOD` - Deno with dependency caching
- `buildNpmWithFOD` - npm with offline support
- `buildPnpmWorkspaceWithFOD` - pnpm workspaces

See `docs/JAVASCRIPT_DENO_BUILDS.md` for detailed examples.
```

Add new file `docs/PACKAGING_UTILITIES.md`:
- API documentation for all packaging helpers
- Examples for each builder
- Migration guide from old patterns

---

## Estimated Effort

- Phase 1: 4-6 hours
- Phase 2: 3-4 hours
- Phase 3: 2-3 hours
- Phase 4: 4-6 hours
- Phase 5: 2-3 hours
- Phase 6: 2-3 hours

**Total**: ~20 hours

---

## Success Criteria

✅ All new FOD helpers have working examples
✅ pds-dash, slices, frontpage migrate successfully
✅ All builds verified as deterministic
✅ No `lib.fakeHash` in committed code
✅ Documentation is complete and clear
✅ No breaking changes to existing packages

---

## Risk Mitigation

**Risk**: FOD hash calculation failures
**Mitigation**: Provide detailed error messages with examples

**Risk**: Existing packages break
**Mitigation**: Keep old functions working, add deprecation warnings

**Risk**: Complexity increases
**Mitigation**: Start with small focused helpers, document each

---

## Open Questions

1. Should we require `npmDepsHash` or allow `lib.fakeHash` with warning?
   → **Recommend**: Require real hashes, fail with helpful message

2. Should `buildDenoAppWithFOD` be separate function or option on existing?
   → **Recommend**: Separate for clarity, mark old one as deprecated

3. How to handle bundler detection (Vite vs esbuild vs other)?
   → **Recommend**: Explicit parameter, no magic

4. Should we add caching layer for FOD results across builds?
   → **Recommend**: Future phase, document approach first

---

## References

- `docs/JAVASCRIPT_DENO_BUILDS.md` - FOD pattern explanation
- `PACKAGE_FIXES_PLAN.md` - Packages needing these improvements
- `CLAUDE.md` - Project guidelines
