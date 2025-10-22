# Requirements Document

## Introduction

This specification defines the requirements for migrating the pds-gatekeeper package source URL from the current GitHub repository to the new Tangled.org repository location. This migration ensures the package points to the correct upstream source while maintaining compatibility and functionality.

## Glossary

- **PDS_Gatekeeper**: A security microservice for ATProto PDS with 2FA and rate limiting capabilities
- **Source_URL**: The git repository URL used by fetchFromGitHub in the Nix package definition
- **Tangled_Repository**: The new canonical repository location at tangled.org
- **Package_Definition**: The Nix expression file that defines how to build the pds-gatekeeper package
- **Hash_Verification**: The SHA256 hash used to verify the integrity of the fetched source code

## Requirements

### Requirement 1

**User Story:** As a NixOS user, I want the pds-gatekeeper package to fetch from the correct upstream repository, so that I get the latest official version and updates.

#### Acceptance Criteria

1. WHEN building the pds-gatekeeper package, THE Package_Definition SHALL fetch source code from the Tangled_Repository
2. THE Package_Definition SHALL use the correct owner and repository name for the Tangled.org location
3. THE Package_Definition SHALL maintain the same version and revision structure as the current implementation
4. THE Hash_Verification SHALL be updated to match the content from the new Source_URL
5. THE Package_Definition SHALL preserve all existing build configuration and metadata

### Requirement 2

**User Story:** As a package maintainer, I want the migration to preserve all existing functionality, so that users experience no breaking changes.

#### Acceptance Criteria

1. THE Package_Definition SHALL maintain identical build inputs and native build inputs
2. THE Package_Definition SHALL preserve all environment variables and build flags
3. THE Package_Definition SHALL retain the postInstall script for copying email templates and assets
4. THE Package_Definition SHALL maintain all passthru metadata including ATProto and organizational information
5. THE Package_Definition SHALL preserve the meta attributes including description, license, and platforms

### Requirement 3

**User Story:** As a system administrator, I want the package to build successfully with the new source, so that I can deploy the updated version without issues.

#### Acceptance Criteria

1. WHEN the Package_Definition is built, THE build process SHALL complete successfully without errors
2. THE resulting binary SHALL have the same functionality as the previous version
3. THE Package_Definition SHALL include proper error handling if the new Source_URL is unavailable
4. THE build artifacts SHALL maintain the same file structure and permissions
5. THE package SHALL pass all existing tests and validation checks