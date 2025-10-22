# Design Document

## Overview

This design outlines the migration of the pds-gatekeeper package source URL from the current GitHub repository (`fatfingers23/pds_gatekeeper`) to the new canonical location at Tangled.org (`@baileytownsend.dev/pds-gatekeeper`). The migration involves updating the fetchFromGitHub parameters while preserving all existing functionality and metadata.

## Architecture

### Current Implementation
The pds-gatekeeper package currently uses:
- **Owner**: `fatfingers23`
- **Repository**: `pds_gatekeeper`
- **Source**: GitHub-based fetchFromGitHub
- **Version**: `0.1.2`
- **Hash**: Placeholder hash requiring update

### Target Implementation
The migrated package will use:
- **Owner**: `@baileytownsend.dev` (Tangled.org user handle)
- **Repository**: `pds-gatekeeper`
- **Source**: Tangled.org git repository via fetchFromTangled
- **Domain**: `tangled.org` (default tangled.sh or custom domain)
- **Version**: Maintain current version or update if newer available
- **Hash**: Updated SHA256 hash for new source

## Components and Interfaces

### Dependencies

#### fetchFromTangled Integration
The migration requires integrating the fetchFromTangled utility:
- **Source**: Available at `https://tangled.org/@isabelroses.com/fetch-tangled`
- **Integration**: Add fetchFromTangled to package inputs or create local implementation
- **Compatibility**: Provides fetchFromGitHub-like interface for Tangled repositories
- **Features**: Supports both rev and tag-based fetching, handles metadata automatically

### Package Definition Updates

#### Source Configuration
```nix
src = fetchFromTangled {
  domain = "tangled.org";
  owner = "@baileytownsend.dev";
  repo = "pds-gatekeeper";
  rev = "v${version}";
  hash = "sha256-[NEW_HASH]";
};
```

#### Tangled Fetcher Integration
The package will use the fetchFromTangled utility which:
- **Base URL**: Constructs `https://tangled.org/@baileytownsend.dev/pds-gatekeeper`
- **Archive URL**: Uses `${baseUrl}/archive/${rev}` for tarball downloads
- **Compatibility**: Provides similar interface to fetchFromGitHub but adapted for Tangled.org
- **Metadata**: Automatically sets homepage and other metadata fields

### Metadata Updates

#### Repository References
Update all repository references in metadata:
- **passthru.organization.repository**: Update to new Tangled.org URL
- **meta.homepage**: Update to new repository location
- **Maintainer information**: Verify maintainer details remain accurate

#### Organizational Context
Maintain existing organizational classification:
- **Organization**: `individual` (unchanged)
- **Maintainer**: Verify if still `fatfingers23` or update to `baileytownsend.dev`

## Data Models

### Package Metadata Structure
```nix
{
  # Core package definition
  pname = "pds-gatekeeper";
  version = "0.1.2"; # Or updated version
  
  # Source configuration using fetchFromTangled
  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@baileytownsend.dev";
    repo = "pds-gatekeeper";
    rev = "v${version}";
    hash = "[COMPUTED_HASH]";
  };
  
  # Preserved metadata
  passthru = {
    atproto = { /* unchanged */ };
    organization = {
      repository = "https://tangled.org/@baileytownsend.dev/pds-gatekeeper";
      maintainer = "[VERIFIED_MAINTAINER]";
      /* other fields unchanged */
    };
  };
  
  meta = {
    homepage = "https://tangled.org/@baileytownsend.dev/pds-gatekeeper";
    /* other fields unchanged */
  };
}
```

## Error Handling

### Source Availability
- **Primary Strategy**: Use Tangled.org as primary source
- **Fallback Strategy**: If Tangled.org is unavailable, document alternative sources
- **Validation**: Verify repository exists and is accessible before finalizing migration

### Hash Verification
- **Hash Computation**: Use `nix-prefetch-url` with Tangled archive URL to compute correct hash
- **Alternative Method**: Use `nix-build` with empty hash to get correct hash from error message
- **Validation**: Ensure hash matches the actual content from new repository
- **Error Recovery**: Provide clear error messages if hash mismatches occur

### Build Compatibility
- **Dependency Verification**: Ensure new repository has same build dependencies
- **Feature Parity**: Verify all features and functionality remain intact
- **Testing**: Run build tests to confirm successful compilation

## Testing Strategy

### Pre-Migration Validation
1. **Repository Verification**: Confirm new repository exists and is accessible
2. **Content Comparison**: Verify new repository contains equivalent source code
3. **Version Alignment**: Check if version tags match between repositories

### Migration Testing
1. **Build Testing**: Test package builds successfully with new source
2. **Functionality Testing**: Verify binary functionality remains unchanged
3. **Integration Testing**: Test package works with existing NixOS modules

### Post-Migration Validation
1. **Hash Verification**: Confirm computed hash is correct and reproducible
2. **Metadata Accuracy**: Verify all updated metadata fields are correct
3. **Documentation Updates**: Ensure any documentation references are updated

## Implementation Phases

### Phase 1: Repository Analysis
- Investigate Tangled.org repository structure and access methods
- Verify repository content matches current source
- Identify any version differences or updates available

### Phase 2: Package Definition Update
- Update fetchFromGitHub parameters
- Compute and update source hash
- Update metadata references to new repository

### Phase 3: Testing and Validation
- Build package with new source
- Run functionality tests
- Validate all metadata and references

### Phase 4: Documentation and Cleanup
- Update any documentation references
- Verify organizational metadata accuracy
- Ensure compatibility with existing modules and tests

## Security Considerations

### Source Integrity
- **Hash Verification**: Ensure SHA256 hash accurately represents new source
- **Repository Authenticity**: Verify Tangled.org repository is official/authorized
- **Supply Chain Security**: Maintain same security posture as current implementation

### Access Control
- **Repository Access**: Ensure repository remains publicly accessible
- **Maintainer Verification**: Confirm maintainer identity and authorization
- **Update Process**: Establish process for future updates from new source

## Migration Risks and Mitigation

### Repository Availability Risk
- **Risk**: Tangled.org repository becomes unavailable
- **Mitigation**: Document alternative sources and maintain backup references

### Content Divergence Risk
- **Risk**: New repository content differs from original
- **Mitigation**: Thorough content comparison and testing before migration

### Build Compatibility Risk
- **Risk**: New source has different build requirements
- **Mitigation**: Comprehensive build testing and dependency verification

### Metadata Accuracy Risk
- **Risk**: Updated metadata contains incorrect information
- **Mitigation**: Careful verification of all metadata fields and references