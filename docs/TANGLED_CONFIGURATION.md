# Tangled Configuration Guide

This guide covers the enhanced configuration options for Tangled git forge with configurable endpoints and deployment profiles.

## Overview

Tangled is a git forge with ATProto integration that consists of three main components:
- **Knot**: Git server with ATProto identity integration
- **AppView**: Web interface for repository browsing and project management
- **Spindle**: CI/CD and event processing service

## Quick Start

### Basic Standalone Deployment

```nix
{
  imports = [ ./profiles/tangled-deployment.nix ];
  
  services.tangled-deployment = {
    profile = "standalone";
    domain = "git.mycompany.com";
    owner = "did:plc:your-admin-did";
    
    enableServices = {
      appview = true;
      knot = true;
      spindle = true;
    };
  };
}
```

### Custom Endpoints Configuration

```nix
{
  imports = [ ./profiles/tangled-deployment.nix ];
  
  services.tangled-deployment = {
    profile = "distributed";
    domain = "forge.example.com";
    owner = "did:plc:your-admin-did";
    
    endpoints = {
      appview = "https://forge.example.com";
      knot = "https://git.example.com";
      jetstream = "wss://events.example.com";
      nixery = "https://registry.example.com";
      atproto = "https://atproto.example.com";
      plc = "https://identity.example.com";
    };
    
    enableServices = {
      appview = true;
      knot = true;
      spindle = true;
    };
  };
}
```

## Deployment Profiles

### Standalone Profile
All services run on a single machine with coordinated configuration.

**Use case**: Small teams, development environments, simple deployments

**Configuration**:
```nix
services.tangled-deployment.profile = "standalone";
```

### Distributed Profile
Services can run on separate machines with custom endpoint configuration.

**Use case**: Large deployments, microservices architecture, load balancing

**Configuration**:
```nix
services.tangled-deployment.profile = "distributed";
```

### Development Profile
Relaxed security settings for local development and testing.

**Use case**: Local development, testing, CI environments

**Configuration**:
```nix
services.tangled-deployment = {
  profile = "development";
  networking = {
    enableTLS = false;
    enableFirewall = false;
  };
};
```

### Production Profile
Enhanced security and monitoring for production deployments.

**Use case**: Production environments, enterprise deployments

**Configuration**:
```nix
services.tangled-deployment = {
  profile = "production";
  networking = {
    enableTLS = true;
    enableFirewall = true;
  };
};
```

### Custom Profile
Complete manual control over all configuration options.

**Use case**: Complex deployments, specific requirements, advanced configurations

**Configuration**:
```nix
services.tangled-deployment = {
  profile = "custom";
  networking = {
    customPorts = {
      appview = 8080;
      knot = 8081;
      spindle = 8082;
    };
  };
};
```

## Endpoint Configuration

### Core Tangled Endpoints

#### AppView Endpoint
Web interface for repository browsing and project management.

```nix
endpoints.appview = "https://forge.example.com";
```

**Environment Variable**: `APPVIEW_ENDPOINT`

#### Knot Endpoint
Git server for repository operations and SSH access.

```nix
endpoints.knot = "https://git.example.com";
```

**Environment Variable**: `KNOT_ENDPOINT`

#### Jetstream Endpoint
Real-time event streaming for live updates and notifications.

```nix
endpoints.jetstream = "wss://events.example.com";
```

**Environment Variable**: `JETSTREAM_ENDPOINT`

#### Nixery Endpoint
Container registry for CI/CD builds and deployments.

```nix
endpoints.nixery = "https://registry.example.com";
```

**Environment Variable**: `NIXERY_ENDPOINT`

### ATProto Integration Endpoints

#### ATProto Network Endpoint
Primary ATProto network for social features and identity.

```nix
endpoints.atproto = "https://atproto.example.com";
```

**Environment Variable**: `ATPROTO_ENDPOINT`

**Default**: `https://bsky.social` (public Bluesky network)

#### PLC Directory Endpoint
Identity resolution and DID management.

```nix
endpoints.plc = "https://identity.example.com";
```

**Environment Variable**: `PLC_ENDPOINT`

**Default**: `https://plc.directory` (public PLC directory)

## Individual Service Configuration

### Manual Service Configuration

For advanced use cases, you can configure services individually:

```nix
{
  services.tangled-dev.knot = {
    enable = true;
    server = {
      hostname = "git.example.com";
      owner = "did:plc:your-admin-did";
      listenAddr = "0.0.0.0:443";
    };
    endpoints = {
      appview = "https://forge.example.com";
      jetstream = "wss://events.example.com";
      nixery = "https://registry.example.com";
      atproto = "https://atproto.example.com";
      plc = "https://identity.example.com";
    };
  };

  services.tangled-dev.appview = {
    enable = true;
    host = "0.0.0.0";
    port = 443;
    endpoints = {
      knot = "https://git.example.com";
      jetstream = "wss://events.example.com";
      nixery = "https://registry.example.com";
      atproto = "https://atproto.example.com";
      plc = "https://identity.example.com";
    };
  };

  services.tangled-dev.spindle = {
    enable = true;
    server = {
      hostname = "ci.example.com";
      owner = "did:plc:your-admin-did";
    };
    endpoints = {
      appview = "https://forge.example.com";
      knot = "https://git.example.com";
      jetstream = "wss://events.example.com";
      nixery = "https://registry.example.com";
      atproto = "https://atproto.example.com";
      plc = "https://identity.example.com";
    };
  };
}
```

