# Migration Guide

This guide helps users migrate from the old package naming scheme to the new organizational structure.

> **📖 Also see**: [Organizational Migration Guide](ORGANIZATIONAL_MIGRATION.md) for a focused migration reference with tables and quick lookup.

## Overview

The ATProto NUR has been reorganized to reflect actual organizational ownership rather than arbitrary technology groupings. This provides better clarity about project relationships and maintenance responsibilities.

**Key Changes:**
- Packages are now organized by their actual organizational owners
- Package names include organizational prefixes for clarity
- Module names follow the same organizational structure
- Backward compatibility is maintained through aliases and deprecation warnings
- Documentation has been updated to reflect the new structure

## Package Name Changes

### Organizational Structure

Packages are now organized by their actual organizational owners:

| Old Name | New Name | Organization |
|----------|----------|--------------|
| `leaflet` | `hyperlink-academy-leaflet` | Hyperlink Academy |
| `slices` | `slices-network-slices` | Slices Network |
| `teal` | `teal-fm-teal` | Teal.fm |
| `parakeet` | `parakeet-social-parakeet` | Parakeet Social |
| `streamplace` | `stream-place-streamplace` | Stream.place |
| `yoten` | `yoten-app-yoten` | Yoten App |
| `red-dwarf` | `red-dwarf-client-red-dwarf` | Red Dwarf Client |
| `quickdid` | `smokesignal-events-quickdid` | Smokesignal Events |
| `allegedly` | `microcosm-blue-allegedly` | Microcosm |
| `pds-dash` | `witchcraft-systems-pds-dash` | Witchcraft Systems |
| `atbackup` | `atbackup-pages-dev-atbackup` | ATBackup |
| `indigo` | `bluesky-social-indigo` | Official Bluesky |
| `grain` | `bluesky-social-grain` | Official Bluesky |
| `pds-gatekeeper` | `individual-pds-gatekeeper` | Individual Developers |

### Tangled Development Packages

| Old Name | New Name |
|----------|----------|
| `appview` | `tangled-dev-appview` |
| `knot` | `tangled-dev-knot` |
| `spindle` | `tangled-dev-spindle` |
| `genjwks` | `tangled-dev-genjwks` |
| `lexgen` | `tangled-dev-lexgen` |

## Migration Steps

### 1. Update Flake Inputs

If you're using the ATProto NUR in your flake, no changes are needed to your flake inputs. The same flake reference continues to work.

### 2. Update Package References

#### In Nix Expressions

**Old:**
```nix
{
  environment.systemPackages = with pkgs.nur.repos.atproto; [
    leaflet
    teal
    quickdid
  ];
}
```

**New:**
```nix
{
  environment.systemPackages = with pkgs.nur.repos.atproto; [
    hyperlink-academy-leaflet
    teal-fm-teal
    smokesignal-events-quickdid
  ];
}
```

#### In Flake Packages

**Old:**
```nix
{
  packages.x86_64-linux = {
    inherit (inputs.atproto-nur.packages.x86_64-linux) leaflet teal;
  };
}
```

**New:**
```nix
{
  packages.x86_64-linux = {
    leaflet = inputs.atproto-nur.packages.x86_64-linux.hyperlink-academy-leaflet;
    teal = inputs.atproto-nur.packages.x86_64-linux.teal-fm-teal;
  };
}
```

### 3. Update NixOS Module References

