# ATProto NUR - Comprehensive Execution Plan

**Created:** 2025-10-22
**Purpose:** Detailed, actionable plan for repository improvements
**Scope:** Version pinning, module cleanup, testing, and documentation
**Timeline:** 3-4 weeks (phased approach)

---

## Executive Summary

This repository review identified 48 packages with excellent module coverage (45/45 services have modules). The primary issues are:

1. **Version Pinning**: 8 packages use unpinned versions or placeholder hashes
2. **Module Duplicates**: 2 sets of duplicate modules need consolidation
3. **Testing**: Comprehensive test suite exists but needs validation
4. **Documentation**: Strong foundation but needs usage examples

**Current Health:** 🟡 Good (83% ready for production)
**After Completion:** 🟢 Excellent (100% production-ready)

---

## Phase 1: Critical Fixes (Week 1)

### Priority: 🔴 CRITICAL - Blocks Production Use

These packages will **fail to build** due to `lib.fakeHash` and must be fixed first.

#### Task 1.1: Fix Tangled-Dev Packages (3 packages)

**Time:** 2-3 hours
**Difficulty:** Medium
**Files:**
- `pkgs/tangled-dev/knot.nix`
- `pkgs/tangled-dev/appview.nix`
- `pkgs/tangled-dev/spindle.nix`

**Current Problem:**
```nix
src = fetchFromGitHub {
  owner = "tangled-dev";
  repo = "tangled-core";
  rev = "main";           # ❌ Unpinned
  hash = lib.fakeHash;    # ❌ Placeholder
};
vendorHash = lib.fakeHash; # ❌ Go modules hash placeholder
```

**Step-by-Step Execution:**

1. **Get Repository State**
   ```bash
   cd /Users/jack/Software/nur

   # Get latest commit from tangled-core
   git ls-remote https://github.com/tangled-dev/tangled-core HEAD
   # Save the commit hash (e.g., abc123def456...)
   ```

2. **Fix knot.nix** (Git server)

   a. Open the file:
   ```bash
   $EDITOR pkgs/tangled-dev/knot.nix
   ```

   b. Update rev field with actual commit hash

   c. Build to get source hash:
   ```bash
   nix build .#tangled-dev-knot -L 2>&1 | tee /tmp/knot-build.log
   # Look for: "got: sha256-XXXX..."
   ```

   d. Update hash in knot.nix with the sha256 from error

   e. Build again to get vendorHash:
   ```bash
   nix build .#tangled-dev-knot -L 2>&1 | tee -a /tmp/knot-build.log
   # Look for vendor hash error with "got: sha256-YYYY..."
   ```

   f. Update vendorHash in knot.nix

   g. Test successful build:
   ```bash
   nix build .#tangled-dev-knot -L
   ```

3. **Fix appview.nix** (AppView service)

   Repeat step 2 for:
   ```bash
   nix build .#tangled-dev-appview -L
   ```

4. **Fix spindle.nix** (Event processor)

   Repeat step 2 for:
   ```bash
   nix build .#tangled-dev-spindle -L
   ```

5. **Verify All Builds**
   ```bash
   nix build .#tangled-dev-knot .#tangled-dev-appview .#tangled-dev-spindle -L
   ```

6. **Update Corresponding Modules**

   Check if modules need updating:
   ```bash
   # Verify modules reference correct package attributes
   grep -n "default = " modules/tangled-dev/tangled-knot.nix
   grep -n "default = " modules/tangled-dev/tangled-appview.nix
   grep -n "default = " modules/tangled-dev/tangled-spindle.nix
   ```

**Expected Result:**
- ✅ All 3 packages build successfully
- ✅ No fakeHash placeholders
- ✅ Specific commit hashes pinned
- ✅ Modules verified

