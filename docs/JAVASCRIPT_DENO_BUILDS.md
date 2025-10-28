# JavaScript and Deno Build Patterns

This guide addresses nondeterminism issues when packaging JavaScript/TypeScript projects that use external build tools (Vite, esbuild, etc.) alongside Deno.

## Problem Statement

When building Deno projects that call out to JavaScript bundlers (like `deno task build` → Vite), nondeterminism often occurs because:

1. **Online dependency resolution** - npm/deno modules pulled at build time without hashing
2. **Non-deterministic bundlers** - Vite, esbuild generate different output hashes per run
3. **Missing environment controls** - No seed/flags to ensure reproducible output
4. **No offline caching** - Builders can't run offline, pulling from CDN each time

## Current Issues (October 2025)

### Critical Nondeterminism Cases

**pds-dash** (`pkgs/witchcraft-systems/pds-dash.nix`)
- Uses `deno task build` → calls Vite
- Vite generates non-deterministic chunk hashes
- No source map/output control

**slices** (`pkgs/slices-network/slices.nix`)
- `deno task codegen:frontend` unknown builder behavior
- `deno compile --allow-all` pulls dependencies online
- No FOD for dependency caching

**frontpage** (`pkgs/likeandscribe/frontpage.nix`)
- pnpm monorepo with 6 Node.js + 3 Rust packages
- Uses `lib.fakeHash` instead of real npmDepsHash
- Likely calls Vite/bundler in `pnpm build`

## Solution: Fixed-Output Derivation (FOD) Pattern

The key to deterministic builds with external JavaScript builders is **caching dependencies in a FOD before the build runs**.

### Pattern Structure

```nix
{
  # Step 1: FOD to cache all Deno/npm dependencies
  denoCacheFOD = pkgs.runCommand "app-deno-cache" {
    outputHashMode = "recursive";
    outputHash = "sha256-...";  # REAL hash, not fakeHash
    nativeBuildInputs = [ pkgs.deno ];
  } ''
    export DENO_DIR="$out"
    export DENO_NO_UPDATE_CHECK=1

    # Copy source and lock files
    cp -r ${src} ./src

    # Pre-cache all Deno imports
    if [ -f ./src/deno.lock ]; then
      deno cache --lock=./src/deno.lock --reload ./src/main.ts
    fi
  '';

  # Step 2: Main build with offline, deterministic builder
  app = pkgs.stdenv.mkDerivation {
    inherit src;

    buildPhase = ''
      # Use pre-cached dependencies
      export DENO_DIR="$PWD/.deno"
      cp -R ${denoCacheFOD}/* "$DENO_DIR"/

      # Force deterministic output from bundlers
      export NODE_ENV=production
      export VITE_INLINE_ASSETS_THRESHOLD=0

      # Now safe to call deno task build (offline)
      deno task --quiet build
    '';
  };
}
```

## Language-Specific Patterns

### Pure Deno (No External Builders)

**Simple case**: Just use FOD for Deno cache, no special handling needed.

```nix
denoCacheFOD = pkgs.runCommand "app-deno-cache" {
  outputHashMode = "recursive";
  outputHash = "sha256-...";
  nativeBuildInputs = [ pkgs.deno ];
} ''
  export DENO_DIR="$out"
  deno cache --lock=deno.lock --reload src/main.ts
'';

app = pkgs.stdenv.mkDerivation {
  inherit src;
  nativeBuildInputs = [ pkgs.deno ];

  buildPhase = ''
    export DENO_DIR="$PWD/.deno"
    cp -R ${denoCacheFOD}/* "$DENO_DIR"/
    deno compile --allow-all --cached-only --output=app src/main.ts
  '';
};
```

### Deno + Vite (or other npm bundlers)

**Complex case**: Vite is non-deterministic. Need to control its output.

```nix
denoCacheFOD = pkgs.runCommand "app-deno-cache" {
  outputHashMode = "recursive";
  outputHash = "sha256-...";
  nativeBuildInputs = [ pkgs.deno ];
} ''
  export DENO_DIR="$out"
  cp -r ${src} ./src

  # Pre-cache Deno imports
  deno cache --lock=./src/deno.lock --reload ./src/frontend/main.ts

  # Also cache npm packages that deno task will invoke
  # (e.g., if deno task build calls vite)
  if [ -f "./src/package.json" ]; then
    # Deno caches npm:vite when it's invoked
    deno cache --lock=./src/deno.lock ./src/frontend/main.ts
  fi
'';

app = pkgs.stdenv.mkDerivation {
  inherit src;
  nativeBuildInputs = [ pkgs.deno ];
  buildInputs = [ pkgs.nodejs ];

  buildPhase = ''
    export DENO_DIR="$PWD/.deno"
    cp -R ${denoCacheFOD}/* "$DENO_DIR"/
    export DENO_CACHE_DIR="$DENO_DIR/cache"
    export DENO_NO_UPDATE_CHECK=1

    # Control Vite determinism
    cat > deno.json << 'EOF'
{
  "tasks": {
    "build": "deno run --allow-all --no-check npm:vite build -- --minify terser --emptyOutDir false"
  }
}
EOF

    # Offline build
    deno task build --cached-only
  '';
};
```

### npm/pnpm Monorepo with Deno

**Very complex**: Multiple packages, workspace structure, nested builders.

