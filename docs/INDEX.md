# ATProto NUR Documentation Index

**Welcome to the Complete Documentation Hub for the ATProto Nix User Repository**

This is your central entry point for all documentation. Navigate by your role, find specific topics, or explore the complete guide structure.

---

## 🎯 By Role

### 👤 I'm a User Installing Packages

Start here for package installation and basic usage:

1. **[README.md](../README.md)** - Quick start, package overview, common commands
2. **[CLAUDE.md](./CLAUDE.md)** - Detailed technical guide for users and developers

### 🏗️ I'm Deploying a Service

Choose your service below:

- **Running a PDS Dashboard?** → [PDS_DASHBOARD_INDEX.md](./PDS_DASHBOARD_INDEX.md)
- **Setting up ATProto Relay?** → [INDIGO_INDEX.md](./INDIGO_INDEX.md)
- **Configuring Any NixOS Module?** → [MODULES_INDEX.md](./MODULES_INDEX.md)

### 🔧 I'm Contributing or Developing

Guides for building and extending:

1. **[NUR_BEST_PRACTICES.md](./NUR_BEST_PRACTICES.md)** - Architecture and design patterns
2. **[PACKAGES_AND_MODULES_GUIDE.md](./PACKAGES_AND_MODULES_GUIDE.md)** - How to create packages and modules
3. **[JAVASCRIPT_DENO_BUILDS.md](./JAVASCRIPT_DENO_BUILDS.md)** - Deterministic builds for JavaScript/Deno

### 🔐 I'm Managing Secrets

Secrets and credential management:

1. **[SECRETS_INTEGRATION.md](./SECRETS_INTEGRATION.md)** - Secrets management patterns and backends

### 📊 I'm Planning or Reviewing

Planning, roadmaps, and status:

1. **[ROADMAP.md](./ROADMAP.md)** - Development roadmap and recent work
2. **[DOCUMENTATION_STATUS.md](./DOCUMENTATION_STATUS.md)** - Health audit of all documentation
3. **[DOCUMENTATION_MAINTENANCE_GUIDE.md](./DOCUMENTATION_MAINTENANCE_GUIDE.md)** - How to keep docs updated

---

## 📚 By Topic

### Service Deployment & Configuration
- **[PDS_DASHBOARD_INDEX.md](./PDS_DASHBOARD_INDEX.md)** - PDS Dashboard setup and configuration
  - [PDS_DASH_THEMED_GUIDE.md](./PDS_DASH_THEMED_GUIDE.md) - Complete integration guide
  - [PDS_DASH_EXAMPLES.md](./PDS_DASH_EXAMPLES.md) - Real-world configuration examples
  - [PDS_DASH_IMPLEMENTATION_SUMMARY.md](./PDS_DASH_IMPLEMENTATION_SUMMARY.md) - Technical details

- **[INDIGO_INDEX.md](./INDIGO_INDEX.md)** - ATProto Relay and discovery services
  - [INDIGO_QUICK_START.md](./INDIGO_QUICK_START.md) - Fast setup reference
  - [INDIGO_SERVICES.md](./INDIGO_SERVICES.md) - All 10 services explained
  - [INDIGO_ARCHITECTURE.md](./INDIGO_ARCHITECTURE.md) - Architecture and relationships

- **[MODULES_INDEX.md](./MODULES_INDEX.md)** - NixOS module system
  - [PACKAGES_AND_MODULES_GUIDE.md](./PACKAGES_AND_MODULES_GUIDE.md) - Using modules for deployment
  - [MODULES_ARCHITECTURE_REVIEW.md](./MODULES_ARCHITECTURE_REVIEW.md) - 74 modules across 23 directories
  - [PACKAGES_VS_MODULES_ANALYSIS.md](./PACKAGES_VS_MODULES_ANALYSIS.md) - Package and module alignment
  - [NIXOS_MODULES_CONFIG.md](./NIXOS_MODULES_CONFIG.md) - Configuration patterns

