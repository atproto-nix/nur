# Design Document

## Overview

This design restructures the ATProto NUR package and module hierarchy to reflect actual organizational ownership rather than arbitrary technology groupings. Based on analysis of the code repositories, we'll reorganize packages under their proper organizational owners while maintaining backward compatibility.

## Architecture

### Current Structure Problems

The current structure groups packages arbitrarily:
- `pkgs/atproto/` - Mixed applications from different organizations
- `pkgs/microcosm/` - Correctly organized by organization
- `pkgs/blacksky/` - Correctly organized by organization  
- `pkgs/bluesky/` - Correctly organized by organization

### Proposed Organizational Structure

Based on repository analysis, the correct organizational hierarchy should be:

```
pkgs/
├── hyperlink-academy/          # Learning Futures Inc.
│   └── leaflet/               # Collaborative writing platform
├── slices-network/            # Slices Network
│   └── slices/               # Custom AppView platform
├── teal-fm/                   # Teal.fm
│   └── teal/                 # Music social platform
├── parakeet-social/           # Parakeet Social
│   └── parakeet/             # Bluesky AppView implementation
├── stream-place/              # Stream.place
│   └── streamplace/          # Video infrastructure platform
├── yoten-app/                 # Yoten App
│   └── yoten/                # Language learning platform
├── red-dwarf-client/          # Red Dwarf Client
│   └── red-dwarf/            # Constellation-based Bluesky client
├── tangled-dev/               # Tangled Development
│   ├── appview/              # Tangled AppView
│   ├── knot/                 # Tangled Knot (Git server)
│   ├── spindle/              # Tangled Spindle (Event processor)
│   ├── genjwks/              # JWKS generator
│   └── lexgen/               # Lexicon generator
├── smokesignal-events/        # Smokesignal Events
│   └── quickdid/             # Identity resolution service
├── microcosm-blue/            # Microcosm (existing, correctly organized)
│   └── allegedly/            # PLC tools (move from atproto)
├── witchcraft-systems/        # Witchcraft Systems
│   └── pds-dash/             # PDS Dashboard (move from bluesky)
├── atbackup-pages-dev/        # ATBackup
│   └── atbackup/             # Backup application
├── bluesky-social/            # Official Bluesky (for official packages)
│   ├── indigo/               # Go implementation (move from atproto)
│   └── grain/                # TypeScript implementation (move from atproto)
└── individual/                # For individual developers without clear org
    └── [individual-projects]  # Fallback category
```

## Components and Interfaces

### Package Migration Strategy

1. **Organizational Mapping**: Create a mapping file that defines the correct organizational ownership for each package
2. **Directory Restructuring**: Move packages from current locations to organization-based directories
3. **Import Updates**: Update all import statements and references to use new paths
4. **Compatibility Layer**: Provide temporary aliases for backward compatibility

### Module Structure Alignment

The module structure should mirror the package structure:

```
modules/
├── hyperlink-academy/
│   └── leaflet.nix
├── slices-network/
│   └── slices.nix
├── teal-fm/
│   └── teal.nix
[... matching package structure ...]
```

### Flake Output Organization

Update `flake.nix` to expose packages using the new organizational structure:

```nix
packages = {
  # Organized by organization
  hyperlink-academy-leaflet = packages.hyperlink-academy.leaflet;
  slices-network-slices = packages.slices-network.slices;
  teal-fm-teal = packages.teal-fm.teal;
  
  # Backward compatibility aliases
  leaflet = packages.hyperlink-academy.leaflet;
  slices = packages.slices-network.slices;
  teal = packages.teal-fm.teal;
};
```

## Data Models

### Organizational Mapping Configuration

```nix
organizationalMapping = {
  "leaflet" = {
    organization = "hyperlink-academy";
    currentPath = "pkgs/atproto/leaflet";
    newPath = "pkgs/hyperlink-academy/leaflet";
    repository = "https://github.com/hyperlink-academy/leaflet";
    maintainer = "Learning Futures Inc.";
  };
  
  "slices" = {
    organization = "slices-network";
    currentPath = "pkgs/atproto/slices";
    newPath = "pkgs/slices-network/slices";
    repository = "https://tangled.sh/slices.network/slices";
    maintainer = "Slices Network";
  };
  
  # ... additional mappings
};
```

### Package Metadata Enhancement

Each package should include organizational metadata:

```nix
passthru.organization = {
  name = "hyperlink-academy";
  displayName = "Hyperlink Academy";
  website = "https://hyperlink.academy";
  contact = "contact@leaflet.pub";
};
```

## Error Handling

### Migration Error Handling

1. **Missing Packages**: If a package cannot be found during migration, log the error and continue with other packages
2. **Import Conflicts**: If new organizational structure creates naming conflicts, use qualified names
3. **Broken References**: Provide clear error messages when old paths are used without compatibility aliases
4. **Validation Failures**: Ensure all moved packages still build correctly in their new locations

### Backward Compatibility

1. **Alias System**: Maintain aliases for old package names for at least one major version
2. **Deprecation Warnings**: Emit warnings when old paths are used
3. **Migration Documentation**: Provide clear upgrade instructions for users
4. **Gradual Migration**: Allow both old and new paths to work during transition period

## Testing Strategy

### Package Build Verification

1. **Build Tests**: Ensure all packages build correctly in their new organizational locations
2. **Import Tests**: Verify that all internal references and imports work with new structure
3. **Module Tests**: Confirm that NixOS modules function properly with reorganized packages
4. **Integration Tests**: Test that services can still be configured and deployed

### Compatibility Testing

1. **Alias Testing**: Verify that backward compatibility aliases work correctly
2. **Migration Testing**: Test the migration process on a copy of the repository
3. **Documentation Testing**: Ensure all documentation examples work with new structure
4. **User Workflow Testing**: Verify common user workflows still function

### Validation Framework

1. **Organizational Validation**: Ensure packages are placed in correct organizational directories
2. **Metadata Validation**: Verify that organizational metadata is complete and accurate
3. **Reference Validation**: Check that all cross-references between packages are maintained
4. **Naming Convention Validation**: Ensure consistent naming patterns within organizations