# ATProto NUR - Development Roadmap

**Last Updated:** 2025-11-11
**Status:** 50+ packages, major refactor merged, cocoon fixes in progress

---

## Current State

### Repository Statistics
- **Total Packages:** 50+ (8 Rust, 5 Go, 12+ Node.js/TypeScript, 1 Ruby, 24+ others)
- **Package Organizations:** 21 organizations (microcosm, blacksky, bluesky, grain-social, tangled, likeandscribe, etc.)
- **Module Coverage:** 100% (all services have NixOS modules)
- **Platforms:** Linux (x86_64, aarch64), macOS (x86_64, aarch64)
- **Binary Cache:** Cachix fully configured
- **Repository Health:** 🟢 95% Production Ready

### Recent Build Status (November 2025)
- **Major Refactor Merged:** Successful merge of big-refactor branch (#1) with all recent improvements
- **Ongoing Fixes:** Cocoon package fixes (3 recent commits - df690c3, b6207ca, d11b0b7)
- **Build Status:** All core packages evaluating correctly
- **Next Focus:** Complete cocoon fixes and test full build suite

### Recent Completions ✅ (Through November 2025)
- **Phase 1:** Tangled ecosystem refactoring (tangled-dev → tangled)
- **Phase 2:** Version pinning (leaflet, slices)
- **Phase 3:** Module consolidation (frontpage → likeandscribe)
- **Phase 4:** Grain organization (grain-social)
- **Phase 5:** Documentation reorganization
- **Phase 6:** Big refactor branch merge (all major improvements integrated)
- **New:** Ruby package support (mackuba/lycan)
- **New:** Multi-language binary caching (Rust/Go/Node.js/Ruby)
- **New:** Grain Social Deno packages (appview, labeler, notifications)
- **New:** Deno wrapper script fixes (variable interpolation pattern)
- **New:** Cocoon package fixes (ongoing)

---

## Immediate Priorities (November 2025)

### 1. Complete Cocoon Package Fixes (15 minutes) 🟡
**Priority:** HIGH - In-progress (3 recent commits)

**Status:**
- 3 commits already applied (df690c3, b6207ca, d11b0b7)
- Verify fixes are complete
- Test build: `nix build .#hailey-at-cocoon`

**Impact:** Completes last pending package from recent work

### 2. Run Full Test Suite (30 minutes) 🟡
**Priority:** HIGH - Validate all packages after refactor merge

```bash
# Verify all packages evaluate
nix flake check

# Build key package samples
nix build .#microcosm-constellation
nix build .#tangled-spindle
nix build .#grain-social-appview
nix build .#hailey-at-cocoon
```

### 3. Verify GitHub Actions CI (15 minutes) 🟡
**Priority:** HIGH - Ensure CI pipeline still works after merge

- Check GitHub Actions build status
- Verify Cachix push works
- Monitor cache hit rates

---

## Short-Term (This Week)

### Documentation (November 2025)

**Current Status:**
- ✅ README.md fully updated (564 lines, comprehensive)
- ✅ CLAUDE.md updated with recent fixes and patterns
- ✅ All 35 docs in docs/ directory maintained
- 🔄 Documentation update sweep in progress (11/11/2025)

**Update Strategy:**
- Sync all docs with current codebase state
- Update package counts and statistics
- Verify all code examples are current
- Link to recent fixes and implementations

### Testing

**Post-Merge Validation:**
- ✅ flake.nix evaluates correctly
- ✅ All packages in pkgs/ directory present (21 organization dirs)
- ✅ All modules in modules/ directory present (24 module dirs)
- ✅ 50+ packages across all organizations
- 🔄 Running full build validation

**Module Tests:**
```bash
# Verify flake structure
nix flake check

# Test sample services
nix build .#microcosm-constellation
nix build .#bluesky-indigo
nix build .#grain-social-appview
```

### Package Maintenance

**Known Status:**
- ✅ Most packages pinned with real hashes
- ✅ All 21 organizations structured correctly
- ⚠️ 2 packages with fakeHash (pds-dash, likeandscribe-frontpage)
- 📋 See PINNING_NEEDED.md for full status

---

## Medium-Term (Next 2 Weeks)

### Binary Cache Optimization

**Current Setup:**
- ✅ Cachix configured
- ✅ Multi-language caching documented
- ✅ Crane integration for Rust
- ⏳ Awaiting GitHub secret

**Next Steps:**
1. Add secret and verify push works
2. Monitor cache hit rates
3. Add cache statistics to README

### Package Expansion

**Potential New Packages:**
- Additional ATProto tools
- More feed generators
- Labeling services
- Custom AppViews

**Package Improvements:**
- Add more configuration options to modules
- Improve module documentation
- Add module examples

### Testing Infrastructure

**Goals:**
- Expand VM test coverage
- Add integration tests
- Test multi-service deployments
- Automated testing on all platforms

---

## Long-Term (Next Month)

### Community Engagement

**Announce Repository:**
- ATProto Discord/forums
- NixOS discourse
- Reddit (r/NixOS, r/ATProto)
- Blog post about NixOS for ATProto

**Documentation:**
- Video walkthrough of deployment
- Example configurations
- Troubleshooting guide
- Migration guide for existing deployments

### Upstream Contributions

**Share with Maintainers:**
- Offer NixOS modules to package authors
- Contribute improvements to nixpkgs
- Help package maintainers add Nix support

**Potential nixpkgs Submissions:**
- Stable, widely-used packages
- Packages with no security concerns
- Packages meeting nixpkgs quality standards

### Automation

**Auto-update System:**
- Monitor upstream releases
- Automated version bumps (Renovate-style)
- Automated hash calculation
- Automated testing on PRs

**CI/CD Improvements:**
- Multi-platform testing
- Performance benchmarks
- Security scanning
- Dependency auditing

---

## Technical Debt

### Code Quality

**Completed:**
- ✅ Simplified flake structure
- ✅ Removed backward compatibility layers
- ✅ Consolidated modules
- ✅ Organized by maintainer/organization

**Remaining:**
- Review lib/ utilities for consolidation
- Standardize module patterns
- Improve error messages

### Documentation

**Completed:**
- ✅ CLAUDE.md (AI assistant instructions)
- ✅ docs/CACHIX.md (binary cache guide)
- ✅ README.md updates
- ✅ Organized docs/ directory

**Remaining:**
- Module usage examples
- Advanced configuration guide
- Performance tuning guide
- Security hardening guide

---

## Success Metrics

### Week 1 Complete When:
- ✅ Binary cache operational
- ✅ All 49 packages building
- ✅ Documentation reorganized
- ✅ CI/CD updated

### Month 1 Complete When:
- ✅ 50+ packages
- ✅ Community awareness campaign
- ✅ Comprehensive documentation
- ✅ Automated testing

### Production Ready When:
- ✅ All packages tested
- ✅ Binary cache stable
- ✅ Documentation complete
- ✅ Community adoption
- ✅ Regular maintenance

---

## Package Development Workflow

### Adding a New Package

1. **Research:**
   - Verify package is ATProto-related
   - Check license compatibility
   - Identify correct organization

2. **Package:**
   - Create `pkgs/ORGANIZATION/package-name.nix`
   - Pin to specific commit (not "main")
   - Calculate real hashes (no `lib.fakeHash`)
   - Test build on multiple platforms

3. **Module:**
   - Create `modules/ORGANIZATION/package-name.nix`
   - Follow existing module patterns
   - Add configuration validation
   - Include examples in comments

4. **Test:**
   - Add VM test if applicable
   - Test module configuration
   - Verify backward compatibility

5. **Document:**
   - Add to README.md
   - Update package count
   - Add to organizational section

6. **Commit:**
   ```bash
   git add pkgs/ORGANIZATION/ modules/ORGANIZATION/
   git commit -m "feat(ORGANIZATION): add package-name"
   ```

### Updating a Package

1. **Check Upstream:**
   - Review changelog
   - Note breaking changes
   - Check for security fixes

2. **Update:**
   - Update `rev` to new commit SHA
   - Recalculate hash (will fail first, shows correct hash)
   - Update version string
   - Update dependencies if needed

3. **Test:**
   - Build package
   - Test module still works
   - Check backward compatibility

4. **Commit:**
   ```bash
   git commit -m "chore(ORGANIZATION): update package-name to vX.Y.Z"
   ```

---

## Architecture Decisions

### Organizational Structure
**Decision:** Organize by maintainer/organization
**Rationale:**
- Easy to find packages by author
- Reflects real-world ecosystem
- Clear ownership
- Natural grouping

### Module Naming
**Decision:** `services.ORGANIZATION-package-name`
**Rationale:**
- Prevents naming conflicts
- Clear package source
- Consistent pattern
- Backward compatibility via aliases

### Version Pinning
**Decision:** Always pin to specific commits
**Rationale:**
- Reproducible builds
- No surprise breakage
- Clear audit trail
- Explicit updates

### Binary Cache
**Decision:** Cachix for binary distribution
**Rationale:**
- Free for open source
- Excellent GitHub Actions integration
- Wide adoption in Nix community
- Easy user setup

---

## Resources

### Documentation
- [AT Protocol Docs](https://atproto.com)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Package Manager](https://nixos.org/manual/nix/stable/)
- [Cachix Docs](https://docs.cachix.org/)

### Community
- [ATProto Discord](https://discord.gg/atproto)
- [NixOS Discourse](https://discourse.nixos.org/)
- [NixOS Matrix](https://matrix.to/#/#nixos:nixos.org)

### Development
- [Crane Documentation](https://crane.dev/) - Rust builds
- [nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
- [MCP-NixOS](https://mcp-nixos.io/) - AI-assisted development

---

## Questions & Decisions

### Open Questions

1. **Automation:**
   - Should we auto-update packages?
   - How often to run dependency checks?

2. **Testing:**
   - What's the right test coverage target?
   - Should we test on all 4 platforms?

3. **Community:**
   - What's the best way to gather feedback?
   - Should we create a Discord/Matrix channel?

4. **Upstream:**
   - Which packages to submit to nixpkgs?
   - How to coordinate with package maintainers?

### Decisions Made

✅ **Organization:** By maintainer/organization
✅ **Naming:** Flattened (org-package) for packages
✅ **Modules:** Nested (services.org-package)
✅ **Compatibility:** Aliases for renamed services
✅ **Binary Cache:** Cachix (not self-hosted)
✅ **Documentation:** Markdown in docs/ directory
✅ **Languages:** Support all (Rust, Go, Node.js, Ruby, etc.)

---

## Current Focus

**This Week:**
1. ✅ Complete documentation reorganization
2. ⏳ Add Cachix GitHub secret
3. ⏳ Test all package builds
4. ⏳ Update CI/CD workflows

**Next Week:**
1. Monitor binary cache usage
2. Expand test coverage
3. Create additional deployment guides
4. Community announcement

**This Month:**
1. Reach 50+ packages
2. Achieve 100% test coverage
3. Complete all documentation
4. Launch community outreach

---

**Status:** Repository is production-ready for early adopters. Binary cache and expanded documentation will make it ready for wider adoption.

**Next Action:** Add `CACHIX_AUTH_TOKEN` GitHub secret to enable binary cache.