### Package Management & Build Patterns
- **[CLAUDE.md](./CLAUDE.md)** - Common commands, build patterns, troubleshooting
- **[NUR_BEST_PRACTICES.md](./NUR_BEST_PRACTICES.md)** - Architectural patterns and best practices
- **[JAVASCRIPT_DENO_BUILDS.md](./JAVASCRIPT_DENO_BUILDS.md)** - Deterministic JavaScript/Deno builds
- **[TANGLED.md](./TANGLED.md)** - Tangled.org infrastructure overview

### Infrastructure & Operations
- **[SECRETS_INTEGRATION.md](./SECRETS_INTEGRATION.md)** - Secrets management (agenix, sops-nix)
- **[WORKERD_INTEGRATION.md](./WORKERD_INTEGRATION.md)** - Cloudflare Workers runtime self-hosting
- **[KONBINI_FIX.md](./KONBINI_FIX.md)** - Konbini service setup and troubleshooting
- **[STREAMPLACE_SETUP.md](./STREAMPLACE_SETUP.md)** - Streamplace configuration guide

### Service-Specific Guides
- **[RED_DWARF.md](./RED_DWARF.md)** - Red Dwarf web client
- **[SLICES_QUICK_REFERENCE.md](./SLICES_QUICK_REFERENCE.md)** - Slices network operations
- **[SLICES_NIXOS_DEPLOYMENT_GUIDE.md](./SLICES_NIXOS_DEPLOYMENT_GUIDE.md)** - Full deployment guide

### Architecture & Planning
- **[ROADMAP.md](./ROADMAP.md)** - Development roadmap, recent completions, planned work
- **[DOCUMENTATION_STATUS.md](./DOCUMENTATION_STATUS.md)** - Complete audit of all 34 docs
- **[DOCUMENTATION_MAINTENANCE_GUIDE.md](./DOCUMENTATION_MAINTENANCE_GUIDE.md)** - Keeping docs current
- **[MCP_INTEGRATION.md](./MCP_INTEGRATION.md)** - MCP-NixOS integration for real-time package info

---

## 📋 Complete Documentation List

### Quick Navigation Indexes (Entry Points)
| File | Purpose |
|------|---------|
| **[INDEX.md](./INDEX.md)** (this file) | Main documentation hub - you are here |
| **[PDS_DASHBOARD_INDEX.md](./PDS_DASHBOARD_INDEX.md)** | Quick navigation for PDS Dashboard |
| **[INDIGO_INDEX.md](./INDIGO_INDEX.md)** | Quick navigation for Indigo relay services |
| **[MODULES_INDEX.md](./MODULES_INDEX.md)** | Quick navigation for NixOS modules |

### Service Deployment Guides (Use-case specific)
| File | Purpose | Scope |
|------|---------|-------|
| **[PDS_DASH_THEMED_GUIDE.md](./PDS_DASH_THEMED_GUIDE.md)** | Complete PDS Dashboard guide | 4 themes, SSL, examples |
| **[PDS_DASH_EXAMPLES.md](./PDS_DASH_EXAMPLES.md)** | Configuration examples ready to use | 6 scenarios (standalone, SSL, multi-instance) |
| **[PDS_DASH_IMPLEMENTATION_SUMMARY.md](./PDS_DASH_IMPLEMENTATION_SUMMARY.md)** | Technical implementation details | Architecture, components, build system |
| **[INDIGO_QUICK_START.md](./INDIGO_QUICK_START.md)** | Fast relay setup reference | Basic relay deployment |
| **[INDIGO_SERVICES.md](./INDIGO_SERVICES.md)** | All Indigo services explained | 10 services with configurations |
| **[INDIGO_ARCHITECTURE.md](./INDIGO_ARCHITECTURE.md)** | Service architecture and relationships | Deployment patterns |