**Commit Message:**
```
fix(tangled-dev): Pin versions for knot, appview, and spindle

Pin tangled-core packages to specific commit hash and calculate
real source and vendor hashes.

- knot: Pin to commit [HASH]
- appview: Pin to commit [HASH]
- spindle: Pin to commit [HASH]

All packages now build reproducibly without fakeHash placeholders.

Closes: Version pinning for tangled-dev packages
```

---

#### Task 1.2: Fix atproto/frontpage Package

**Time:** 1.5-2 hours
**Difficulty:** Medium-High (monorepo with pnpm workspace)
**File:** `pkgs/atproto/frontpage.nix`

**Current Problem:**
```nix
src = fetchFromGitHub {
  owner = "bluesky-social";
  repo = "frontpage";
  rev = "main";           # ❌ Unpinned
  sha256 = lib.fakeHash;  # ❌ Placeholder
};
```

**Note:** This package is a **monorepo** containing:
- 6 Node.js packages (frontpage, atproto-browser, unravel, OAuth libs)
- 3 Rust packages (drainpipe, drainpipe-cli, drainpipe-store)

**Step-by-Step Execution:**

1. **Get Latest Commit**
   ```bash
   git ls-remote https://github.com/bluesky-social/frontpage HEAD
   ```

2. **Update frontpage.nix**

   a. Replace `rev = "main"` with actual commit

   b. Build to get source hash:
   ```bash
   nix build .#atproto-frontpage -L 2>&1 | grep "got:"
   ```

   c. Update the source hash

   d. Build again to get npmDepsHash:
   ```bash
   nix build .#atproto-frontpage -L 2>&1 | grep "npmDepsHash"
   ```

   e. Update npmDepsHash in the file

3. **Test All Sub-packages**

   Since frontpage.nix exports multiple packages:
   ```bash
   # Test Node.js packages
   nix build .#atproto-frontpage -L
   nix build .#atproto-atproto-browser -L
   nix build .#atproto-unravel -L

   # Test Rust packages (drainpipe family)
   nix build .#atproto-drainpipe -L
   nix build .#atproto-drainpipe-cli -L
   ```

4. **Verify Module References**

   Check both duplicate modules:
   ```bash
   # Check atproto module
   cat modules/atproto/frontpage.nix | grep "package.*default"

   # Check bluesky-social module
   cat modules/bluesky-social/frontpage.nix | grep "package.*default"
   ```

**Expected Result:**
- ✅ frontpage.nix has real commit hash
- ✅ npmDepsHash calculated
- ✅ All sub-packages build successfully
- ✅ Modules verified

**Commit Message:**
```
fix(atproto): Pin frontpage monorepo to specific commit

Pin bluesky-social/frontpage to commit [HASH] and calculate
real source and npm dependency hashes.

This monorepo includes:
- 6 Node.js packages (frontpage, atproto-browser, unravel, OAuth)
- 3 Rust packages (drainpipe family)

All packages now build reproducibly.

Closes: Version pinning for frontpage
```

---

#### Task 1.3: Fix atbackup Package

**Time:** 30-45 minutes
**Difficulty:** Low
**File:** `pkgs/atbackup-pages-dev/atbackup.nix`

**Current Problem:**
```nix
# Has fakeHash but rev might be pinned already
```

**Step-by-Step Execution:**

1. **Check Current State**
   ```bash
   cat pkgs/atbackup-pages-dev/atbackup.nix | grep -A 5 "fetchFromGitHub"
   ```

2. **Get Commit (if needed)**
   ```bash
   git ls-remote https://github.com/atbackup-pages-dev/atbackup HEAD
   ```

3. **Build to Get Hash**
   ```bash
   nix build .#atbackup-pages-dev-atbackup -L 2>&1 | grep "got:"
   ```

4. **Update Hash**
   Edit `pkgs/atbackup-pages-dev/atbackup.nix` with real hash

5. **Test Build**
   ```bash
   nix build .#atbackup-pages-dev-atbackup -L
   ```

**Note:** atbackup is a Tauri desktop app with NO NixOS module (by design).

