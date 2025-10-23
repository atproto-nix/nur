# Cachix Binary Cache Setup

This document describes how the Cachix binary cache is configured for the ATProto NUR.

## Overview

**Cache Name:** `atproto`
**Public URL:** https://atproto.cachix.org
**Public Key:** `atproto.cachix.org-1:mgH0q9dt3ZI9puHEfIGDnkRBfT80I3vfEh4Wda2B0rk=`

## What is Cachix?

Cachix provides binary caches for Nix packages, allowing users to download pre-built binaries instead of building from source. This dramatically speeds up package installation.

## User Setup

Users can enable the Cachix cache in three ways:

### 1. Using the Cachix CLI (Recommended)

```bash
# Install Cachix
nix-env -iA cachix -f https://cachix.org/api/v1/install

# Enable the atproto cache
cachix use atproto
```

This automatically configures the substituter and public key.

### 2. NixOS Configuration

Add to `/etc/nixos/configuration.nix`:

```nix
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://atproto.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "atproto.cachix.org-1:mgH0q9dt3ZI9puHEfIGDnkRBfT80I3vfEh4Wda2B0rk="
    ];
  };
}
```

Then rebuild: `sudo nixos-rebuild switch`

### 3. Non-NixOS Configuration

Add to `~/.config/nix/nix.conf`:

```
substituters = https://cache.nixos.org https://atproto.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= atproto.cachix.org-1:mgH0q9dt3ZI9puHEfIGDnkRBfT80I3vfEh4Wda2B0rk=
```

Restart the Nix daemon: `sudo systemctl restart nix-daemon`

## CI/CD Integration

The GitHub Actions workflow (`.github/workflows/build.yml`) automatically pushes built packages to Cachix.

### Setup Steps (One-Time)

1. **Generate Auth Token on Cachix:**
   - Go to https://app.cachix.org/cache/atproto
   - Navigate to Settings → Auth tokens
   - Create a new auth token (or use existing signing key)

2. **Add GitHub Secret:**
   - Go to your GitHub repository settings
   - Navigate to Settings → Secrets and variables → Actions
   - Add a new repository secret:
     - **Name:** `CACHIX_AUTH_TOKEN` (or `CACHIX_SIGNING_KEY`)
     - **Value:** The auth token from Cachix

3. **Workflow Configuration:**
   The workflow is already configured in `.github/workflows/build.yml`:

   ```yaml
   cachixName:
     - atproto

   - name: Setup cachix
     uses: cachix/cachix-action@v16
     if: ${{ matrix.cachixName != '<YOUR_CACHIX_NAME>' }}
     with:
       name: ${{ matrix.cachixName }}
       authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
   ```

### How It Works

1. GitHub Actions builds all packages on each push/PR
2. Successfully built packages are automatically pushed to Cachix
3. Users can then download pre-built binaries instead of building from source

## Manual Push to Cachix

If you want to manually push packages to Cachix:

```bash
# Build and push a single package
nix build .#microcosm-constellation
cachix push atproto ./result

# Build and push all packages
nix build .#packages.x86_64-linux --all
cachix push atproto ./result*

# Or use a one-liner
nix build .#microcosm-constellation | cachix push atproto
```

## Package Coverage

Currently **47/50 packages** (94%) have pre-built binaries available via Cachix.

**Packages without binaries** (3 remaining):
1. `likeandscribe-frontpage` - Needs npmDepsHash (pnpm workspace issue)
2. `atbackup-pages-dev-atbackup` - Blocked by libsoup2 security vulnerability
3. Any packages that failed to build in CI

See `PINNING_NEEDED.md` for details on packages needing fixes.

## Cache Statistics

You can view cache statistics at:
- **Dashboard:** https://app.cachix.org/cache/atproto
- **Public page:** https://atproto.cachix.org

## Benefits

**For Users:**
- Faster installation (no compilation needed)
- Reduced disk space usage
- Consistent builds across machines

**For CI/CD:**
- Faster CI runs (reuse cached artifacts)
- Reduced GitHub Actions minutes
- Better build reproducibility

**For the Ecosystem:**
- Lower barrier to entry
- Easier testing and development
- Better user experience

## Troubleshooting

### Cache Not Being Used

If Nix is still building from source:

1. **Verify cache is configured:**
   ```bash
   nix show-config | grep substituters
   nix show-config | grep trusted-public-keys
   ```

2. **Check if package is in cache:**
   ```bash
   nix path-info --store https://atproto.cachix.org .#microcosm-constellation
   ```

3. **Force use of substituters:**
   ```bash
   nix build .#microcosm-constellation --option substitute true
   ```

### Permission Denied

If you get permission errors:

```bash
# For NixOS: Add your user to trusted-users
nix.settings.trusted-users = [ "root" "your-username" ];

# For non-NixOS: Edit /etc/nix/nix.conf
trusted-users = root your-username
```

Then restart the Nix daemon.

## Security

- **Public key verification:** All downloads are verified using the public key
- **HTTPS:** All communication uses encrypted HTTPS
- **Reproducible builds:** Packages should build identically from source
- **No secrets in public logs:** Auth tokens are GitHub secrets, never logged

## Maintenance

The binary cache is maintained automatically by:
- GitHub Actions on every push to main
- Nightly rebuild workflow (2:51 UTC daily)
- Manual pushes by maintainers when needed

## Resources

- [Cachix Documentation](https://docs.cachix.org/)
- [Nix Manual - Substituters](https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-substituters)
- [GitHub Actions Cachix Action](https://github.com/cachix/cachix-action)

## Questions?

- Check the [Cachix FAQ](https://docs.cachix.org/faq)
- Ask in NixOS Discourse
- Open an issue on this repository
