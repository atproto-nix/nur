# Implementation Plan

- [x] 1. Establish core repository structure and packaging utilities
  - Create standardized directory structure for packages, modules, and overlays
  - Implement shared packaging utilities and helper functions for ATProto applications
  - Set up package metadata schema and validation functions
  - _Requirements: 1.1, 1.3, 3.2, 3.3_

- [x] 1.1 Create core directory structure and build system
  - Implement the main directory layout (pkgs/, modules/, overlays/, templates/)
  - Create the root default.nix and flake.nix files for the repository
  - Set up overlay system for exposing packages to nixpkgs
  - _Requirements: 1.1, 3.2_

- [x] 1.2 Implement ATProto packaging utilities library
  - Write helper functions for common ATProto packaging patterns (Node.js, Rust, Go)
  - Create package metadata validation and schema enforcement
  - Implement dependency resolution utilities for ATProto packages
  - Create lib/atproto.nix with mkAtprotoPackage and mkRustAtprotoService helpers
  - _Requirements: 1.3, 3.2, 3.3_

- [x] 1.3 Fix flake.nix package exposure and integration
  - Update default.nix to include bluesky packages collection
  - Fix flake.nix to properly expose bluesky packages in outputs
  - Update overlay.nix to include all package collections (microcosm, blacksky, bluesky)
  - Ensure proper craneLib integration for all Rust packages
  - _Requirements: 1.1, 3.2_

- [x] 1.4 Create package templates and documentation
  - Write Nix flake templates for new ATProto package creation
  - Create packaging guidelines and contribution documentation
  - Implement example packages demonstrating best practices
  - _Requirements: 3.1, 3.3, 3.4_

- [x] 2. Package core ATProto libraries and dependencies
  - Package fundamental ATProto libraries (lexicon, crypto, common utilities)
  - Implement language-specific packaging for Node.js, Rust, and Go ATProto libraries
  - Create package definitions with proper metadata and dependency management
  - _Requirements: 1.1, 1.2, 1.4_

- [x] 2.1 Analyze and prioritize ATProto applications from code-references
  - Review all applications in code-references directory for packaging feasibility
  - Identify core ATProto libraries and dependencies needed across applications
  - Create packaging priority matrix based on complexity, dependencies, and community value
  - Document packaging requirements and challenges for each application
  - _Requirements: 1.1, 1.2, 1.4_

- [x] 2.2 Package ATProto core libraries
  - Create packages for atproto-lexicon, atproto-crypto, and atproto-common
  - Extract and package shared libraries from reference implementations (Indigo, Grain)
  - Implement proper dependency management and version constraints
  - Add ATProto-specific metadata to package definitions
  - _Requirements: 1.1, 1.2, 1.4_

- [x] 2.3 Package ATProto client libraries and APIs
  - Create packages for ATProto client libraries in multiple languages
  - Implement API definition packages and code generation tools
  - Set up cross-language compatibility and binding generation
  - _Requirements: 1.1, 1.2_

- [x] 2.4 Write unit tests for core library packages
  - Create build verification tests for all core library packages
  - Implement dependency compatibility testing
  - Add security scanning integration for packaged libraries
  - Fix missing tests/constellation.nix referenced in tests/default.nix
  - _Requirements: 1.4_

- [x] 3. Implement ATProto application packages
  - Package major ATProto applications (PDS, relay, feed generators, labelers)
  - Create application-specific build configurations and asset handling
  - Implement proper service metadata and configuration schemas
  - _Requirements: 1.1, 1.2, 3.4, 4.2_

- [x] 3.1 Complete official Bluesky application packages
  - Replace placeholder implementation in pkgs/bluesky/default.nix with real packages
  - Package official Bluesky PDS from code-references/frontpage
  - Package Bluesky relay, feed generator, and labeler applications
  - Implement proper Node.js/TypeScript build configurations using buildNpmPackage
  - Add support for multiple database backends (SQLite, PostgreSQL)
  - _Requirements: 1.1, 1.2, 2.1_

- [x] 3.2 Fix and complete Blacksky rsky packages
  - Fix placeholder cargo hashes (currently all zeros) in pkgs/blacksky/rsky/default.nix
  - Update source references to use specific commit hashes instead of "main" branch
  - Add proper build environment setup with OpenSSL, zstd, and other dependencies
  - Test and validate all rsky package builds (pds, relay, feedgen, satnav, firehose, jetstream-subscriber, labeler)
  - _Requirements: 1.1, 1.2, 2.1_

