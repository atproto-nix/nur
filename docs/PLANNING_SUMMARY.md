# Planning Summary - October 2025

This document summarizes the planning work completed in October 2025 to improve the ATProto NUR.

## Documents Created

### 1. JAVASCRIPT_DENO_BUILDS.md
**Purpose**: Guide developers on deterministic JavaScript/Deno builds with external bundlers
**Length**: 9.0K
**Key Content**:
- Root cause analysis of Vite/esbuild nondeterminism
- Fixed-Output Derivation (FOD) pattern explanation
- Language-specific patterns (Deno, Deno+Vite, npm monorepos)
- Troubleshooting and testing procedures
- References to problematic packages: pds-dash, slices, frontpage

**Status**: Complete ✅

---

### 2. LIB_PACKAGING_IMPROVEMENTS.md
**Purpose**: Strategic plan to improve lib/packaging.nix for the NUR's needs
**Length**: 14K
**Key Content**:
- Current assessment of 944-line lib/packaging.nix
- Analysis of gaps vs. strengths
- 4-phase improvement plan (~20 hours total)
- Proposed new FOD helpers and determinism utilities
- Implementation timeline and testing strategy

**Proposed Additions to lib/packaging.nix**:
- Phase 1: `buildDenoAppWithFOD`, `buildNpmWithFOD`, `buildPnpmWorkspaceWithFOD`
- Phase 2: `mkDeterministicNodeEnv`, `applyDeterminismFlags`, `validateBuildDeterminism`
- Phase 3: API improvements, consistent error handling
- Phase 4: Universal bundler wrappers, fallback patterns

**Status**: Complete ✅

---

### 3. PACKAGE_FIXES_PLAN.md
**Purpose**: Actionable plan to fix 3 critical packages and 2 code quality issues
**Length**: 6.8K
**Key Content**:
- Fix pds-dash unpinned version (15 min)
- Calculate frontpage npmDepsHash (1-2 hours)
- Clean up rsky commented code (10 min)
- Fix yoten aarch64 placeholder (15 min)
- Document build patterns (1 hour)
- Timeline: 2.5-3.5 hours total

**Status**: Complete ✅

---

## Updated Documentation

### CLAUDE.md
**Changes**:
- Added section on JavaScript/Deno with External Builders
- Updated Repository Status with Oct 2025 review grade (A-)
- Added Known Issues section for nondeterminism cases
- Referenced new docs/JAVASCRIPT_DENO_BUILDS.md
- Updated lib files section to reference lib/packaging.nix improvements

**Status**: Updated ✅

---

### docs/README.md
**Changes**:
- Added "Quick Links by Task" section for faster navigation
- Added entry for LIB_PACKAGING_IMPROVEMENTS.md
- Clarified what each document covers and who should read it

**Status**: Updated ✅

---

## Key Findings from Review

### Package Quality (October 2025)
- **Overall Grade**: A- (95% compliance)
- **Total Packages**: ~45 across 18 organizations
- **Lines of Code**: ~5,135 lines
- **Multi-platform**: x86_64/aarch64 Linux/Darwin

### Strengths ✅
- Excellent organizational structure
- Comprehensive build helpers
- Custom Tangled.org fetcher
- Rich metadata throughout
- Complex builds handled correctly (yoten example)

### Issues Found ⚠️
**Critical Issues**:
1. pds-dash: unpinned `rev = "main"` (reproducibility violation)
2. frontpage: missing `npmDepsHash` (build blocker)
3. slices: no FOD for dependency caching

**Nondeterminism Cases**:
- pds-dash + Vite: Chunk hashes change per build
- slices + codegen: Unknown builder determinism
- frontpage + pnpm: Workspace bundling non-deterministic

**Code Quality**:
- yoten: aarch64-linux hash placeholder
- rsky: Large commented code block

---

## Recommended Next Steps

### Immediate (Week 1)
1. Fix pds-dash unpinned version
2. Clean up rsky commented code
3. Fix yoten aarch64 placeholder

**Effort**: ~40 minutes
**Impact**: HIGH (unblocks further work, improves code quality)

### Short Term (Week 2)
4. Calculate frontpage npmDepsHash
5. Migrate packages to FOD pattern (once lib/packaging.nix updated)

**Effort**: 2-3 hours
**Impact**: HIGH (fixes build blockers, ensures reproducibility)

### Medium Term (Weeks 3-4)
6. Implement Phase 1 of lib/packaging.nix improvements
   - Add FOD helpers
   - Update existing builders
   - Document with examples

