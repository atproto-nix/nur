# Packages Needing Version Pinning

The following packages have unpinned versions (`rev = "main"`) or placeholder hashes (`lib.fakeHash`) that need to be fixed for reproducible builds.

## Files Requiring Updates

### Tangled Dev Packages (3 files)
- `pkgs/tangled-dev/spindle.nix` - rev="main", fakeHash
- `pkgs/tangled-dev/appview.nix` - rev="main", fakeHash
- `pkgs/tangled-dev/knot.nix` - rev="main", fakeHash

**Repo**: https://github.com/tangled-dev/tangled-core

### Other Packages

- `pkgs/witchcraft-systems/pds-dash.nix` - rev="main", fakeHash
  - **Repo**: https://github.com/witchcraft-systems/pds-dash

- `pkgs/hyperlink-academy/leaflet.nix` - rev="main"
  - **Repo**: https://github.com/hyperlink-academy/leaflet

- `pkgs/blacksky/rsky/default.nix` - contains TODO comments about pinning
  - **Repo**: https://github.com/blacksky-algorithms/rsky

- `pkgs/atproto/frontpage.nix` - rev="main", fakeHash
  - **Repo**: https://github.com/bluesky-social/frontpage

- `pkgs/slices-network/slices.nix` - rev="main"
  - **Repo**: https://github.com/slices-network/slices

- `pkgs/atbackup-pages-dev/atbackup.nix` - fakeHash only
  - **Repo**: https://github.com/atbackup-pages-dev/atbackup

## How to Fix

For each package:

1. **Find latest commit**:
   ```bash
   git ls-remote https://github.com/OWNER/REPO HEAD
   ```

2. **Update the .nix file**:
   - Replace `rev = "main"` with actual commit hash
   - Replace `hash = lib.fakeHash` with actual hash

3. **Calculate the hash**:
   ```bash
   # Try to build - it will fail with correct hash
   nix build .#PACKAGE_NAME 2>&1 | grep "got:"

   # Or use nix-prefetch
   nix-prefetch-url --unpack https://github.com/OWNER/REPO/archive/COMMIT.tar.gz
   ```

4. **For Go modules** (spindle, appview, knot):
   ```bash
   # Build will fail and show correct vendorHash
   nix build .#tangled-dev-spindle 2>&1 | grep "got:"
   ```

## Priority

**High Priority** (blocks reproducibility):
- All tangled-dev packages (if you use them)
- atproto/frontpage (if you use it)
- atbackup (has fakeHash)

**Medium Priority**:
- witchcraft-systems/pds-dash
- hyperlink-academy/leaflet
- slices-network/slices

**Low Priority**:
- blacksky/rsky (just has TODO comments, might already work)

## Notes

- Some packages may already build successfully despite using `rev = "main"` if they don't have fakeHash
- Packages with only `rev = "main"` but real hashes will build but aren't reproducible
- Packages with `lib.fakeHash` will fail to build immediately

## Current Status

✅ Flake evaluates successfully (48 packages)
⚠️  8 packages need pinning for full reproducibility
❌ ~6 packages will fail to build due to fakeHash
