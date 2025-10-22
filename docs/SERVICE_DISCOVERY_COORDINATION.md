# Service Discovery and Coordination

This document describes the service discovery and coordination system for ATproto services, providing mechanisms for multi-service deployments with automatic dependency management and configuration templating.

## Overview

The service discovery and coordination system consists of several key components:

1. **Service Discovery**: Automatic registration and discovery of services across different backends
2. **Dependency Management**: Automatic resolution of service dependencies with health checking
3. **Configuration Templating**: Dynamic configuration generation with service discovery integration
4. **Deployment Profiles**: Pre-configured deployment scenarios for common ATproto stacks

## Service Discovery

### Supported Backends

The system supports multiple service discovery backends:

- **Consul**: Full-featured service discovery with health checking and KV store
- **etcd**: Distributed key-value store for service registration
- **DNS**: DNS-based service discovery for simple deployments
- **File**: File-based service registry for development and testing
- **Environment**: Environment variable-based discovery for containerized deployments

### Configuration

```nix
services.atproto-stacks = {
  discovery = {
    backend = "consul";
    consulAddress = "127.0.0.1:8500";
  };
};
```

### Service Registration

Services are automatically registered with the discovery backend when they start:

```nix
{
  services = {
    pds = {
      port = 3000;
      tags = [ "atproto" "pds" ];
      healthEndpoint = "/health";
    };
  };
}
```

## Dependency Management

### Dependency Types

The system supports different types of service dependencies:

- **Required**: Service cannot start without this dependency
- **Optional**: Service can start but may have reduced functionality  
- **Soft**: Service prefers this dependency but can work without it
- **Circular**: Mutual dependency that requires special handling

### Health Check Strategies

Multiple health check strategies are supported:

- **HTTP**: Check HTTP endpoint for 200 status
- **TCP**: Check TCP port connectivity
- **Command**: Execute custom command
- **File**: Check file existence
- **systemd**: Check systemd service status

### Configuration

```nix
{
  services = {
    pds = {
      dependencies = [
        {
          name = "database";
          type = "required";
          healthCheck = {
            strategy = "tcp";
            port = 5432;
            timeout = 10;
            retries = 3;
          };
        }
        {
          name = "redis";
          type = "optional";
          healthCheck = {
            strategy = "http";
            endpoint = "/ping";
            port = 6379;
          };
        }
      ];
    };
  };
}
```

## Configuration Templating

### Template System

The configuration templating system allows dynamic generation of service configurations based on discovered services and variables:

```nix
{
  template = ''
    PDS_HOSTNAME=''${hostname}
    PDS_PORT=''${port}
    PDS_DATABASE_URL=''${service.database.url}
    PDS_APPVIEW_URL=''${service.appview.url}
  '';
  
  variables = {
    hostname = { type = "string"; required = true; };
    port = { type = "number"; default = 3000; };
  };
}
```

### Service Variable Resolution

Templates can reference discovered services using the `service.` prefix:

- `''${service.database.url}` - Database service URL
- `''${service.appview.port}` - AppView service port
- `''${service.pds.did}` - PDS service DID

### Output Formats

Templates support multiple output formats:

- **JSON**: Structured configuration files
- **YAML**: Human-readable configuration
- **TOML**: Configuration format popular with Rust applications
- **ENV**: Environment variable format
- **INI**: Traditional configuration file format

## Deployment Profiles

### Pre-defined Profiles

The system includes several pre-defined deployment profiles:

#### Simple PDS
Single-node PDS deployment with basic services:
```nix
services.atproto-stacks.profile = "simple-pds";
```

#### Full Node
Complete ATproto network node with all services:
```nix
services.atproto-stacks.profile = "full-node";
```

#### Development Cluster
Development configuration with relaxed security:
```nix
services.atproto-stacks.profile = "dev-cluster";
```

#### Production Cluster
Production configuration with enhanced security:
```nix
services.atproto-stacks.profile = "prod-cluster";
```

### Custom Profiles

You can create custom deployment profiles:

```nix
{
  services.atproto-stacks = {
    profile = "custom";
    
    services = {
      pds = {
        enable = true;
        port = 3000;
        dependencies = [ "database" ];
      };
      
      database = {
        enable = true;
        type = "postgresql";
        port = 5432;
      };
    };
    
    coordination = {
      strategy = "hub-spoke";
      enableHealthChecks = true;
    };
  };
}
```

## Coordination Strategies

### Hub-Spoke
Central coordinator manages all services:
- Simple to understand and debug
- Single point of failure
- Good for small to medium deployments

