# Documentation

This directory contains guides and references for working with the ATProto NUR.

## Quick Links by Task

- **Packaging Deno/JS projects?** → [JAVASCRIPT_DENO_BUILDS.md](./JAVASCRIPT_DENO_BUILDS.md)
- **Using lib/packaging.nix?** → [LIB_PACKAGING_IMPROVEMENTS.md](./LIB_PACKAGING_IMPROVEMENTS.md)
- **Improving packaging.nix?** → [LIB_PACKAGING_IMPROVEMENTS.md](./LIB_PACKAGING_IMPROVEMENTS.md)
- **Modularizing packaging.nix?** → [MODULAR_PACKAGING_PLAN.md](./MODULAR_PACKAGING_PLAN.md)
- **Adding a new build tool?** → [MODULAR_PACKAGING_PLAN.md](./MODULAR_PACKAGING_PLAN.md#adding-a-new-build-tool)
- **Best practices per language?** → [MODULAR_PACKAGING_PLAN.md](./MODULAR_PACKAGING_PLAN.md#best-practices-per-languagetool)
- **NixOS integration?** → [MCP_INTEGRATION.md](./MCP_INTEGRATION.md)

## Core Documentation

### [JAVASCRIPT_DENO_BUILDS.md](./JAVASCRIPT_DENO_BUILDS.md)
Comprehensive guide to building JavaScript and Deno projects with external build tools (Vite, esbuild, etc.).

**Key Topics**:
- Nondeterminism issues with bundlers
- Fixed-Output Derivation (FOD) pattern for dependency caching
- Language-specific patterns (pure Deno, Deno + Vite, npm monorepos)
- Hash calculation and troubleshooting
- Examples from the repository

**Related Packages**:
- `pkgs/witchcraft-systems/pds-dash.nix` - Deno + Vite
- `pkgs/slices-network/slices.nix` - Deno + codegen + compilation
- `pkgs/likeandscribe/frontpage.nix` - pnpm workspace with bundler

**Read this if**: You're packaging Deno projects, dealing with build determinism issues, or working with JavaScript bundlers in Nix.

### [LIB_PACKAGING_IMPROVEMENTS.md](./LIB_PACKAGING_IMPROVEMENTS.md)
Strategic plan to improve `lib/packaging.nix` for better JavaScript/Deno support.

**Key Topics**:
- Current assessment of lib/packaging.nix (944 lines)
- Critical gaps: FOD helpers, determinism controls, hash validation
- Proposed improvements organized in 4 phases
- Implementation strategy with timeline (~20 hours)
- Testing and documentation plans

**Proposes**:
- New FOD helpers: `buildDenoAppWithFOD`, `buildNpmWithFOD`, `buildPnpmWorkspaceWithFOD`
- Determinism helpers: `mkDeterministicNodeEnv`, `applyDeterminismFlags`
- Validation: `validateBuildDeterminism`
- Better error handling and examples

**Read this if**: You're planning to improve lib/packaging.nix, or want to understand what helpers we need for deterministic builds.

### [MODULAR_PACKAGING_PLAN.md](./MODULAR_PACKAGING_PLAN.md)
Strategic architectural plan to break up `lib/packaging.nix` into language and tool-specific submodules.

**Key Topics**:
- Current monolithic structure problems
- Proposed modular directory hierarchy (Rust, Node.js, Go, Deno by language, then build tools)
- Best practices per language and build tool (with examples)
- How to add new build tools (esbuild, bundlers, etc.)
- Migration strategy with backward compatibility
- Testing and validation approach

**Proposes**:
- `/lib/packaging/{rust,nodejs,go,deno}/` language modules
- `/lib/packaging/nodejs/bundlers/{vite,esbuild}/` tool-specific helpers
- `/lib/packaging/determinism/` for FOD and determinism validation
- `/lib/packaging/shared/` for cross-cutting concerns
- Module size: Each <300 lines for clarity

**Benefits**:
- Discoverability (find tools by language)
- Maintainability (changes isolated to modules)
- Extensibility (add bundlers without editing monolithic file)
- Clarity (understand relationships clearly)

**Read this if**: You're architecting the modular structure, adding new build tools, or want to understand best practices per language.

---

## Parent Documentation

See `../CLAUDE.md` for:
- Project overview
- Repository structure
- Build system patterns
- Common commands
- Best practices

See `../PACKAGE_FIXES_PLAN.md` for:
- Specific package fixes needed (Oct 2025)
- Timeline and action items
- Testing checklist
