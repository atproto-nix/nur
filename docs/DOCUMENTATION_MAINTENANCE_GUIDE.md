# Documentation Maintenance Guide

Quick reference for keeping documentation synchronized with code changes.

---

## When You Make Code Changes

### Adding a New Package

**Files to Update:**
1. ✅ `README.md` - Add to appropriate category
2. ✅ `pkgs/ORGANIZATION/default.nix` - Export the package
3. ✅ `modules/ORGANIZATION/` - Create NixOS module
4. ✅ `modules/default.nix` - Add module import (if new organization)
5. 📋 `CLAUDE.md` - Update package count (line 653: "50+ packages")
6. 📋 `ROADMAP.md` - Note new package in recent work

**Verification Checklist:**
- [ ] Package appears in `nix flake show`
- [ ] `nix build .#org-package-name` works
- [ ] Module path `services.org-package-name` is accessible
- [ ] README example uses correct package name format

---

### Fixing a Bug or Adding a Feature

**Files to Check:**
1. 📋 **CLAUDE.md** - If fixing a known issue, update troubleshooting section (lines 524-607)
2. 📋 **ROADMAP.md** - Update "Recent Completions" or "Current Focus"
3. 📋 **CODE_REVIEW_AND_COMMENTS.md** - If architectural change, note impact
4. 💾 **Commit message** - Reference relevant documentation

**When to Update Documentation:**
- Bug fixes affecting user-facing behavior → Update ROADMAP.md
- Critical issue resolution → Add to CLAUDE.md Troubleshooting
- Performance improvements → Update ROADMAP.md
- New patterns discovered → Update NUR_BEST_PRACTICES.md

---

### Changing Package Organization

**Files to Update:**
1. ✅ `pkgs/ORGANIZATION/` - Move files as needed
2. ✅ `modules/ORGANIZATION/` - Move corresponding modules
3. 📋 `README.md` - Update organizational section (lines 500-517)
4. 📋 `PACKAGES_AND_MODULES_GUIDE.md` - Update examples if organizational structure changed
5. 📋 `ROADMAP.md` - Document refactoring in recent work

**Example:** When tangled-dev → tangled refactoring happened:
- Updated README.md organizational section
- Updated CLAUDE.md package naming patterns
- Added to ROADMAP.md Phase 1 completions

---

### Updating Dependencies or Inputs

**Files to Check:**
1. 📋 `CLAUDF.md` - Update if flake inputs changed (lines 477-487)
2. 📋 `NUR_BEST_PRACTICES.md` - If input strategy changed (lines 97-114)
3. 📋 `ROADMAP.md` - If major version bumps

**Example:** When updating nixpkgs, rust-overlay versions:
- Note in ROADMAP.md "Flake inputs updated"
- Update CLAUDE.md if new overlays added
- Check if any packages affected by new nixpkgs

---

### Adding/Removing Services

**Files to Update:**
1. ✅ `modules/ORGANIZATION/` - Add/remove service module
2. ✅ `modules/ORGANIZATION/default.nix` - Update module list
3. 📋 `README.md` - Update NixOS modules section (lines 185-247)
4. 📋 `modules/default.nix` - If new organization, update module list
5. 📋 `CLAUDF.md` - Update module architecture if significant change

**Related Documentation:**
- Individual service guides (RED_DWARF.md, TANGLED.md, etc.) should reference new modules

---

## Documentation Files by Purpose

### Core Reference (Primary Source of Truth)

| File | Purpose | Update When |
|------|---------|------------|
| **README.md** | Public-facing, user guide | Adding packages, major changes |
| **CLAUDE.md** | Technical guide, troubleshooting | New patterns, fixes, architecture |
| **flake.nix** | Source of truth for packages | Every package change |
| **NUR_BEST_PRACTICES.md** | Architecture & patterns | New best practices discovered |

### Architecture & Design

| File | Purpose | Update When |
|------|---------|------------|
| **CODE_REVIEW_AND_COMMENTS.md** | Architectural review | Major refactoring |
| **NUR_BEST_PRACTICES.md** | Design patterns | New patterns established |
| **MODULES_ARCHITECTURE_REVIEW.md** | Module ecosystem analysis | Module structure changes |
| **PACKAGES_AND_MODULES_GUIDE.md** | Contributor guide | Process changes |

### Feature-Specific Guides

| File | Purpose | Update When |
|------|---------|------------|
| **JAVASCRIPT_DENO_BUILDS.md** | Deno build patterns | New Deno packages |
| **SECRETS_INTEGRATION.md** | Secrets management | Backend changes |
| **MCP_INTEGRATION.md** | AI assistant setup | MCP features change |
| **CACHIX.md** | Binary cache | Cache configuration changes |

### Service Guides

| File | Purpose | Update When |
|------|---------|------------|
| **guides/RED_DWARF.md** | Red Dwarf deployment | Service changes |
| **guides/TANGLED.md** | Tangled stack deployment | Service changes |
| **PDS_DASH_*.md** (3 files) | PDS Dashboard guides | Dashboard changes |
| **SLICES_*.md** (2 files) | Slices AppView guides | Slices changes |

### Project Management