### Leader-Follower
Elected leader coordinates the cluster:
- Automatic failover
- More complex setup
- Good for high availability

### Peer-to-Peer
Services coordinate directly with each other:
- No single point of failure
- More network traffic
- Good for large, distributed deployments

### Mesh
Full mesh connectivity between services:
- Maximum redundancy
- High network overhead
- Good for critical deployments

## Usage Examples

### Basic PDS Deployment

```nix
{
  imports = [ ./profiles/atproto-stacks.nix ];
  
  services.atproto-stacks = {
    profile = "simple-pds";
    domain = "my-pds.example.com";
    
    discovery = {
      backend = "file";
    };
    
    coordination = {
      strategy = "hub-spoke";
      enableHealthChecks = true;
    };
  };
}
```

### Multi-Service Development Environment

```nix
{
  imports = [ ./profiles/atproto-stacks.nix ];
  
  services.atproto-stacks = {
    profile = "dev-cluster";
    domain = "dev.local";
    
    discovery = {
      backend = "env";
    };
    
    coordination = {
      strategy = "peer-to-peer";
      enableHealthChecks = false;  # Faster startup for development
    };
  };
}
```

### Production Deployment with Consul

```nix
{
  imports = [ ./profiles/atproto-stacks.nix ];
  
  services.atproto-stacks = {
    profile = "prod-cluster";
    domain = "atproto.example.com";
    
    discovery = {
      backend = "consul";
      consulAddress = "consul.internal:8500";
    };
    
    coordination = {
      strategy = "leader-follower";
      enableHealthChecks = true;
      dependencyTimeout = 60;
    };
  };
  
  # Additional production configuration
  services.consul = {
    enable = true;
    extraConfig = {
      datacenter = "dc1";
      encrypt = "base64-encoded-key";
    };
  };
}
```

## Monitoring and Debugging

### Health Check Monitoring

The system automatically creates monitoring services for all dependencies:

```bash
# Check health of all services
systemctl status atproto-monitor-*

# View health check logs
journalctl -u atproto-monitor-database

# Manual health check
/nix/store/.../health-check-database
```

### Dependency Coordination

View dependency coordination status:

```bash
# Check coordination services
systemctl status atproto-*-deps

# View coordination logs
journalctl -u atproto-pds-deps

# Check startup order
systemctl list-dependencies atproto-pds.service
```

### Service Discovery

Inspect service discovery state:

```bash
# File backend
cat /etc/atproto/discovery/*.json

# Consul backend
consul catalog services
consul health service pds

# Environment backend
env | grep ATPROTO_SERVICE_
```

## Troubleshooting

### Common Issues

1. **Circular Dependencies**
   - Error: "Circular dependency detected"
   - Solution: Review dependency graph and break cycles

2. **Health Check Failures**
   - Error: Service fails to start due to dependency health check
   - Solution: Check dependency service logs and network connectivity

3. **Discovery Backend Unavailable**
   - Error: Cannot register with discovery backend
   - Solution: Ensure discovery backend is running and accessible

4. **Template Variable Missing**
   - Error: "Required variable 'X' is missing"
   - Solution: Provide all required template variables

### Debug Commands

```bash
# Test service discovery
nix-instantiate --eval --expr 'import ./lib/service-discovery.nix'

# Validate dependency graph
nix-instantiate --eval --expr 'import ./lib/dependency-management.nix'

# Check template processing
nix-instantiate --eval --expr 'import ./lib/config-templating.nix'

# Run coordination tests
nix build .#tests.service-discovery-coordination
```

## API Reference

### Service Discovery Functions

- `mkServiceDiscovery`: Create service discovery configuration
- `mkServiceCoordination`: Create service coordination configuration
- `mkDeploymentProfile`: Create deployment profile
- `generateDiscoveryConfig`: Generate discovery backend configuration

### Dependency Management Functions

- `mkDependency`: Create dependency specification
- `mkDependencyGraph`: Create dependency graph from services
- `mkDependencyManagement`: Create dependency management configuration
- `mkHealthCheck`: Create health check configuration

### Configuration Templating Functions

- `mkConfigTemplate`: Create configuration template
- `mkConfigurationTemplating`: Create templating system
- `processTemplateWithDiscovery`: Process template with service discovery
- `generateStackConfigs`: Generate configuration files for service stack

## Integration with Existing Services

The coordination system integrates seamlessly with existing ATproto service modules. Services can opt-in to coordination features by adding dependency specifications to their configuration.

See the individual service documentation for specific coordination options and examples.