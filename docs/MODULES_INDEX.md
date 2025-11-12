# NixOS Modules Documentation Index

**Quick Navigation Hub for NixOS Service Modules and Configuration Patterns**

This index covers the NixOS modules available in the ATProto NUR, how to use them, and architectural patterns. Choose your scenario below or browse the detailed guides.

---

## Quick Links by Scenario

### 🚀 Want to Deploy a Service?
→ **[Packages & Modules Guide](./PACKAGES_AND_MODULES_GUIDE.md)** - How to use NixOS modules to deploy services

### 🏗️ Understanding Module Architecture?
→ **[Modules Architecture Review](./MODULES_ARCHITECTURE_REVIEW.md)** - 74 modules across 23 directories

### 📊 Comparing Packages vs Modules?
→ **[Packages vs Modules Analysis](./PACKAGES_VS_MODULES_ANALYSIS.md)** - Which services have modules, alignment analysis

### 🔧 Need Configuration Patterns?
→ **[NixOS Modules Config Guide](./NIXOS_MODULES_CONFIG.md)** - Common patterns and best practices

### 🎯 Finding a Specific Service?
→ **[Packages & Modules Guide - Quick Reference](./PACKAGES_AND_MODULES_GUIDE.md#quick-reference)** - Service names and module paths

---

## Documentation Overview

| File | Purpose | Best For |
|------|---------|----------|
| **[PACKAGES_AND_MODULES_GUIDE.md](./PACKAGES_AND_MODULES_GUIDE.md)** | How to deploy services using NixOS modules | Getting started with service deployment |
| **[MODULES_ARCHITECTURE_REVIEW.md](./MODULES_ARCHITECTURE_REVIEW.md)** | Complete architecture of 74 NixOS modules | Understanding the module system |
| **[PACKAGES_VS_MODULES_ANALYSIS.md](./PACKAGES_VS_MODULES_ANALYSIS.md)** | Package and module alignment analysis | Seeing what's available and where |
| **[NIXOS_MODULES_CONFIG.md](./NIXOS_MODULES_CONFIG.md)** | Configuration patterns and best practices | Solving specific configuration problems |

---

## Common Tasks

### Enable a Service in NixOS
The simplest way to deploy a service using its NixOS module.

```nix
# In your configuration.nix
services.ORGANIZATION-SERVICE = {
  enable = true;
  # Service-specific configuration...
};
```

**Examples**:
- `services.microcosm-constellation.enable = true;`
- `services.blacksky-pds.enable = true;`
- `services.indigo-relay.enable = true;`

**See**: [PACKAGES_AND_MODULES_GUIDE.md](./PACKAGES_AND_MODULES_GUIDE.md)

### Find a Service's Module Configuration Options
Look up all available configuration options for a specific service.

**See**: [PACKAGES_AND_MODULES_GUIDE.md § Quick Reference](./PACKAGES_AND_MODULES_GUIDE.md#quick-reference) - Lists all services and their module paths

### Deploy Multiple Related Services
Configure interdependent services together.

```nix
# PDS with relay
services.blacksky-pds.enable = true;
services.indigo-relay.enable = true;

# Relay with discovery services
services.indigo-relay.enable = true;
services.indigo-palomar.enable = true;  # Search
services.indigo-bluepages.enable = true; # Identity caching
```

**See**: [MODULES_ARCHITECTURE_REVIEW.md § Deployment Patterns](./MODULES_ARCHITECTURE_REVIEW.md#deployment-patterns)

### Use Configuration Patterns
Apply common configuration patterns to your module setup.

**See**: [NIXOS_MODULES_CONFIG.md](./NIXOS_MODULES_CONFIG.md)

### Find Services by Category
Browse services organized by purpose (infrastructure, discovery, applications, etc.).

**See**: [MODULES_ARCHITECTURE_REVIEW.md § Module Organization](./MODULES_ARCHITECTURE_REVIEW.md#module-organization)

---

## Module Statistics

| Category | Count | Purpose |
|----------|-------|---------|
| **Core Infrastructure** | 7 | Protocol foundation, build systems, utilities |
| **Specialized Ecosystems** | 45 | Microservices, relays, discovery services |
| **Application Bundles** | 14 | Complete applications and platforms |
| **Infrastructure & Utilities** | 8 | Logging, monitoring, admin tools |
| **TOTAL** | 74 | All available NixOS service modules |

---

## Services Overview by Organization

See [MODULES_ARCHITECTURE_REVIEW.md](./MODULES_ARCHITECTURE_REVIEW.md) for complete list. Main categories:

| Organization | Modules | Purpose |
|--------------|---------|---------|
| **Microcosm** | 9 | ATProto microservices (Rust) |
| **Blacksky** | 9 | Full PDS platform |
| **Tangled** | 5 | Git forge services |
| **Grain Social** | 4 | Photo-sharing platform |
| **Indigo** | 3 | Reference ATProto implementation |
| **Jetstream** | 3 | Event streaming services |
| **Others** | 32 | Various specialized services |

---

## Key Concepts

### Package vs Module
- **Package** (`pkgs/`): Nix package definition - what the software is and how to build it
- **Module** (`modules/`): NixOS configuration - how to deploy and configure the service

### Shared Libraries
The following shared libraries provide common patterns across all modules:

- **service-common.nix**: Common service patterns (users, firewall, directories)
- **microcosm.nix**: Microcosm-specific patterns (workspace building, Rust services)
- **nixos-integration.nix**: NixOS integration patterns

### Module Organization
Modules mirror the package organization structure:
- `pkgs/ORGANIZATION/` → `modules/ORGANIZATION/`
- `modules/default.nix` imports all organization module directories
- Each organization's `default.nix` exports its service modules

---

## Related Documentation

- **[README.md](../README.md)** - Package overview and main documentation hub
- **[CLAUDE.md](./CLAUDE.md)** - Technical guide for developers
- **[INDIGO_INDEX.md](./INDIGO_INDEX.md)** - Indigo relay services index
- **[PDS_DASHBOARD_INDEX.md](./PDS_DASHBOARD_INDEX.md)** - PDS Dashboard services index

---

## Module Architecture Quick View

```
NUR Modules (modules/)
├── Core Infrastructure
│   ├── atproto-core (2)      # Protocol foundation
│   ├── plcbundle (1)         # DID operation archiving
│   ├── crane-daemon (1)      # Build system
│   └── [4 others]
├── Specialized Ecosystems
│   ├── microcosm (9)         # ATProto microservices
│   ├── blacksky (9)          # Full PDS deployment
│   ├── tangled (5)           # Git forge services
│   ├── grain-social (4)      # Photo-sharing
│   └── [37 others]
├── Application Bundles (14)   # Complete applications
└── Infrastructure & Utilities (8) # Logging, monitoring

Total: 74 NixOS service modules
```

---

## Quick Reference

| Task | Document | Section |
|------|----------|---------|
| Deploy a service | PACKAGES_AND_MODULES_GUIDE.md | Overview |
| Find service options | PACKAGES_AND_MODULES_GUIDE.md | Quick Reference |
| Understand architecture | MODULES_ARCHITECTURE_REVIEW.md | Module Organization |
| Check package-module alignment | PACKAGES_VS_MODULES_ANALYSIS.md | Executive Summary |
| Learn config patterns | NIXOS_MODULES_CONFIG.md | Common Patterns |

---

## Next Steps

1. **Choose a service** you want to deploy
2. **Find the module** in [MODULES_ARCHITECTURE_REVIEW.md § Module Organization](./MODULES_ARCHITECTURE_REVIEW.md#module-organization)
3. **Read the package guide** to understand what the service does
4. **Check configuration patterns** in [NIXOS_MODULES_CONFIG.md](./NIXOS_MODULES_CONFIG.md)
5. **Add to your configuration.nix** and test
6. **Deploy** with `sudo nixos-rebuild switch`

Need help finding a specific service? Use [PACKAGES_AND_MODULES_GUIDE.md § Quick Reference](./PACKAGES_AND_MODULES_GUIDE.md#quick-reference).

---

**Last Updated**: November 11, 2025
**Status**: Complete and production-ready
**Total Modules**: 74 across 23 main directories