### Package & Module Documentation
| File | Purpose |
|------|---------|
| **[PACKAGES_AND_MODULES_GUIDE.md](./PACKAGES_AND_MODULES_GUIDE.md)** | How to deploy services, module configuration |
| **[MODULES_ARCHITECTURE_REVIEW.md](./MODULES_ARCHITECTURE_REVIEW.md)** | Complete analysis of 74 NixOS modules |
| **[PACKAGES_VS_MODULES_ANALYSIS.md](./PACKAGES_VS_MODULES_ANALYSIS.md)** | Package/module alignment inventory |
| **[NIXOS_MODULES_CONFIG.md](./NIXOS_MODULES_CONFIG.md)** | Configuration patterns and best practices |

### Technical Reference
| File | Purpose |
|------|---------|
| **[CLAUDE.md](./CLAUDE.md)** | AI assistant guide, technical details, build patterns, troubleshooting |
| **[NUR_BEST_PRACTICES.md](./NUR_BEST_PRACTICES.md)** | Architecture patterns, packaging guidelines, design principles |
| **[JAVASCRIPT_DENO_BUILDS.md](./JAVASCRIPT_DENO_BUILDS.md)** | Deterministic JavaScript/Deno builds, FOD patterns |
| **[TANGLED.md](./TANGLED.md)** | Tangled.org infrastructure details |

### Service-Specific Guides
| File | Purpose |
|------|---------|
| **[KONBINI_FIX.md](./KONBINI_FIX.md)** | Konbini service setup and operations |
| **[RED_DWARF.md](./RED_DWARF.md)** | Red Dwarf web client configuration |
| **[STREAMPLACE_SETUP.md](./STREAMPLACE_SETUP.md)** | Streamplace streaming service setup |
| **[SLICES_QUICK_REFERENCE.md](./SLICES_QUICK_REFERENCE.md)** | Slices network operations quick reference |
| **[SLICES_NIXOS_DEPLOYMENT_GUIDE.md](./SLICES_NIXOS_DEPLOYMENT_GUIDE.md)** | Complete Slices deployment guide |
| **[WORKERD_INTEGRATION.md](./WORKERD_INTEGRATION.md)** | Cloudflare Workers runtime integration |

### Infrastructure & Management
| File | Purpose |
|------|---------|
| **[SECRETS_INTEGRATION.md](./SECRETS_INTEGRATION.md)** | Secrets management patterns (agenix, sops-nix) |
| **[MCP_INTEGRATION.md](./MCP_INTEGRATION.md)** | MCP-NixOS setup for AI assistants |
| **[ROADMAP.md](./ROADMAP.md)** | Development roadmap, status updates, planned work |

### Documentation & Maintenance
| File | Purpose |
|------|---------|
| **[DOCUMENTATION_STATUS.md](./DOCUMENTATION_STATUS.md)** | Health audit of all 34 documentation files |
| **[DOCUMENTATION_MAINTENANCE_GUIDE.md](./DOCUMENTATION_MAINTENANCE_GUIDE.md)** | Procedures for keeping documentation current |

---

## 🗂️ Archive

Historical and planning documents are organized in `.archived/`:
- **[.archived/README.md](./.archived/README.md)** - Explanation of archive structure
- **[.archived/planning/](./. archived/planning/)** - Unimplemented proposals
- **[.archived/research/](././archived/research/)** - Historical research findings

---

## ⚡ Quick Start

### First Time Here?

1. **Just need packages?** → Start with [README.md](../README.md)
2. **Want to deploy a service?** → Check [PDS_DASHBOARD_INDEX.md](./PDS_DASHBOARD_INDEX.md), [INDIGO_INDEX.md](./INDIGO_INDEX.md), or [MODULES_INDEX.md](./MODULES_INDEX.md)
3. **Building new packages?** → Read [NUR_BEST_PRACTICES.md](./NUR_BEST_PRACTICES.md)

### Common Questions

