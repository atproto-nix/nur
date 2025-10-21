# ATproto Ecosystem Expansion Requirements

## Introduction

This specification defines the requirements for expanding the ATproto Nix User Repository (NUR) ecosystem to include comprehensive packaging of ATproto applications and services found in the code-references directory. The goal is to transform the current limited ecosystem (microcosm-rs and blacksky/rsky) into a complete packaging solution supporting 20+ ATproto applications across multiple programming languages and deployment scenarios.

## Glossary

- **ATproto**: AT Protocol - The decentralized social networking protocol
- **NUR**: Nix User Repository - A community-driven package repository for Nix
- **PDS**: Personal Data Server - ATproto service for storing user data
- **AppView**: ATproto service that provides custom views of network data
- **Lexicon**: ATproto schema definition language for data structures
- **Jetstream**: ATproto real-time event streaming protocol
- **DID**: Decentralized Identifier - Identity system used by ATproto
- **PLC**: Public Ledger Consortium - DID method used by ATproto
- **Firehose**: ATproto event stream containing all network activity
- **Relay**: ATproto service that aggregates and redistributes data
- **Feed_Generator**: ATproto service that creates custom content feeds
- **Labeler**: ATproto service that provides content moderation labels
- **Crane**: Nix library for building Rust packages with Cargo
- **BuildNpmPackage**: Nix function for building Node.js packages
- **BuildGoModule**: Nix function for building Go packages
- **SystemD_Service**: Linux service management system used by NixOS
- **NixOS_Module**: Declarative configuration system for NixOS services

## Requirements

### Requirement 1: Infrastructure Service Packaging

**User Story:** As a system administrator, I want to deploy core ATproto infrastructure services using Nix packages, so that I can run a complete ATproto network node with declarative configuration.

#### Acceptance Criteria

1. WHEN deploying Allegedly PLC tools, THE ATproto_NUR SHALL provide a complete Rust package with PostgreSQL integration
2. WHEN configuring Allegedly services, THE ATproto_NUR SHALL provide NixOS_Module with database setup and TLS certificate management
3. WHEN installing Tangled git forge, THE ATproto_NUR SHALL provide improved configuration options for custom endpoints
4. WHEN deploying Microcosm services, THE ATproto_NUR SHALL provide updated packages using code-references source with all missing services
5. WHEN running infrastructure services, THE ATproto_NUR SHALL provide SystemD_Service configurations with security hardening

### Requirement 2: Official Implementation Support

**User Story:** As a developer, I want to use official ATproto implementations in my Nix environment, so that I can develop and test against reference implementations.

#### Acceptance Criteria

1. WHEN packaging Frontpage/Bluesky, THE ATproto_NUR SHALL provide Node.js packages supporting pnpm workspaces and monorepo structure
2. WHEN building Indigo Go services, THE ATproto_NUR SHALL provide Go packages for relay, rainbow, palomar, and hepa services
3. WHEN deploying official services, THE ATproto_NUR SHALL provide NixOS_Module configurations matching upstream deployment patterns
4. WHEN using official libraries, THE ATproto_NUR SHALL provide core ATproto libraries as separate packages for reuse
5. WHERE official implementations exist, THE ATproto_NUR SHALL prioritize these over community alternatives

### Requirement 3: Community Implementation Integration

**User Story:** As an ATproto ecosystem participant, I want access to community-maintained implementations, so that I can choose the best tools for my specific use case.

#### Acceptance Criteria

1. WHEN using rsky Rust implementation, THE ATproto_NUR SHALL provide updated packages with all services and libraries
2. WHEN deploying community services, THE ATproto_NUR SHALL provide equivalent functionality to official implementations
3. WHEN choosing implementations, THE ATproto_NUR SHALL provide clear documentation of differences and compatibility
4. WHEN packaging community tools, THE ATproto_NUR SHALL maintain compatibility with existing blacksky namespace
5. WHERE community implementations provide unique features, THE ATproto_NUR SHALL package these alongside official versions

### Requirement 4: Application Platform Support

**User Story:** As an application developer, I want to deploy ATproto applications using Nix, so that I can build custom experiences on the ATproto network.

#### Acceptance Criteria

1. WHEN deploying Leaflet collaborative writing platform, THE ATproto_NUR SHALL provide Node.js package with Supabase integration options
2. WHEN running Slices custom AppView platform, THE ATproto_NUR SHALL provide coordinated Rust and Deno packaging
3. WHEN configuring application platforms, THE ATproto_NUR SHALL provide NixOS_Module with database and authentication setup
4. WHEN building applications, THE ATproto_NUR SHALL provide development environment packages and tooling
5. WHERE applications require complex dependencies, THE ATproto_NUR SHALL provide modular packaging approaches

