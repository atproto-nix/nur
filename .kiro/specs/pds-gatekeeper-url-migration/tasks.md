# Implementation Plan - Migrate All Tangled Repositories to fetchFromTangled

- [x] 1. Set up fetchFromTangled integration
  - Add fetchFromTangled utility to the repository for Tangled.org repository access
  - Create or integrate the fetcher implementation from isabelroses.com/fetch-tangled
  - Ensure fetchFromTangled is available in package scope
  - _Requirements: 1.1, 2.1_

- [-] 2. Update pds-gatekeeper package definition
  - [x] 2.1 Replace fetchFromGitHub with fetchFromTangled in package inputs
    - Modify the package function signature to include fetchFromTangled
    - Update the src definition to use fetchFromTangled instead of fetchFromGitHub
    - Set correct domain, owner, and repo parameters for Tangled.org
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 2.2 Update source parameters for Tangled.org repository
    - Change owner from "fatfingers23" to "@baileytownsend.dev"
    - Change repo from "pds_gatekeeper" to "pds-gatekeeper"
    - Set domain to "tangled.org"
    - Maintain existing version and rev structure
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 2.3 Compute and update source hash
    - Use nix-prefetch-url or build attempt to get correct hash for new source
    - Replace placeholder hash with computed SHA256 hash
    - Verify hash corresponds to correct source content
    - _Requirements: 1.4_

- [x] 3. Update package metadata and references
  - [x] 3.1 Update repository URLs in passthru metadata
    - Change passthru.organization.repository to new Tangled.org URL
    - Verify maintainer information is still accurate
    - Update any other repository references in metadata
    - _Requirements: 2.4, 2.5_

  - [x] 3.2 Update meta attributes
    - Change meta.homepage to new Tangled.org repository URL
    - Verify all other meta attributes remain accurate
    - Ensure organizational context reflects any maintainer changes
    - _Requirements: 2.4, 2.5_

- [x] 4. Validate package functionality
  - [x] 4.1 Test package builds successfully
    - Build the updated package definition
    - Verify build completes without errors
    - Check that all build inputs and environment variables work correctly
    - _Requirements: 3.1, 3.4_

  - [x] 4.2 Verify package contents and functionality
    - Check that resulting binary has expected functionality
    - Verify email templates and assets are properly copied
    - Ensure postInstall script works correctly with new source
    - _Requirements: 3.2, 3.4_

  - [ ]* 4.3 Run integration tests
    - Test package works with existing NixOS modules
    - Verify compatibility with pds-gatekeeper service configuration
    - Check that all passthru metadata is accessible
    - _Requirements: 3.5_

- [x] 5. Migrate existing Tangled repositories to fetchFromTangled
  - [x] 5.1 Update atbackup package (atbackup-pages-dev/atbackup.nix)
    - Replace fetchgit with fetchFromTangled for @atbackup.pages.dev/atbackup
    - Update domain, owner, and repo parameters appropriately
    - Compute new hash for fetchFromTangled format
    - _Requirements: 1.1, 1.2, 1.4_

  - [x] 5.2 Update red-dwarf package (red-dwarf-client/red-dwarf.nix)
    - Replace fetchgit with fetchFromTangled for @whey.party/red-dwarf
    - Update source parameters for Tangled.org format
    - Verify build compatibility with new fetcher
    - _Requirements: 1.1, 1.2, 1.4_

  - [x] 5.3 Update streamplace package (stream-place/streamplace.nix)
    - Replace fetchgit with fetchFromTangled for @stream.place/streamplace
    - Update source configuration for proper Tangled.org access
    - Test build process with new fetcher
    - _Requirements: 1.1, 1.2, 1.4_

  - [x] 5.4 Update slices package (slices-network/slices.nix)
    - Replace fetchgit with fetchFromTangled for @slices.network/slices
    - Handle the "main" branch reference appropriately (use tag or specific rev)
    - Update fake hash to proper computed hash
    - _Requirements: 1.1, 1.2, 1.4_

  - [x] 5.5 Update quickdid package (smokesignal-events/quickdid.nix)
    - Replace fetchgit with fetchFromTangled for @smokesignal.events/quickdid
    - Update source parameters for Tangled.org format
    - Verify package builds correctly with new fetcher
    - _Requirements: 1.1, 1.2, 1.4_

  - [x] 5.6 Update yoten package (yoten-app/yoten.nix)
    - Replace current placeholder implementation with fetchFromTangled for @yoten.app/yoten
    - Implement actual source fetching instead of current stub
    - Add proper build configuration based on repository analysis
    - _Requirements: 1.1, 1.2, 1.4_

- [-] 6. Research and migrate potential GitHub-to-Tangled candidates
  - [x] 6.1 Research allegedly package migration potential
    - Check if @microcosm.blue/Allegedly exists on Tangled.org
    - Compare with current GitHub source at microcosm-cc/allegedly
    - Migrate to fetchFromTangled if Tangled repository is canonical
    - _Requirements: 1.1, 1.2_

  - [x] 6.2 Research leaflet package migration potential
    - Check if @leaflet.pub/leaflet or similar exists on Tangled.org
    - Compare with current GitHub source at hyperlink-academy/leaflet
    - Migrate to fetchFromTangled if Tangled repository is available and preferred
    - _Requirements: 1.1, 1.2_

  - [ ] 6.3 Research tangled-core projects migration potential
    - Check if @tangled.dev/core or similar exists on Tangled.org
    - Compare with current GitHub source at tangled-dev/tangled-core
    - Migrate tangled-dev packages to fetchFromTangled if Tangled repository is canonical
    - _Requirements: 1.1, 1.2_

  - [ ]* 6.4 Document migration decisions and rationale
    - Create documentation explaining which packages were migrated and why
    - Document any packages that remained on GitHub and the reasoning
    - Provide guidance for future package additions regarding Tangled vs GitHub
    - _Requirements: 2.4, 2.5_

- [ ] 7. Update package collection integration
  - [ ] 6.1 Verify all packages are properly exposed in collections
    - Check that all updated packages are available in their respective collections
    - Ensure packages appear in default.nix exports
    - Verify flake outputs include all updated packages
    - _Requirements: 2.1, 2.2, 2.3_

  - [ ] 6.2 Update any dependent configurations
    - Check if any modules or tests reference the old fetching methods
    - Update documentation or examples that mention repository access
    - Ensure CI/CD configurations work with all updated packages
    - _Requirements: 2.4, 2.5_

- [ ] 8. Comprehensive validation of all migrations
  - [ ] 7.1 Build test all migrated packages
    - Run nix build for all packages that were migrated to fetchFromTangled
    - Verify no build failures or hash mismatches
    - Check that all packages produce expected outputs
    - _Requirements: 3.1, 3.4_

  - [ ] 7.2 Validate fetchFromTangled integration consistency
    - Ensure all packages use consistent fetchFromTangled parameters
    - Verify domain settings are appropriate for each repository
    - Check that all hash computations are correct
    - _Requirements: 1.4, 3.5_

  - [ ]* 7.3 Run integration tests for all affected packages
    - Test packages work with their corresponding NixOS modules
    - Verify service configurations remain functional
    - Check that all passthru metadata is preserved and accessible
    - _Requirements: 3.5_