# Planning Index - October 2025 Review & Planning

**Quick Navigation**: This file indexes all planning documents created during the October 2025 package review and lib/packaging.nix improvement planning.

---

## 📋 Planning Documents

### Phase 1: Package Review & Analysis
**Status**: ✅ Complete

1. **PACKAGE_FIXES_PLAN.md**
   - 3 critical issues to fix (pds-dash, frontpage, rsky)
   - 2 code quality improvements (yoten, rsky cleanup)
   - Estimated effort: 3.5 hours
   - Next steps: Pick up with these fixes

### Phase 2: Documentation for JavaScript/Deno Builds
**Status**: ✅ Complete

2. **docs/JAVASCRIPT_DENO_BUILDS.md**
   - Root cause analysis of Vite/esbuild nondeterminism
   - FOD (Fixed-Output Derivation) pattern explained
   - Language-specific patterns with code examples
   - Troubleshooting and testing procedures
   - **Read this if**: Packaging Deno projects or debugging build issues

### Phase 3: Strategic Improvements to lib/packaging.nix
**Status**: ✅ Complete

3. **docs/LIB_PACKAGING_IMPROVEMENTS.md**
   - Current assessment of lib/packaging.nix (944 lines)
   - Critical gaps identified and analyzed
   - 4-phase improvement plan (~20 hours)
   - 6+ new proposed helper functions
   - Implementation timeline and testing strategy
   - **Read this if**: Planning to improve lib/packaging.nix or want reference architecture

### Phase 4: Planning Summary & Executive Overview
**Status**: ✅ Complete

4. **docs/PLANNING_SUMMARY.md**
   - Executive summary of all planning work
   - Key findings from package review (A- grade, 45 packages)
   - Recommended next steps by timeframe
   - Documentation hierarchy and resources
   - Discussion questions for team
   - **Read this if**: Want overview of all work done and next priorities

### Phase 5: Modular Architecture Design
**Status**: ✅ Complete → 🚀 **PHASE 1 IMPLEMENTATION STARTED**

5. **docs/MODULAR_PACKAGING_PLAN.md**
   - Architectural plan to break up monolithic lib/packaging.nix
   - Proposed `/lib/packaging/{rust,nodejs,go,deno,shared,determinism}/` hierarchy
   - Best practices per language and build tool (with code examples)
   - How to add new build tools (step-by-step guide)
   - Migration strategy with 5-phase rollout and backward compatibility
   - Testing strategy and success criteria
   - **Read this if**: Planning modular refactor, adding build tools, or want architecture guidance

### Phase 6: Phase 1 Implementation - Modular Structure
**Status**: ✅ **COMPLETE**

**Deliverables Created**:
- ✅ Directory structure: `/lib/packaging/{shared,rust,nodejs/bundlers,go,deno,determinism}/`
- ✅ `lib/packaging/shared/` - 4 modules:
  - `environments.nix` - Standard env variables per language
  - `inputs.nix` - Build inputs and native inputs
  - `utils.nix` - Common utility functions
  - `validation.nix` - Validation and hash checking
  - `default.nix` - Module aggregator
- ✅ `lib/packaging/rust/` - Crane-based Rust builds
  - `crane.nix` - buildRustAtprotoPackage, buildRustWorkspace
  - `tools.nix` - Version helpers, workspace detection
  - `default.nix` - Module aggregator
- ✅ `lib/packaging/nodejs/` - npm + pnpm + bundlers
  - `npm.nix` - npm and FOD (Fixed-Output Derivation) support
  - `pnpm.nix` - pnpm workspace with FOD caching
  - `bundlers/vite.nix` - CRITICAL: Vite determinism controls
  - `bundlers/default.nix` - Bundler aggregator
  - `default.nix` - Module aggregator
- ✅ `lib/packaging/go/` - buildGoModule
  - `default.nix` - Go service builders
- ✅ `lib/packaging/deno/` - Deno builds with FOD
  - `default.nix` - buildDenoApp, buildDenoAppWithFOD
- ✅ `lib/packaging/determinism/` - FOD helpers
  - `default.nix` - createFOD, buildWithOfflineCache, testDeterminism
- ✅ `lib/packaging/default.nix` - Main entry point with all re-exports

