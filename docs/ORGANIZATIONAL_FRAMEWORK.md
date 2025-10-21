# Organizational Framework

This document explains the organizational structure of the ATProto NUR and provides guidelines for maintaining and extending it.

## Overview

The ATProto NUR uses an organizational framework that groups packages and modules by their actual organizational ownership rather than arbitrary technical categories. This approach provides several benefits:

- **Clear Ownership**: Easy identification of project maintainers and responsible parties
- **Logical Grouping**: Related projects from the same organization are grouped together
- **Ecosystem Visibility**: Better understanding of the ATProto ecosystem landscape
- **Maintenance Clarity**: Simplified contribution and maintenance workflows

## Organizational Structure

### Current Organizations

The repository currently includes the following organizations:

#### Hyperlink Academy
- **Website**: https://hyperlink.academy
- **Projects**: Leaflet (collaborative writing platform)
- **Contact**: contact@leaflet.pub
- **Focus**: Educational technology and collaborative tools

#### Slices Network
- **Website**: https://tangled.sh/slices.network
- **Projects**: Slices (custom AppView platform)
- **Focus**: Custom ATProto AppView implementations

#### Teal.fm
- **Website**: https://teal.fm
- **Projects**: Teal (music social platform)
- **Focus**: Music-focused social networking

#### Parakeet Social
- **Projects**: Parakeet (ATProto AppView implementation)
- **Focus**: Full-featured ATProto AppView services

#### Stream.place
- **Projects**: Streamplace (video infrastructure platform)
- **Focus**: Video streaming and multimedia infrastructure

#### Yoten App
- **Projects**: Yoten (language learning platform)
- **Focus**: Educational applications with social features

#### Red Dwarf Client
- **Projects**: Red Dwarf (Bluesky client)
- **Focus**: Enhanced Bluesky client applications

#### Tangled Development
- **Website**: https://tangled.org
- **Projects**: AppView, Knot, Spindle, GenJWKS, LexGen
- **Focus**: Git forge infrastructure with ATProto integration

#### Smokesignal Events
- **Projects**: QuickDID (identity resolution service)
- **Focus**: Identity and DID resolution services

#### Microcosm Blue
- **Projects**: Allegedly (PLC tools)
- **Focus**: ATProto infrastructure and tooling

#### Witchcraft Systems
- **Projects**: PDS Dashboard
- **Focus**: PDS management and monitoring tools

#### ATBackup Pages Dev
- **Projects**: ATBackup (backup application)
- **Focus**: Data backup and archival solutions

#### Official Bluesky Social
- **Website**: https://bsky.social
- **Projects**: Indigo (Go implementation), Grain (TypeScript implementation)
- **Focus**: Official ATProto implementations

#### Individual Developers
- **Projects**: Various individual contributions
- **Focus**: Projects without clear organizational ownership

### Legacy Collections

Some existing collections are maintained for backward compatibility:

#### Microcosm
- **Projects**: Constellation, Spacedust, Slingshot, UFOs, Who-am-i, Quasar, Pocket, Reflector
- **Status**: Existing collection, maintained as-is

#### Blacksky
- **Projects**: Community ATProto tools
- **Status**: Existing collection, maintained as-is

## Package Naming Convention

### Organizational Packages

New packages follow the organizational naming convention:

```
{organization}-{project}
```

Examples:
- `hyperlink-academy-leaflet`
- `smokesignal-events-quickdid`
- `tangled-dev-appview`

### Service Names

NixOS service modules follow the same convention:

```
services.{organization}-{project}
```

Examples:
- `services.hyperlink-academy-leaflet`
- `services.smokesignal-events-quickdid`
- `services.tangled-dev-appview`

## Directory Structure

### Package Organization

```
pkgs/
├── {organization}/
│   ├── default.nix          # Organization entry point with metadata
│   ├── {project}/
│   │   └── default.nix      # Individual project package
│   └── lib.nix             # Shared utilities (optional)
```

### Module Organization

```
modules/
├── {organization}/
│   ├── default.nix          # Organization module collection
│   └── {project}.nix        # Individual service module
```

## Organizational Metadata

Each organization includes standardized metadata:

