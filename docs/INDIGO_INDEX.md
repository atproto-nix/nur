# Indigo Services Documentation Index

**Quick Navigation Hub for ATProto Relay and Discovery Services**

Indigo is a suite of services for running ATProto infrastructure including relays, discovery services, and monitoring tools. Choose your scenario below or browse the detailed guides.

---

## Quick Links by Scenario

### 🚀 Want to Deploy a Relay?
→ **[Quick Start Guide](./INDIGO_QUICK_START.md)** - Get a relay running in 5 minutes

### 🏗️ Need to Understand the Architecture?
→ **[Architecture Guide](./INDIGO_ARCHITECTURE.md)** - How services work together and service overview

### 📋 Looking for Service Details?
→ **[Complete Services Guide](./INDIGO_SERVICES.md)** - All 10 services, what they do, and how to configure them

### 🔗 Which Services Should I Use?
→ **[Architecture Guide - When to Use Each Service](./INDIGO_ARCHITECTURE.md#when-to-use-each-service)** - Decision tree for your deployment

### 🐛 Troubleshooting Relay Issues?
→ **[Complete Services Guide - Troubleshooting](./INDIGO_SERVICES.md#troubleshooting)** - Common problems and solutions

---

## Documentation Overview

| File | Purpose | Best For |
|------|---------|----------|
| **[INDIGO_QUICK_START.md](./INDIGO_QUICK_START.md)** | Fast setup reference for common scenarios | Getting started quickly |
| **[INDIGO_SERVICES.md](./INDIGO_SERVICES.md)** | Complete guide to all 10 Indigo services | Understanding what each service does |
| **[INDIGO_ARCHITECTURE.md](./INDIGO_ARCHITECTURE.md)** | Architecture and service relationships | Learning how services integrate |

---

## Common Tasks

### Deploy a Basic Relay
The simplest way to run a relay on your system.

```nix
services.postgresql.enable = true;

services.indigo-relay = {
  enable = true;
  settings = {
    hostname = "relay.example.com";
    database = {
      url = "postgres://relay:password@localhost:5432/relay";
    };
    adminPasswordFile = "/run/secrets/relay-admin-password";
  };
};

networking.firewall.allowedTCPPorts = [ 80 443 ];
```

**See**: [INDIGO_QUICK_START.md](./INDIGO_QUICK_START.md)

### Deploy Full ATProto Infrastructure
Multiple Indigo services working together for complete network support.

**See**: [INDIGO_ARCHITECTURE.md § Deployment Patterns](./INDIGO_ARCHITECTURE.md#deployment-patterns)

### Add Search & Discovery
Enable full-text search and identity caching services alongside your relay.

**See**: [INDIGO_SERVICES.md § Search & Discovery Services](./INDIGO_SERVICES.md#search--discovery-services)

### Monitor Your Relay
Setup monitoring and metrics collection for your relay instance.

**See**: [INDIGO_SERVICES.md § Sonar - Metrics and Monitoring](./INDIGO_SERVICES.md#sonar)

### Configure Database
Choose between PostgreSQL (recommended) or SQLite for your relay storage.

**See**: [INDIGO_QUICK_START.md](./INDIGO_QUICK_START.md) and [INDIGO_SERVICES.md](./INDIGO_SERVICES.md)

---

## What is Indigo?

Indigo is the official reference implementation of ATProto infrastructure services. It provides:

- **Relays** - Collect and distribute firehose events from across the ATProto network
- **Discovery Services** - Full-text search (Palomar), identity caching (Bluepages)
- **Fanout & Caching** - Cache and distribute firehose events efficiently (Rainbow)
- **Monitoring** - Metrics and logging services for operational visibility (Sonar)
- **Admin Tools** - Administrative interfaces and operations support

---

## Services Overview

| Service | Purpose | Type | Database |
|---------|---------|------|----------|
| **Indigo Relay** | Modern ATProto relay, collects firehose | Core | PostgreSQL/SQLite |
| **Rainbow** | Fanout and cache firehose events | Cache | Redis/Memory |
| **Palomar** | Full-text search over firehose | Discovery | OpenSearch/Elasticsearch |
| **Bluepages** | Identity and handle caching | Discovery | Redis |
| **Beemo** | Bot operations and admin tasks | Tool | - |
| **Sonar** | Metrics and monitoring | Monitoring | Prometheus |

See [INDIGO_SERVICES.md](./INDIGO_SERVICES.md) for complete details on all services.

---

## Related Documentation

- **[README.md](../README.md)** - Package overview and main documentation hub
- **[CLAUDE.md](./CLAUDE.md)** - Technical guide for developers
- **[NUR_BEST_PRACTICES.md](./NUR_BEST_PRACTICES.md)** - Architecture and design patterns

---

## Quick Reference

| Resource | Location | Purpose |
|----------|----------|---------|
| **Package** | `pkgs/bluesky-social/indigo.nix` | Indigo services package |
| **Relay Module** | `modules/bluesky-social/indigo-relay.nix` | Relay service configuration |
| **Architecture** | `docs/INDIGO_ARCHITECTURE.md` | Service relationships diagram |

---

## Deployment Scenarios

### Scenario 1: Simple Relay (≤1M users)
- Relay only
- PostgreSQL database
- Single instance
- Basic monitoring

**See**: [INDIGO_QUICK_START.md](./INDIGO_QUICK_START.md)

### Scenario 2: Full Infrastructure (5M+ users)
- Relay + Rainbow (fanout/cache)
- Palomar (search)
- Bluepages (identity)
- PostgreSQL + Redis + OpenSearch
- Multi-instance with load balancing

**See**: [INDIGO_ARCHITECTURE.md § Deployment Patterns](./INDIGO_ARCHITECTURE.md#deployment-patterns)

### Scenario 3: Development/Testing
- Relay with SQLite
- Single machine
- No monitoring required

**See**: [INDIGO_QUICK_START.md](./INDIGO_QUICK_START.md)

---

## Next Steps

1. **Choose your deployment scenario** from the "Deployment Scenarios" section above
2. **Read the Quick Start** for basic setup
3. **Understand the architecture** to know what services you need
4. **Configure your services** using examples from the Services Guide
5. **Test** with `nix flake check` before deploying
6. **Deploy** with `sudo nixos-rebuild switch`

Need help? Check the **[Services Guide - Troubleshooting](./INDIGO_SERVICES.md#troubleshooting)** section.

---

## Key Concepts

- **Firehose**: Real-time stream of all ATProto events (commits, deletes, etc.)
- **Relay**: Service that subscribes to PDS instances and emits a combined firehose
- **Sync Protocol**: Method for PDS/relay communication (currently v1.1)
- **Repository Events**: Individual changes to user accounts, records, blobs

---

**Last Updated**: November 11, 2025
**Status**: Complete and production-ready
**Services**: 10 total (3 core, 3 discovery, 2 fanout/cache, 2 operational)
