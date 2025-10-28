# Modular Packaging Library Design Plan

## Executive Summary

Current `lib/packaging.nix` (944 lines) is monolithic and difficult to navigate. This plan breaks it into **language-specific modules** with **build-tool-specific submodules**, improving maintainability, discoverability, and extensibility.

**Current Problem**: One 944-line file handling Rust, Node.js, Go, Deno with multiple build tools each
**Solution**: Organized hierarchy: `lib/` → language → build-tool → functions
**Benefit**: Easy to find patterns, add tools, understand best practices

---

## Proposed File Structure

```
lib/
├── packaging/                          # New: Modular packaging library
│   ├── default.nix                     # Entry point, re-exports all
│   ├── shared/                         # Shared utilities
│   │   ├── default.nix                 # Exports all shared
│   │   ├── environments.nix            # Standard envs (standardEnv, etc.)
│   │   ├── inputs.nix                  # Standard build/native inputs
│   │   ├── utils.nix                   # Common helpers
│   │   └── validation.nix              # Validation functions
│   │
│   ├── rust/                           # Rust ecosystem
│   │   ├── default.nix                 # Exports all Rust builders
│   │   ├── crane.nix                   # Crane-based builds
│   │   │   ├── buildRustAtprotoPackage
│   │   │   └── buildRustWorkspace
│   │   └── tools.nix                   # Shared Rust utils
│   │
│   ├── nodejs/                         # Node.js ecosystem
│   │   ├── default.nix                 # Exports all Node builders
│   │   ├── npm.nix                     # npm builds
│   │   │   ├── buildNpmPackage
│   │   │   └── buildNpmWithFOD         # NEW
│   │   ├── pnpm.nix                    # pnpm workspace builds
│   │   │   ├── buildPnpmWorkspace
│   │   │   └── buildPnpmWorkspaceWithFOD  # NEW
│   │   ├── yarn.nix                    # yarn builds (future)
│   │   ├── bundlers/                   # Bundler-specific helpers
│   │   │   ├── default.nix             # Export bundler helpers
│   │   │   ├── vite.nix                # Vite-specific (determinism)
│   │   │   ├── esbuild.nix             # esbuild-specific
│   │   │   └── webpack.nix             # webpack support (future)
│   │   └── tools.nix                   # Shared Node utils
│   │
│   ├── go/                             # Go ecosystem
│   │   ├── default.nix                 # Exports all Go builders
│   │   ├── buildGoModule.nix           # buildGoModule wrapper
│   │   │   ├── buildGoAtprotoModule
│   │   │   └── buildGoService
│   │   └── tools.nix                   # Shared Go utils
│   │
│   ├── deno/                           # Deno ecosystem
│   │   ├── default.nix                 # Exports all Deno builders
│   │   ├── deno.nix                    # Pure Deno builds
│   │   │   ├── buildDenoApp
│   │   │   └── buildDenoAppWithFOD     # NEW
│   │   ├── deno-bundlers/              # Deno calling JS bundlers
│   │   │   ├── default.nix             # Export Deno+bundler helpers
│   │   │   ├── deno-vite.nix           # Deno + Vite pattern
│   │   │   ├── deno-esbuild.nix        # Deno + esbuild
│   │   │   └── deno-external.nix       # Generic Deno + external
│   │   └── tools.nix                   # Shared Deno utils
│   │
│   ├── multi-language/                 # Multi-language coordination
│   │   ├── default.nix                 # Exports coordinators
│   │   ├── buildMultiLanguageProject
│   │   ├── validateCrossLanguageInterfaces
│   │   └── coordinateBuildOrder
│   │
│   └── determinism/                    # NEW: Determinism utilities
│       ├── default.nix                 # Export determinism helpers
│       ├── fod.nix                     # FOD pattern helpers
│       │   ├── createDependencyFOD
│       │   ├── createDenoFOD
│       │   └── createNpmFOD
│       ├── environments.nix            # Deterministic env controls
│       │   ├── mkDeterministicNodeEnv
│       │   ├── mkDeterministicRustEnv
│       │   └── mkDeterministicGoEnv
│       └── validation.nix              # Determinism validation
│           └── validateBuildDeterminism
│
├── packaging.nix                       # LEGACY: Compatibility wrapper
│   # Re-exports from lib/packaging/ for backward compatibility
│   # Will be deprecated after migration period
│
├── atproto.nix                         # LEGACY: Keep as-is
└── fetch-tangled.nix                   # LEGACY: Keep as-is
```

