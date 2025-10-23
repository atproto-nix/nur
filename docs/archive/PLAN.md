# ATProto NUR Development Plan

This document outlines the strategic roadmap for the ATProto NUR repository.

## Current Status (2025-10-22)

**Achievements:**
- ✅ 48 packages available and evaluating successfully
- ✅ Multi-platform support (x86_64/aarch64 Linux/Darwin)
- ✅ NixOS modules for all service packages
- ✅ Simplified repository structure (removed over-engineering)
- ✅ Organizational structure by maintainer
- ✅ CLAUDE.md created for AI agent guidance

**Known Issues:**
- ⚠️ 9 packages with unpinned versions (`rev = "main"` or `lib.fakeHash`)
- ⚠️ ~6 packages will fail to build due to `lib.fakeHash`
- ⚠️ 6 placeholder packages (indigo, grain, parakeet, teal, genjwks, lexgen)
- ⚠️ Broken `../profiles` import in `modules/default.nix` (directory doesn't exist)
- ⚠️ Empty `docs/` directory
- ⚠️ Cachix cache not yet populated (atproto.cachix.org)
- ⚠️ No CI/CD pipeline for automated builds

## Phase 1: Critical Fixes (Priority: HIGH)

### 1.1 Fix Build Blockers
**Goal:** Make all packages buildable

**Tasks:**
- [ ] Pin tangled-dev packages (appview, knot, spindle)
  - Find latest commits from https://github.com/tangled-dev/tangled-core
  - Calculate source hashes and vendorHash values
  - Test builds on at least one platform
- [ ] Pin atbackup-pages-dev/atbackup.nix
  - Calculate real hash to replace `lib.fakeHash`
- [ ] Pin witchcraft-systems/pds-dash.nix
  - Pin rev and calculate source + npmDepsHash
- [ ] Pin atproto/frontpage.nix
  - Pin rev and calculate hashes

**Success Criteria:**
- All packages build successfully (or fail for reasons other than fakeHash)
- `nix flake check` passes without hash errors

**Time Estimate:** 2-4 hours

### 1.2 Pin Versions for Reproducibility
**Goal:** Ensure reproducible builds

**Tasks:**
- [ ] Pin hyperlink-academy/leaflet.nix (has rev="main")
- [ ] Pin slices-network/slices.nix (has rev="main")
- [ ] Review and fix blacksky/rsky TODOs
- [ ] Verify all packages have specific commit hashes

**Success Criteria:**
- No `rev = "main"` or `rev = "master"` in codebase
- All packages are bit-for-bit reproducible
- Delete PINNING_NEEDED.md or mark as resolved

**Time Estimate:** 1-2 hours

### 1.3 Fix Broken References
**Goal:** Clean up repository structure

**Tasks:**
- [ ] Fix `modules/default.nix` - remove `../profiles` import (directory doesn't exist)
- [ ] Remove or populate empty `docs/` directory
- [ ] Check for other broken imports or references
- [ ] Test module evaluation: `nix eval .#nixosModules.default`

**Success Criteria:**
- No evaluation errors from broken imports
- Module system loads cleanly

**Time Estimate:** 30 minutes

## Phase 2: Package Quality (Priority: MEDIUM)

### 2.1 Handle Placeholder Packages
**Goal:** Decide fate of placeholder packages

**Placeholder packages:**
1. `bluesky-social-indigo` - Official Go implementation
2. `bluesky-social-grain` - Official TypeScript implementation
3. `parakeet-social-parakeet` - AppView implementation
4. `teal-fm-teal` - Music platform
5. `tangled-dev-genjwks` - JWKS generator
6. `tangled-dev-lexgen` - Lexicon generator

**Options per package:**
- **Implement:** Create real package definitions
- **Keep as placeholder:** Document as "coming soon"
- **Remove:** Delete if not needed

**Tasks:**
- [ ] Research each placeholder - is upstream ready to package?
- [ ] Implement packages where feasible (indigo, grain are complex)
- [ ] Document rationale for keeping/removing in comments
- [ ] Update README.md to clearly mark placeholders

**Success Criteria:**
- Clear status for each package (implemented, planned, or removed)
- README accurately reflects package availability

**Time Estimate:** 4-8 hours (depending on implementation choices)

### 2.2 Add Package Tests
**Goal:** Verify package functionality

**Test categories:**
1. **Build tests** (already implicit via flake)
2. **Runtime tests** - Services start and respond
3. **Integration tests** - Services work together
4. **Module tests** - NixOS configurations evaluate

**Tasks:**
- [ ] Review existing tests in `tests/` directory
- [ ] Create runtime smoke tests for key services:
  - microcosm-constellation (most popular?)
  - blacksky-pds
  - smokesignal-events-quickdid
- [ ] Test NixOS module configurations
- [ ] Document test execution in README

**Success Criteria:**
- At least 5 key packages have runtime tests
- Test suite runs in CI (see Phase 3)

**Time Estimate:** 6-10 hours

### 2.3 Improve Package Metadata
**Goal:** Better package discovery and documentation

**Tasks:**
- [ ] Ensure all packages have good `meta.description`
- [ ] Add `meta.longDescription` where helpful
- [ ] Verify `meta.homepage` links are correct
- [ ] Add `meta.license` information (currently inconsistent)
- [ ] Document upstream repository URLs in package files

**Success Criteria:**
- `nix search` provides useful results
- Package metadata is complete and accurate

**Time Estimate:** 2-3 hours

## Phase 3: Infrastructure (Priority: MEDIUM)

### 3.1 Set Up Cachix Binary Cache
**Goal:** Fast package installation for users

**Current state:**
- Badge in README references `atproto.cachix.org`
- Cache likely not populated or configured

**Tasks:**
- [ ] Verify Cachix project exists and access
- [ ] Build all packages for all platforms:
  - x86_64-linux (priority)
  - aarch64-linux
  - x86_64-darwin
  - aarch64-darwin (priority for Apple Silicon)
- [ ] Push to cachix cache
- [ ] Test cache functionality
- [ ] Update README with correct public key

**Success Criteria:**
- All buildable packages available in cache
- Users can install without building from source
- Cache stays updated (via CI)

**Time Estimate:** 2-4 hours (plus build time)

### 3.2 Implement CI/CD Pipeline
**Goal:** Automated builds and testing

**Platform options:**
- GitHub Actions (since repo mirrors to GitHub)
- Tangled CI (if available - primary dev platform)
- Both (ideal)

**Tasks:**
- [ ] Set up GitHub Actions workflow
  - Trigger on push to main
  - Build changed packages
  - Run test suite
  - Push to Cachix
- [ ] Configure for all platforms (use matrix builds)
- [ ] Add build status badges to README
- [ ] Set up scheduled builds (weekly?) for dependency updates
- [ ] Implement Tangled CI if available

**Success Criteria:**
- CI runs on every commit
- Build failures are caught before merge
- Cache stays fresh automatically

**Time Estimate:** 4-8 hours

### 3.3 Set Up Update Automation
**Goal:** Track upstream changes

**Tasks:**
- [ ] Evaluate tools:
  - nixpkgs-update bot
  - nix-update CLI tool
  - Custom script using GitHub API
- [ ] Create script to check for new upstream releases
- [ ] Document update process in CLAUDE.md
- [ ] Consider automated PRs for updates (optional)

**Success Criteria:**
- Easy way to check if packages are outdated
- Update process is documented

**Time Estimate:** 3-6 hours

## Phase 3.5: Developer Experience (Priority: MEDIUM)

### 3.4 Integrate MCP-NixOS for AI Assistance
**Goal:** Improve AI-assisted development accuracy

**What is MCP-NixOS:**
- Model Context Protocol server for NixOS resources
- Provides real-time access to 130K+ packages, 22K+ options
- Prevents AI hallucinations about package availability
- Source: https://mcp-nixos.io/

**Tasks:**
- [ ] Install MCP-NixOS locally (`nix profile install github:utensils/mcp-nixos`)
- [ ] Configure Claude Code/IDE to use MCP server
- [ ] Update CLAUDE.md with MCP setup instructions
- [ ] Add to development shell in flake.nix
- [ ] Create MCP usage examples documentation
- [ ] Update README with MCP badge and info
- [ ] Add to CONTRIBUTING.md

**Success Criteria:**
- AI assistant provides accurate NixOS package information
- Configuration suggestions use real options
- Faster package development (less trial-and-error)
- Better quality modules (accurate syntax)

**Time Estimate:** 2-3 hours

**See:** MCP_INTEGRATION.md for detailed implementation plan

## Phase 4: User Experience (Priority: LOW-MEDIUM)

### 4.1 Create Example Configurations
**Goal:** Help users deploy services

**Examples to create:**
- [ ] Basic PDS setup (blacksky-pds)
- [ ] Microcosm service cluster (constellation + slingshot + spacedust)
- [ ] Development environment (multiple services)
- [ ] Production deployment patterns
- [ ] Docker/Podman OCI images (optional)

**Location:** `examples/` directory (new)

**Success Criteria:**
- 3-5 working example configurations
- Documentation explains each example

**Time Estimate:** 6-10 hours

### 4.2 Improve Documentation
**Goal:** Better onboarding and usage

**Tasks:**
- [ ] README.md improvements:
  - Reorganize for clarity
  - Add "Quick Start" section with copy-paste examples
  - Add troubleshooting section
  - Add contribution guidelines
  - Link to example configurations
- [ ] Create ARCHITECTURE.md (optional):
  - Package organization rationale
  - Module system design
  - Build system overview
- [ ] Create CONTRIBUTING.md:
  - How to add packages
  - How to test changes
  - Code review process

**Success Criteria:**
- New users can deploy a service in <10 minutes
- Contributors understand how to add packages

**Time Estimate:** 4-6 hours

### 4.3 Package Discovery Improvements
**Goal:** Users can find what they need

**Tasks:**
- [ ] Create package matrix/table in README
  - Service type (PDS, relay, AppView, etc.)
  - Language (Rust, Go, TypeScript)
  - Status (stable, beta, planned)
  - Has NixOS module? (yes/no)
- [ ] Add search tags/keywords to packages
- [ ] Consider web interface (GitHub Pages?)
  - Auto-generated from flake.nix
  - Searchable package list
  - Usage examples

**Success Criteria:**
- Users can quickly find relevant packages
- Clear overview of ecosystem coverage

**Time Estimate:** 3-5 hours

## Phase 5: Ecosystem Growth (Priority: LOW)

### 5.1 Add Missing Packages
**Goal:** Comprehensive ATProto ecosystem coverage

**Potential additions:**
- [ ] atproto-oauth (OAuth libraries)
- [ ] More feed generators (community projects)
- [ ] Labeling services
- [ ] Data analysis tools
- [ ] Backup/archival tools
- [ ] Client applications

**Process:**
1. Survey ATProto ecosystem for popular projects
2. Prioritize by usage/maturity
3. Add packages following existing patterns
4. Create issues for tracking

**Success Criteria:**
- 60+ packages (from current 48)
- Cover major use cases

**Time Estimate:** Ongoing (1-2 hours per package)

### 5.2 Community Engagement
**Goal:** Attract users and contributors

**Tasks:**
- [ ] Announce on ATProto/Bluesky communities
- [ ] Create blog post or announcement
- [ ] Submit to NUR official registry
- [ ] Respond to issues/PRs promptly
- [ ] Create GitHub Discussions for Q&A
- [ ] Consider Discord/Matrix channel (if demand exists)

**Success Criteria:**
- 5+ external contributors
- Active issue/PR engagement
- Known in ATProto community

**Time Estimate:** Ongoing

### 5.3 Integration with Other NixOS Ecosystems
**Goal:** Better interoperability

**Potential integrations:**
- [ ] Submit core packages to nixpkgs (microcosm, blacksky-pds)
- [ ] NixOS module options integration
- [ ] Home Manager modules (for client apps)
- [ ] Darwin modules (for macOS services)
- [ ] NixOS profiles for common deployments

**Success Criteria:**
- Easier discovery via nixpkgs
- Broader NixOS ecosystem awareness

**Time Estimate:** 8-15 hours (plus review time)

## Maintenance Strategy

### Regular Tasks (Weekly/Monthly)

**Weekly:**
- [ ] Check for upstream updates on key packages
- [ ] Review open issues/PRs
- [ ] Monitor CI build status
- [ ] Check Cachix cache health

**Monthly:**
- [ ] Update flake inputs (`nix flake update`)
- [ ] Rebuild all packages on all platforms
- [ ] Review package usage metrics (if available)
- [ ] Update documentation as needed

**Quarterly:**
- [ ] Major dependency updates
- [ ] Security audit
- [ ] Evaluate new packages to add
- [ ] Review and update roadmap

### Long-term Sustainability

**Documentation:**
- Keep CLAUDE.md updated for AI assistance
- Maintain PLAN.md with progress
- Document major architectural decisions

**Code Quality:**
- Maintain simplicity (resist over-engineering)
- Follow NixOS/Nix best practices
- Regular refactoring to reduce duplication

**Community:**
- Foster welcoming contribution environment
- Recognize contributors
- Share responsibility with co-maintainers

## Success Metrics

### Technical Metrics
- **Build success rate:** >95% of packages build on all platforms
- **Cache hit rate:** >90% (once Cachix is populated)
- **Test coverage:** >50% of packages have runtime tests
- **Update freshness:** <30 days behind upstream on average

### Community Metrics
- **GitHub stars:** Target 100+ (indicates interest)
- **Contributors:** Target 5+ regular contributors
- **Issues/PRs:** <7 day median response time
- **Deployments:** Track via telemetry (opt-in) or surveys

### User Experience Metrics
- **Time to first service:** <10 minutes from flake to running service
- **Documentation completeness:** All packages documented
- **Example coverage:** 5+ working example configurations

## Risk Assessment

### High Risk
1. **Upstream instability:** ATProto ecosystem is young and changing
   - *Mitigation:* Pin versions, track breaking changes, maintain compatibility shims
2. **Maintenance burden:** 48+ packages is significant
   - *Mitigation:* Automation, community contributors, focus on core packages

### Medium Risk
1. **Build failures on platforms:** Cross-platform issues
   - *Mitigation:* CI on all platforms, platform-specific fixes
2. **Cachix costs:** Binary cache storage/bandwidth
   - *Mitigation:* Monitor usage, optimize cache, seek sponsorship if needed

### Low Risk
1. **Naming conflicts:** Package names may conflict with nixpkgs
   - *Mitigation:* Clear prefixing (org-package), document in CLAUDE.md
2. **License compliance:** Various upstream licenses
   - *Mitigation:* Document licenses, ensure compliance

## Appendix: Useful Commands

```bash
# Check package status
nix flake show | grep "package '"

# Build all packages (warning: slow)
nix flake check

# Build specific package on all systems
nix build .#microcosm-constellation --system x86_64-linux
nix build .#microcosm-constellation --system aarch64-linux

# Update specific package
nix-update --flake PACKAGE-NAME

# Push to cachix
nix build .#PACKAGE-NAME
cachix push atproto $(readlink -f result)

# Generate dependency graph
nix-store -q --graph $(nix-build -A PACKAGE-NAME) | dot -Tpng > deps.png
```

## Timeline Estimate

**Phase 1 (Critical):** 1 week
**Phase 2 (Quality):** 2-3 weeks
**Phase 3 (Infrastructure):** 1-2 weeks
**Phase 4 (UX):** 2-3 weeks
**Phase 5 (Growth):** Ongoing

**Total to "stable" release:** 6-9 weeks of focused work

## Next Steps

**Immediate (this week):**
1. Fix all packages with `lib.fakeHash` (Phase 1.1)
2. Pin remaining `rev = "main"` packages (Phase 1.2)
3. Fix broken `../profiles` import (Phase 1.3)
4. Set up basic GitHub Actions CI (Phase 3.2)

**Short-term (this month):**
1. Decide on placeholder packages (Phase 2.1)
2. Set up Cachix cache (Phase 3.1)
3. Integrate MCP-NixOS for AI assistance (Phase 3.4)
4. Add smoke tests for key packages (Phase 2.2)
5. Create 2-3 example configurations (Phase 4.1)

**Medium-term (next quarter):**
1. Complete documentation overhaul (Phase 4.2)
2. Add update automation (Phase 3.3)
3. Begin ecosystem growth (Phase 5.1)
4. Community engagement (Phase 5.2)

---

**Document Status:** Living document - update as priorities change
**Last Updated:** 2025-10-22
**Next Review:** 2025-11-22
