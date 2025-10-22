# ATproto Ecosystem Expansion Implementation Plan

## Phase 1: Foundation Infrastructure (Months 1-2)

- [x] 1. Establish organizational framework and core libraries
  - Create new organizational directory structure in pkgs/ and modules/
  - Implement lib/atproto-core.nix with ATproto-specific packaging functions
  - Implement lib/packaging.nix with multi-language build utilities
  - Implement lib/service-common.nix with NixOS service patterns
  - _Requirements: 6.1, 6.2, 6.3, 8.4, 8.5_

- [x] 2. Package Allegedly PLC tools with full infrastructure support
  - Create pkgs/individual/allegedly.nix fetching from official GitHub repository
  - Implement PostgreSQL integration with proper environment variables
  - Create modules/individual/allegedly.nix with NixOS service configuration
  - Add TLS/ACME certificate management and database setup automation
  - _Requirements: 1.1, 1.2, 7.1, 7.4_

- [x] 3. Enhance Tangled git forge with configurable endpoints
  - Update existing Tangled packages to support custom endpoint configuration
  - Make tangled.org/tangled.sh references configurable through NixOS options
  - Add support for custom appview, jetstream, and nixery endpoints
  - Create deployment profile configurations for common scenarios
  - _Requirements: 1.3, 7.2, 10.1_

- [x] 4. Update Microcosm-rs packages with official GitHub source
  - Update pkgs/microcosm/default.nix to fetch from github.com/at-microcosm/microcosm-rs
  - Add missing services: jetstream and links packages
  - Improve shared dependency artifacts and build optimization
  - Update corresponding NixOS modules for new services
  - _Requirements: 1.4, 3.4, 6.1_

- [ ]* 5. Create comprehensive testing infrastructure
  - Implement package-level build verification tests
  - Create service integration tests for NixOS modules
  - Add automated security scanning and vulnerability detection
  - Set up continuous integration for all packages
  - _Requirements: 9.1, 9.2, 9.4_

## Phase 2: Official Implementations (Months 3-4)

- [x] 6. Package Frontpage/Bluesky official implementation
  - Create pkgs/atproto/frontpage/ fetching from github.com/bluesky-social/frontpage
  - Implement pnpm workspace packaging with catalog dependency support
  - Handle complex Next.js and Turbopack build requirements
  - Create NixOS modules for PDS, relay, and AppView services
  - _Requirements: 2.1, 2.3, 6.2_

- [x] 7. Package Indigo Go implementation and core libraries
  - Create pkgs/atproto/indigo/ fetching from github.com/bluesky-social/indigo
  - Package core libraries: api, atproto, lex, xrpc, did, repo, carstore, events
  - Package services: relay, rainbow, palomar, hepa
  - Implement NixOS modules matching upstream deployment patterns
  - _Requirements: 2.2, 2.4, 6.3, 8.2_

- [x] 8. Package core ATproto TypeScript libraries
  - Create individual packages for @atproto namespace libraries
  - Package @atproto/api, @atproto/lexicon, @atproto/xrpc, @atproto/did
  - Package @atproto/identity, @atproto/repo, @atproto/syntax
  - Ensure proper dependency resolution and version compatibility
  - _Requirements: 2.4, 8.1, 8.4_

- [x] 9. Implement enhanced multi-language build coordination
  - Create buildRustWorkspace function with improved shared artifacts
  - Implement buildPnpmWorkspace for complex Node.js monorepos
  - Create buildGoAtprotoModule with ATproto-specific environment
  - Add buildDenoApp function for TypeScript Deno applications
  - _Requirements: 6.1, 6.2, 6.3, 6.5_

- [ ]* 10. Add performance optimization and monitoring
  - Implement build performance monitoring and optimization
  - Add runtime performance monitoring for services
  - Create resource usage optimization for database-heavy services
  - Implement automated performance regression detection
  - _Requirements: 9.3, 9.4_

## Phase 3: Community Ecosystem (Months 5-6)

- [x] 11. Update rsky/blacksky packages with complete service collection
  - Update pkgs/blacksky/rsky/ to fetch from official rsky GitHub repository
  - Add missing services: rsky-pdsadmin and other new components
  - Fix existing service packages and improve Rust packaging patterns
  - Update modules/blacksky/ with enhanced service configurations
  - _Requirements: 3.1, 3.2, 3.4_

- [x] 12. Package Leaflet collaborative writing platform
  - Create pkgs/hyperlink-academy/leaflet.nix fetching from official repository
  - Handle complex Next.js build with Supabase integration
  - Implement real-time sync dependencies (Replicache, WebSockets)
  - Create modules/hyperlink-academy/leaflet.nix with database setup
  - _Requirements: 4.1, 4.3, 6.2_

- [x] 13. Package Slices custom AppView platform
  - Create pkgs/slices-network/slices/ fetching from tangled.sh/slices.network/slices
  - Implement API backend packaging with PostgreSQL and Redis support
  - Package Deno frontend with server-side rendering support
  - Create NixOS module with multi-tenant architecture support
  - _Requirements: 4.2, 4.3, 6.5_

- [x] 14. Package utility and development tools
  - Create pkgs/smokesignal-events/quickdid.nix fetching from tangled.sh repository
  - Package pds-dash (Svelte/Deno) fetching from official repository
  - Package pds-gatekeeper (Rust) fetching from official repository with email support
  - Package atbackup (Tauri) fetching from official repository with desktop support
  - _Requirements: 5.1, 5.2, 5.5_

- [x] 15. Implement service discovery and coordination
  - Create service discovery mechanisms for multi-service deployments
  - Implement configuration templating for service coordination
  - Add automatic service dependency management
  - Create unified deployment profiles for common ATproto stacks
  - _Requirements: 7.2, 7.5, 10.1_

## Phase 4: Specialized Applications (Months 7+)

- [ ] 16. Package specialized applications based on community demand
  - Evaluate and prioritize remaining applications (Streamplace, Teal, Parakeet)
  - Package selected applications with appropriate complexity handling
  - Create advanced packaging patterns for multimedia and complex dependencies
  - Implement specialized deployment configurations
  - _Requirements: 4.4, 5.4, 10.4_

- [x] 17. Create comprehensive documentation and examples
  - Write complete deployment guides for all service combinations
  - Create step-by-step setup tutorials for complex configurations
  - Develop packaging templates and contribution guidelines
  - Implement package discovery and comparison documentation
  - _Requirements: 10.1, 10.2, 10.3, 10.5_

- [ ] 18. Implement long-term maintenance and update strategies
  - Create automated dependency monitoring and update systems
  - Implement compatibility testing for upstream changes
  - Establish community contribution and review processes
  - Create sustainable maintenance workflows and ownership models
  - _Requirements: 9.2, 9.4, 10.2_

- [ ]* 19. Add advanced security and compliance features
  - Implement comprehensive security scanning and auditing
  - Add compliance checking for ATproto protocol standards
  - Create security hardening profiles for production deployments
  - Implement automated vulnerability response and patching
  - _Requirements: 7.4, 9.4_

- [ ]* 20. Optimize ecosystem performance and resource usage
  - Implement advanced build caching and optimization strategies
  - Add resource usage monitoring and optimization for all services
  - Create performance tuning guides and automated optimization
  - Implement ecosystem-wide performance benchmarking and regression testing
  - _Requirements: 9.3, 9.4_