# Naming Fixes Applied

## Summary

Fixed confusing "tier2" and "tier3" naming in test files to use clearer, organizational names.

## Changes Made

### Test Files Renamed

1. **tests/tier2-modules.nix** → **tests/third-party-apps-modules.nix**
   - Tests: leaflet, slices, parakeet, teal
   - Category: Third-party web applications and AppViews
   - More descriptive name that reflects actual content

2. **tests/tier3-modules.nix** → **tests/specialized-apps-modules.nix**
   - Tests: streamplace, yoten, red-dwarf
   - Category: Specialized applications (video, learning, clients)
   - More descriptive name that reflects actual content

### Files Updated

**tests/default.nix:**
- Changed exports from `tier2-modules` and `tier3-modules`
- To: `third-party-apps-modules` and `specialized-apps-modules`

**.github/workflows/build.yml:**
- Updated test invocations to use new names
- Lines 193-194: `nix build .#tests.{new-name}`

**.tangled/workflows/build.yml:**
- Updated test invocations to use new names
- Lines 248-249: `run_test "{new-name}"`
- Updated section header from "Tier-based Module Tests" to "Application Module Tests"
- Updated summary line from "Tier-based module testing" to "Application module testing"

**test files themselves:**
- Updated `name =` attribute in nixosTest
- Updated test script echo messages
- Updated comments to describe purpose clearly

## Rationale

**Problems with "tier" naming:**
- ❌ Implies hierarchy or importance level (tier1 > tier2 > tier3)
- ❌ Not self-documenting - what defines a "tier"?
- ❌ Doesn't match organizational structure elsewhere in repo
- ❌ Confusing for new contributors
- ❌ Arbitrary categorization

**Benefits of new naming:**
- ✅ Self-documenting: name describes content
- ✅ Matches organizational principle (group by maintainer/type)
- ✅ Clear purpose at a glance
- ✅ No implied hierarchy
- ✅ Easier to extend (can add more categories without numerical ordering)

## Testing

After these changes, the tests can be run with:

```bash
# New names (current)
nix build .#tests.third-party-apps-modules
nix build .#tests.specialized-apps-modules

# Old names (removed)
# nix build .#tests.tier2-modules  # No longer exists
# nix build .#tests.tier3-modules  # No longer exists
```

## Other Naming Issues Found

While fixing these, we also identified other naming inconsistencies to address:

1. **modules/default.nix** - Has broken `../profiles` import (directory doesn't exist)
2. **bluesky-legacy** directory - Could be renamed or merged
3. Some tests reference "atproto" module paths that don't match current structure

These will be addressed in separate fixes.

## Impact

**Breaking changes:** None for end users (only affects internal test names)

**CI/CD:** Updated both GitHub Actions and Tangled workflows

**Documentation:** Will update PLAN.md and TODO.md to reflect completion

---

**Date:** 2025-10-22
**Status:** ✅ Complete
