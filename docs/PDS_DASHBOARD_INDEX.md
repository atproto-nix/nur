# PDS Dashboard Documentation Index

**Quick Navigation Hub for PDS Dashboard Setup and Configuration**

This is your entry point for all PDS Dashboard related documentation. Choose your scenario below or browse the detailed guides linked throughout.

---

## Quick Links by Scenario

### 🚀 Just Want to Get Started?
→ **[Quick Start Guide](./PDS_DASH_THEMED_GUIDE.md#quick-start)** - 5-minute setup for standalone dashboard

### 📋 Looking for Configuration Examples?
→ **[Real-world Examples](./PDS_DASH_EXAMPLES.md)** - 6 complete setup examples with SSL, multi-instance, and more

### 🔧 Need Implementation Details?
→ **[Implementation Summary](./PDS_DASH_IMPLEMENTATION_SUMMARY.md)** - Architecture, components, and build system details

### 🎨 Want to Use Custom Themes?
→ **[Themed Implementation Guide](./PDS_DASH_THEMED_GUIDE.md#components)** - Available themes: default, express, sunset, witchcraft

### 🐛 Troubleshooting Issues?
→ **[Themed Guide - Troubleshooting](./PDS_DASH_THEMED_GUIDE.md#troubleshooting)** - Common issues and solutions

---

## Documentation Overview

| File | Purpose | Best For |
|------|---------|----------|
| **[PDS_DASH_THEMED_GUIDE.md](./PDS_DASH_THEMED_GUIDE.md)** | Complete integration guide with all components explained | Learning how everything works together |
| **[PDS_DASH_EXAMPLES.md](./PDS_DASH_EXAMPLES.md)** | Real-world configuration examples ready to use | Copy-paste ready configs for your setup |
| **[PDS_DASH_IMPLEMENTATION_SUMMARY.md](./PDS_DASH_IMPLEMENTATION_SUMMARY.md)** | Technical deep dive into the implementation | Understanding the architecture and components |

---

## Common Tasks

### Enable PDS Dashboard on Your System
```nix
services.witchcraft-systems.pds-dash = {
  enable = true;
  buildTheme = true;
  theme = "sunset";                          # Choose: default, express, sunset, witchcraft
  virtualHost = "dash.example.com";
  pdsUrl = "http://pds.example.com:3000";
  frontendUrl = "https://bsky.app";
  enableSSL = true;                          # Enable HTTPS
  acmeHost = "example.com";                  # ACME certificate host
};
```

**See**: [PDS_DASH_EXAMPLES.md § Simple Standalone Dashboard](./PDS_DASH_EXAMPLES.md#simple-standalone)

### Deploy Multiple Dashboards
Multiple themed dashboards with different configurations on the same system.

**See**: [PDS_DASH_EXAMPLES.md § Multiple Dashboards](./PDS_DASH_EXAMPLES.md#multiple-dashboards)

### Use with SSL/ACME Certificates
Automatic HTTPS setup with Let's Encrypt integration.

**See**: [PDS_DASH_EXAMPLES.md § With SSL/ACME](./PDS_DASH_EXAMPLES.md#with-ssl-acme)

### Integrate with Your PDS Service
Use dashboard as part of your PDS service configuration (future).

**See**: [PDS_DASH_THEMED_GUIDE.md § Integrated with rsky PDS](./PDS_DASH_THEMED_GUIDE.md#integrated-with-rsky-pds-future)

### Available Themes and Customization
Configure colors, layout, branding, and behavior at build time.

**See**: [PDS_DASH_IMPLEMENTATION_SUMMARY.md § Parameterized Builder](./PDS_DASH_IMPLEMENTATION_SUMMARY.md#1-parameterized-builder)

---

## What is PDS Dashboard?

The PDS Dashboard (pds-dash) is a web-based interface for monitoring and managing your Personal Data Server (PDS). It provides:

- **Real-time monitoring** of PDS status and performance
- **User management** interface (future feature)
- **Service health checks** and diagnostics
- **Customizable themes** to match your branding
- **Multi-instance support** for managing multiple PDS services
- **Standalone or integrated** deployment options

---

## Related Documentation

- **[README.md](../README.md)** - Package overview and main documentation hub
- **[CLAUDE.md](./CLAUDE.md)** - Technical guide for developers and AI assistants
- **[NUR_BEST_PRACTICES.md](./NUR_BEST_PRACTICES.md)** - Architecture and design patterns

---

## Quick Reference

| Component | Location | Purpose |
|-----------|----------|---------|
| **Package** | `pkgs/witchcraft-systems/pds-dash.nix` | Nix package for pds-dash |
| **Theme Builder** | `pkgs/witchcraft-systems/pds-dash-themed.nix` | Build packages with custom themes |
| **NixOS Module** | `modules/witchcraft-systems/pds-dash.nix` | Service configuration options |

---

## Next Steps

1. **Choose your scenario** from the "Quick Links by Scenario" section above
2. **Read the relevant guide** from the "Documentation Overview" table
3. **Copy an example** from the Examples document that matches your needs
4. **Customize** configuration for your setup
5. **Test** with `nix flake check` before rebuilding
6. **Deploy** with `sudo nixos-rebuild switch`

Need help? Check the **[Troubleshooting](#quick-links-by-scenario)** section of the Themed Guide.

---

**Last Updated**: November 11, 2025
**Status**: Complete and production-ready
**Themes Available**: 4 (default, express, sunset, witchcraft)