**Effort**: 6-8 hours
**Impact**: VERY HIGH (enables deterministic builds for future packages)

### Long Term (Weeks 5+)
7. Implement Phases 2-4 of lib/packaging.nix improvements
8. Migrate all JavaScript/Deno packages to new patterns
9. Add CI/CD checks for nondeterminism

**Effort**: 12-14 hours
**Impact**: STRATEGIC (platform-wide improvement)

---

## Documentation Hierarchy

```
CLAUDE.md (Main reference)
├── Points to docs/JAVASCRIPT_DENO_BUILDS.md
├── Points to docs/LIB_PACKAGING_IMPROVEMENTS.md
├── References PACKAGE_FIXES_PLAN.md
└── Links to specific package files

docs/README.md (Quick navigation)
├── Quick links by task
├── Links to all major docs
└── Cross-references

PACKAGE_FIXES_PLAN.md (Action items)
├── Specific packages to fix
├── Step-by-step instructions
└── Testing checklist

docs/JAVASCRIPT_DENO_BUILDS.md (How-to guide)
├── Root cause analysis
├── FOD pattern explanation
├── Language-specific patterns
└── Troubleshooting

docs/LIB_PACKAGING_IMPROVEMENTS.md (Strategic plan)
├── Current assessment
├── Gap analysis
├── Phased improvements
└── Implementation timeline

docs/PLANNING_SUMMARY.md (This document)
├── Documents created
├── Key findings
├── Next steps
└── Effort estimates
```

---

## Success Metrics

### By End of Week 1
- [ ] 3 critical package fixes applied and tested
- [ ] Code quality improved (no fakeHash, no unpinned revisions)

### By End of Week 2
- [ ] frontpage npmDepsHash calculated
- [ ] All packages build successfully
- [ ] No `lib.fakeHash` in committed code

### By End of Month
- [ ] Phase 1 lib/packaging.nix improvements merged
- [ ] FOD helpers available for new packages
- [ ] 2-3 packages migrated to new pattern
- [ ] Documentation complete

### By End of Quarter
- [ ] All JavaScript/Deno packages deterministic
- [ ] CI/CD checks in place
- [ ] lib/packaging.nix is reference implementation
- [ ] Community can easily add new packages

---

## Resources

### Documentation
- CLAUDE.md - Central reference
- docs/JAVASCRIPT_DENO_BUILDS.md - Bundler patterns
- docs/LIB_PACKAGING_IMPROVEMENTS.md - Strategic plan
- PACKAGE_FIXES_PLAN.md - Immediate action items

### Tools
- nix flake check - Verify all packages
- nixpkgs-fmt - Format Nix files
- diffoscope - Compare determinism
- nix-unit - Unit test Nix code

### External References
- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Reproducible Builds](https://reproducible-builds.org/)
- [Vite Documentation](https://vitejs.dev/)
- [Deno Manual](https://docs.deno.com/)

---

## Questions for Discussion

1. **Priority**: Should we implement all of lib/packaging.nix improvements at once, or phase them in?
   - Options: (a) Big PR, (b) Multiple small PRs, (c) Experimental branch
   - Recommendation: (b) Multiple small PRs for easier review

2. **Breaking Changes**: Should we deprecate old patterns or keep them working?
   - Options: (a) Require migration, (b) Warn, (c) Keep working
   - Recommendation: (c) Keep working with deprecation warnings

3. **Testing**: Should we add automated determinism testing to CI?
   - Options: (a) Yes (expensive), (b) Manual checks (risk), (c) Sampling (compromise)
   - Recommendation: (c) Sample 3 packages on each PR, full test weekly

4. **Documentation**: Should we document in code or separate docs?
   - Options: (a) Code comments only, (b) External docs only, (c) Both
   - Recommendation: (c) Both - examples in code, deep dives in docs

---

## Conclusion

The October 2025 review revealed a high-quality codebase (A-) with excellent structure but specific gaps around JavaScript/Deno determinism. Clear, actionable plans have been created to:

1. **Fix immediate issues** (PACKAGE_FIXES_PLAN.md) - ~3 hours
2. **Guide future developers** (JAVASCRIPT_DENO_BUILDS.md) - Documentation
3. **Improve tools** (LIB_PACKAGING_IMPROVEMENTS.md) - Strategic plan

The repository is well-positioned for growth with these improvements in place.

---

**Created**: October 28, 2025
**Review Grade**: A- (95% compliance)
**Next Phase**: Immediate fixes + Phase 1 lib/packaging.nix improvements