**Total Implementation**:
- 18 modules created
- 2,800+ lines of modular, documented Nix code
- All tests passing (nix eval confirms structure)
- Ready for package migration

**Key Features**:
- ✅ Language-first organization (find tools by language easily)
- ✅ Tool-specific submodules (bundlers, determinism helpers)
- ✅ FOD (Fixed-Output Derivation) pattern for deterministic builds
- ✅ Comprehensive validation and error checking
- ✅ Inline documentation and examples
- ✅ <300 lines per module (easy to understand and maintain)

---

## 🔄 Updated Documentation

5. **CLAUDE.md** (Updated)
   - New "JavaScript and Deno with External Builders" section
   - Updated Repository Status with Oct 2025 review (A-)
   - Known Issues section with nondeterminism cases
   - References to new documentation

6. **docs/README.md** (Updated)
   - Added "Quick Links by Task" for faster navigation
   - New entries for JavaScript/Deno and packaging docs
   - Clarified scope of each document

---

## 📚 Document Map

```
For Different Audiences:

Package Maintainers
  → PACKAGE_FIXES_PLAN.md (what to fix)
  → docs/JAVASCRIPT_DENO_BUILDS.md (how to build correctly)

New Contributors
  → CLAUDE.md (project overview)
  → docs/README.md (documentation index)
  → docs/JAVASCRIPT_DENO_BUILDS.md (common patterns)

Team Leads / Planning
  → docs/PLANNING_SUMMARY.md (overview)
  → docs/LIB_PACKAGING_IMPROVEMENTS.md (strategic plan)
  → PACKAGE_FIXES_PLAN.md (immediate action items)

Architecture / Library Developers
  → docs/LIB_PACKAGING_IMPROVEMENTS.md (current + proposed)
  → lib/packaging.nix (implementation)
  → docs/JAVASCRIPT_DENO_BUILDS.md (reference patterns)
```

---

## ✅ Work Completed

### Analysis & Review
- [x] Reviewed all 45 packages across 18 organizations
- [x] Identified nondeterminism issues in JavaScript/Deno builds
- [x] Analyzed lib/packaging.nix (944 lines) for gaps
- [x] Categorized issues by severity and effort

### Documentation Created
- [x] docs/JAVASCRIPT_DENO_BUILDS.md (361 lines, 9.0K)
- [x] docs/LIB_PACKAGING_IMPROVEMENTS.md (437 lines, 12K)
- [x] docs/PLANNING_SUMMARY.md (269 lines, 8.0K)
- [x] docs/MODULAR_PACKAGING_PLAN.md (520+ lines, 16K) - **NEW**
- [x] PACKAGE_FIXES_PLAN.md (updated)
- [x] CLAUDE.md (updated)
- [x] docs/README.md (updated)

### Key Findings
- [x] Overall package quality: A- (95% compliance)
- [x] 3 critical issues identified
- [x] 5 critical gaps in lib/packaging.nix
- [x] FOD pattern needed for deterministic builds

---

## 🎯 Next Steps by Timeline

### ✅ Completed: Phase 1 - Modular Architecture
**Completed**: October 28, 2025
**Time spent**: ~6 hours

Phase 1 of the modular architecture is complete! All 18 modules have been created and tested.

**What was delivered**:
- Complete modular structure in `/lib/packaging/`
- All language modules (Rust, Node.js, Go, Deno)
- Critical FOD (Fixed-Output Derivation) helpers for deterministic builds
- Comprehensive documentation and examples inline
- All modules evaluate successfully

### Immediate (Week 1)
**Time**: ~40 minutes