- [x] 3.3 Package real ATProto applications from code-references
  - Replace placeholder packages in pkgs/atproto/default.nix with real implementations
  - Package Allegedly PLC tools from code-references/Allegedly
  - Package atbackup from code-references/atbackup
  - Package quickdid from code-references/quickdid
  - Update source hashes and commit references for streamplace, yoten, and red-dwarf
  - _Requirements: 1.1, 1.2, 2.1_

- [ ] 3.4 Package Tangled git forge components
  - Replace Tangled placeholder packages with real implementations from code-references/tangled-core
  - Package knot (git hosting server) with proper Go build configuration
  - Package spindle (CI/CD server) with Docker integration support
  - Package appview (web interface) with proper asset building
  - Make hardcoded tangled.org/tangled.sh references configurable through build-time parameters
  - _Requirements: 1.1, 1.2, 3.4_

- [ ] 3.5 Package Tier 2 ATProto applications
  - Package Leaflet (collaborative writing) from code-references/leaflet
  - Package Slices (custom AppViews) from code-references/slices
  - Package Parakeet (ATProto services) from code-references/parakeet
  - Package Teal (ATProto platform) from code-references/teal
  - Implement proper Node.js/TypeScript and multi-language build configurations
  - _Requirements: 1.1, 1.2, 2.1_

- [ ]* 3.6 Write integration tests for application packages
  - Create end-to-end build tests for all application packages
  - Implement service startup and configuration validation tests
  - Add performance benchmarking for packaged applications
  - _Requirements: 1.4, 4.3_

- [x] 4. Create base ATProto service module system
  - Implement core NixOS module infrastructure for ATProto services
  - Create shared configuration options and validation systems
  - Set up user management and security defaults for ATProto services
  - _Requirements: 2.1, 2.2, 2.3, 5.1, 5.4_

- [x] 4.1 Standardize and improve existing service modules
  - Standardize the microcosm service modules to follow consistent patterns
  - Improve security hardening in existing modules (constellation, spacedust, etc.)
  - Add comprehensive configuration validation and error handling
  - Implement shared configuration patterns across all service modules
  - _Requirements: 2.1, 2.2, 5.1, 5.4_