```nix
npmCacheFOD = pkgs.runCommand "monorepo-npm-cache" {
  outputHashMode = "recursive";
  outputHash = "sha256-...";
  nativeBuildInputs = [ pkgs.nodejs pkgs.nodePackages.pnpm ];
} ''
  cp -r ${src} .
  export PNPM_HOME="$PWD/.pnpm"

  # Lock all dependencies
  pnpm install --frozen-lockfile

  # Store in $out for reuse
  mkdir -p $out/.pnpm-store
  cp -r node_modules $out/
  cp -r .pnpm-store $out/
'';

app = pkgs.stdenv.mkDerivation {
  inherit src;
  nativeBuildInputs = with pkgs; [ nodejs nodePackages.pnpm deno ];

  buildPhase = ''
    export PNPM_HOME="$PWD/.pnpm"
    export PATH="$PNPM_HOME:$PATH"

    # Restore cached dependencies
    cp -r ${npmCacheFOD}/node_modules .
    cp -r ${npmCacheFOD}/.pnpm-store ./.pnpm-store

    # Deterministic env
    export NODE_ENV=production
    export VITE_INLINE_ASSETS_THRESHOLD=0

    # Build
    pnpm build --prod
  '';
};
```

## Calculating Hashes

### For Deno Cache FOD

```bash
# 1. Set outputHash to fakeHash temporarily
outputHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

# 2. Try to build
nix build .#app 2>&1 | grep "got:"
# Output: hash mismatch in file produced by fetcher, output hash should be ...

# 3. Copy the actual hash from error message
outputHash = "sha256-<actual-hash-from-error>";
```

### For npm Cache FOD

Same process - set to fakeHash, let build fail, copy actual hash.

```bash
# Try with fakeHash
nix build .#app 2>&1 | tail -20
# Look for: "hash mismatch in file produced by fetcher"
# Copy that hash value
```

## Avoiding Common Pitfalls

### ❌ DON'T: Use online builders directly

```nix
# BAD - Vite will be downloaded and executed online
buildPhase = ''
  deno task build  # Might pull vite from npm:// online
'';
```

### ✅ DO: Cache dependencies first

```nix
# GOOD - Vite is cached offline in denoCacheFOD
buildPhase = ''
  export DENO_DIR="$PWD/.deno"
  cp -R ${denoCacheFOD}/* "$DENO_DIR"/
  deno task build --cached-only
'';
```

### ❌ DON'T: Use lib.fakeHash for npm dependencies

```nix
# BAD - Will never build
buildNpmPackage {
  npmDepsHash = lib.fakeHash;
}
```

### ✅ DO: Calculate real hashes

```nix
# GOOD - Real hash ensures reproducibility
buildNpmPackage {
  npmDepsHash = "sha256-<calculated>";
}
```

### ❌ DON'T: Skip determinism controls

```nix
# BAD - Vite output will differ per build
buildPhase = ''
  pnpm build  # No env vars controlling output
'';
```

### ✅ DO: Control builder output

```nix
# GOOD - Vite produces deterministic output
buildPhase = ''
  export NODE_ENV=production
  export VITE_INLINE_ASSETS_THRESHOLD=0
  pnpm build --prod
'';
```

## Troubleshooting

### Issue: "hash mismatch" on every build

**Cause**: FOD outputHash calculated incorrectly or dependencies changed.

**Fix**:
```bash
# 1. Reset to fakeHash
outputHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

# 2. Clean and rebuild
nix build .#app --no-link 2>&1 | grep "got:"

# 3. Copy new hash
outputHash = "sha256-<new-hash>";
```

### Issue: "deno cache --cached-only" fails offline

**Cause**: Dependencies not fully pre-cached in FOD.

**Fix**: In FOD, add all entry points:
```bash
deno cache --lock=deno.lock --reload src/main.ts
deno cache --lock=deno.lock --reload src/build.ts
deno cache --lock=deno.lock --reload tools/codegen.ts
```

### Issue: Vite still generates different chunk hashes

**Cause**: Vite configuration or environment variables affecting output.

**Fix**: Control all sources of variation:
```bash
export NODE_ENV=production
export VITE_INLINE_ASSETS_THRESHOLD=0
export CI=true  # Some builders use this flag
export TZ=UTC   # Ensure consistent timestamps

# Consider patching vite.config.ts if needed:
patchShebangs() {
  # Some projects need build script patching
}
```

## Testing Determinism

After implementing FOD pattern:

```bash
# Build twice, hashes should match
nix build .#app --no-link -o result1
nix build .#app --no-link -o result2
diff -r result1 result2  # Should be empty (or use diffoscope)

# Check for timestamps/non-determinism
nix build .#app --no-link -o result
find result -exec stat {} \; | grep Modify  # All should be epoch
```

## References

- [Nix Manual: Fixed-Output Derivations](https://nixos.org/manual/nix/stable/glossary#gloss-fixed-output-derivation)
- [Deno: deno cache](https://docs.deno.com/runtime/manual/basics/modules/)
- [Vite: Deterministic Builds](https://vitejs.dev/)
- [Reproducible Builds](https://reproducible-builds.org/)

## Related Issues

See `PACKAGE_FIXES_PLAN.md` for specific packages needing determinism fixes:
- pds-dash: Vite nondeterminism
- slices: Deno codegen builder
- frontpage: pnpm workspace bundling