```nix
organizationMeta = {
  name = "organization-name";
  displayName = "Human Readable Name";
  website = "https://organization.com";
  description = "Brief description of the organization";
  maintainers = [ "github-handle" ];
  contact = "contact@organization.com";  # Optional
  repository = "https://github.com/org/repo";  # Optional
};
```

This metadata is used for:
- Package documentation generation
- Maintainer contact information
- Organizational validation
- Ecosystem mapping

## Adding New Organizations

### Prerequisites

Before adding a new organization:

1. **Verify Ownership**: Ensure you have permission to represent the organization
2. **Check Existing**: Verify the organization doesn't already exist
3. **Gather Information**: Collect organizational metadata (website, contact, etc.)
4. **Plan Structure**: Determine which projects belong to the organization

### Implementation Steps

1. **Create Directory Structure**:
   ```bash
   mkdir -p pkgs/your-organization
   mkdir -p modules/your-organization
   ```

2. **Create Organization Entry Point**:
   ```nix
   # pkgs/your-organization/default.nix
   { lib, callPackage, ... }:
   
   let
     organizationMeta = {
       name = "your-organization";
       displayName = "Your Organization";
       website = "https://your-org.com";
       description = "ATProto projects by Your Organization";
       maintainers = [ "your-github-handle" ];
     };
   in
   {
     passthru.organization = organizationMeta;
     
     # Export projects
     project-name = callPackage ./project-name { 
       inherit organizationMeta;
     };
   }
   ```

3. **Create Module Collection**:
   ```nix
   # modules/your-organization/default.nix
   {
     project-name = ./project-name.nix;
   }
   ```

4. **Update Root Collections**:
   - Add to `pkgs/default.nix`
   - Add to `modules/default.nix`
   - Update `flake.nix` outputs

5. **Add Documentation**:
   - Update this document with organization information
   - Add organization to README.md
   - Include in migration guide if moving existing packages

## Validation and Testing

### Organizational Validation

The repository includes validation tools to ensure organizational consistency:

```bash
# Validate organizational structure
nix build .#tests.organizational-framework

# Check organizational metadata
./scripts/organizational-validation.sh
```

### Required Validations

1. **Metadata Completeness**: All organizations must have complete metadata
2. **Naming Consistency**: Package and module names must follow conventions
3. **Directory Structure**: Proper directory organization must be maintained
4. **Cross-References**: All references between packages must be valid

## Migration Guidelines

### Moving Existing Packages

When moving packages to organizational structure:

1. **Identify Organization**: Determine the correct organizational owner
2. **Create Structure**: Set up organizational directories if needed
3. **Move Package**: Relocate package to organizational directory
4. **Update References**: Update all imports and references
5. **Add Aliases**: Provide backward compatibility aliases
6. **Update Documentation**: Reflect changes in documentation

### Deprecation Process

For packages being moved:

1. **Add Deprecation Warning**: Include warning in old package location
2. **Provide Alias**: Create alias pointing to new location
3. **Update Documentation**: Add migration instructions
4. **Maintain Compatibility**: Keep aliases for at least one major version
5. **Remove Old Names**: Eventually remove deprecated names

## Best Practices

### Organizational Naming

- Use kebab-case for organization names
- Choose descriptive, recognizable names
- Avoid generic terms (e.g., "tools", "utils")
- Use official organization names when possible

### Project Naming

- Use kebab-case for project names
- Keep names concise but descriptive
- Avoid redundant organizational prefixes in project names
- Use upstream project names when packaging existing software

### Metadata Management

- Keep organizational metadata up to date
- Include contact information for maintenance
- Provide clear descriptions
- Link to official websites and repositories

### Documentation

- Document all organizational changes
- Provide migration guides for structural changes
- Keep examples current with organizational structure
- Include organizational context in package descriptions

## Future Considerations

### Scaling

As the ecosystem grows:

- Monitor organizational structure effectiveness
- Consider sub-organizational groupings if needed
- Evaluate naming convention scalability
- Plan for organizational changes and mergers

### Automation

Potential automation improvements:

- Automated organizational validation
- Metadata consistency checking
- Migration assistance tools
- Documentation generation from metadata

### Community

Community involvement:

- Encourage organizational representatives to maintain their sections
- Provide clear contribution guidelines
- Support community-driven organizational additions
- Facilitate communication between organizations

This organizational framework provides a solid foundation for managing the growing ATProto ecosystem while maintaining clarity and consistency.