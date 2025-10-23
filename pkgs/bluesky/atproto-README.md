# ATproto Official Implementations

This directory contains official AT Protocol implementations packaged for Nix.

## Indigo (Go Implementation)

The Indigo package provides the official Go implementation of ATproto services and libraries.

### Core Services

- **relay**: Core ATproto relay service for data distribution
- **rainbow**: AppView service for custom data views  
- **palomar**: Search indexer for ATproto content
- **hepa**: Moderation and labeling service

### Core Libraries

The `coreLibraries` package provides access to core ATproto Go libraries:

- **api**: ATproto API definitions and client
- **atproto**: Core ATproto protocol implementation  
- **lex**: Lexicon schema handling
- **xrpc**: XRPC protocol implementation
- **did**: Decentralized Identifier utilities
- **repo**: Repository and MST implementation
- **carstore**: CAR file storage
- **events**: Event streaming and firehose

### Usage

```nix
# In your flake.nix or configuration.nix
{
  # Enable Indigo services
  services.atproto.indigo = {
    relay.enable = true;
    rainbow.enable = true;
    palomar.enable = true;
    hepa.enable = true;
  };
}
```

### Package Access

```nix
# Access individual services
pkgs.nur.repos.atproto.atproto.indigo.relay
pkgs.nur.repos.atproto.atproto.indigo.rainbow
pkgs.nur.repos.atproto.atproto.indigo.palomar
pkgs.nur.repos.atproto.atproto.indigo.hepa

# Access core libraries
pkgs.nur.repos.atproto.atproto.indigo.coreLibraries
```

## Implementation Details

- **Source**: Fetched from `github.com/bluesky-social/indigo`
- **Build System**: Go modules with `buildGoModule`
- **Dependencies**: PostgreSQL, SQLite support
- **Security**: Full systemd hardening applied
- **Platform Support**: Unix systems (Linux, macOS, BSD)

## Testing

Integration tests are available in `tests/indigo-services.nix` which verify:

- Service startup and configuration
- Database integration (PostgreSQL/SQLite)
- Network connectivity and health checks
- Security hardening and user isolation
- Service coordination and dependencies