Module names have also been updated to match the organizational structure. See the [Module Migration](#module-migration) section below.

## Backward Compatibility

### Deprecation Period

- **Old package names** continue to work but will show deprecation warnings
- **Old module names** continue to work with compatibility aliases
- **Backward compatibility** will be maintained for at least one major version

### Deprecation Warnings

When using old package names, you'll see warnings like:
```
warning: Package 'leaflet' is deprecated. Use 'hyperlink-academy-leaflet' instead. See migration guide at: https://github.com/ATProto-NUR/atproto-nur/blob/main/docs/MIGRATION.md
```

These warnings help identify where updates are needed in your configuration.

## Module Migration

### NixOS Module Changes

Module imports have been reorganized to match package organization:

#### Old Module Structure
```nix
{
  imports = [
    inputs.atproto-nur.nixosModules.atproto
    inputs.atproto-nur.nixosModules.bluesky
  ];
  
  services = {
    atproto-leaflet.enable = true;
    bluesky-pds-dash.enable = true;
  };
}
```

#### New Module Structure
```nix
{
  imports = [
    inputs.atproto-nur.nixosModules.hyperlink-academy
    inputs.atproto-nur.nixosModules.witchcraft-systems
  ];
  
  services = {
    hyperlink-academy-leaflet.enable = true;
    witchcraft-systems-pds-dash.enable = true;
  };
}
```

### Module Compatibility Aliases

The ATProto NUR includes a comprehensive compatibility system that automatically handles module name changes. The compatibility system provides:

1. **Automatic Renaming**: Old module names are automatically redirected to new ones
2. **Deprecation Warnings**: Clear warnings help identify what needs to be updated
3. **Seamless Migration**: Existing configurations continue to work during transition

#### Service Name Mappings

**ATProto Services (moved from atproto/ to organizational directories):**
- `services.atproto-leaflet` → `services.hyperlink-academy-leaflet`
- `services.atproto-slices` → `services.slices-network-slices`
- `services.atproto-teal` → `services.teal-fm-teal`
- `services.atproto-parakeet` → `services.parakeet-social-parakeet`
- `services.atproto-streamplace` → `services.stream-place-streamplace`
- `services.atproto-yoten` → `services.yoten-app-yoten`
- `services.atproto-red-dwarf` → `services.red-dwarf-client-red-dwarf`
- `services.atproto-quickdid` → `services.smokesignal-events-quickdid`
- `services.atproto-allegedly` → `services.microcosm-blue-allegedly`
- `services.atproto-atbackup` → `services.atbackup-pages-dev-atbackup`

**Tangled Development Services:**
- `services.atproto-appview` → `services.tangled-dev-appview`
- `services.atproto-knot` → `services.tangled-dev-knot`
- `services.atproto-spindle` → `services.tangled-dev-spindle`

**Bluesky Services (moved from bluesky/ to organizational directories):**
- `services.bluesky.pds-dash` → `services.witchcraft-systems-pds-dash`
- `services.bluesky-pds-gatekeeper` → `services.individual-pds-gatekeeper`
- `services.bluesky-frontpage` → `services.bluesky-social-frontpage`

**Official Bluesky Services (moved from atproto/ to bluesky-social/):**
- `services.atproto-indigo-hepa` → `services.bluesky-social-indigo-hepa`
- `services.atproto-indigo-palomar` → `services.bluesky-social-indigo-palomar`
- `services.atproto-indigo-rainbow` → `services.bluesky-social-indigo-rainbow`
- `services.atproto-indigo-relay` → `services.bluesky-social-indigo-relay`
- `services.atproto-grain-appview` → `services.bluesky-social-grain-appview`
- `services.atproto-grain-darkroom` → `services.bluesky-social-grain-darkroom`
- `services.atproto-grain-labeler` → `services.bluesky-social-grain-labeler`
- `services.atproto-grain-notifications` → `services.bluesky-social-grain-notifications`

**Legacy Service Names (for services that might have used simple names):**
- `services.leaflet` → `services.hyperlink-academy-leaflet`
- `services.slices` → `services.slices-network-slices`
- `services.teal` → `services.teal-fm-teal`
- `services.parakeet` → `services.parakeet-social-parakeet`
- `services.streamplace` → `services.stream-place-streamplace`
- `services.yoten` → `services.yoten-app-yoten`
- `services.red-dwarf` → `services.red-dwarf-client-red-dwarf`
- `services.quickdid` → `services.smokesignal-events-quickdid`
- `services.allegedly` → `services.microcosm-blue-allegedly`
- `services.atbackup` → `services.atbackup-pages-dev-atbackup`
- `services.pds-dash` → `services.witchcraft-systems-pds-dash`
- `services.pds-gatekeeper` → `services.individual-pds-gatekeeper`

#### How the Compatibility System Works

The compatibility system uses NixOS's `mkRenamedOptionModule` function to:

1. **Automatically redirect** old option paths to new ones
2. **Preserve all configuration** - your existing settings continue to work
3. **Show deprecation warnings** to help you identify what needs updating
4. **Maintain type safety** - all option validation continues to work

#### Example Deprecation Warning

When using an old service name, you'll see a warning like:
```
warning: The module option 'services.atproto-leaflet' is deprecated. 
Please use 'services.hyperlink-academy-leaflet' instead. 
See the migration guide for more information.
```

## Organizational Benefits

The new structure provides several benefits:

1. **Clear Ownership**: Easy to identify who maintains each project
2. **Logical Grouping**: Related projects from the same organization are grouped together
3. **Ecosystem Understanding**: Better visibility into the ATProto ecosystem landscape
4. **Contribution Clarity**: Easier to find the right people for contributions and issues

## Getting Help

If you encounter issues during migration:

1. **Check the warnings**: Deprecation warnings provide specific guidance
2. **Review this guide**: Ensure you've followed all migration steps
3. **Check the documentation**: Updated documentation reflects the new structure
4. **Open an issue**: If you find problems, please report them

## Timeline

- **Current**: Both old and new names work (with deprecation warnings for old names)
- **Next major version**: Old names will be removed
- **Recommendation**: Migrate as soon as convenient to avoid future breakage

## Examples

### Complete Migration Example

**Before:**
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    atproto-nur.url = "github:ATProto-NUR/atproto-nur";
  };

  outputs = { self, nixpkgs, atproto-nur }: {
    nixosConfigurations.myserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        atproto-nur.nixosModules.atproto
        {
          services.atproto-leaflet = {
            enable = true;
            port = 3000;
          };
          
          environment.systemPackages = with atproto-nur.packages.x86_64-linux; [
            leaflet
            quickdid
          ];
        }
      ];
    };
  };
}
```

**After:**
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    atproto-nur.url = "github:ATProto-NUR/atproto-nur";
  };

  outputs = { self, nixpkgs, atproto-nur }: {
    nixosConfigurations.myserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        atproto-nur.nixosModules.default  # Includes all organizational modules
        {
          services.hyperlink-academy-leaflet = {
            enable = true;
            port = 3000;
          };
          
          environment.systemPackages = with atproto-nur.packages.x86_64-linux; [
            hyperlink-academy-leaflet
            smokesignal-events-quickdid
          ];
        }
      ];
    };
  };
}
```

