# Requirements Document

## Introduction

This specification addresses the incorrect naming hierarchy in the ATProto NUR packages and modules structure. Currently, applications are organized by technology or arbitrary groupings rather than their actual organizational ownership. This creates confusion and doesn't reflect the real-world relationships between projects and their maintainers.

## Glossary

- **ATProto NUR**: The Nix User Repository for AT Protocol applications and services
- **Package Hierarchy**: The organizational structure of packages in `pkgs/` directories
- **Module Hierarchy**: The organizational structure of NixOS modules in `modules/` directories
- **Organizational Owner**: The company, group, or individual that maintains a project
- **Repository Structure**: The directory layout that reflects ownership relationships

## Requirements

### Requirement 1

**User Story:** As a NixOS administrator, I want packages organized by their actual organizational ownership, so that I can understand project relationships and maintenance responsibilities.

#### Acceptance Criteria

1. WHEN examining the package structure, THE ATProto_NUR SHALL organize packages by organizational owner rather than technology type
2. WHEN a project has a clear organizational owner, THE ATProto_NUR SHALL place it under the appropriate organization directory
3. WHEN multiple projects share the same organizational owner, THE ATProto_NUR SHALL group them together under a single organization namespace
4. WHERE an organization has multiple related projects, THE ATProto_NUR SHALL maintain clear separation between distinct applications
5. IF an organization name changes or projects move, THEN THE ATProto_NUR SHALL provide migration paths for existing configurations

### Requirement 2

**User Story:** As a developer contributing to the ATProto ecosystem, I want to easily locate packages from specific organizations, so that I can understand the ecosystem landscape and find related projects.

#### Acceptance Criteria

1. WHEN browsing the package directory, THE ATProto_NUR SHALL use organization names as top-level directories
2. WHEN an organization maintains multiple ATProto applications, THE ATProto_NUR SHALL group them under the organization's directory
3. WHILE maintaining backward compatibility, THE ATProto_NUR SHALL provide clear migration documentation
4. WHERE organizations use different names across platforms, THE ATProto_NUR SHALL use the most canonical organization identifier
5. IF a project lacks clear organizational ownership, THEN THE ATProto_NUR SHALL place it in an appropriate fallback category

### Requirement 3

**User Story:** As a system integrator, I want NixOS modules to follow the same organizational hierarchy as packages, so that configuration and deployment remain consistent.

#### Acceptance Criteria

1. WHEN configuring services through NixOS modules, THE ATProto_NUR SHALL mirror the package organizational structure
2. WHEN enabling services from the same organization, THE ATProto_NUR SHALL provide consistent configuration patterns
3. WHILE preserving existing service functionality, THE ATProto_NUR SHALL update module paths to match organizational structure
4. WHERE services have dependencies within the same organization, THE ATProto_NUR SHALL make these relationships explicit
5. IF module paths change due to reorganization, THEN THE ATProto_NUR SHALL provide compatibility aliases during transition

### Requirement 4

**User Story:** As a package maintainer, I want clear guidelines for where to place new packages based on organizational ownership, so that the hierarchy remains consistent as the ecosystem grows.

#### Acceptance Criteria

1. WHEN adding a new package, THE ATProto_NUR SHALL provide clear placement rules based on organizational ownership
2. WHEN an organization is new to the repository, THE ATProto_NUR SHALL establish appropriate directory structure
3. WHILE maintaining consistency, THE ATProto_NUR SHALL handle edge cases like individual developers vs organizations
4. WHERE ownership is ambiguous, THE ATProto_NUR SHALL provide fallback categorization rules
5. IF organizational relationships change, THEN THE ATProto_NUR SHALL support package migration between categories