---

## Module Responsibilities

### `/shared` - Cross-cutting concerns

**environments.nix**:
```nix
{
  standardRustEnv = { ... };           # Rust-specific
  standardNodeEnv = { ... };           # Node-specific
  standardGoEnv = { ... };             # Go-specific
  standardDenoEnv = { ... };           # Deno-specific
}
```

**inputs.nix**:
```nix
{
  standardRustInputs = { ... };
  standardNodeInputs = { ... };
  standardGoInputs = { ... };
  standardDenoInputs = { ... };
}
```

**utils.nix**:
```nix
{
  validatePackageConfig = { ... };
  mergeMeta = { ... };
  applyOrgMetadata = { ... };
}
```

**validation.nix**:
```nix
{
  validateHash = { ... };              # Ensure real hash (not fakeHash)
  validateVersion = { ... };
  validateRevision = { ... };          # Ensure pinned (not "main")
}
```

### `/rust/crane.nix` - Rust with Crane

```nix
{
  buildRustAtprotoPackage = { ... };   # Single package
  buildRustWorkspace = { ... };        # Workspace with members
  buildRustService = { ... };          # Service with systemd config
}
```

### `/nodejs/npm.nix` - npm package manager

```nix
{
  buildNpmPackage = { ... };           # Existing npm builder
  buildNpmWithFOD = { ... };           # NEW: Offline npm
}
```

### `/nodejs/pnpm.nix` - pnpm workspaces

```nix
{
  buildPnpmWorkspace = { ... };        # Existing pnpm
  buildPnpmWorkspaceWithFOD = { ... }; # NEW: Offline pnpm
}
```

### `/nodejs/bundlers/vite.nix` - Vite-specific patterns

```nix
{
  mkDeterministicViteConfig = { ... };      # Patch vite.config.ts
  viteDeterminismEnv = { ... };             # Env vars for Vite
  buildWithViteOffline = { ... };           # Vite + FOD pattern
}
```

### `/nodejs/bundlers/esbuild.nix` - esbuild patterns

```nix
{
  esbuildDeterminismEnv = { ... };
  buildWithEsbuildOffline = { ... };
}
```

### `/deno/deno-vite.nix` - Deno calling Vite

```nix
{
  buildDenoWithVite = { ... };         # NEW: Deno task → npm:vite
  buildDenoWithViteOffline = { ... };  # NEW: With FOD caching
}
```

### `/deno/deno-external.nix` - Generic Deno + external builder

```nix
{
  buildDenoWithExternalBuilder = { ... };  # Generic pattern
}
```

### `/determinism/fod.nix` - FOD helpers

```nix
{
  createDependencyFOD = { language, src, ... };      # Generic FOD
  createDenoFOD = { src, denoLock, ... };            # Deno-specific
  createNpmFOD = { src, packageManager, ... };       # npm-specific
  createPnpmFOD = { src, workspaces, ... };          # pnpm-specific
}
```

### `/determinism/environments.nix` - Determinism controls

```nix
{
  mkDeterministicNodeEnv = { bundler ? "vite", ... };
  viteDeterminismFlags = { ... };      # NODE_ENV=production, etc.
  esbuildDeterminismFlags = { ... };
}
```

---

## Migration Strategy

### Phase 1: Create modular structure (Week 1)
- [ ] Create `/lib/packaging/` directory
- [ ] Create all module files with functions copied from current lib/packaging.nix
- [ ] Create `/lib/packaging/default.nix` that re-exports everything
- [ ] Keep old `lib/packaging.nix` as wrapper for backward compatibility