| Question | See |
|----------|-----|
| How do I install a package? | [README.md § Quick Start](../README.md#quick-start) |
| How do I deploy a service? | [MODULES_INDEX.md](./MODULES_INDEX.md) |
| What build patterns are available? | [CLAUDE.md § Build Patterns](./CLAUDE.md#build-system-patterns) |
| How do I add a new package? | [NUR_BEST_PRACTICES.md](./NUR_BEST_PRACTICES.md) |
| How do I manage secrets? | [SECRETS_INTEGRATION.md](./SECRETS_INTEGRATION.md) |
| What's the project status? | [ROADMAP.md](./ROADMAP.md) |

---

## 📖 Reading Guide

### For Beginners
1. [README.md](../README.md) - Get oriented
2. [PDS_DASHBOARD_INDEX.md](./PDS_DASHBOARD_INDEX.md) or [INDIGO_INDEX.md](./INDIGO_INDEX.md) - See a real deployment
3. [MODULES_INDEX.md](./MODULES_INDEX.md) - Understand how to configure services
4. [ROADMAP.md](./ROADMAP.md) - See the bigger picture

### For Contributors
1. [NUR_BEST_PRACTICES.md](./NUR_BEST_PRACTICES.md) - Architecture and patterns
2. [CLAUDE.md](./CLAUDE.md) - Technical deep dive and troubleshooting
3. [PACKAGES_AND_MODULES_GUIDE.md](./PACKAGES_AND_MODULES_GUIDE.md) - Creating packages/modules
4. Specific service guides as needed

### For Operators/DevOps
1. [MODULES_INDEX.md](./MODULES_INDEX.md) - Find your service
2. Service-specific guides (PDS, Indigo, Slices, etc.)
3. [SECRETS_INTEGRATION.md](./SECRETS_INTEGRATION.md) - Credential management
4. [DOCUMENTATION_MAINTENANCE_GUIDE.md](./DOCUMENTATION_MAINTENANCE_GUIDE.md) - Keeping things current

---

## 🔗 Cross-Links

### Related Documentation in Main Repo
- **[README.md](../README.md)** - Package overview and quick start
- **[flake.nix](../flake.nix)** - Repository configuration
- **[pkgs/](../pkgs/)** - Package definitions
- **[modules/](../modules/)** - NixOS service modules

### External Resources
- [AT Protocol Docs](https://atproto.com) - Protocol specifications
- [Bluesky Social](https://bsky.social) - Main platform
- [Tangled.org](https://tangled.org) - Primary development platform
- [NixOS Manual](https://nixos.org/manual/nix/stable/) - Nix language reference
- [Crane Documentation](https://github.com/ipetkov/crane) - Rust builder

---

## 📊 Documentation Statistics

- **Total Files**: 34+ markdown files
- **Total Lines**: ~15,000+ lines of documentation
- **Service Guides**: 11 (PDS Dashboard, Indigo, Slices, Red Dwarf, Konbini, etc.)
- **Technical Guides**: 10 (build patterns, secrets, architecture, etc.)
- **Quick References**: 4 (navigation indexes)
- **Status**: ✅ Production-ready (Grade A)

---

## 🆘 Need Help?

1. **Can't find what you're looking for?** - Try searching this page (Ctrl+F)
2. **Looking for a specific service?** - Check [MODULES_INDEX.md](./MODULES_INDEX.md) or [PACKAGES_AND_MODULES_ANALYSIS.md](./PACKAGES_VS_MODULES_ANALYSIS.md)
3. **Having issues?** - See [CLAUDE.md § Troubleshooting](./CLAUDE.md#troubleshooting)
4. **Documentation issue?** - Check [DOCUMENTATION_MAINTENANCE_GUIDE.md](./DOCUMENTATION_MAINTENANCE_GUIDE.md)

---

**Last Updated**: November 11, 2025
**Status**: Complete and production-ready
**Maintained By**: ATProto NUR community
**License**: Same as repository

**Navigation Tip**: Use the links above to navigate. Each document has back-links to this index for easy returns.
