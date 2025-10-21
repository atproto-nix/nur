# ATProto Core Libraries

This package collection provides core ATProto libraries and utilities for building ATProto applications.

## Available Packages

### TypeScript/Node.js Libraries (Official)
- `atproto-lexicon` - Schema definition and validation
- `atproto-api` - Main ATProto client API  
- `atproto-xrpc` - XRPC protocol implementation
- `atproto-identity` - Identity resolution and management
- `atproto-repo` - Repository management
- `atproto-syntax` - Syntax parsing and validation

### Rust Libraries (Community)
- `rsky-lexicon` - Rust lexicon schema handling
- `rsky-crypto` - Cryptographic utilities
- `rsky-common` - Common utilities and types
- `rsky-syntax` - Syntax parsing
- `rsky-identity` - Identity and DID management
- `rsky-repo` - Repository management
- `rsky-firehose` - Event streaming
- `microcosm-links` - URI parsing and validation

### Client Libraries
- `frontpage-atproto-client` - TypeScript client from Frontpage
- `atproto-browser` - Browser-based ATProto client
- `frontpage-oauth` - OAuth implementation for ATProto
- `indigo-atproto` - Go client libraries from Indigo

### API Definitions and Code Generation
- `atproto-lexicons` - Lexicon schema definitions
- `atproto-codegen` - Cross-language code generation
- `atproto-lex-cli` - Lexicon CLI tools

### Supporting Libraries
- `multiformats` - Multiformat data structures

### Development Tools
- `atproto-lex-cli` - Code generation from lexicon schemas
- `atproto-codegen` - Cross-language binding generator

## Usage

```nix
# In your flake.nix or configuration
{
  inputs.atproto-nur.url = "github:owner/atproto-nur";
  
  outputs = { nixpkgs, atproto-nur, ... }: {
    packages = {
      # Use individual libraries
      my-app = pkgs.buildNpmPackage {
        buildInputs = [ atproto-nur.packages.atproto-api ];
      };
    };
  };
}
```

## Package Metadata

All packages include ATProto-specific metadata:
- `type`: "library", "application", or "tool"
- `services`: List of ATProto services provided
- `protocols`: List of supported protocols

This metadata enables automated tooling and dependency management.