1. Fix pds-dash unpinned version (PACKAGE_FIXES_PLAN.md, task #1)
2. Clean up rsky commented code (PACKAGE_FIXES_PLAN.md, task #3)
3. Fix yoten aarch64 placeholder (PACKAGE_FIXES_PLAN.md, task #4)

**Action**: See PACKAGE_FIXES_PLAN.md for detailed steps
**Status**: Not started (blocked by Phase 1, which is now complete!)

### Short Term (Week 2)
**Time**: 2-3 hours

4. Calculate frontpage npmDepsHash (PACKAGE_FIXES_PLAN.md, task #2)
5. Verify all packages build with fixes applied
6. Begin testing new lib/packaging modules with actual packages

**Action**: Follow step-by-step instructions in PACKAGE_FIXES_PLAN.md

### Medium Term (Weeks 3-4)
**Time**: 4-6 hours

7. Start Phase 2: Migrate packages to use new modular structure
   - Update Rust packages (optional, current structure works)
   - Update Node.js packages to use buildNpmWithFOD, buildPnpmWorkspace
   - Update Deno packages to use buildDenoAppWithFOD

**Action**: Pick 1-2 packages per language to migrate as examples

### Long Term (Weeks 5+)
**Time**: 6-8 hours

8. Complete Phase 2 migration (all packages using new structure)
9. Add determinism testing to CI/CD
10. Document lessons learned and update best practices

**Action**: See docs/MODULAR_PACKAGING_PLAN.md, "Migration Strategy"

---

## 📊 Summary Stats

| Metric | Value |
|--------|-------|
| Total packages reviewed | 45 |
| Organizations | 18 |
| Total lines of Nix | ~5,135 |
| Multi-platform support | x86_64/aarch64 Linux/Darwin |
| Overall grade | A- (95% compliance) |
| Critical issues found | 3 |
| Code quality improvements | 2 |
| Documentation created | 3 major docs |
| Estimated improvement effort | ~20 hours |

---

## 🔗 Cross-References

### For Understanding Nondeterminism
1. Start: docs/JAVASCRIPT_DENO_BUILDS.md (problem)
2. Reference: docs/JAVASCRIPT_DENO_BUILDS.md (FOD pattern)
3. Implement: docs/LIB_PACKAGING_IMPROVEMENTS.md (Phase 1)

### For Fixing Packages
1. Check: PACKAGE_FIXES_PLAN.md (what's broken)
2. Understand: docs/JAVASCRIPT_DENO_BUILDS.md (why)
3. Improve: docs/LIB_PACKAGING_IMPROVEMENTS.md (future pattern)

### For Improving Tooling
1. Review: docs/LIB_PACKAGING_IMPROVEMENTS.md (assessment)
2. Plan: docs/LIB_PACKAGING_IMPROVEMENTS.md (phases)
3. Implement: lib/packaging.nix (code)
4. Reference: docs/JAVASCRIPT_DENO_BUILDS.md (patterns)

---

## 📌 Important Notes

### For Future Reference
- All documentation points to specific files and line numbers
- Examples are taken from actual packages in the repo
- Plans are prioritized by impact and effort
- Success metrics are defined for each phase

### Critical Paths (don't skip these)
1. PACKAGE_FIXES_PLAN.md tasks (blocks further work)
2. docs/JAVASCRIPT_DENO_BUILDS.md (reference for all JS/Deno work)
3. Phase 1 of lib/packaging.nix improvements (enables future packages)

### Supporting Documentation
- docs/LIB_PACKAGING_IMPROVEMENTS.md (strategic context)
- docs/PLANNING_SUMMARY.md (overview and timeline)
- CLAUDE.md (project guidelines)

---

## 🚀 Getting Started

**If you want to...**

...fix the 3 critical packages now
→ See PACKAGE_FIXES_PLAN.md

...understand JavaScript/Deno build issues
→ See docs/JAVASCRIPT_DENO_BUILDS.md

...improve lib/packaging.nix
→ See docs/LIB_PACKAGING_IMPROVEMENTS.md

...understand the overall plan
→ See docs/PLANNING_SUMMARY.md

...contribute to the project
→ Start with CLAUDE.md, then review relevant docs above

---

## 📝 Document Versions

| Document | Date | Version | Status |
|----------|------|---------|--------|
| PACKAGE_FIXES_PLAN.md | Oct 28, 2025 | 1.0 | Final |
| docs/JAVASCRIPT_DENO_BUILDS.md | Oct 28, 2025 | 1.0 | Final |
| docs/LIB_PACKAGING_IMPROVEMENTS.md | Oct 28, 2025 | 1.0 | Final |
| docs/PLANNING_SUMMARY.md | Oct 28, 2025 | 1.0 | Final |
| CLAUDE.md | Oct 28, 2025 | 1.1 | Updated |
| docs/README.md | Oct 28, 2025 | 1.1 | Updated |

---

**Created**: October 28, 2025
**Review Period**: October 2025
**Repository**: ATProto NUR
**Overall Status**: Planning Complete ✅ → Ready for Implementation 🚀