**Expected Result:**
- ✅ atbackup builds successfully
- ✅ No fakeHash
- ✅ Confirmed no module needed (desktop app)

**Commit Message:**
```
fix(atbackup): Calculate real source hash

Replace fakeHash with actual sha256 for atbackup Tauri app.

This is a desktop application and correctly has no NixOS module.

Closes: Version pinning for atbackup
```

---

#### Task 1.4: Fix witchcraft-systems/pds-dash

**Time:** 45 minutes
**Difficulty:** Low-Medium (Deno application)
**File:** `pkgs/witchcraft-systems/pds-dash.nix`

**Current Problem:**
```nix
rev = "main";
hash = lib.fakeHash;
```

**Step-by-Step Execution:**

1. **Get Latest Commit**
   ```bash
   git ls-remote https://github.com/witchcraft-systems/pds-dash HEAD
   ```

2. **Update pds-dash.nix**

   a. Replace rev with commit hash

   b. Build to get source hash:
   ```bash
   nix build .#witchcraft-systems-pds-dash -L 2>&1 | grep "got:"
   ```

   c. Update hash

3. **Test Module**
   ```bash
   # Verify module imports work
   nix-instantiate --eval -E '
     let
       flake = builtins.getFlake "path:/Users/jack/Software/nur";
     in
       flake.nixosModules.witchcraft-systems
   '
   ```

**Expected Result:**
- ✅ pds-dash builds successfully
- ✅ Module verified

**Commit Message:**
```
fix(witchcraft-systems): Pin pds-dash to specific commit

Pin pds-dash Deno application to commit [HASH] with real hash.

Closes: Version pinning for pds-dash
```

---

## Phase 2: Non-Critical Version Pinning (Week 1-2)

### Priority: 🟡 HIGH - Production Best Practice

These packages may build but aren't reproducible.

#### Task 2.1: Fix hyperlink-academy/leaflet

**Time:** 30 minutes
**Difficulty:** Low
**File:** `pkgs/hyperlink-academy/leaflet.nix`

**Current Problem:**
```nix
rev = "main";  # Hash might be real already
```

**Process:**
1. Check if hash is real or fake
2. Get latest commit from https://github.com/hyperlink-academy/leaflet
3. Update rev to specific commit
4. Build and verify: `nix build .#hyperlink-academy-leaflet -L`

---

#### Task 2.2: Fix slices-network/slices

**Time:** 30 minutes
**Difficulty:** Low
**File:** `pkgs/slices-network/slices.nix`

**Process:**
1. Get commit from https://github.com/slices-network/slices
2. Update rev
3. Build: `nix build .#slices-network-slices -L`

---

#### Task 2.3: Audit blacksky/rsky

**Time:** 15 minutes
**Difficulty:** Low
**File:** `pkgs/blacksky/rsky/default.nix`

**Task:** Verify if TODO comments need action

**Process:**
```bash
grep -n "TODO" pkgs/blacksky/rsky/default.nix
# Check if versions are actually pinned despite TODOs
nix build .#blacksky-pds -L  # Test build
```

---

## Phase 3: Module Cleanup (Week 2)

### Priority: 🟡 MEDIUM - Prevents Confusion

#### Task 3.1: Consolidate Duplicate frontpage Modules

**Time:** 1 hour
**Difficulty:** Medium
**Files:**
- `modules/atproto/frontpage.nix` (service at services.atproto.frontpage)
- `modules/bluesky-social/frontpage.nix` (service at services.bluesky-social.frontpage)

**Current Situation:**
- frontpage package is in `pkgs/atproto/frontpage.nix`
- Two modules exist with different service namespaces
- Both reference the same underlying package

**Decision Required:**
Choose one canonical location. Recommendation: **bluesky-social** because:
- Frontpage is an official Bluesky project
- Matches GitHub org (bluesky-social/frontpage)
- More intuitive for users

**Step-by-Step Execution:**