### Phase 2: Organize and refactor (Week 2)
- [ ] Move shared code to `/lib/packaging/shared/`
- [ ] Move language-specific code to language directories
- [ ] Extract bundler-specific patterns
- [ ] Add new FOD and determinism modules

### Phase 3: Update imports (Week 3)
- [ ] Update all packages to use new paths (or keep using compatibility wrapper)
- [ ] Add deprecation warnings to old imports
- [ ] Document migration for contributors

### Phase 4: Documentation and best practices (Week 4)
- [ ] Document each module with examples
- [ ] Create "Adding a new build tool" guide
- [ ] Update CLAUDE.md with new structure
- [ ] Create best practices per language/tool

### Phase 5: Deprecation and cleanup (Future)
- [ ] After all packages migrated, deprecate `lib/packaging.nix`
- [ ] Remove wrapper, make new structure canonical
- [ ] Archive old version in git history

---

## Best Practices Per Language/Tool

### ✅ Rust (via Crane)

**File**: `lib/packaging/rust/crane.nix`

**Best Practices**:
1. Use `buildRustWorkspace` for monorepos, `buildRustAtprotoPackage` for single packages
2. Always pin exact versions (no `rev = "main"`)
3. Use `craneLib.buildDepsOnly` for dependency caching
4. Reuse `cargoArtifacts` across workspace members
5. Pin hashes (no `lib.fakeHash`)

**Example**:
```nix
buildRustWorkspace {
  owner = "example";
  repo = "project";
  rev = "abc123...";  # Pinned commit
  sha256 = "sha256-...";  # Real hash
  members = [ "package1" "package2" ];
}
```

### ✅ Node.js + npm

**File**: `lib/packaging/nodejs/npm.nix`

**Best Practices**:
1. Use `buildNpmPackage` for simple packages
2. Use `buildNpmWithFOD` for deterministic offline builds
3. Pin `npmDepsHash` (no `lib.fakeHash`)
4. Validate package.json exists before build
5. Use `NODE_ENV=production` for production builds

**Example**:
```nix
buildNpmWithFOD {
  src = fetchFromGitHub { ... };
  npmDepsHash = "sha256-...";  # Real hash
  determinism = true;
}
```

### ✅ Node.js + pnpm Workspaces

**File**: `lib/packaging/nodejs/pnpm.nix`

**Best Practices**:
1. Use `buildPnpmWorkspaceWithFOD` (NEW)
2. Pre-cache dependencies with FOD
3. Freeze lockfile (`--frozen-lockfile`)
4. Handle catalog dependencies properly
5. Validate pnpm-workspace.yaml structure

**Example**:
```nix
buildPnpmWorkspaceWithFOD {
  src = fetchFromGitHub { ... };
  workspaces = [ "packages/app" "packages/lib" ];
  pnpmFODHash = "sha256-...";  # Real hash
}
```

### ⚠️ Node.js + Bundlers (Vite, esbuild)

**File**: `lib/packaging/nodejs/bundlers/{vite,esbuild}.nix`

**Critical**: Bundlers generate non-deterministic output!

**Best Practices**:
1. ALWAYS use FOD for offline caching before bundler runs
2. Control output with environment variables:
   - `NODE_ENV=production`
   - `VITE_INLINE_ASSETS_THRESHOLD=0`
   - `CI=true` (some bundlers behave differently)
3. Avoid dynamic chunk naming
4. Disable source maps in production
5. Test determinism: build twice, compare outputs

**Example**:
```nix
buildWithViteOffline {
  src = fetchFromGitHub { ... };
  npmFODHash = "sha256-...";
  viteEnv = {
    NODE_ENV = "production";
    VITE_INLINE_ASSETS_THRESHOLD = "0";
  };
}
```

### ✅ Go (via buildGoModule)

**File**: `lib/packaging/go/buildGoModule.nix`

**Best Practices**:
1. Always pin `vendorHash` (no `lib.fakeHash`)
2. Use `proxyVendor = true` for offline builds
3. Include `go mod download` in preBuild
4. Test with `doCheck = true`
5. Use ldflags for version information

