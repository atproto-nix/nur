# ATProto NUR - Planning Summary

**Date:** 2025-10-22
**Status:** Plans complete, ready for implementation

---

## What We've Done Today

### ✅ Completed Tasks

1. **Analyzed the Repository**
   - 48 packages across 21 organizations
   - Multi-platform NUR for AT Protocol ecosystem
   - Recently simplified from over-engineered structure

2. **Fixed Naming Issues**
   - Renamed `tier2-modules` → `third-party-apps-modules`
   - Renamed `tier3-modules` → `specialized-apps-modules`
   - Updated all references in tests, workflows, and documentation
   - Created NAMING_FIXES.md documenting changes

3. **Created Comprehensive Plans**
   - **CLAUDE.md** - AI agent guidance (3,000+ words)
   - **PLAN.md** - 5-phase development roadmap with metrics
   - **TODO.md** - Quick-reference action items
   - **NEXT_STEPS.md** - Detailed implementation guide (8-12 hours)
   - **MCP_INTEGRATION.md** - AI assistance setup plan (2-3 hours)
   - **NAMING_FIXES.md** - Record of naming improvements

---

## Critical Issues Identified

### 🔴 Critical (Blocks Building)
1. **6 packages with `lib.fakeHash`** - Won't build until hashes calculated
   - tangled-dev/knot.nix
   - tangled-dev/appview.nix
   - tangled-dev/spindle.nix
   - witchcraft-systems/pds-dash.nix
   - atbackup-pages-dev/atbackup.nix
   - atproto/frontpage.nix

### 🟡 High Priority (Affects Reproducibility)
2. **8 packages with `rev = "main"`** - Build but not reproducible
   - All 6 above (also have rev="main")
   - hyperlink-academy/leaflet.nix
   - slices-network/slices.nix

3. **Broken Import** - `modules/default.nix` references non-existent `../profiles`

### 🟢 Medium Priority
4. **6 placeholder packages** - Need decisions (implement/keep/remove)
   - bluesky-social-indigo
   - bluesky-social-grain
   - parakeet-social-parakeet
   - teal-fm-teal
   - tangled-dev-genjwks
   - tangled-dev-lexgen

---

## Repository Structure Overview

```
nur/
├── pkgs/               # 48 packages organized by maintainer
│   ├── microcosm/      # 9 Rust services
│   ├── blacksky/       # 13 community tools
│   ├── atproto/        # 8 TypeScript libraries
│   ├── bluesky-social/ # 2 official (placeholders)
│   ├── tangled-dev/    # 5 infrastructure
│   └── [15+ other orgs]
├── modules/            # NixOS service modules (mirrors pkgs/)
├── lib/                # Build utilities
│   ├── atproto.nix     # Main packaging helpers
│   └── fetch-tangled.nix # Tangled.org fetcher
├── tests/              # 31 test files
└── [documentation]
```

---

## Implementation Roadmap

### Phase 1: Critical Fixes (Week 1) - 4-5 hours
**Goal:** Make everything buildable and reproducible

- [x] Fix naming issues (completed today)
- [ ] Pin versions for 6 fakeHash packages (2-3 hours)
- [ ] Pin rev="main" for remaining packages (1 hour)
- [ ] Fix broken profiles import (10 minutes)
- [ ] Verify all builds work (30 minutes)

**Outcome:** All 48 packages build successfully, no fakeHash, no rev="main"

### Phase 2: Package Quality (Week 2-3) - 12-22 hours
**Goal:** Clean up placeholders and improve metadata

- [ ] Decide on 6 placeholder packages (2-4 hours)
- [ ] Add runtime tests for key packages (6-10 hours)
- [ ] Improve package metadata (2-3 hours)
- [ ] Handle placeholder implementations/removals (2-5 hours)

**Outcome:** Clear package status, better discoverability, some tests

### Phase 3: Infrastructure (Week 2-3) - 9-17 hours
**Goal:** Automation and distribution

- [ ] Set up Cachix binary cache (2-4 hours)
- [ ] Implement CI/CD pipeline (4-8 hours)
- [ ] Set up update automation (3-6 hours)

**Outcome:** Fast installs, automated builds, update tracking

### Phase 3.5: Developer Experience (Week 2) - 2-3 hours
**Goal:** Better AI assistance

- [ ] Install and configure MCP-NixOS (25 minutes)
- [ ] Update documentation with MCP info (1 hour)
- [ ] Add to development shell (20 minutes)
- [ ] Create usage examples (30 minutes)

**Outcome:** Accurate AI suggestions, faster development

### Phase 4: User Experience (Week 3-4) - 11-21 hours
**Goal:** Documentation and examples

- [ ] Create example configurations (6-10 hours)
- [ ] Improve documentation (4-6 hours)
- [ ] Package discovery improvements (3-5 hours)

**Outcome:** Easy onboarding, clear usage patterns

### Phase 5: Ecosystem Growth (Ongoing)
**Goal:** Community and expansion

- [ ] Add missing packages (1-2 hours each)
- [ ] Community engagement (ongoing)
- [ ] Integration with nixpkgs (8-15 hours)

**Outcome:** 60+ packages, active community, wider reach

---

## Timeline Summary