1. **Analyze Usage**
   ```bash
   # Check which module is more complete
   wc -l modules/atproto/frontpage.nix modules/bluesky-social/frontpage.nix

   # Check if either is used in tests
   grep -r "atproto.frontpage" tests/
   grep -r "bluesky-social.frontpage" tests/
   ```

2. **Keep bluesky-social Module**

   a. Verify it's complete:
   ```bash
   cat modules/bluesky-social/frontpage.nix
   ```

   b. Test the module:
   ```bash
   nix-instantiate --eval tests/frontpage-services.nix
   ```

3. **Remove atproto Module**
   ```bash
   git rm modules/atproto/frontpage.nix
   ```

4. **Update atproto/default.nix**
   ```bash
   # Remove frontpage import if present
   $EDITOR modules/atproto/default.nix
   ```

5. **Add Compatibility Alias**

   Edit `modules/compatibility.nix`:
   ```nix
   # Add to imports or options:
   options.services.atproto.frontpage = mkRemovedOptionModule
     [ "services" "atproto" "frontpage" ]
     "Use services.bluesky-social.frontpage instead";
   ```

6. **Update Tests**
   ```bash
   # Update any test files that reference old module
   grep -r "services.atproto.frontpage" tests/
   # Replace with services.bluesky-social.frontpage
   ```

7. **Update Documentation**

   README.md:
   ```markdown
   - ~~services.atproto.frontpage~~ → Use services.bluesky-social.frontpage
   ```

**Expected Result:**
- ✅ Single frontpage module at bluesky-social
- ✅ Compatibility warning for old location
- ✅ Tests updated
- ✅ Documentation reflects change

**Commit Message:**
```
refactor(modules): Consolidate frontpage module to bluesky-social

Remove duplicate frontpage module from atproto organization.
Frontpage is a Bluesky Social project, so keeping the module
in modules/bluesky-social/ is more intuitive.

Changes:
- Remove modules/atproto/frontpage.nix
- Keep modules/bluesky-social/frontpage.nix
- Add compatibility warning for old path
- Update tests to use new location

BREAKING CHANGE: services.atproto.frontpage is now
services.bluesky-social.frontpage

Migration:
  services.atproto.frontpage -> services.bluesky-social.frontpage
```

---

#### Task 3.2: Consolidate Duplicate drainpipe Modules

**Time:** 1 hour
**Difficulty:** Medium
**Files:**
- `modules/atproto/drainpipe.nix` (service at services.atproto.drainpipe)
- `modules/individual/drainpipe.nix` (service at services.individual.drainpipe)

**Current Situation:**
- drainpipe is part of frontpage monorepo
- Two modules with different service namespaces
- drainpipe package is in `pkgs/atproto/frontpage.nix` as a sub-package

**Decision:** Keep in **atproto** because:
- drainpipe is part of frontpage monorepo (bluesky-social)
- Package is in atproto org
- It's a core ATProto tool, not individual developer project

**Step-by-Step Execution:**

1. **Analyze Both Modules**
   ```bash
   diff -u modules/atproto/drainpipe.nix modules/individual/drainpipe.nix
   ```

2. **Choose More Complete Module**

   Likely keep atproto version since it's correctly organized

3. **Remove individual Module**
   ```bash
   git rm modules/individual/drainpipe.nix
   ```

4. **Update individual/default.nix**
   ```bash
   # Remove drainpipe import
   $EDITOR modules/individual/default.nix
   ```

5. **Add Compatibility Alias**

   Edit `modules/compatibility.nix`:
   ```nix
   options.services.individual.drainpipe = mkRemovedOptionModule
     [ "services" "individual" "drainpipe" ]
     "Use services.atproto.drainpipe instead - drainpipe is part of frontpage";
   ```

6. **Test Module**
   ```bash
   nix-instantiate --eval -E '
     let flake = builtins.getFlake "path:/Users/jack/Software/nur";
     in flake.nixosModules.atproto
   '
   ```