**Example**:
```nix
buildGoAtprotoModule {
  owner = "example";
  repo = "project";
  rev = "abc123...";
  sha256 = "sha256-...";
  vendorHash = "sha256-...";  # Real hash
}
```

### ⚠️ Deno (Pure)

**File**: `lib/packaging/deno/deno.nix`

**Best Practices**:
1. Use `buildDenoAppWithFOD` for offline dependency caching
2. Always pin `deno.lock` in repository
3. Pre-cache all entry points in FOD
4. Use `--cached-only` flag in build phase
5. Validate deno.json/deno.jsonc exists

**Example**:
```nix
buildDenoAppWithFOD {
  src = fetchFromGitHub { ... };
  denoLock = "deno.lock";
  denoFODHash = "sha256-...";
  entryPoints = [ "src/main.ts" ];
}
```

### ⚠️⚠️ Deno + External Builders (Vite, esbuild)

**File**: `lib/packaging/deno/deno-vite.nix`

**MOST COMPLEX**: Combines Deno's online caching with bundler nondeterminism

**Critical Practices**:
1. FOD for Deno imports FIRST
2. FOD for bundler dependencies SECOND
3. Control bundler output with env vars
4. Build OFFLINE using both FODs
5. Test determinism carefully

**Example**:
```nix
buildDenoWithViteOffline {
  src = fetchFromGitHub { ... };
  denoLock = "deno.lock";
  denoFODHash = "sha256-...";
  npmFODHash = "sha256-...";  # For npm:vite
  determinism = true;
}
```

**Pattern** (simplified):
```
1. denoCacheFOD = mkDenoFOD { ... }
2. npmCacheFOD = mkNpmFOD { ... }
3. build = stdenv.mkDerivation {
     preBuild = ''
       cp -R ${denoCacheFOD}/* $DENO_DIR/
       cp -R ${npmCacheFOD}/node_modules .
       deno task build --cached-only  # Offline
     '';
   }
```

---

## Documentation Per Module

Each module should have:

1. **README-style header** in the .nix file
   ```nix
   # Deno + Vite builds
   #
   # This module provides helpers for building Deno applications that
   # call out to Vite (npm:vite) during the build process.
   #
   # Key challenge: Deno caching + Vite determinism + offline build
   #
   # Pattern: denoCacheFOD → npmCacheFOD → offline build
   #
   # See docs/JAVASCRIPT_DENO_BUILDS.md for detailed explanation
   #
   # Example:
   #   buildDenoWithViteOffline {
   #     src = fetchFromGitHub { ... };
   #     denoFODHash = "sha256-...";
   #     npmFODHash = "sha256-...";
   #   }
   ```

2. **Inline examples** showing correct usage
   ```nix
   # Correct: Use FOD, offline build
   buildDenoWithViteOffline { ... }

   # Wrong: No FOD, online build, nondeterministic
   # buildDenoApp { ... }  # ❌ Don't use
   ```

3. **Links to external documentation**
   ```nix
   # See also:
   # - docs/JAVASCRIPT_DENO_BUILDS.md (detailed guide)
   # - docs/MODULAR_PACKAGING_PLAN.md (architecture)
   # - CLAUDE.md (project guidelines)
   ```

---

## Adding a New Build Tool

### Example: Add support for `esbuild`

**Step 1**: Create `/lib/packaging/nodejs/bundlers/esbuild.nix`
```nix
# esbuild bundler support for Node.js projects
#
# Provides deterministic, offline builds using FOD pattern
{ lib, pkgs, ... }:

{
  esbuildDeterminismEnv = { ... };
  buildWithEsbuildOffline = { ... };
}
```

**Step 2**: Update `/lib/packaging/nodejs/bundlers/default.nix`
```nix
{
  vite = import ./vite.nix { ... };
  esbuild = import ./esbuild.nix { ... };  # NEW
  webpack = import ./webpack.nix { ... };
}
```

**Step 3**: Update `/lib/packaging/nodejs/default.nix`
```nix
bundlers = import ./bundlers { ... };
```

