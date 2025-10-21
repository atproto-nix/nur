# Implementation Plan

- [x] 1. Create organizational mapping and validation framework
  - Create organizational mapping configuration file that defines correct ownership for each package
  - Implement validation functions to verify organizational placement
  - Add organizational metadata schema for packages
  - _Requirements: 1.1, 1.2, 4.1, 4.2_

- [x] 2. Restructure package directories by organization
- [x] 2.1 Create new organizational directory structure in pkgs/
  - Create directories for hyperlink-academy, slices-network, teal-fm, parakeet-social, stream-place, yoten-app, red-dwarf-client, tangled-dev, smokesignal-events, witchcraft-systems, atbackup-pages-dev
  - Move microcosm-blue/allegedly from current atproto location
  - Ensure proper directory permissions and structure
  - _Requirements: 1.1, 2.1, 2.2_

- [x] 2.2 Move packages to correct organizational directories
  - Move leaflet to pkgs/hyperlink-academy/leaflet/
  - Move slices to pkgs/slices-network/slices/
  - Move teal to pkgs/teal-fm/teal/
  - Move parakeet to pkgs/parakeet-social/parakeet/
  - Move streamplace to pkgs/stream-place/streamplace/
  - Move yoten to pkgs/yoten-app/yoten/
  - Move red-dwarf to pkgs/red-dwarf-client/red-dwarf/
  - Move tangled components to pkgs/tangled-dev/
  - Move quickdid to pkgs/smokesignal-events/quickdid/
  - Move allegedly to pkgs/microcosm-blue/allegedly/
  - Move pds-dash to pkgs/witchcraft-systems/pds-dash/
  - Move atbackup to pkgs/atbackup-pages-dev/atbackup/
  - _Requirements: 1.2, 1.3, 2.2_

- [x] 2.3 Create organizational default.nix files
  - Create default.nix in each organizational directory that exports the organization's packages
  - Add organizational metadata and documentation
  - Implement consistent package naming patterns within organizations
  - _Requirements: 2.2, 4.1_

- [x] 3. Update package imports and references
- [x] 3.1 Update root package collections
  - Modify pkgs/default.nix to import from organizational directories
  - Update flake.nix package exports to use new organizational structure
  - Ensure all packages are still accessible through the main package set
  - _Requirements: 1.1, 2.1_

- [x] 3.2 Update cross-package references
  - Find and update any internal references between packages that use old paths
  - Update module imports that reference packages
  - Verify that package dependencies still resolve correctly
  - _Requirements: 1.4, 3.4_

- [x] 4. Restructure NixOS modules to match package organization
- [x] 4.1 Create organizational module directories
  - Create module directories matching package organization structure
  - Move existing modules to appropriate organizational directories
  - Update module imports in modules/default.nix
  - _Requirements: 3.1, 3.2_

- [x] 4.2 Update module package references
  - Update all module files to reference packages from new organizational locations
  - Ensure service configurations use correct package paths
  - Verify that module options and defaults work with reorganized packages
  - _Requirements: 3.1, 3.4_

- [-] 5. Implement backward compatibility system
- [x] 5.1 Create package aliases for old names
  - Add aliases in flake.nix for all moved packages using old names
  - Implement deprecation warnings for old package names
  - Document migration path for users
  - _Requirements: 1.5, 3.3, 3.5_

- [x] 5.2 Create module compatibility aliases
  - Add module aliases for old service names and paths
  - Ensure existing NixOS configurations continue to work
  - Provide clear migration documentation for module users
  - _Requirements: 3.3, 3.5_

- [ ] 6. Update documentation and metadata
- [x] 6.1 Update package metadata with organizational information
  - Add organizational metadata to all package definitions
  - Update package descriptions to include organizational context
  - Ensure homepage and repository URLs are correct
  - _Requirements: 2.4, 4.2_

- [x] 6.2 Update documentation files
  - Update README.md to reflect new organizational structure
  - Update PACKAGING.md with organizational placement guidelines
  - Update CONTRIBUTING.md with new directory structure
  - Create migration guide for existing users
  - _Requirements: 4.1, 4.4_

- [ ] 6.3 Create organizational documentation
  - Create documentation for each organization explaining their ATProto projects
  - Add contact information and contribution guidelines per organization
  - Document relationships between projects within organizations
  - _Requirements: 2.1, 2.2_

- [ ] 7. Validate and test the reorganized structure
- [ ] 7.1 Verify all packages build correctly
  - Test that all packages build in their new organizational locations
  - Verify that package metadata is complete and accurate
  - Ensure no build dependencies are broken by the reorganization
  - _Requirements: 1.1, 1.2_

- [x] 7.2 Test NixOS module functionality
  - Verify that all modules work with reorganized packages
  - Test service configurations and deployments
  - Ensure module options and defaults function correctly
  - _Requirements: 3.1, 3.2_

- [ ]* 7.3 Test backward compatibility
  - Verify that old package names still work through aliases
  - Test that existing NixOS configurations continue to function
  - Validate deprecation warnings are displayed appropriately
  - _Requirements: 3.3, 3.5_

- [x] 8. Update CI/CD and automation
- [ ] 8.1 Update build workflows
  - Modify GitHub Actions workflows to handle new directory structure
  - Update any automated testing that references specific package paths
  - Ensure CI builds and tests all organizational packages
  - _Requirements: 1.1, 2.1_

- [ ] 8.2 Update maintenance scripts
  - Modify dependency update scripts to work with organizational structure
  - Update any automation that generates or modifies package files
  - Ensure scripts can handle the new directory layout
  - _Requirements: 4.1, 4.4_