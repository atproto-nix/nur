# Product Overview

## ATproto NUR (Nix User Repository)

This repository provides a comprehensive Nix packaging ecosystem for AT Protocol (ATproto) applications and services. It enables NixOS users to easily install, configure, and deploy ATproto infrastructure including Personal Data Servers (PDS), relays, feed generators, labelers, and other ecosystem components.

## Current Status

The repository currently packages two main ATproto service collections:

- **Microcosm-rs**: A suite of Rust-based ATproto services including Constellation (backlink indexer), Spacedust, Slingshot, UFOs, Who-am-i, Quasar, Pocket, and Reflector
- **Blacksky**: ATproto community services and tools

## Target Applications

Based on analysis of available ATproto applications, the ecosystem aims to support:

1. **Infrastructure Services**: PDS, relays, feed generators, labelers
2. **Development Tools**: CLI tools, lexicon utilities, testing frameworks  
3. **Applications**: Collaborative writing platforms, custom AppViews, media services
4. **Identity Services**: DID management, PLC tools

## Goals

- Provide production-ready Nix packages for the ATproto ecosystem
- Enable declarative configuration through NixOS modules
- Support both development and production deployment scenarios
- Maintain security best practices and operational excellence
- Foster community contributions through standardized packaging patterns