## Network Configuration

### TLS/SSL Configuration

Enable TLS for production deployments:

```nix
services.tangled-deployment.networking.enableTLS = true;
```

This automatically configures:
- ACME certificates for all domains
- Nginx reverse proxy with TLS termination
- Secure headers and HSTS

### Firewall Configuration

Control firewall rules:

```nix
services.tangled-deployment.networking.enableFirewall = true;
```

### Custom Ports

Configure custom ports for services:

```nix
services.tangled-deployment.networking.customPorts = {
  appview = 8080;
  knot = 8081;
  spindle = 8082;
};
```

## Security Considerations

### Production Security

For production deployments, ensure:

1. **Use environment files for secrets**:
   ```nix
   services.tangled-dev.appview.environmentFile = "/etc/tangled/secrets.env";
   ```

2. **Configure proper DID ownership**:
   ```nix
   services.tangled-deployment.owner = "did:plc:your-verified-admin-did";
   ```

3. **Enable TLS and firewall**:
   ```nix
   services.tangled-deployment.networking = {
     enableTLS = true;
     enableFirewall = true;
   };
   ```

4. **Use secure secret management**:
   ```nix
   services.tangled-dev.spindle.server.secrets.provider = "openbao";
   ```

### Development Security

For development environments:

```nix
services.tangled-deployment = {
  profile = "development";
  networking = {
    enableTLS = false;
    enableFirewall = false;
  };
};
```

## Deployment Scenarios

### Single-Node Development
```nix
# See examples/tangled-deployment-scenarios.nix - Scenario 1
```

### Small Team Deployment
```nix
# See examples/tangled-deployment-scenarios.nix - Scenario 2
```

### Enterprise Distributed Deployment
```nix
# See examples/tangled-deployment-scenarios.nix - Scenario 3
```

### High-Security Production
```nix
# See examples/tangled-deployment-scenarios.nix - Scenario 4
```

### Multi-Region Deployment
```nix
# See examples/tangled-deployment-scenarios.nix - Scenario 5
```

### Hybrid Cloud Deployment
```nix
# See examples/tangled-deployment-scenarios.nix - Scenario 6
```

## Troubleshooting

### Common Issues

1. **Service won't start**: Check that required options are set
   - `domain` must be configured
   - `owner` DID must be valid
   - Endpoints must be reachable

2. **Authentication failures**: Verify DID configuration
   - Ensure PLC endpoint is accessible
   - Check DID resolution works
   - Verify owner DID is correct

3. **Network connectivity**: Check endpoint configuration
   - Verify all endpoints are reachable
   - Check firewall rules
   - Ensure TLS certificates are valid

### Debugging

Enable debug logging:

```nix
services.tangled-dev.knot.server.dev = true;
services.tangled-dev.spindle.server.dev = true;
```

Check service logs:

```bash
journalctl -u tangled-knot
journalctl -u tangled-appview
journalctl -u tangled-spindle
```

### Validation

Test endpoint connectivity:

```bash
# Test AppView
curl -I https://forge.example.com

# Test Knot git server
git ls-remote https://git.example.com/test-repo

# Test Jetstream WebSocket
wscat -c wss://events.example.com

# Test ATProto endpoint
curl -I https://atproto.example.com/xrpc/_health

# Test PLC directory
curl -I https://identity.example.com/did:plc:test
```

## Migration from Default Endpoints

To migrate from default tangled.org/tangled.sh endpoints:

1. **Update configuration**:
   ```nix
   services.tangled-deployment.endpoints = {
     appview = "https://your-forge.example.com";
     knot = "https://your-git.example.com";
     jetstream = "wss://your-events.example.com";
     nixery = "https://your-registry.example.com";
   };
   ```

2. **Update client configurations**:
   - Update git remotes: `git remote set-url origin https://your-git.example.com/repo`
   - Update CI/CD configurations
   - Update documentation and links

3. **Test connectivity**:
   - Verify all services are reachable
   - Test git operations
   - Verify web interface functionality

## Advanced Configuration

### Load Balancing

For high-availability deployments:

```nix
services.tangled-deployment.endpoints = {
  appview = "https://forge-lb.example.com";
  knot = "https://git-lb.example.com";
  jetstream = "wss://events-lb.example.com";
  nixery = "https://registry-lb.example.com";
};
```

### Multi-Tenant Configuration

For hosting multiple organizations:

```nix
# Organization A
services.tangled-deployment = {
  domain = "org-a.forge.example.com";
  owner = "did:plc:org-a-admin";
  endpoints = {
    appview = "https://org-a.forge.example.com";
    knot = "https://git-a.example.com";
    # ... other endpoints
  };
};
```

### Monitoring Integration

Add monitoring and observability:

```nix
services.prometheus.enable = true;
services.grafana.enable = true;
services.loki.enable = true;

# Custom metrics endpoints
services.tangled-dev.appview.extraEnvironment = {
  METRICS_ENABLED = "true";
  METRICS_PORT = "9090";
};
```

## References

- [ATProto Specification](https://atproto.com)
- [PLC Directory](https://plc.directory)
- [Tangled Development](https://tangled.dev)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)