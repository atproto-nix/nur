# Organizational Migration Guide

This document provides guidance for migrating from the old technical category structure to the new organizational ownership structure.

## Overview

The ATProto NUR has been reorganized from technical categories (like `atproto`, `bluesky`, etc.) to organizational ownership structure. This provides better clarity about project relationships, maintenance responsibilities, and ecosystem organization.

## Migration Summary

### Package Name Changes

The following packages have been moved to their new organizational locations:

#### From `atproto/` to Organizational Directories

| Old Name | New Name | Organization |
|----------|----------|--------------|
| `allegedly` | `microcosm-blue-allegedly` | Microcosm Blue |
| `atbackup` | `atbackup-pages-dev-atbackup` | ATBackup Pages Dev |
| `quickdid` | `smokesignal-events-quickdid` | Smokesignal Events |
| `streamplace` | `stream-place-streamplace` | Stream.place |
| `yoten` | `yoten-app-yoten` | Yoten App |
| `red-dwarf` | `red-dwarf-client-red-dwarf` | Red Dwarf Client |
| `appview` | `tangled-dev-appview` | Tangled Development |
| `knot` | `tangled-dev-knot` | Tangled Development |
| `spindle` | `tangled-dev-spindle` | Tangled Development |
| `genjwks` | `tangled-dev-genjwks` | Tangled Development |
| `lexgen` | `tangled-dev-lexgen` | Tangled Development |
| `leaflet` | `hyperlink-academy-leaflet` | Hyperlink Academy |
| `slices` | `slices-network-slices` | Slices Network |
| `teal` | `teal-fm-teal` | Teal.fm |
| `parakeet` | `parakeet-social-parakeet` | Parakeet Social |
| `indigo` | `bluesky-social-indigo` | Official Bluesky |
| `grain` | `bluesky-social-grain` | Official Bluesky |

#### From `bluesky/` to Organizational Directories

| Old Name | New Name | Organization |
|----------|----------|--------------|
| `pds-dash` | `witchcraft-systems-pds-dash` | Witchcraft Systems |
| `pds-gatekeeper` | `individual-pds-gatekeeper` | Individual Developers |
| `frontpage` | `bluesky-social-frontpage` | Official Bluesky |

### Service Name Changes

NixOS service names have been updated to match the organizational structure:

#### New Service Names

| Old Service | New Service | Status |
|-------------|-------------|---------|
| `services.atproto-leaflet` | `services.hyperlink-academy-leaflet` | ✅ Available |
| `services.atproto-slices` | `services.slices-network-slices` | ✅ Available |
| `services.atproto-teal` | `services.teal-fm-teal` | ✅ Available |
| `services.atproto-parakeet` | `services.parakeet-social-parakeet` | ✅ Available |
| `services.atproto-quickdid` | `services.smokesignal-events-quickdid` | ✅ Available |
| `services.atproto-allegedly` | `services.microcosm-blue-allegedly` | ✅ Available |
| `services.atproto-atbackup` | `services.atbackup-pages-dev-atbackup` | ✅ Available |
| `services.bluesky-pds-gatekeeper` | `services.individual-pds-gatekeeper` | ✅ Available |
| `services.bluesky.pds-dash` | `services.witchcraft-systems-pds-dash` | ✅ Available |
| `services.bluesky-frontpage` | `services.bluesky-social-frontpage` | ✅ Available |

## Backward Compatibility

### Automatic Aliases

The repository includes automatic backward compatibility through the `modules/compatibility.nix` module:

- **Package Aliases**: Old package names continue to work with deprecation warnings
- **Service Aliases**: Old service names are automatically redirected to new names
- **Gradual Migration**: Users can migrate at their own pace

### Example Compatibility

```nix
# Old configuration (still works with warnings)
services.atproto-leaflet.enable = true;
services.quickdid.enable = true;
services.pds-dash.enable = true;

# New configuration (recommended)
services.hyperlink-academy-leaflet.enable = true;
services.smokesignal-events-quickdid.enable = true;
services.witchcraft-systems-pds-dash.enable = true;
```

## Migration Steps

### 1. Update Package References

If you're using packages directly:

```bash
# Old way
nix run github:atproto-nix/nur#quickdid

# New way
nix run github:atproto-nix/nur#smokesignal-events-quickdid

# Backward compatibility (works but shows deprecation warning)
nix run github:atproto-nix/nur#quickdid
```

### 2. Update NixOS Configuration

Update your NixOS configuration to use the new service names:

```nix
# Before
{
  services = {
    atproto-leaflet.enable = true;
    atproto-quickdid.enable = true;
    bluesky-pds-gatekeeper.enable = true;
  };
}

# After
{
  services = {
    hyperlink-academy-leaflet.enable = true;
    smokesignal-events-quickdid.enable = true;
    individual-pds-gatekeeper.enable = true;
  };
}
```

### 3. Update Flake Inputs

If you're importing specific packages in your flake:

```nix
# Before
{
  packages.default = inputs.atproto-nur.packages.${system}.quickdid;
}

# After
{
  packages.default = inputs.atproto-nur.packages.${system}.smokesignal-events-quickdid;
}
```

### 4. Update Documentation and Scripts

Update any documentation, scripts, or automation that references the old names:

- CI/CD pipelines
- Deployment scripts
- Documentation examples
- Package lists

## Benefits of Organizational Structure

### Clear Ownership

Each package is now clearly associated with its maintaining organization:

- **Hyperlink Academy**: Educational technology company
- **Smokesignal Events**: Identity and event services
- **Witchcraft Systems**: PDS management tools
- **Individual Developers**: Community contributions
- **Official Bluesky**: Official Bluesky implementations

### Better Maintenance

- Organizations can maintain their own packages independently
- Clear contact points for issues and contributions
- Easier to track project relationships and dependencies

### Ecosystem Visibility

- Better understanding of the ATProto ecosystem landscape
- Clearer picture of who's building what
- Easier discovery of related projects

## Troubleshooting

### Deprecation Warnings

If you see deprecation warnings, update your configuration to use the new names:

```
warning: The module option 'services.atproto-leaflet' is deprecated. 
Please use 'services.hyperlink-academy-leaflet' instead.
```

### Service Not Found

If a service isn't found, check the migration table above or use the organizational validation script:

```bash
./scripts/organizational-validation.sh
```

### Package Build Issues

If you encounter package build issues after migration:

1. Check that you're using the correct new package name
2. Verify the package exists in the new organizational structure
3. Check for any configuration changes required

## Getting Help

- **Documentation**: See `docs/ORGANIZATIONAL_FRAMEWORK.md` for detailed information
- **Validation**: Use `./scripts/organizational-validation.sh` to check your setup
- **Issues**: Report migration issues on the repository issue tracker

## Timeline

- **Phase 1** (Current): Organizational structure implemented with backward compatibility
- **Phase 2** (Future): Deprecation warnings for old names
- **Phase 3** (Future): Removal of backward compatibility aliases

The migration is designed to be gradual and non-breaking. You can continue using old names while planning your migration to the new organizational structure.