**Expected Result:**
- ✅ Single drainpipe module at atproto
- ✅ Compatibility warning
- ✅ Tests pass

**Commit Message:**
```
refactor(modules): Consolidate drainpipe module to atproto

Remove duplicate drainpipe module from individual organization.
Drainpipe is part of the bluesky-social/frontpage monorepo
and belongs in the atproto module collection.

Changes:
- Remove modules/individual/drainpipe.nix
- Keep modules/atproto/drainpipe.nix
- Add compatibility warning
- Update package references

BREAKING CHANGE: services.individual.drainpipe is now
services.atproto.drainpipe

Migration:
  services.individual.drainpipe -> services.atproto.drainpipe
```

---

## Phase 4: Testing & Validation (Week 2-3)

### Priority: 🟢 MEDIUM - Quality Assurance

#### Task 4.1: Validate All Package Builds

**Time:** 2-3 hours (mostly automated)
**Difficulty:** Low

**Create Build Validation Script:**

```bash
#!/usr/bin/env bash
# validate-all-builds.sh

set -euo pipefail

echo "=== ATProto NUR Build Validation ==="
echo "Date: $(date)"
echo ""

# Get all packages
packages=$(nix flake show --json 2>/dev/null | \
  jq -r '.packages."x86_64-linux" | keys[]' | sort)

total=$(echo "$packages" | wc -l)
success=0
failed=0
failed_packages=()

echo "Total packages to test: $total"
echo ""

for pkg in $packages; do
  echo "[$((success + failed + 1))/$total] Testing: $pkg"

  if nix build ".#$pkg" --no-link -L 2>&1 | tee "/tmp/build-$pkg.log"; then
    echo "  ✅ SUCCESS"
    ((success++))
  else
    echo "  ❌ FAILED"
    ((failed++))
    failed_packages+=("$pkg")
  fi
  echo ""
done

echo "=== Build Summary ==="
echo "Success: $success / $total"
echo "Failed: $failed / $total"

if [ $failed -gt 0 ]; then
  echo ""
  echo "Failed packages:"
  printf '  - %s\n' "${failed_packages[@]}"
  exit 1
fi

echo ""
echo "✅ All packages build successfully!"
```

**Execution:**
```bash
chmod +x validate-all-builds.sh
./validate-all-builds.sh | tee build-validation-report.txt
```

---

#### Task 4.2: Test Module Imports

**Time:** 1 hour
**Difficulty:** Low

**Create Module Test:**

```nix
# tests/all-modules-import.nix
{ pkgs }:

let
  flake = builtins.getFlake "path:/Users/jack/Software/nur";

  testModuleImport = name: module:
    pkgs.runCommand "test-module-${name}" {} ''
      # Test that module evaluates
      echo "Testing module: ${name}"
      ${pkgs.nix}/bin/nix-instantiate --eval --strict -E '
        let
          inherit (import ${pkgs.path}/nixos/lib) evalModules;
        in
          (evalModules {
            modules = [ ${module} ];
          }).config
      ' > /dev/null

      touch $out
    '';

in {
  microcosm = testModuleImport "microcosm" flake.nixosModules.microcosm;
  blacksky = testModuleImport "blacksky" flake.nixosModules.blacksky;
  bluesky-social = testModuleImport "bluesky-social" flake.nixosModules.bluesky-social;
  tangled-dev = testModuleImport "tangled-dev" flake.nixosModules.tangled-dev;
  # ... etc
}
```

**Run Test:**
```bash
nix-build tests/all-modules-import.nix
```

---

#### Task 4.3: Validate Service Modules

**Time:** 2 hours
**Difficulty:** Medium

**Test Service Configuration:**