| File | Purpose | Update When |
|------|---------|------------|
| **ROADMAP.md** | Development plan | Every release/milestone |
| **DOCUMENTATION_STATUS.md** | Documentation health | Monthly maintenance |
| **PLANNING_SUMMARY.md** | Planning notes | Feature planning |

---

## Verification Commands

Use these to verify documentation is accurate:

```bash
# List all packages
nix flake show 2>&1 | grep "package '"

# Verify module imports
nix flake show 2>&1 | grep "nixosModule"

# Check package count
nix eval '.#packages.x86_64-linux' --json | jq 'length'

# Verify specific package
nix flake check --build-timeout 5

# Check module exists
nix eval '.#nixosModules.default' 2>&1 | head -20
```

---

## Documentation Update Workflow

### Before Committing Code

```bash
# 1. Make code changes
# 2. Run verification (see above)
# 3. Update relevant docs
git diff docs/  # Review documentation changes
# 4. Verify code examples still work
# 5. Commit with reference to docs
git commit -m "feat(org): add package; update README + ROADMAP"
```

### Monthly Documentation Review

```bash
# 1. Read DOCUMENTATION_STATUS.md
# 2. Check "Files Needing Minor Updates" section
# 3. For each file:
#    - Open file
#    - Verify package names match current code
#    - Verify service paths are correct
#    - Check for broken examples
# 4. Commit any fixes
#    git commit -m "docs: verify and update minor doc references"
```

### Release Checklist

Before releasing a new version:
- [ ] Update ROADMAP.md with new milestone
- [ ] Verify all package counts in documentation
- [ ] Update CLAUDE.md if new patterns added
- [ ] Check guides for outdated information
- [ ] Run verification commands (above)
- [ ] Update README.md recent changes section
- [ ] Create CHANGELOG entry linking to updated docs

---

## Common Documentation Patterns

### Adding a New Service to a Guide

**Template for guides (RED_DWARF.md, TANGLED.md, etc.):**

```markdown
### 3. ServiceName (`org-service-name`)
**Purpose:** What this service does
**What it does:** Detailed description of functionality
**Depends on:** Other services it needs

**Package:** `atproto-nur.packages.x86_64-linux.org-service-name`
**Module:** `atproto-nur.nixosModules.org` → `services.org-service-name`
```

### Updating Code Examples

Always verify examples with:
```bash
# For NixOS module examples
nix eval '.#nixosModules.org-service' -q  # Verify module exists

# For flake examples
nix flake show  # Verify package exists

# For Nix code
nix eval '.#org-service' --json | head -5  # Test evaluation
```

### Referencing Sections in CLAUDE.md

When documentation has cross-references:
- Use markdown links: `[Section Name](./CLAUDE.md#section-name)`
- Format section headers with `##` for easy linking
- Test links with: `grep "^## " CLAUDE.md`

---

## Quick Reference: Files by Organization

When working with a specific organization, check these files:

### Microcosm (Rust services)
- Package list: `pkgs/microcosm/default.nix`
- Modules: `modules/microcosm/`
- Documentation: README.md § Microcosm Services
- Guides: CLAUDE.md § Rust Packages

### Grain Social (Deno + Rust)
- Package list: `pkgs/grain-social/default.nix`
- Modules: `modules/grain-social/`
- Documentation: README.md § Grain Social
- Build patterns: JAVASCRIPT_DENO_BUILDS.md

### Tangled (Go infrastructure)
- Package list: `pkgs/tangled/default.nix`
- Modules: `modules/tangled/`
- Documentation: README.md § Tangled Infrastructure
- Deployment guide: guides/TANGLED.md

### Bluesky (Official)
- Package list: `pkgs/bluesky/default.nix`
- Modules: `modules/bluesky/`
- Architecture: INDIGO_ARCHITECTURE.md
- Quick start: INDIGO_QUICK_START.md

### Blacksky (Community)
- Package list: `pkgs/blacksky/default.nix`
- Modules: `modules/blacksky/`
- Documentation: README.md § Blacksky/Rsky

---

## Documentation Style Guide

### Code Examples
- Use triple backticks with language specification
- Include full working examples (not snippets)
- Test all examples before committing
- Show output when helpful

### Service Names
- Use full name format: `org-service-name`
- Example: `microcosm-constellation` (not just `constellation`)
- In configuration: `services.org-service-name`

### Links
- Use relative links: `[CLAUDE.md](./CLAUDE.md)`
- Use full links for external: `[NixOS](https://nixos.org/)`
- Test all links before committing

### Sections
- Use `#` for H1 (file title only)
- Use `##` for H2 (main sections)
- Use `###` for H3 (subsections)
- Use `####` for H4 (fine details)

---

## Reporting Documentation Issues

When you find outdated documentation:

1. **Check DOCUMENTATION_STATUS.md** - Is it a known issue?
2. **Create an issue** with:
   - File name and line number
   - What's wrong (outdated, incorrect, missing)
   - What should be there instead
   - Severity (broken example, misleading, minor typo)
3. **Link to relevant code** - Reference flake.nix, modules, etc.
4. **Provide fix suggestion** - What text should replace current?

---

**Last Updated:** November 11, 2025
**Maintenance Interval:** Monthly (or with major releases)
**Owner:** Repository maintainers
