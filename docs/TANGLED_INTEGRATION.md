# Tangled Git Forge Integration

This document describes the integration of Tangled, a git forge with ATProto integration, including its components and deployment patterns.

## Overview

Tangled is a distributed git forge that integrates with the AT Protocol to provide decentralized code hosting and collaboration. The ATProto NUR includes comprehensive support for all Tangled components with production-ready NixOS modules.

## Tangled Components

### Knot - Git Server

**Package**: `atproto-knot`  
**Module**: `services.atproto-tangled-knot`

The core git hosting server that provides SSH access, repository management, and ATProto integration.

**Key Features:**
- Git repository hosting with SSH access
- ATProto identity integration for authentication
- SSH key management through ATProto
- Repository access control and permissions
- Integration with AppView for web interface
- Configurable git operations and hooks

**Configuration Example:**
```nix
services.atproto-tangled-knot = {
  enable = true;
  
  server = {
    hostname = "git.example.com";
    owner = "did:plc:your-owner-did";
    listenAddr = "0.0.0.0:5555";
    internalListenAddr = "127.0.0.1:5444";
  };
  
  appviewEndpoint = "https://tangled.example.com";
  
  repo = {
    mainBranch = "main";
  };
  
  motd = "Welcome to Tangled Git Forge\n";
  
  openFirewall = true;
};
```

**SSH Integration:**
Knot integrates with OpenSSH to provide ATProto-based authentication:
- SSH keys are fetched from ATProto identity records
- Repository access is controlled through ATProto permissions
- Git operations are logged and can be published to ATProto

### AppView - Web Interface

**Package**: `atproto-appview`  
**Module**: `services.atproto-tangled-appview`

The web interface for browsing repositories, managing projects, and interacting with the git forge.

**Key Features:**
- Web-based repository browser
- Project management interface
- Issue tracking and collaboration tools
- ATProto identity integration
- Responsive design for all devices
- Integration with Knot git server

**Configuration Example:**
```nix
services.atproto-tangled-appview = {
  enable = true;
  
  port = 3000;
  host = "127.0.0.1";
  
  cookieSecret = "your-secure-cookie-secret";
  
  environmentFile = "/run/secrets/tangled-appview.env";
  
  extraEnvironment = {
    TANGLED_KNOT_URL = "http://localhost:5444";
    TANGLED_THEME = "default";
  };
  
  openFirewall = false; # Behind reverse proxy
};
```

### Spindle - Event Processing

**Package**: `atproto-spindle`  
**Module**: `services.atproto-tangled-spindle`

The event processing component that handles CI/CD, notifications, and ATProto publishing.

**Key Features:**
- Git event processing and webhooks
- CI/CD pipeline execution
- ATProto event publishing
- Notification system
- Integration with external services
- Configurable processing rules

**Configuration Example:**
```nix
services.atproto-tangled-spindle = {
  enable = true;
  
  server = {
    port = 8080;
    hostname = "spindle.example.com";
  };
  
  processing = {
    workers = 4;
    queueSize = 1000;
  };
  
  atproto = {
    publishEvents = true;
    did = "did:plc:your-spindle-did";
    signingKeyFile = "/run/secrets/atproto-signing-key";
  };
  
  ci = {
    enable = true;
    dockerSupport = true;
    nixSupport = true;
  };
};
```

## Development Tools

### JWKS Generator

**Package**: `atproto-genjwks`

Utility for generating JSON Web Key Sets (JWKS) for ATProto authentication.

**Features:**
- Generate JWKS for ATProto services
- Key rotation and management
- Integration with Tangled authentication
- Command-line interface

### Lexicon Generator

**Package**: `atproto-lexgen`

Tool for generating ATProto lexicon definitions and code bindings.

**Features:**
- Lexicon schema generation
- Multi-language code generation
- Validation and testing tools
- Integration with Tangled development workflow

## Deployment Patterns

### Complete Tangled Forge

Deploy all components together for a full git forge:

```nix
{
  services = {
    # Core git server
    atproto-tangled-knot = {
      enable = true;
      server = {
        hostname = "git.example.com";
        owner = "did:plc:your-owner-did";
      };
      openFirewall = true;
    };
    
    # Web interface
    atproto-tangled-appview = {
      enable = true;
      port = 3000;
    };
    
    # Event processing
    atproto-tangled-spindle = {
      enable = true;
      server.port = 8080;
      ci.enable = true;
    };
    
    # Reverse proxy
    nginx = {
      enable = true;
      virtualHosts = {
        "tangled.example.com" = {
          locations = {
            "/".proxyPass = "http://localhost:3000";
            "/api/events/".proxyPass = "http://localhost:8080";
          };
        };
      };
    };
  };
  
  # Required system services
  services.openssh.enable = true;
  services.postgresql.enable = true;
}
```

### Development Setup

Minimal setup for development and testing:

```nix
{
  services = {
    atproto-tangled-knot = {
      enable = true;
      server = {
        hostname = "localhost";
        owner = "did:plc:dev-owner";
        dev = true; # Disable signature verification
      };
    };
    
    atproto-tangled-appview = {
      enable = true;
      port = 3000;
      extraEnvironment = {
        NODE_ENV = "development";
      };
    };
  };
}
```

