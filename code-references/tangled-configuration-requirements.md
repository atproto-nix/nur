# Tangled Configuration Requirements

## Hardcoded Values That Need Configuration

Based on analysis of the Tangled codebase, these values are currently hardcoded and need to be made configurable for our ATProto Nix ecosystem:

### 1. Service Endpoints

**Appview Endpoint** (knot module):
- Current default: `"https://tangled.org"`
- Used in: `APPVIEW_ENDPOINT` environment variable
- Purpose: Where knot reports to for service registration

**Jetstream Endpoint** (spindle module):
- Current default: `"wss://jetstream1.us-west.bsky.network/subscribe"`
- Used in: `SPINDLE_SERVER_JETSTREAM` environment variable  
- Purpose: ATProto event stream for CI/CD triggers

**Nixery Instance** (spindle module):
- Current default: `"nixery.tangled.sh"`
- Used in: `SPINDLE_PIPELINES_NIXERY` environment variable
- Purpose: Container image registry for CI/CD pipelines

### 2. Go Module Imports

All Go source files import `tangled.org/core/*` packages:
- `tangled.org/core/api/tangled`
- `tangled.org/core/idresolver`
- `tangled.org/core/rbac`
- `tangled.org/core/log`
- `tangled.org/core/spindle/*`
- And many others...

### 3. Documentation References

**Spindle MOTD**:
- File: `spindle/motd`
- Contains: `https://tangled.sh/@tangled.sh/core/tree/master/docs/spindle`
- Purpose: Help text shown to users

## Required Configuration Options

When packaging Tangled for our ecosystem, we need to provide:

### Package-Level Configuration
```nix
{
  # Go module path override
  modulePath = "example.com/my-forge/core";
  
  # Service endpoints
  defaultAppviewEndpoint = "https://my-forge.example.com";
  defaultJetstreamEndpoint = "wss://jetstream1.us-west.bsky.network/subscribe";
  defaultNixeryInstance = "nixery.example.com";
  
  # Documentation URLs
  documentationBaseUrl = "https://my-forge.example.com/docs";
}
```

### Module-Level Configuration
```nix
services.tangled = {
  knot = {
    appviewEndpoint = "https://my-forge.example.com";
    # ... other knot options
  };
  
  spindle = {
    jetstreamEndpoint = "wss://my-jetstream.example.com/subscribe";
    nixeryInstance = "my-nixery.example.com";
    # ... other spindle options
  };
};
```

## Implementation Strategy

1. **Fork/Patch Approach**: Create a configurable fork of Tangled that accepts these values as build-time parameters
2. **Template Generation**: Use Nix to template the Go source files with configurable values
3. **Environment Override**: Ensure all hardcoded values can be overridden via environment variables
4. **Documentation Updates**: Generate documentation with correct URLs for the deployment

## Priority Configuration Values

**High Priority** (breaks functionality if wrong):
- `appviewEndpoint` - knot won't register properly
- `jetstreamEndpoint` - spindle won't receive events
- `modulePath` - Go imports will fail

**Medium Priority** (affects user experience):
- `nixeryInstance` - CI/CD containers may not work
- `documentationBaseUrl` - help links will be broken

**Low Priority** (cosmetic):
- MOTD messages and branding text