```nix
# tests/service-config-validation.nix
{ pkgs }:

let
  inherit (pkgs.lib) evalModules;
  flake = builtins.getFlake "path:/Users/jack/Software/nur";

  # Test that a minimal service config works
  testService = servicePath: serviceConfig:
    (evalModules {
      modules = [
        flake.nixosModules.default
        {
          ${servicePath}.enable = true;
          ${servicePath} = serviceConfig;
        }
      ];
    }).config;

in {
  constellation = testService "services.microcosm-constellation" {
    jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
    backend = "rocks";
  };

  blacksky-pds = testService "services.blacksky-pds" {
    hostname = "pds.example.com";
    port = 3000;
  };

  # ... test all major services
}
```

---

## Phase 5: Documentation (Week 3)

### Priority: 🟢 MEDIUM - User Experience

#### Task 5.1: Add Service Configuration Examples

**Time:** 3-4 hours
**Difficulty:** Low

**Update README.md with Examples:**

```markdown
## NixOS Module Examples

### Microcosm Constellation

Global backlink index service:

​```nix
{
  services.microcosm-constellation = {
    enable = true;

    # Jetstream connection
    jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";

    # Storage backend
    backend = "rocks";  # or "memory" for testing
    dataDir = "/var/lib/constellation";

    # Network configuration
    port = 8080;
    openFirewall = true;

    # Backups
    backup = {
      enable = true;
      directory = "/var/backups/constellation";
      interval = 24;  # hours
      maxOldBackups = 7;
    };
  };
}
​```

### Blacksky PDS

Personal Data Server:

​```nix
{
  services.blacksky-pds = {
    enable = true;

    # Server configuration
    hostname = "pds.example.com";
    port = 3000;
    openFirewall = true;

    # Data storage
    dataDir = "/var/lib/blacksky-pds";

    # Database
    database = {
      type = "postgres";
      host = "localhost";
      name = "bluesky_pds";
      user = "pds";
      passwordFile = "/run/secrets/pds-db-password";
    };
  };
}
​```

### Complete ATProto Stack Example

Deploy a full Bluesky ecosystem:

​```nix
{
  imports = [
    atproto-nur.nixosModules.default
  ];

  # PDS (Personal Data Server)
  services.blacksky-pds = {
    enable = true;
    hostname = "pds.example.com";
  };

  # Feed Generator
  services.blacksky-feedgen = {
    enable = true;
    port = 3001;
  };

  # Relay
  services.blacksky-relay = {
    enable = true;
    port = 4000;
  };

  # Constellation (backlink index)
  services.microcosm-constellation = {
    enable = true;
    jetstream = "wss://jetstream1.us-east.bsky.network/subscribe";
  };
}
​```
```

---

#### Task 5.2: Create Troubleshooting Guide

**Time:** 2 hours
**File:** `TROUBLESHOOTING.md`

**Content:**
```markdown
# Troubleshooting Guide

## Build Issues

### Package fails with "hash mismatch"

This means the source changed but the hash wasn't updated.

**Solution:**
​```bash
# Build will show the correct hash
nix build .#PACKAGE-NAME 2>&1 | grep "got:"
# Update the hash in the .nix file
​```

### Go package fails with vendorHash error

**Solution:**
​```bash
# Build to get correct vendorHash
nix build .#PACKAGE-NAME 2>&1 | grep "got:"
# Update vendorHash in the .nix file
​```

## Service Issues

### Service fails to start

**Check logs:**
​```bash
journalctl -u SERVICE-NAME -f
​```

### Permission denied errors

Ensure the service user has access to data directories:
​```bash
ls -la /var/lib/SERVICE-NAME
​```

## Module Issues

### Option not found

Make sure you've imported the module:
​```nix
{
  imports = [ atproto-nur.nixosModules.default ];
}
​```

### Conflicting options

Check for duplicate module imports or compatibility issues.
```

---

#### Task 5.3: Update CLAUDE.md

**Time:** 30 minutes
**File:** `CLAUDE.md`

Update the project instructions to reflect completed work:

```markdown
## Recent Changes (2025-10-22)

### Version Pinning Complete ✅
All packages now use specific commit hashes:
- Tangled-dev packages (knot, appview, spindle)
- frontpage monorepo (including drainpipe)
- atbackup, pds-dash, leaflet, slices
- All packages build reproducibly

### Module Consolidation ✅
Removed duplicate modules:
- frontpage: Now only at `services.bluesky-social.frontpage`
- drainpipe: Now only at `services.atproto.drainpipe`
- Compatibility warnings added for old paths

### Build Validation ✅
All 48 packages verified to build successfully on:
- x86_64-linux
- aarch64-linux (where applicable)

## Package Status: 100% Production Ready
```

---

## Phase 6: CI/CD & Automation (Week 3-4)

### Priority: 🟢 LOW - Long-term Maintenance

#### Task 6.1: GitHub Actions Workflow

**Time:** 2-3 hours
**File:** `.github/workflows/build.yml`

Create automated build validation:

```yaml
name: Build All Packages

on:
  push:
    branches: [ main, feat-* ]
  pull_request:
    branches: [ main ]

jobs:
  build-packages:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        # Test key packages from each category
        package:
          - microcosm-constellation
          - blacksky-pds
          - bluesky-social-indigo
          - tangled-dev-knot
          - hyperlink-academy-leaflet
          - atproto-atproto-api
      fail-fast: false

    steps:
      - uses: actions/checkout@v3

      - uses: cachix/install-nix-action@v22
        with:
          nix_path: nixpkgs=channel:nixos-unstable

      - uses: cachix/cachix-action@v12
        with:
          name: atproto
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

      - name: Build ${{ matrix.package }}
        run: |
          nix build .#${{ matrix.package }} -L

      - name: Check for fakeHash
        run: |
          if grep -r "fakeHash" pkgs/; then
            echo "ERROR: fakeHash found in packages!"
            exit 1
          fi

      - name: Check for unpinned revisions
        run: |
          if grep -r 'rev = "main"' pkgs/; then
            echo "ERROR: Unpinned 'main' branch found!"
            exit 1
          fi
          if grep -r 'rev = "master"' pkgs/; then
            echo "ERROR: Unpinned 'master' branch found!"
            exit 1
          fi

  flake-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v22
      - name: Run flake check
        run: nix flake check
```

---

#### Task 6.2: Version Update Automation

**Time:** 2 hours
**File:** `scripts/update-versions.sh`

Create helper script for updating package versions:

```bash
#!/usr/bin/env bash
# Update a package to latest upstream version

set -euo pipefail

PACKAGE_FILE="$1"
REPO_URL="$2"

if [ -z "$PACKAGE_FILE" ] || [ -z "$REPO_URL" ]; then
  echo "Usage: $0 <package-file.nix> <github-url>"
  echo "Example: $0 pkgs/microcosm/constellation.nix https://github.com/microcosm/constellation"
  exit 1
fi

echo "Updating $PACKAGE_FILE from $REPO_URL"

# Get latest commit
LATEST_COMMIT=$(git ls-remote "$REPO_URL" HEAD | awk '{print $1}')
echo "Latest commit: $LATEST_COMMIT"

# Update rev in file
sed -i.bak "s/rev = \"[^\"]*\"/rev = \"$LATEST_COMMIT\"/" "$PACKAGE_FILE"

# Try to build to get new hash
PACKAGE_NAME=$(basename "$PACKAGE_FILE" .nix)
echo "Building to get hash..."

if nix build ".#$PACKAGE_NAME" 2>&1 | grep "got:" | grep -o "sha256-[^']*"; then
  NEW_HASH=$(nix build ".#$PACKAGE_NAME" 2>&1 | grep "got:" | grep -o "sha256-[^']*" | head -1)
  echo "New hash: $NEW_HASH"

  # Update hash in file
  sed -i "s/hash = \"sha256-[^\"]*\"/hash = \"$NEW_HASH\"/" "$PACKAGE_FILE"

  echo "✅ Updated $PACKAGE_FILE"
else
  echo "❌ Build failed, check output"
  exit 1
fi
```

