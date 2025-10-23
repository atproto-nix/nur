# Cachix Setup - Next Steps

The Cachix binary cache has been configured for the ATProto NUR! Here's what's been done and what's left to do.

## ✅ Completed

1. **Created Cachix cache** at https://atproto.cachix.org
2. **Updated GitHub Actions workflow** (`.github/workflows/build.yml`)
   - Changed `cachixName` from placeholder to `atproto`
   - Workflow ready to push builds automatically
3. **Updated README.md** with Cachix setup instructions
   - Added public key: `atproto.cachix.org-1:mgH0q9dt3ZI9puHEfIGDnkRBfT80I3vfEh4Wda2B0rk=`
   - Three setup methods documented (CLI, NixOS, non-NixOS)
4. **Created comprehensive documentation** (CACHIX_SETUP.md)
   - User setup instructions
   - CI/CD integration details
   - Manual push instructions
   - Troubleshooting guide
5. **Committed changes** (20 commits ahead of origin/main)

## 🔴 Required: Add GitHub Secret

**To enable automatic pushing to Cachix from CI:**

### Option 1: Using Auth Token (Recommended)

1. Go to https://app.cachix.org/cache/atproto
2. Navigate to **Settings → Auth tokens**
3. Click **Generate auth token** or copy existing token
4. Go to your GitHub repository: https://github.com/YOUR_USERNAME/nur/settings/secrets/actions
5. Click **New repository secret**
6. Add secret:
   - **Name:** `CACHIX_AUTH_TOKEN`
   - **Value:** Paste the auth token from Cachix
7. Click **Add secret**

### Option 2: Using Signing Key (Alternative)

1. On Cachix cache settings page, find the **Signing key**
2. Copy the signing key value
3. Add to GitHub secrets as:
   - **Name:** `CACHIX_SIGNING_KEY`
   - **Value:** Paste the signing key

**Note:** The workflow supports both `CACHIX_AUTH_TOKEN` and `CACHIX_SIGNING_KEY`, but auth token is recommended for easier management.

## 🟢 Optional: Test the Setup

### Test Locally (if you have auth token)

```bash
# Install cachix if not already installed
nix-env -iA cachix -f https://cachix.org/api/v1/install

# Authenticate with your cache
cachix authtoken YOUR_TOKEN_HERE

# Build and push a package
nix build .#microcosm-constellation
cachix push atproto ./result

# Or in one command
nix build .#microcosm-constellation | cachix push atproto
```

### Test in CI (after adding GitHub secret)

1. Make a small commit (e.g., update a comment)
2. Push to GitHub: `git push origin main`
3. Watch GitHub Actions: https://github.com/YOUR_USERNAME/nur/actions
4. Check build logs for "Setup cachix" step
5. Verify packages appear at: https://atproto.cachix.org

## 📊 Current Package Status

- **Total packages:** 50
- **Packages that will build in CI:** 47 (94%)
- **Packages blocked:** 3 (6%)

### Blocked Packages

1. **likeandscribe-frontpage**
   - Issue: Needs npmDepsHash (pnpm workspace compatibility)
   - Status: Source hash complete, build will fail on npmDepsHash

2. **atbackup-pages-dev-atbackup**
   - Issue: libsoup2 security vulnerability (EOL, 14+ CVEs)
   - Status: Requires `NIXPKGS_ALLOW_INSECURE=1` to build
   - Note: CI shouldn't build this until upstream fixes

3. **Any package that hasn't been tested yet**
   - Some packages may fail first CI run due to platform-specific issues

## 🚀 Next Actions

### Immediate (Required)
1. **Add `CACHIX_AUTH_TOKEN` to GitHub secrets** (see above)
2. **Push commits to GitHub:** `git push origin main`
3. **Monitor first CI run** to ensure Cachix integration works

### Short-term (Recommended)
4. **Fix frontpage npmDepsHash** (may require pnpm-specific solution)
5. **Test all packages build in CI** (watch for failures)
6. **Update PINNING_NEEDED.md** after successful CI run
7. **Consider removing atbackup** until security issue is resolved upstream

### Long-term (Nice to have)
8. **Set up Cachix deploy key** for better security
9. **Enable Cachix webhooks** for notifications
10. **Add cache statistics badge** to README
11. **Document cache usage in metrics**

## 📝 Commands Summary

```bash
# Push to GitHub (starts CI build with Cachix)
git push origin main

# Manually build and push packages
nix build .#microcosm-constellation | cachix push atproto

# Build all working packages and push
nix build .#packages.x86_64-linux.microcosm-constellation \
          .#packages.x86_64-linux.blacksky-pds \
          .#packages.x86_64-linux.tangled-knot \
  | cachix push atproto

# Check if package is in cache
nix path-info --store https://atproto.cachix.org .#microcosm-constellation

# Enable cache for users
cachix use atproto
```

## 🔗 Important Links

- **Cache dashboard:** https://app.cachix.org/cache/atproto
- **Public page:** https://atproto.cachix.org
- **GitHub Actions:** https://github.com/YOUR_USERNAME/nur/actions
- **Cachix docs:** https://docs.cachix.org/

## ✅ Success Criteria

You'll know the setup is working when:

1. ✅ GitHub Actions "Setup cachix" step succeeds (not skipped)
2. ✅ Build logs show "Pushing paths to cachix"
3. ✅ Packages appear at https://atproto.cachix.org
4. ✅ Users can install packages without building:
   ```bash
   cachix use atproto
   nix build github:YOUR_USERNAME/nur#microcosm-constellation
   # Should download from cache, not build from source
   ```

## 🐛 Troubleshooting

### CI Step is Skipped

**Symptom:** GitHub Actions shows "Setup cachix: skipped"

**Solution:** The `CACHIX_AUTH_TOKEN` secret is missing. Add it to GitHub repository secrets.

### Push Fails with Authentication Error

**Symptom:** CI logs show "Authentication failed"

**Solution:**
1. Verify the token is correct in GitHub secrets
2. Regenerate token on Cachix if needed
3. Update GitHub secret with new token

### Builds Fail with Weird Errors

**Symptom:** Packages that build locally fail in CI

**Solution:**
1. Check if package needs platform-specific dependencies
2. Verify all hashes are calculated on Linux x86_64
3. Check for missing nativeBuildInputs

### Cache Not Working for Users

**Symptom:** Users still building from source despite `cachix use atproto`

**Solution:**
1. Verify package actually exists in cache
2. Check user's nix.conf has correct substituter
3. Ensure public key matches exactly
4. Try with `--option substitute true` flag

## 📚 Documentation

All documentation is in place:
- **README.md** - User-facing setup instructions
- **CACHIX_SETUP.md** - Complete technical documentation
- **CACHIX_NEXT_STEPS.md** - This file (can be deleted after setup)
- **.github/workflows/build.yml** - CI configuration

## 🎉 After Setup

Once the GitHub secret is added and first CI run succeeds:

1. Users can enable cache with: `cachix use atproto`
2. Packages install in seconds instead of minutes/hours
3. CI runs will be faster (cached dependencies)
4. You can delete this file: `rm CACHIX_NEXT_STEPS.md`

---

**Current Status:** 🟡 Configuration complete, awaiting GitHub secret

**Blockers:** None (just need to add the secret)

**Time to complete:** 5 minutes (add secret + verify CI run)