## Migration Checklist

Use this checklist to ensure a complete migration:

### Package References
- [ ] Update all package names to use organizational prefixes
- [ ] Replace old package imports in flake.nix
- [ ] Update environment.systemPackages references
- [ ] Update any custom derivations that reference ATProto packages

### Service Configuration
- [ ] Update all service module names to use organizational prefixes
- [ ] Update service configuration options if they changed
- [ ] Test service startup and functionality
- [ ] Update any custom service configurations

### Documentation and Scripts
- [ ] Update README files that reference package names
- [ ] Update deployment scripts and automation
- [ ] Update CI/CD configurations
- [ ] Update documentation examples

### Testing
- [ ] Test that all services start correctly
- [ ] Verify that package functionality is unchanged
- [ ] Test backward compatibility (old names should work with warnings)
- [ ] Validate that all configurations are properly migrated

## Troubleshooting

### Common Issues

**Issue: Package not found**
```
error: attribute 'leaflet' missing
```
**Solution:** Use the new organizational name: `hyperlink-academy-leaflet`

**Issue: Service module not found**
```
error: The option `services.atproto-leaflet' does not exist
```
**Solution:** Use the new service name: `services.hyperlink-academy-leaflet`

**Issue: Deprecation warnings**
```
warning: Package 'leaflet' is deprecated. Use 'hyperlink-academy-leaflet' instead.
```
**Solution:** This is expected during migration. Update to the new name when convenient.

### Getting Help

If you encounter issues:
1. Check this migration guide for the correct new names
2. Look for deprecation warnings that provide guidance
3. Review the updated documentation for examples
4. Open an issue if you find problems not covered here

This migration provides a cleaner, more maintainable structure while preserving backward compatibility during the transition period.