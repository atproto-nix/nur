# ATproto Packaging Templates and Guidelines

This document provides comprehensive templates and guidelines for packaging ATproto applications in the NUR ecosystem.

## Table of Contents

1. [Packaging Philosophy](#packaging-philosophy)
2. [Language-Specific Templates](#language-specific-templates)
3. [Service Module Templates](#service-module-templates)
4. [Testing Templates](#testing-templates)
5. [Documentation Templates](#documentation-templates)
6. [Contribution Workflow](#contribution-workflow)

## Packaging Philosophy

### Core Principles

1. **Organizational Clarity**: Packages are organized by their actual organizational ownership
2. **Security First**: All packages include comprehensive security hardening
3. **Reproducible Builds**: Exact version pinning and content addressing
4. **Minimal Dependencies**: Only include necessary dependencies
5. **Comprehensive Testing**: Every package includes appropriate tests

### Naming Conventions

```
{organization}-{project}-{component}

Examples:
- smokesignal-events-quickdid
- hyperlink-academy-leaflet  
- microcosm-blue-allegedly
- bluesky-social-frontpage
```

### Directory Structure

```
pkgs/{organization}/
├── default.nix          # Package collection
├── {project}/
│   ├── default.nix      # Main package
│   ├── {component}.nix  # Individual components
│   └── README.md        # Package documentation

modules/{organization}/
├── default.nix          # Module collection
├── {project}.nix        # Service module
└── README.md            # Module documentation
```

## Language-Specific Templates

### Rust Package Template

```nix
# pkgs/{organization}/{project}/default.nix
{ lib
, stdenv
, fetchFromGitHub
, craneLib
, pkg-config
, openssl
, zstd
, lz4
, sqlite
, postgresql
, rocksdb
, llvmPackages
}:

let
  # Common environment for all Rust ATproto packages
  commonEnv = {
    OPENSSL_NO_VENDOR = "1";
    ZSTD_SYS_USE_PKG_CONFIG = "1";
    ROCKSDB_INCLUDE_DIR = "${rocksdb}/include";
    ROCKSDB_LIB_DIR = "${rocksdb}/lib";
    LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
  };

  # Source fetching
  src = fetchFromGitHub {
    owner = "{organization}";
    repo = "{project}";
    rev = "{commit-hash}";
    sha256 = "{sha256-hash}";
  };

  # Shared dependency artifacts
  cargoArtifacts = craneLib.buildDepsOnly {
    inherit src;
    pname = "{project}-deps";
    version = "0.0.0";
    
    env = commonEnv;
    
    nativeBuildInputs = [
      pkg-config
    ];
    
    buildInputs = [
      openssl
      zstd
      lz4
      sqlite
      postgresql
      rocksdb
    ];
  };

  # Package metadata
  packageMeta = {
    description = "Brief description of the ATproto service";
    longDescription = ''
      Detailed description explaining:
      - What ATproto services this provides
      - Key features and capabilities
      - Integration points with other services
    '';
    homepage = "https://github.com/{organization}/{project}";
    license = lib.licenses.mit;  # Adjust as needed
    maintainers = with lib.maintainers; [ atproto-team ];
    platforms = lib.platforms.linux;
    
    # ATproto-specific metadata
    atproto = {
      category = "infrastructure";  # or "application", "utility", "library"
      services = [ "pds" "relay" "feedgen" ];  # ATproto services provided
      protocols = [ "xrpc" "jetstream" "firehose" ];  # Protocols supported
      dependencies = [ "postgresql" "redis" ];  # External dependencies
      tier = 1;  # 1=foundation, 2=ecosystem, 3=specialized
    };
  };

in

# Single service package
craneLib.buildPackage {
  pname = "{organization}-{project}";
  version = "1.0.0";
  
  inherit src cargoArtifacts;
  
  env = commonEnv;
  
  nativeBuildInputs = [
    pkg-config
  ];
  
  buildInputs = [
    openssl
    zstd
    lz4
    sqlite
    postgresql
    rocksdb
  ];
  
  # Build configuration
  cargoExtraArgs = "--bin {service-name}";
  
  # Install additional files
  postInstall = ''
    # Install configuration templates
    mkdir -p $out/share/{project}/config
    cp -r config/* $out/share/{project}/config/
    
    # Install documentation
    mkdir -p $out/share/doc/{project}
    cp README.md $out/share/doc/{project}/
    
    # Install systemd service template
    mkdir -p $out/lib/systemd/system
    substitute systemd/{service-name}.service $out/lib/systemd/system/{organization}-{project}.service \
      --replace "@out@" "$out"
  '';
  
  meta = packageMeta;
}

# Multi-service workspace package
# Use this pattern for Rust workspaces with multiple services
/*
let
  # Workspace members
  workspaceMembers = [
    "service-a"
    "service-b" 
    "service-c"
  ];
  
  # Build individual services
  buildMember = member: craneLib.buildPackage {
    inherit src cargoArtifacts;
    pname = "{organization}-{project}-${member}";
    version = "1.0.0";
    
    env = commonEnv;
    
    cargoExtraArgs = "--package ${member}";
    
    # Handle special naming cases
    installPhase = ''
      runHook preInstall
      
      # Install binary with consistent naming
      mkdir -p $out/bin
      cp target/release/${member} $out/bin/${
        if member == "ufos/fuzz" then "ufos-fuzz" else member
      }
      
      runHook postInstall
    '';
    
    meta = packageMeta // {
      description = "ATproto ${member} service";
    };
  };

in
lib.genAttrs workspaceMembers buildMember
*/
```

### Node.js/TypeScript Package Template

```nix
# pkgs/{organization}/{project}/default.nix
{ lib
, stdenv
, fetchFromGitHub
, buildNpmPackage
, nodejs_20
, python3
, pkg-config
, vips
, postgresql
}:

buildNpmPackage rec {
  pname = "{organization}-{project}";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "{organization}";
    repo = "{project}";
    rev = "{commit-hash}";
    sha256 = "{sha256-hash}";
  };
  
  # Use package-lock.json or yarn.lock
  npmDepsHash = "{npm-deps-hash}";
  
  # For pnpm workspaces
  # pnpmDepsHash = "{pnpm-deps-hash}";
  
  nativeBuildInputs = [
    nodejs_20
    python3
    pkg-config
  ];
  
  buildInputs = [
    vips
    postgresql
  ];
  
  # Environment variables
  env = {
    PYTHON = "${python3}/bin/python";
    # Disable telemetry
    NEXT_TELEMETRY_DISABLED = "1";
    DO_NOT_TRACK = "1";
  };
  
  # Build configuration
  npmBuildScript = "build";
  
  # For monorepos, specify workspace
  # npmWorkspace = "packages/{workspace-name}";
  
  # Skip tests during build (run separately)
  npmFlags = [ "--ignore-scripts" ];
  
  # Install phase
  postInstall = ''
    # Install additional assets
    mkdir -p $out/share/{project}
    cp -r public $out/share/{project}/ || true
    cp -r assets $out/share/{project}/ || true
    
    # Install configuration templates
    mkdir -p $out/share/{project}/config
    cp config.example.json $out/share/{project}/config/ || true
    
    # Create wrapper script
    mkdir -p $out/bin
    cat > $out/bin/{project} << EOF
#!/bin/bash
cd $out/lib/node_modules/{project}
exec ${nodejs_20}/bin/node dist/index.js "\$@"
EOF
    chmod +x $out/bin/{project}
  '';
  
  meta = {
    description = "ATproto {project} application";
    longDescription = ''
      Detailed description of the Node.js/TypeScript application.
    '';
    homepage = "https://github.com/{organization}/{project}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ atproto-team ];
    platforms = lib.platforms.linux;
    
    atproto = {
      category = "application";
      services = [ "appview" "feedgen" ];
      protocols = [ "xrpc" "websocket" ];
      dependencies = [ "postgresql" "redis" ];
      tier = 2;
    };
  };
}
```

### Go Package Template

```nix
# pkgs/{organization}/{project}/default.nix
{ lib
, buildGoModule
, fetchFromGitHub
, pkg-config
, sqlite
, postgresql
}:

buildGoModule rec {
  pname = "{organization}-{project}";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "{organization}";
    repo = "{project}";
    rev = "{commit-hash}";
    sha256 = "{sha256-hash}";
  };
  
  vendorHash = "{vendor-hash}";
  
  nativeBuildInputs = [
    pkg-config
  ];
  
  buildInputs = [
    sqlite
    postgresql
  ];
  
  # Build configuration
  env = {
    CGO_ENABLED = "1";
  };
  
  # Build specific subpackages
  subPackages = [ "cmd/{service-name}" ];
  
  # Or build multiple services
  # subPackages = [ "cmd/service-a" "cmd/service-b" ];
  
  # Install additional files
  postInstall = ''
    # Install configuration
    mkdir -p $out/share/{project}/config
    cp -r config/* $out/share/{project}/config/
    
    # Install migrations
    mkdir -p $out/share/{project}/migrations
    cp -r migrations/* $out/share/{project}/migrations/
  '';
  
  # Tests
  checkPhase = ''
    runHook preCheck
    go test ./...
    runHook postCheck
  '';
  
  meta = {
    description = "ATproto {project} service";
    longDescription = ''
      Go-based ATproto service description.
    '';
    homepage = "https://github.com/{organization}/{project}";
    license = lib.licenses.apache2;
    maintainers = with lib.maintainers; [ atproto-team ];
    platforms = lib.platforms.linux;
    
    atproto = {
      category = "infrastructure";
      services = [ "relay" "pds" ];
      protocols = [ "xrpc" "http" ];
      dependencies = [ "postgresql" ];
      tier = 1;
    };
  };
}
```

### Deno Package Template

```nix
# pkgs/{organization}/{project}/default.nix
{ lib
, stdenv
, fetchFromGitHub
, deno
, nodejs_20
}:

stdenv.mkDerivation rec {
  pname = "{organization}-{project}";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "{organization}";
    repo = "{project}";
    rev = "{commit-hash}";
    sha256 = "{sha256-hash}";
  };
  
  nativeBuildInputs = [
    deno
    nodejs_20  # For npm dependencies if needed
  ];
  
  # Deno configuration
  configurePhase = ''
    export DENO_DIR=$TMPDIR/deno
    export DENO_INSTALL_ROOT=$out
  '';
  
  buildPhase = ''
    # Cache dependencies
    deno cache --reload main.ts
    
    # Build if needed
    deno task build || true
  '';
  
  installPhase = ''
    mkdir -p $out/bin $out/share/{project}
    
    # Copy source files
    cp -r . $out/share/{project}/
    
    # Create wrapper script
    cat > $out/bin/{project} << EOF
#!/bin/bash
cd $out/share/{project}
exec ${deno}/bin/deno run --allow-all main.ts "\$@"
EOF
    chmod +x $out/bin/{project}
  '';
  
  meta = {
    description = "ATproto {project} Deno application";
    longDescription = ''
      Deno-based ATproto application description.
    '';
    homepage = "https://github.com/{organization}/{project}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ atproto-team ];
    platforms = lib.platforms.linux;
    
    atproto = {
      category = "application";
      services = [ "appview" ];
      protocols = [ "xrpc" "websocket" ];
      dependencies = [ "postgresql" ];
      tier = 2;
    };
  };
}
```

## Service Module Templates

### Basic Service Module Template

```nix
# modules/{organization}/{project}.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.{organization}-{project};
  
  # Package reference
  package = pkgs.{organization}-{project};
  
  # Configuration file generation
  configFile = pkgs.writeText "{project}-config.json" (builtins.toJSON {
    inherit (cfg.settings) hostname port;
    database = cfg.settings.database;
    # Add other configuration options
  });
  
  # Service user and group
  user = "{project}";
  group = "{project}";
  
in

{
  options.services.{organization}-{project} = {
    enable = mkEnableOption "ATproto {project} service";
    
    package = mkOption {
      type = types.package;
      default = package;
      defaultText = literalExpression "pkgs.{organization}-{project}";
      description = "Package to use for {project}";
    };
    
    settings = {
      hostname = mkOption {
        type = types.str;
        default = "localhost";
        description = "Hostname for the service";
      };
      
      port = mkOption {
        type = types.port;
        default = 3000;
        description = "Port for the service";
      };
      
      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/{project}";
        description = "Data directory for {project}";
      };
      
      database = mkOption {
        type = types.submodule {
          options = {
            type = mkOption {
              type = types.enum [ "postgresql" "sqlite" ];
              default = "postgresql";
              description = "Database type";
            };
            
            url = mkOption {
              type = types.str;
              description = "Database connection URL";
            };
            
            maxConnections = mkOption {
              type = types.int;
              default = 20;
              description = "Maximum database connections";
            };
          };
        };
        description = "Database configuration";
      };
      
      extraConfig = mkOption {
        type = types.attrs;
        default = {};
        description = "Additional configuration options";
      };
    };
    
    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for this service";
    };
    
    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Environment file containing secrets";
    };
  };
  
  config = mkIf cfg.enable {
    # User and group management
    users.users.${user} = {
      isSystemUser = true;
      group = group;
      home = cfg.settings.dataDir;
      createHome = true;
      description = "ATproto {project} service user";
    };
    
    users.groups.${group} = {};
    
    # Directory management
    systemd.tmpfiles.rules = [
      "d '${cfg.settings.dataDir}' 0755 ${user} ${group} - -"
      "d '${cfg.settings.dataDir}/logs' 0755 ${user} ${group} - -"
      "d '${cfg.settings.dataDir}/cache' 0755 ${user} ${group} - -"
    ];
    
    # Service configuration
    systemd.services.{organization}-{project} = {
      description = "ATproto {project} service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      
      # Service dependencies
      wants = mkIf (cfg.settings.database.type == "postgresql") [ "postgresql.service" ];
      after = mkIf (cfg.settings.database.type == "postgresql") [ "postgresql.service" ];
      
      serviceConfig = {
        Type = "simple";
        User = user;
        Group = group;
        
        # Working directory
        WorkingDirectory = cfg.settings.dataDir;
        
        # Command
        ExecStart = "${cfg.package}/bin/{project} --config ${configFile}";
        
        # Restart configuration
        Restart = "always";
        RestartSec = "10s";
        
        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
        
        # File system access
        ReadWritePaths = [ cfg.settings.dataDir ];
        ReadOnlyPaths = [ "/nix/store" ];
        
        # Network access
        IPAddressDeny = mkIf (!cfg.openFirewall) [ "any" ];
        IPAddressAllow = mkIf (!cfg.openFirewall) [ "localhost" "127.0.0.0/8" "::1" ];
        
        # Capabilities
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        
        # Environment
        Environment = [
          "HOME=${cfg.settings.dataDir}"
          "DATA_DIR=${cfg.settings.dataDir}"
        ];
        
        # Load environment file if specified
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;
      };
      
      # Health check
      postStart = ''
        timeout=60
        while [ $timeout -gt 0 ]; do
          if ${pkgs.curl}/bin/curl -f http://${cfg.settings.hostname}:${toString cfg.settings.port}/health 2>/dev/null; then
            break
          fi
          sleep 1
          timeout=$((timeout - 1))
        done
        
        if [ $timeout -eq 0 ]; then
          echo "Service failed to start within 60 seconds"
          exit 1
        fi
      '';
    };
    
    # Firewall configuration
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.settings.port ];
    };
    
    # Assertions
    assertions = [
      {
        assertion = cfg.settings.database.url != "";
        message = "Database URL must be specified";
      }
      {
        assertion = cfg.settings.hostname != "";
        message = "Hostname must be specified";
      }
    ];
  };
}
```

### Advanced Service Module Template

```nix
# modules/{organization}/{project}.nix - Advanced version with clustering support
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.{organization}-{project};
  
  # Import service discovery utilities
  serviceDiscovery = import ../../lib/service-discovery.nix { inherit lib pkgs; };
  
  # Configuration generation with service discovery
  configFile = pkgs.writeText "{project}-config.json" (builtins.toJSON (
    cfg.settings // {
      # Inject service discovery endpoints
      services = serviceDiscovery.generateServiceConfig cfg.discovery;
    }
  ));
  
in

{
  options.services.{organization}-{project} = {
    enable = mkEnableOption "ATproto {project} service";
    
    # ... basic options from simple template ...
    
    # Clustering options
    clustering = {
      enable = mkEnableOption "clustering support";
      
      nodeId = mkOption {
        type = types.str;
        default = config.networking.hostName;
        description = "Unique node identifier";
      };
      
      peers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of peer nodes";
      };
      
      role = mkOption {
        type = types.enum [ "primary" "secondary" "worker" ];
        default = "primary";
        description = "Node role in cluster";
      };
    };
    
    # Service discovery
    discovery = {
      backend = mkOption {
        type = types.enum [ "consul" "etcd" "dns" "static" ];
        default = "static";
        description = "Service discovery backend";
      };
      
      consulAddress = mkOption {
        type = types.str;
        default = "127.0.0.1:8500";
        description = "Consul server address";
      };
      
      serviceName = mkOption {
        type = types.str;
        default = "{project}";
        description = "Service name for discovery";
      };
    };
    
    # Performance tuning
    performance = {
      workers = mkOption {
        type = types.int;
        default = 4;
        description = "Number of worker processes";
      };
      
      maxConnections = mkOption {
        type = types.int;
        default = 1000;
        description = "Maximum concurrent connections";
      };
      
      cacheSize = mkOption {
        type = types.str;
        default = "128MB";
        description = "Cache size";
      };
    };
    
    # Monitoring
    monitoring = {
      enable = mkEnableOption "monitoring endpoints";
      
      metricsPort = mkOption {
        type = types.port;
        default = 9090;
        description = "Prometheus metrics port";
      };
      
      healthCheckInterval = mkOption {
        type = types.int;
        default = 30;
        description = "Health check interval in seconds";
      };
    };
    
    # Backup configuration
    backup = {
      enable = mkEnableOption "automatic backups";
      
      interval = mkOption {
        type = types.int;
        default = 24;
        description = "Backup interval in hours";
      };
      
      retention = mkOption {
        type = types.int;
        default = 7;
        description = "Number of backups to retain";
      };
      
      destination = mkOption {
        type = types.str;
        default = "${cfg.settings.dataDir}/backups";
        description = "Backup destination directory";
      };
    };
  };
  
  config = mkIf cfg.enable {
    # ... basic configuration from simple template ...
    
    # Service discovery registration
    systemd.services.{organization}-{project}-discovery = mkIf (cfg.discovery.backend != "static") {
      description = "Service discovery for {project}";
      wantedBy = [ "{organization}-{project}.service" ];
      before = [ "{organization}-{project}.service" ];
      
      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = group;
        
        ExecStart = serviceDiscovery.generateRegistrationScript {
          backend = cfg.discovery.backend;
          serviceName = cfg.discovery.serviceName;
          address = cfg.settings.hostname;
          port = cfg.settings.port;
          consulAddress = cfg.discovery.consulAddress;
        };
      };
    };
    
    # Monitoring service
    systemd.services.{organization}-{project}-monitor = mkIf cfg.monitoring.enable {
      description = "Monitoring for {project}";
      wantedBy = [ "multi-user.target" ];
      after = [ "{organization}-{project}.service" ];
      
      serviceConfig = {
        Type = "simple";
        User = user;
        Group = group;
        
        ExecStart = "${pkgs.writeScript "{project}-monitor" ''
          #!/bin/bash
          while true; do
            if ! ${pkgs.curl}/bin/curl -f http://${cfg.settings.hostname}:${toString cfg.settings.port}/health; then
              echo "Health check failed at $(date)"
              # Could trigger alerts here
            fi
            sleep ${toString cfg.monitoring.healthCheckInterval}
          done
        ''}";
        
        Restart = "always";
      };
    };
    
    # Backup service
    systemd.services.{organization}-{project}-backup = mkIf cfg.backup.enable {
      description = "Backup for {project}";
      
      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = group;
        
        ExecStart = "${pkgs.writeScript "{project}-backup" ''
          #!/bin/bash
          set -e
          
          BACKUP_DIR="${cfg.backup.destination}"
          TIMESTAMP=$(date +%Y%m%d_%H%M%S)
          BACKUP_FILE="$BACKUP_DIR/{project}_$TIMESTAMP.tar.gz"
          
          mkdir -p "$BACKUP_DIR"
          
          # Create backup
          tar -czf "$BACKUP_FILE" -C "${cfg.settings.dataDir}" .
          
          # Clean old backups
          find "$BACKUP_DIR" -name "{project}_*.tar.gz" -type f -mtime +${toString cfg.backup.retention} -delete
          
          echo "Backup completed: $BACKUP_FILE"
        ''}";
      };
    };
    
    # Backup timer
    systemd.timers.{organization}-{project}-backup = mkIf cfg.backup.enable {
      description = "Backup timer for {project}";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = "*-*-* */${toString cfg.backup.interval}:00:00";
        Persistent = true;
      };
    };
    
    # Firewall for monitoring
    networking.firewall = mkIf cfg.monitoring.enable {
      allowedTCPPorts = [ cfg.monitoring.metricsPort ];
    };
  };
}
```

## Testing Templates

### Package Test Template

```nix
# tests/{organization}-{project}.nix
{ pkgs, lib, ... }:

let
  package = pkgs.{organization}-{project};
in

{
  name = "{organization}-{project}-test";
  
  # Basic build test
  build-test = pkgs.runCommand "{project}-build-test" {} ''
    # Test that the package builds and has expected outputs
    test -f ${package}/bin/{project}
    test -d ${package}/share/{project}
    
    # Test that the binary can show version/help
    ${package}/bin/{project} --version || ${package}/bin/{project} --help
    
    touch $out
  '';
  
  # Configuration validation test
  config-test = pkgs.runCommand "{project}-config-test" {
    buildInputs = [ package pkgs.jq ];
  } ''
    # Test configuration file parsing
    echo '{"hostname": "test", "port": 3000}' > config.json
    
    # Validate configuration (if the binary supports it)
    ${package}/bin/{project} --validate-config config.json || true
    
    touch $out
  '';
}
```

### Integration Test Template

```nix
# tests/{organization}-{project}-integration.nix
import <nixpkgs/nixos/tests/make-test-python.nix> ({ pkgs, ... }: {
  name = "{organization}-{project}-integration";
  
  nodes = {
    server = { config, pkgs, ... }: {
      imports = [
        ../modules/{organization}/{project}.nix
      ];
      
      services.{organization}-{project} = {
        enable = true;
        settings = {
          hostname = "localhost";
          port = 3000;
          database = {
            type = "sqlite";
            url = "sqlite:///var/lib/{project}/test.db";
          };
        };
        openFirewall = true;
      };
      
      # Test database
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "{project}_test" ];
        ensureUsers = [{
          name = "{project}";
          ensurePermissions = {
            "DATABASE {project}_test" = "ALL PRIVILEGES";
          };
        }];
      };
    };
    
    client = { config, pkgs, ... }: {
      environment.systemPackages = [ pkgs.curl pkgs.jq ];
    };
  };
  
  testScript = ''
    start_all()
    
    # Wait for service to start
    server.wait_for_unit("{organization}-{project}.service")
    server.wait_for_open_port(3000)
    
    # Test health endpoint
    server.succeed("curl -f http://localhost:3000/health")
    
    # Test API endpoints
    with subtest("API functionality"):
        # Test basic API calls
        result = server.succeed("curl -s http://localhost:3000/api/status | jq -r .status")
        assert "ok" in result
        
        # Test database connectivity
        server.succeed("curl -f http://localhost:3000/api/db/health")
    
    # Test from client node
    with subtest("External connectivity"):
        client.succeed("curl -f http://server:3000/health")
    
    # Test service restart
    with subtest("Service resilience"):
        server.succeed("systemctl restart {organization}-{project}")
        server.wait_for_unit("{organization}-{project}.service")
        server.wait_for_open_port(3000)
        server.succeed("curl -f http://localhost:3000/health")
    
    # Test configuration changes
    with subtest("Configuration reload"):
        # This would test configuration reloading if supported
        pass
  '';
})
```

## Documentation Templates

### Package README Template

```markdown
# {Organization} {Project}

Brief description of what this ATproto service/application does.

## Features

- Feature 1: Description
- Feature 2: Description  
- Feature 3: Description

## ATproto Integration

This package provides the following ATproto services:
- **Service 1**: Description and purpose
- **Service 2**: Description and purpose

Supported ATproto protocols:
- XRPC: Core request/response protocol
- Jetstream: Real-time event streaming
- Firehose: Network-wide event stream

## Installation

### Using Nix Flakes

```bash
# Install directly
nix profile install github:atproto-nix/nur#{organization}-{project}

# Run temporarily
nix run github:atproto-nix/nur#{organization}-{project}

# Use in shell
nix shell github:atproto-nix/nur#{organization}-{project}
```

### NixOS Module

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    atproto-nur.url = "github:atproto-nix/nur";
  };

  outputs = { nixpkgs, atproto-nur, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        atproto-nur.nixosModules.default
        {
          services.{organization}-{project} = {
            enable = true;
            settings = {
              hostname = "example.com";
              port = 3000;
              database.url = "postgresql://user@localhost/db";
            };
          };
        }
      ];
    };
  };
}
```

## Configuration

### Basic Configuration

```nix
services.{organization}-{project} = {
  enable = true;
  
  settings = {
    hostname = "localhost";
    port = 3000;
    
    database = {
      type = "postgresql";
      url = "postgresql://user:pass@localhost/dbname";
      maxConnections = 20;
    };
    
    # Service-specific options
    extraConfig = {
      feature1 = true;
      feature2 = "value";
    };
  };
  
  openFirewall = true;
};
```

### Advanced Configuration

```nix
services.{organization}-{project} = {
  enable = true;
  
  # Clustering
  clustering = {
    enable = true;
    role = "primary";
    peers = [ "node2.example.com" "node3.example.com" ];
  };
  
  # Service discovery
  discovery = {
    backend = "consul";
    consulAddress = "consul.example.com:8500";
  };
  
  # Performance tuning
  performance = {
    workers = 8;
    maxConnections = 2000;
    cacheSize = "512MB";
  };
  
  # Monitoring
  monitoring = {
    enable = true;
    metricsPort = 9090;
  };
  
  # Backups
  backup = {
    enable = true;
    interval = 12; # hours
    retention = 14; # days
  };
};
```

## Development

### Building from Source

```bash
# Clone repository
git clone https://github.com/{organization}/{project}
cd {project}

# Enter development environment
nix develop

# Build package
nix build

# Run tests
nix build .#tests
```

### Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.

## License

This package is licensed under [LICENSE]. See the original project repository for details.

## Upstream

- **Repository**: https://github.com/{organization}/{project}
- **Documentation**: https://{organization}.github.io/{project}
- **Issues**: https://github.com/{organization}/{project}/issues
```

## Contribution Workflow

### 1. Package Proposal

Before starting work on a new package, create an issue with:

```markdown
# Package Proposal: {Organization} {Project}

## Overview
Brief description of the ATproto application/service.

## Upstream Information
- **Repository**: https://github.com/{organization}/{project}
- **License**: MIT/Apache2/etc
- **Language**: Rust/Node.js/Go/etc
- **Maturity**: Alpha/Beta/Stable

## ATproto Integration
- **Services**: List of ATproto services provided
- **Protocols**: XRPC, Jetstream, etc
- **Dependencies**: Database, external services, etc

## Packaging Plan
- [ ] Package definition
- [ ] NixOS module
- [ ] Integration tests
- [ ] Documentation

## Complexity Assessment
- **Tier**: 1 (Foundation) / 2 (Ecosystem) / 3 (Specialized)
- **Dependencies**: Simple/Moderate/Complex
- **Build System**: Standard/Custom
- **Special Requirements**: None/Database/External APIs/etc

## Timeline
Estimated completion: X weeks
```

### 2. Implementation Checklist

```markdown
# Implementation Checklist

## Package Development
- [ ] Create package definition using appropriate template
- [ ] Test package builds successfully
- [ ] Verify all dependencies are correctly specified
- [ ] Add comprehensive metadata
- [ ] Test installation and basic functionality

## NixOS Module Development  
- [ ] Create service module using template
- [ ] Implement comprehensive configuration options
- [ ] Add security hardening
- [ ] Test service starts and stops correctly
- [ ] Verify configuration validation

## Testing
- [ ] Create package build tests
- [ ] Implement integration tests
- [ ] Test service module functionality
- [ ] Verify security hardening works
- [ ] Test backup/restore if applicable

## Documentation
- [ ] Write package README
- [ ] Document configuration options
- [ ] Create usage examples
- [ ] Add troubleshooting guide
- [ ] Update main documentation

## Quality Assurance
- [ ] Code review by maintainer
- [ ] Security review
- [ ] Performance testing
- [ ] Documentation review
- [ ] Final integration testing
```

### 3. Review Process

1. **Initial Review**: Check package structure and basic functionality
2. **Security Review**: Verify security hardening and best practices
3. **Integration Review**: Test with existing ecosystem
4. **Documentation Review**: Ensure comprehensive documentation
5. **Final Approval**: Merge and update indexes

### 4. Maintenance Responsibilities

Package maintainers are responsible for:

- **Updates**: Keep packages current with upstream releases
- **Security**: Monitor and address security vulnerabilities
- **Bug Fixes**: Respond to and fix reported issues
- **Documentation**: Keep documentation current and accurate
- **Community**: Respond to user questions and feedback

This comprehensive template system ensures consistent, high-quality packages across the entire ATproto NUR ecosystem.