**Step 4**: Update `/lib/packaging/default.nix`
```nix
nodejs.bundlers.esbuild.buildWithEsbuildOffline
```

**Step 5**: Document in `/docs/MODULAR_PACKAGING_PLAN.md`
- Add esbuild to bundler list
- Update best practices section
- Add example for esbuild

**Step 6**: Create example package using it

---

## File Size and Complexity Reduction

**Current**:
- `lib/packaging.nix` = 944 lines (monolithic)
- Hard to find specific language/tool
- Difficult to understand relationships

**Proposed**:
```
lib/packaging/
├── shared/ = ~150 lines (reusable, simple)
├── rust/ = ~150 lines (crane-focused)
├── nodejs/ = ~250 lines (npm + pnpm + bundlers)
├── go/ = ~100 lines (simple wrapper)
├── deno/ = ~200 lines (pure + external builders)
├── multi-language/ = ~100 lines (coordination)
├── determinism/ = ~200 lines (FOD, validation)
└── default.nix = ~100 lines (re-exports)
---
Total: ~1,050 lines (more, but MUCH better organized)
```

**Benefits**:
- ✅ Easier to find what you need (navigate by language)
- ✅ Easier to understand relationships (each file is self-contained)
- ✅ Easier to add tools (create new bundler file)
- ✅ Easier to maintain (changes isolated to relevant module)
- ✅ Easier to test (test individual modules)

---

## Testing Strategy

### Unit Tests
```bash
# Test individual modules
nix eval lib/packaging/rust/crane.nix
nix eval lib/packaging/nodejs/bundlers/vite.nix
nix eval lib/packaging/deno/deno-vite.nix
```

### Integration Tests
```bash
# Test using new structure
nix build .#slices-network-slices
nix build .#pds-dash
nix build .#frontpage
```

### Determinism Tests
```bash
# Build twice, verify identical
nix build .#app -o result1
nix build .#app -o result2
diff -r result1 result2  # Should be empty
```

---

## Backward Compatibility

**During migration**:
```nix
# lib/packaging.nix (wrapper for compatibility)
{
  # Re-export from new structure
  inherit (import ./packaging { inherit lib pkgs craneLib; })
    buildRustAtprotoPackage
    buildPnpmWorkspace
    buildDenoApp
    ...
}
```

**Timeline**:
- Month 1: New structure exists, old wrapper works
- Months 2-3: Migrate packages to new paths
- Month 4: Deprecate wrapper with warnings
- Month 5+: Remove wrapper, new structure is canonical

---

## Success Criteria

✅ All language/tool patterns are discoverable
✅ Each module is <300 lines (easy to understand)
✅ Clear best practices documented per tool
✅ Easy to add new bundlers/tools
✅ All packages build successfully with new structure
✅ No `lib.fakeHash` in any module
✅ All FOD patterns use real hashes
✅ Determinism tests pass for JS/Deno packages

---

## Open Questions for Discussion

1. **Should we split multi-language coordination to separate module?**
   → Yes (proposed above)

2. **Should old `lib/packaging.nix` be kept indefinitely or deprecated?**
   → Keep for 1-2 months, then deprecate with warnings

3. **Should bundler helpers be in `/nodejs/bundlers/` or separate?**
   → In language-specific folder (Deno also uses bundlers)

4. **Should we add pnpm, yarn, bun as sibling modules?**
   → Yes, pattern is: `/nodejs/{npm,pnpm,yarn,bun}.nix`

5. **How do we handle language-agnostic tools (bundlers)?**
   → Create `/bundlers/` at top level? Or language-specific?
   → Recommendation: Language-specific (Deno+Vite differs from Node+Vite)

---

## Next Steps

1. Approval of directory structure
2. Start Phase 1: Create `/lib/packaging/` skeleton
3. Move functions incrementally, test after each move
4. Update documentation as structure solidifies
5. Roll out to packages gradually

---

**Timeline**: 4 weeks (1 week per phase)
**Effort**: ~25-30 hours
**Risk**: Low (backward compatible, incremental)
**Benefit**: HIGH (much better maintainability and extensibility)