### Production Deployment

Production-ready configuration with security hardening:

```nix
{
  services = {
    atproto-tangled-knot = {
      enable = true;
      server = {
        hostname = "git.example.com";
        owner = "did:plc:production-owner";
        dbPath = "/var/lib/tangled-knot/production.db";
      };
      motdFile = "/etc/tangled/motd";
    };
    
    atproto-tangled-appview = {
      enable = true;
      port = 3000;
      environmentFile = "/run/secrets/tangled-appview.env";
    };
    
    # SSL termination
    nginx = {
      enable = true;
      virtualHosts."git.example.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://localhost:3000";
      };
    };
  };
  
  # Security hardening
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";
  };
}
```

## ATProto Integration

### Identity Management

Tangled integrates with ATProto for identity and authentication:

- **User Authentication**: Users authenticate using their ATProto DIDs
- **SSH Key Management**: SSH keys are stored in ATProto identity records
- **Repository Permissions**: Access control based on ATProto relationships
- **Event Publishing**: Git events can be published to ATProto feeds

### Repository Metadata

Repositories can include ATProto metadata:

```json
{
  "atproto": {
    "did": "did:plc:repo-owner",
    "collection": "dev.tangled.repo",
    "visibility": "public",
    "topics": ["nix", "atproto", "git"],
    "license": "MIT"
  }
}
```

### Event Publishing

Git events are published to ATProto:

- **Push Events**: New commits and branches
- **Issue Events**: Issue creation and updates
- **Pull Request Events**: PR creation, review, and merge
- **Release Events**: Tag creation and releases

## Security Considerations

### SSH Security

- SSH keys are validated through ATProto identity records
- Repository access is controlled through ATProto permissions
- Git operations are logged and auditable
- SSH configuration is managed declaratively

### Web Security

- All web interfaces use HTTPS in production
- Content Security Policy headers are enforced
- Session management uses secure cookies
- Input validation and sanitization

### ATProto Security

- All ATProto operations use proper authentication
- Signing keys are stored securely
- Event publishing includes proper signatures
- Identity verification is enforced

## Monitoring and Observability

### Logging

All Tangled components provide structured logging:

```nix
services.atproto-tangled-knot.settings.logLevel = "info";
services.atproto-tangled-appview.extraEnvironment.LOG_LEVEL = "info";
services.atproto-tangled-spindle.settings.logLevel = "info";
```

### Metrics

Services expose metrics for monitoring:

- Git operation metrics (pushes, clones, etc.)
- Web interface usage metrics
- Event processing metrics
- ATProto integration metrics

### Health Checks

Health check endpoints for service monitoring:

- Knot: Internal API health endpoint
- AppView: Web application health check
- Spindle: Event processing status

## Development Workflow

### Local Development

1. **Setup Development Environment**:
   ```bash
   nix develop
   ```

2. **Configure Services**:
   ```nix
   services.atproto-tangled-knot.server.dev = true;
   ```

3. **Start Services**:
   ```bash
   nixos-rebuild switch
   ```

4. **Test Integration**:
   ```bash
   git clone ssh://git@localhost/test-repo
   ```

### Contributing

To contribute to Tangled integration:

1. **Package Updates**: Follow ATProto packaging guidelines
2. **Module Improvements**: Enhance NixOS module configuration
3. **Documentation**: Update integration guides and examples
4. **Testing**: Add comprehensive integration tests

## Troubleshooting

### Common Issues

1. **SSH Authentication Failures**:
   - Verify ATProto identity records contain SSH keys
   - Check SSH key format and encoding
   - Validate DID resolution

2. **Web Interface Errors**:
   - Check AppView service logs
   - Verify database connectivity
   - Validate environment configuration

3. **Event Processing Issues**:
   - Monitor Spindle service status
   - Check event queue status
   - Verify ATProto publishing configuration

### Diagnostic Commands

```bash
# Check service status
systemctl status atproto-tangled-knot
systemctl status atproto-tangled-appview
systemctl status atproto-tangled-spindle

# View logs
journalctl -u atproto-tangled-knot -f
journalctl -u atproto-tangled-appview -f

# Test SSH connectivity
ssh -T git@your-hostname

# Test web interface
curl -f http://localhost:3000/health
```

## Future Development

### Planned Features

- **Enhanced CI/CD**: More pipeline types and integrations
- **Advanced Permissions**: Fine-grained access control
- **Federation**: Multi-instance Tangled networks
- **Mobile Apps**: Native mobile applications

### Integration Opportunities

- **ATProto Feeds**: Repository activity feeds
- **Social Features**: Developer collaboration tools
- **Decentralized Issues**: ATProto-based issue tracking
- **Cross-Platform**: Integration with other git forges

## Resources

- [Tangled Documentation](https://tangled.org/docs)
- [ATProto Specification](https://atproto.com/)
- [Git Integration Patterns](docs/GIT_INTEGRATION.md)
- [Development Setup Guide](docs/DEVELOPMENT.md)