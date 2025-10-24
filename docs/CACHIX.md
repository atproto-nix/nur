# Cachix Binary Cache - Complete Guide

This document describes the Cachix binary cache setup for the ATProto NUR, including user setup, CI/CD integration, and multi-language caching strategies.

## Overview

**Cache Name:** `atproto`
**Public URL:** https://atproto.cachix.org
**Public Key:** `atproto.cachix.org-1:mgH0q9dt3ZI9puHEfIGDnkRBfT80I3vfEh4Wda2B0rk=`

## What is Cachix?

Cachix provides binary caches for Nix packages, allowing users to download pre-built binaries instead of building from source. This dramatically speeds up package installation.

**Benefits:**
- **For Users:** Faster installation (seconds vs minutes/hours), reduced disk space, consistent builds
- **For CI/CD:** Faster CI runs, reduced GitHub Actions minutes, better reproducibility
- **For Ecosystem:** Lower barrier to entry, easier testing and development

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

## Multi-Language Caching

The ATProto NUR packages use 4 different languages, each with optimized caching strategies:

### Rust Packages (Crane + Cachix)

**Packages:** Microcosm services (constellation, spacedust, slingshot, etc.), Blacksky/rsky services

**Caching Strategy:**
```nix
# Crane builds dependencies once, reuses for all packages in workspace
cargoArtifacts = craneLib.buildDepsOnly {
  inherit src;
  # ... builds only Cargo.lock dependencies
};

# Each package reuses the artifacts
craneLib.buildPackage {
  inherit src cargoArtifacts;  # ← Reuses pre-built dependencies
  cargoExtraArgs = "--package ${packageName}";
};
```

**What gets cached:**
1. **Local (Crane):** Cargo dependencies compiled once per workspace
2. **Remote (Cachix):** Both `cargoArtifacts` AND final binaries

**Build times:**
- **Without cache:** 15-30 minutes per service (download deps + compile)
- **With Crane only:** 2-5 minutes (reuse deps, rebuild package)
- **With Cachix:** 5-10 seconds (download pre-built binary)

### Go Packages

**Packages:** Tangled infrastructure (knot, spindle, appview), indigo

**Caching Strategy:**
```nix
buildGoModule {
  vendorHash = "sha256-...";  # Pre-calculated vendor dependencies hash
  # Go modules cached in /nix/store, uploaded to Cachix
};
```

**What gets cached:**
1. **Nix store:** Vendored Go modules
2. **Cachix:** Vendored modules + compiled binaries

**Build times:**
- **Without cache:** 5-15 minutes (download modules + compile)
- **With Cachix:** 5 seconds (download everything)

### Node.js/TypeScript Packages

**Packages:** ATProto libraries, frontpage, grain

**Caching Strategy:**
```nix
buildNpmPackage {
  npmDepsHash = "sha256-...";  # Pre-calculated npm dependencies hash
  # node_modules cached in /nix/store, uploaded to Cachix
};
```

**What gets cached:**
1. **Nix store:** npm dependencies (node_modules equivalent)
2. **Cachix:** Dependencies + webpack output + final artifacts

**Build times:**
- **Without cache:** 10-20 minutes (npm install + webpack)
- **With Cachix:** 5 seconds (download everything)

### Ruby Packages

**Packages:** Lycan feed generator

**Caching Strategy:**
```nix
env = bundlerEnv {
  inherit ruby gemdir gemset;
  # All gems + native extensions built once
};
```

**What gets cached:**
1. **Nix store:** Bundled gems with compiled native extensions
2. **Cachix:** Complete Ruby environment + wrapped executable

**Build times:**
- **Without cache:** 5-10 minutes (gem install + native extensions)
- **With Cachix:** 5 seconds (download everything)

## CI/CD Integration

The GitHub Actions workflow (`.github/workflows/build.yml`) automatically pushes built packages to Cachix.

### Setup Steps (Required)

To enable automatic cache pushing from CI, add a GitHub secret:

#### Option 1: Auth Token (Recommended)

1. Go to https://app.cachix.org/cache/atproto
2. Navigate to **Settings → Auth tokens**
3. Click **Generate auth token** or copy existing token
4. Go to your GitHub repository settings
5. Navigate to **Settings → Secrets and variables → Actions**
6. Add new repository secret:
   - **Name:** `CACHIX_AUTH_TOKEN`
   - **Value:** The auth token from Cachix

#### Option 2: Signing Key (Alternative)

1. On Cachix cache settings page, find the **Signing key**
2. Copy the signing key value
3. Add to GitHub secrets as:
   - **Name:** `CACHIX_SIGNING_KEY`
   - **Value:** The signing key