| Phase | Duration | Effort | Priority |
|-------|----------|--------|----------|
| **Phase 1** | Week 1 | 4-5 hours | 🔴 Critical |
| **Phase 2** | Week 2-3 | 12-22 hours | 🟡 High |
| **Phase 3** | Week 2-3 | 9-17 hours | 🟡 High |
| **Phase 3.5** | Week 2 | 2-3 hours | 🟢 Medium |
| **Phase 4** | Week 3-4 | 11-21 hours | 🟢 Medium |
| **Phase 5** | Ongoing | Variable | 🔵 Low |
| **TOTAL** | 6-9 weeks | 38-68 hours | |

**Minimum viable (critical only):** 4-5 hours
**Recommended first pass (critical + high):** 25-44 hours
**Full v1.0 release:** 38-68 hours

---

## Next Immediate Actions

### This Week (Start Today)

1. **Fix tangled-dev packages** (2-3 hours)
   ```bash
   git ls-remote https://github.com/tangled-dev/tangled-core HEAD
   # Then update knot.nix, appview.nix, spindle.nix
   ```

2. **Fix other fakeHash packages** (2 hours)
   - pds-dash.nix
   - atbackup.nix
   - frontpage.nix (may defer if complex)

3. **Pin remaining rev="main"** (1 hour)
   - leaflet.nix
   - slices.nix

4. **Fix broken import** (10 minutes)
   ```bash
   # Edit modules/default.nix, remove ../profiles line
   ```

5. **Verify everything builds** (30 minutes)
   ```bash
   nix flake show  # Should list 48 packages
   nix build .#microcosm-constellation -L
   nix build .#blacksky-pds -L
   # etc.
   ```

### This Month

6. **Set up MCP-NixOS** (2-3 hours)
   - Install: `nix profile install github:utensils/mcp-nixos`
   - Configure Claude Code
   - Update documentation

7. **Decide on placeholders** (2-4 hours)
   - Research each package
   - Implement, keep, or remove

8. **Set up Cachix** (2-4 hours)
   - Build all packages
   - Push to cache
   - Update README

---

## Documentation Created

All planning documents are now in place:

1. **CLAUDE.md** - For AI agents working in this repo
2. **PLAN.md** - Comprehensive 5-phase roadmap
3. **TODO.md** - Quick reference action items
4. **NEXT_STEPS.md** - Detailed step-by-step guide
5. **MCP_INTEGRATION.md** - AI assistance setup
6. **NAMING_FIXES.md** - Record of today's fixes
7. **SUMMARY.md** - This document

---

## Success Metrics

### Technical (v1.0 release)
- ✅ 48 packages evaluate (DONE)
- ⬜ >95% build successfully (currently ~85%)
- ⬜ 0 packages with fakeHash (currently 6)
- ⬜ 0 packages with rev="main" (currently 8)
- ⬜ >90% cache hit rate (currently 0%, no cache)
- ⬜ >50% packages have tests (currently minimal)
- ⬜ <30 days behind upstream average

### User Experience
- ⬜ <10 minutes from flake to running service
- ⬜ All packages documented
- ⬜ 5+ working example configurations
- ⬜ Clear contribution process

### Community
- ⬜ 100+ GitHub stars
- ⬜ 5+ regular contributors
- ⬜ <7 day median response time

---

## Risk Assessment

### High Risk
- **Upstream instability:** ATProto ecosystem is young and changing
  - *Mitigation:* Pin versions, track changes, maintain compatibility
- **Maintenance burden:** 48+ packages is significant
  - *Mitigation:* Automation, community, focus on core

### Medium Risk
- **Cross-platform builds:** May fail on some platforms
  - *Mitigation:* CI on all platforms, platform-specific fixes
- **Cachix costs:** Storage/bandwidth
  - *Mitigation:* Monitor usage, optimize, seek sponsorship

### Low Risk
- **Naming conflicts:** May conflict with nixpkgs
  - *Mitigation:* Clear prefixing, documentation
- **License compliance:** Various licenses
  - *Mitigation:* Document licenses, ensure compliance

---

## Resources

### Internal Documentation
- CLAUDE.md - AI agent guidance
- PLAN.md - Full roadmap
- TODO.md - Action items
- NEXT_STEPS.md - Implementation guide
- MCP_INTEGRATION.md - AI setup
- NAMING_FIXES.md - Today's changes

### External Resources
- [AT Protocol Docs](https://atproto.com)
- [Bluesky Social](https://bsky.social)
- [Tangled](https://tangled.org)
- [NUR Guidelines](https://github.com/nix-community/NUR)
- [Crane (Rust builder)](https://github.com/ipetkov/crane)
- [MCP-NixOS](https://mcp-nixos.io/)

---

## Current Status

**Repository Health:** ⚠️ Good but needs critical fixes
**Documentation:** ✅ Complete
**Planning:** ✅ Complete
**Ready to Code:** ✅ Yes - start with NEXT_STEPS.md

**Estimated time to stable release:** 6-9 weeks (38-68 hours)
**Estimated time to minimum viable:** 1 week (4-5 hours)

---

**Ready to begin implementation!**

Start with: `NEXT_STEPS.md` → Task 1.1 (Fix Tangled-dev packages)