- [ ] 4.2 Fix and complete Blacksky service modules
  - Fix package references in modules/blacksky/rsky/*.nix (currently referencing pkgs.blacksky.* incorrectly)
  - Implement proper user/group management instead of DynamicUser
  - Add comprehensive systemd security hardening (NoNewPrivileges, ProtectSystem, etc.)
  - Fix preStart scripts and service configuration validation
  - Test and validate all blacksky service modules (pds, relay, feedgen, satnav, firehose, jetstream-subscriber, labeler)
  - _Requirements: 2.3, 6.3_

- [ ] 4.3 Implement monitoring and logging integration
  - Add systemd journal integration for centralized logging
  - Create Prometheus metrics endpoints configuration
  - Implement health check and diagnostic capabilities
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 5. Implement service-specific NixOS modules
  - Create dedicated modules for each ATProto service (PDS, relay, feed generator, labeler)
  - Implement service-specific configuration options and systemd service definitions
  - Add inter-service dependency management and startup ordering
  - _Requirements: 2.1, 2.2, 2.4, 2.5_

- [ ] 5.1 Create comprehensive PDS service ecosystem
  - Implement services.bluesky.pds module with comprehensive configuration options
  - Create services.pds-dash module for PDS web dashboard integration
  - Add services.pds-gatekeeper module for PDS registration and user management
  - Design unified PDS deployment profiles that coordinate all PDS-related services
  - Implement database integration (SQLite, PostgreSQL) and migration support
  - _Requirements: 2.1, 2.2, 2.4, 5.1, 5.4_

- [ ] 5.2 Create Tangled service modules (knot and spindle)
  - Implement services.tangled.knot module with git hosting configuration
  - Create services.tangled.spindle module with CI/CD pipeline management
  - Add SSH key management, Docker integration, and reverse proxy configuration
  - Configure all endpoints (appview, jetstream, nixery) to be user-configurable instead of hardcoded
  - _Requirements: 2.1, 2.2, 2.4, 2.5_

- [x] 5.3 Create modules for Tier 1 ATProto applications
  - Create service modules for Allegedly PLC tools with PostgreSQL integration
  - Implement service modules for official ATProto reference implementations (Indigo, Grain)
  - Add modules for ATProto backup and utility tools (atbackup, quickdid)
  - _Requirements: 2.1, 2.2, 2.4_

- [x] 5.4 Create modules for Tier 2 ATProto applications
  - Create service modules for Leaflet collaborative writing platform
  - Implement service modules for Slices custom AppView platform
  - Add modules for Parakeet and Teal ATProto services
  - _Requirements: 2.1, 2.2, 2.4_

- [x] 5.5 Create modules for specialized ATProto services
  - Create service modules for Streamplace video infrastructure
  - Implement service modules for Yoten and Red Dwarf
  - Add modules for other specialized applications as needed
  - _Requirements: 2.1, 2.2, 2.4_

- [ ]* 5.6 Write module integration tests
  - Create NixOS VM tests for each service module
  - Implement inter-service communication validation
  - Add configuration validation and error handling tests
  - Expand existing test coverage to include all new modules
  - _Requirements: 2.3, 4.3_

- [ ] 6. Implement security hardening and operational features
  - Add comprehensive systemd security constraints for all services
  - Implement network isolation and privilege management
  - Create update and rollback mechanisms with data migration support
  - _Requirements: 5.1, 5.2, 5.3, 5.5, 6.1, 6.2, 6.4, 6.5_

- [ ] 6.1 Implement systemd security hardening
  - Add comprehensive systemd security settings to all service modules
  - Implement privilege dropping and capability management
  - Create network isolation options for services that don't require external access
  - _Requirements: 5.1, 5.2, 5.4_

- [ ] 6.2 Create update and migration system
  - Implement atomic service updates with rollback capabilities
  - Add configuration migration helpers for breaking changes
  - Create data migration tools for service updates
  - _Requirements: 6.1, 6.3, 6.4, 6.5_

- [ ] 6.3 Add operational monitoring and diagnostics
  - Implement comprehensive health checking for all services
  - Add diagnostic information collection for service failures
  - Create operational dashboards and alerting integration
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ]* 6.4 Write security and operational tests
  - Create security constraint validation tests
  - Implement update and rollback scenario testing
  - Add monitoring and alerting integration tests
  - _Requirements: 5.3, 6.2_

- [ ] 7. Create deployment profiles and integration
  - Implement pre-configured deployment profiles for common scenarios
  - Create integration with existing NixOS configurations and services
  - Add documentation and examples for production deployments
  - _Requirements: 2.1, 2.2, 2.4, 6.1, 6.2_

- [ ] 7.1 Create development deployment profile
  - Implement development profile with local services and minimal security
  - Add quick-start configuration for local ATProto development
  - Create development tools integration and debugging support
  - _Requirements: 2.1, 2.2_

- [ ] 7.2 Create PDS-focused deployment profiles
  - Create "simple-pds" profile for basic PDS deployment
  - Create "managed-pds" profile including pds-dash and pds-gatekeeper
  - Create "enterprise-pds" profile with backup, monitoring, and management tools
  - Design service coordination and dependency management between PDS components
  - _Requirements: 2.1, 2.2, 5.1, 5.4, 6.1, 6.2_

- [ ] 7.3 Create production deployment profile
  - Implement production profile with full security hardening
  - Add external database and storage integration
  - Create load balancing and high availability configuration options
  - _Requirements: 2.1, 2.2, 5.1, 5.4, 6.1, 6.2_

- [x] 7.4 Integrate with existing NixOS ecosystem
  - Add integration with common NixOS services (nginx, PostgreSQL, Redis)
  - Create compatibility with existing NixOS security and monitoring tools
  - Implement proper service ordering and dependency management
  - _Requirements: 2.4, 2.5, 4.1, 6.1_

- [ ]* 7.5 Create deployment documentation and examples
  - Write comprehensive deployment guides for different scenarios
  - Create example configurations for common use cases
  - Add troubleshooting guides and operational runbooks
  - Document PDS ecosystem integration patterns and best practices
  - _Requirements: 2.1, 2.2, 4.3_

- [ ] 8. Update CI/CD and maintenance infrastructure
  - Update .tangled/workflows/build.yml to test all package collections
  - Add automated testing for all service modules
  - Implement security scanning and vulnerability checking
  - Add automated dependency updates and hash verification
  - _Requirements: 1.4, 4.3, 6.2_