### How CI Works

```yaml
# From .github/workflows/build.yml
- name: Setup cachix
  uses: cachix/cachix-action@v16
  with:
    name: atproto
    authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
```

**Workflow:**
1. GitHub Actions builds all packages on each push/PR
2. Successfully built packages are automatically pushed to Cachix
3. Users can then download pre-built binaries instead of building from source
4. Nightly rebuilds at 2:51 UTC keep cache fresh

## Manual Push to Cachix

If you want to manually push packages to Cachix:

```bash
# Build and push a single package
nix build .#microcosm-constellation
cachix push atproto ./result

# Build and push multiple packages
nix build .#microcosm-constellation .#blacksky-pds
cachix push atproto ./result*

# Or use a one-liner (pipe output)
nix build .#microcosm-constellation | cachix push atproto

# Build organizational "all" packages
nix build .#microcosm-all | cachix push atproto
nix build .#tangled-all | cachix push atproto
```

## Package Coverage

Currently **49 packages** in the NUR, with binary cache coverage:

**Cached via Crane + Cachix (Rust):**
- Microcosm (8 packages): constellation, spacedust, slingshot, ufos, pocket, quasar, reflector, who-am-i
- Blacksky/rsky (7 packages): PDS, relay, feedgen, firehose, labeler, jetstream-subscriber, satnav

**Cached via Cachix (Go):**
- Tangled (3 packages): knot, spindle, appview
- Bluesky (1 package): indigo
- Smokesignal (1 package): quickdid

**Cached via Cachix (Node.js/TypeScript):**
- ATProto libraries (7 packages): api, did, identity, lexicon, repo, syntax, xrpc
- Frontpage (9 sub-packages in monorepo)
- Grain (5 sub-packages)
- Third-party apps: leaflet, slices, teal, yoten, parakeet, etc.

**Cached via Cachix (Ruby):**
- Mackuba (1 package): lycan

## Verifying Cache Usage

Check if a package is in the cache:

```bash
# Method 1: Query cache directly
nix path-info --store https://atproto.cachix.org .#microcosm-constellation

# Method 2: Check during build
nix build .#microcosm-constellation --verbose
# Look for "copying path ... from 'https://atproto.cachix.org'"

# Method 3: Verify substituter config
nix show-config | grep substituters
nix show-config | grep trusted-public-keys
```

## Troubleshooting

### Cache Not Being Used

If Nix is still building from source:

1. **Verify cache is configured:**
   ```bash
   nix show-config | grep substituters
   # Should show: https://atproto.cachix.org

   nix show-config | grep trusted-public-keys
   # Should show: atproto.cachix.org-1:mgH0q9dt3ZI9puHEfIGDnkRBfT80I3vfEh4Wda2B0rk=
   ```

2. **Force use of substituters:**
   ```bash
   nix build .#microcosm-constellation --option substitute true
   ```

3. **Check if package is in cache:**
   ```bash
   nix path-info --store https://atproto.cachix.org .#microcosm-constellation
   ```

### Permission Denied

If you get permission errors:

**For NixOS:** Add your user to trusted-users in `/etc/nixos/configuration.nix`:
```nix
nix.settings.trusted-users = [ "root" "your-username" ];
```

**For non-NixOS:** Edit `/etc/nix/nix.conf`:
```
trusted-users = root your-username
```

Then restart the Nix daemon: `sudo systemctl restart nix-daemon`

### CI Step is Skipped

**Symptom:** GitHub Actions shows "Setup cachix: skipped"

**Solution:** The `CACHIX_AUTH_TOKEN` secret is missing. Add it to GitHub repository secrets.

### Push Fails with Authentication Error

**Symptom:** CI logs show "Authentication failed"

**Solution:**
1. Verify the token is correct in GitHub secrets
2. Regenerate token on Cachix if needed
3. Update GitHub secret with new token

## Cache Statistics

View cache statistics at:
- **Dashboard:** https://app.cachix.org/cache/atproto (requires login)
- **Public page:** https://atproto.cachix.org

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
- [Crane Documentation](https://github.com/ipetkov/crane) - Rust caching

## Next Steps

1. **Add GitHub secret** - `CACHIX_AUTH_TOKEN` or `CACHIX_SIGNING_KEY`
2. **Push to GitHub** - Triggers CI build + Cachix push
3. **Verify** - Check https://atproto.cachix.org for packages

**Current Status:** ✅ Configuration complete, awaiting GitHub secret

---

For questions, check the [Cachix FAQ](https://docs.cachix.org/faq) or open an issue on this repository.