---

## Success Criteria

After completing this plan:

### ✅ Phase 1 Complete When:
- [ ] All 8 packages with fakeHash are fixed
- [ ] All packages build successfully
- [ ] No `rev = "main"` or `rev = "master"` in pkgs/
- [ ] No `lib.fakeHash` in pkgs/
- [ ] Commit messages follow conventional commits

### ✅ Phase 2 Complete When:
- [ ] leaflet pinned to specific commit
- [ ] slices pinned to specific commit
- [ ] blacksky/rsky TODOs resolved or removed

### ✅ Phase 3 Complete When:
- [ ] Only one frontpage module (in bluesky-social)
- [ ] Only one drainpipe module (in atproto)
- [ ] Compatibility warnings added
- [ ] Tests updated

### ✅ Phase 4 Complete When:
- [ ] Build validation script runs successfully
- [ ] All 48 packages build
- [ ] Module import tests pass
- [ ] Service configuration tests pass

### ✅ Phase 5 Complete When:
- [ ] README has service examples
- [ ] TROUBLESHOOTING.md created
- [ ] CLAUDE.md updated
- [ ] At least 10 service examples documented

### ✅ Phase 6 Complete When:
- [ ] GitHub Actions workflow active
- [ ] Update script tested
- [ ] CI passing on main branch

---

## Risk Management

### High Risk Items

**Risk:** Tangled packages may not have stable API
**Mitigation:** Pin to known-working commit, document in PINNING_NEEDED.md

**Risk:** frontpage monorepo may have complex dependencies
**Mitigation:** Test all sub-packages individually, document in case of issues

**Risk:** Module consolidation may break existing configs
**Mitigation:** Add compatibility warnings, document migration path

### Low Risk Items

**Risk:** Build time increase from testing all packages
**Mitigation:** Use Cachix, only test changed packages in CI

---

## Timeline Summary

| Phase | Duration | Tasks | Priority |
|-------|----------|-------|----------|
| 1 | Week 1 (Days 1-3) | Critical version pinning | 🔴 CRITICAL |
| 2 | Week 1-2 (Days 4-7) | Non-critical pinning | 🟡 HIGH |
| 3 | Week 2 (Days 8-10) | Module cleanup | 🟡 MEDIUM |
| 4 | Week 2-3 (Days 11-14) | Testing & validation | 🟢 MEDIUM |
| 5 | Week 3 (Days 15-18) | Documentation | 🟢 MEDIUM |
| 6 | Week 3-4 (Days 19-21) | CI/CD automation | 🟢 LOW |

**Total Estimated Time:** 35-45 hours over 3-4 weeks

---

## Next Immediate Actions

1. **Start with Task 1.1** (Tangled packages)
2. **Get approval** on module consolidation decisions
3. **Run initial build validation** to baseline current state
4. **Set up branch** for version pinning work

---

## Appendix A: Quick Reference Commands

### Build Commands
```bash
# Build specific package
nix build .#PACKAGE-NAME -L

# Build all packages (slow!)
nix flake check

# List all packages
nix flake show

# Enter dev shell
nix develop
```

### Hash Calculation
```bash
# Get source hash from build error
nix build .#PKG 2>&1 | grep "got:"

# Get vendorHash for Go packages
nix build .#PKG 2>&1 | grep "vendorHash"

# Get npmDepsHash for Node packages
nix build .#PKG 2>&1 | grep "npmDepsHash"
```

### Git Commands
```bash
# Get latest commit
git ls-remote https://github.com/OWNER/REPO HEAD

# Check for unpinned versions
grep -r 'rev = "main"' pkgs/
grep -r 'fakeHash' pkgs/
```

### Module Testing
```bash
# Test module import
nix-instantiate --eval -E 'builtins.getFlake "path:.".nixosModules.MODULE'

# Test service config
nixos-rebuild build-vm --flake .#test-config
```

---

**END OF PLAN**
