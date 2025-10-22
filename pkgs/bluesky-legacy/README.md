# Official Bluesky Packages

This package collection provides official Bluesky applications and services from the frontpage repository.

## Available Packages

### Web Applications
- `frontpage` - Official Bluesky web application (Next.js)

### ATProto Services  
- `drainpipe` - ATProto firehose consumer and indexer
- `drainpipe-cli` - CLI tools for drainpipe
- `drainpipe-store` - Storage layer for drainpipe

### Client Libraries
- `oauth` - OAuth implementation for Bluesky applications
- `browser-client` - Browser-based ATProto client

## Usage

### Installing Packages

```nix
# In your flake.nix or configuration
{
  inputs.atproto-nur.url = "github:owner/atproto-nur";
  
  outputs = { nixpkgs, atproto-nur, ... }: {
    packages = {
      # Install individual packages
      my-frontpage = atproto-nur.packages.bluesky-frontpage;
      my-drainpipe = atproto-nur.packages.bluesky-drainpipe;
    };
  };
}
```

### Using NixOS Modules

```nix
# In your NixOS configuration
{
  imports = [ atproto-nur.nixosModules.bluesky ];
  
  services.bluesky = {
    frontpage = {
      enable = true;
      settings = {
        port = 3000;
        hostname = "example.com";
        oauth = {
          clientId = "your-client-id";
          clientSecret = "your-client-secret";
          redirectUri = "https://example.com/auth/callback";
        };
        nextAuth = {
          secret = "your-nextauth-secret";
        };
      };
    };
    
    drainpipe = {
      enable = true;
      settings = {
        firehoseUrl = "wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos";
        logLevel = "info";
      };
    };
  };
}
```

## Configuration

### Frontpage Configuration

The frontpage service supports:
- **Database backends**: SQLite, LibSQL (Turso)
- **OAuth integration**: Full OAuth 2.0 support
- **NextAuth.js**: Session management and authentication
- **Environment files**: Secure credential management

### Drainpipe Configuration

The drainpipe service supports:
- **Multiple storage backends**: Sled, in-memory
- **Configurable processing**: Batch sizes, worker threads
- **Metrics**: Prometheus metrics endpoint
- **Firehose sources**: Any ATProto firehose endpoint

## Database Setup

### SQLite (Default)
```nix
services.bluesky.frontpage.settings.database = {
  type = "sqlite";
  url = "file:/var/lib/bluesky-frontpage/frontpage.db";
};
```

### LibSQL/Turso
```nix
services.bluesky.frontpage.settings.database = {
  type = "libsql";
  url = "libsql://your-database.turso.io";
  authToken = "your-auth-token";
};
```

## Security

All services include comprehensive security hardening:
- Dedicated system users and groups
- systemd security restrictions
- File system isolation
- Network access controls
- Environment file support for secrets

## Development

For development deployments:
```nix
services.bluesky.frontpage.settings.nodeEnv = "development";
services.bluesky.drainpipe.settings.logLevel = "debug";
```