### Requirement 5: Utility and Development Tools

**User Story:** As a developer working with ATproto, I want comprehensive development and utility tools available through Nix, so that I can efficiently build and debug ATproto applications.

#### Acceptance Criteria

1. WHEN using DID management tools, THE ATproto_NUR SHALL provide quickdid and other identity utilities
2. WHEN managing PDS instances, THE ATproto_NUR SHALL provide pds-gatekeeper, pds-dash, and pds-moover tools
3. WHEN developing ATproto applications, THE ATproto_NUR SHALL provide lexicon tools and code generators
4. WHEN debugging ATproto services, THE ATproto_NUR SHALL provide monitoring and inspection utilities
5. WHERE development workflows require specific tools, THE ATproto_NUR SHALL package these with appropriate NixOS_Module integration

### Requirement 6: Multi-Language Build System Support

**User Story:** As a package maintainer, I want consistent build patterns across different programming languages, so that I can efficiently maintain packages and ensure reliable builds.

#### Acceptance Criteria

1. WHEN building Rust packages, THE ATproto_NUR SHALL use Crane with shared dependency artifacts and consistent environment variables
2. WHEN building Node.js packages, THE ATproto_NUR SHALL use BuildNpmPackage with proper lockfile handling and workspace support
3. WHEN building Go packages, THE ATproto_NUR SHALL use BuildGoModule with vendor directory support and CGO integration
4. WHEN building Deno packages, THE ATproto_NUR SHALL provide appropriate packaging patterns for TypeScript applications
5. WHERE packages require multiple languages, THE ATproto_NUR SHALL provide coordinated build processes

### Requirement 7: Service Configuration and Integration

**User Story:** As a system administrator, I want declarative service configuration for all ATproto services, so that I can manage complex deployments with infrastructure as code.

#### Acceptance Criteria

1. WHEN configuring ATproto services, THE ATproto_NUR SHALL provide NixOS_Module with comprehensive option sets
2. WHEN deploying service collections, THE ATproto_NUR SHALL provide profile configurations for common deployment scenarios
3. WHEN managing service dependencies, THE ATproto_NUR SHALL provide automatic database setup and migration handling
4. WHEN securing services, THE ATproto_NUR SHALL provide SystemD_Service hardening and network isolation
5. WHERE services require coordination, THE ATproto_NUR SHALL provide service discovery and configuration templating

### Requirement 8: Core Library Ecosystem

**User Story:** As a developer, I want access to core ATproto libraries as separate Nix packages, so that I can build custom applications without duplicating dependencies.

#### Acceptance Criteria

1. WHEN using TypeScript ATproto libraries, THE ATproto_NUR SHALL provide @atproto namespace packages as individual derivations
2. WHEN using Go ATproto libraries, THE ATproto_NUR SHALL provide Indigo core modules as reusable packages
3. WHEN using Rust ATproto libraries, THE ATproto_NUR SHALL provide rsky libraries and microcosm utilities
4. WHEN building applications, THE ATproto_NUR SHALL provide lexicon validation and code generation tools
5. WHERE libraries have cross-language compatibility, THE ATproto_NUR SHALL provide integration utilities

### Requirement 9: Testing and Quality Assurance

**User Story:** As a package maintainer, I want comprehensive testing for all packages, so that I can ensure reliability and catch regressions early.

#### Acceptance Criteria

1. WHEN building packages, THE ATproto_NUR SHALL provide integration tests for all service modules
2. WHEN updating packages, THE ATproto_NUR SHALL provide automated dependency compatibility checking
3. WHEN deploying services, THE ATproto_NUR SHALL provide smoke tests and health checks
4. WHEN maintaining packages, THE ATproto_NUR SHALL provide automated security scanning and vulnerability detection
5. WHERE packages interact with external services, THE ATproto_NUR SHALL provide mock environments for testing

### Requirement 10: Documentation and Community Support

**User Story:** As a user of the ATproto NUR, I want comprehensive documentation and examples, so that I can effectively use and contribute to the ecosystem.

#### Acceptance Criteria

1. WHEN using ATproto packages, THE ATproto_NUR SHALL provide complete deployment guides and configuration examples
2. WHEN contributing packages, THE ATproto_NUR SHALL provide standardized packaging templates and guidelines
3. WHEN troubleshooting issues, THE ATproto_NUR SHALL provide debugging guides and common problem solutions
4. WHEN exploring the ecosystem, THE ATproto_NUR SHALL provide package discovery and comparison documentation
5. WHERE packages have complex configuration, THE ATproto_NUR SHALL provide step-by-step setup tutorials