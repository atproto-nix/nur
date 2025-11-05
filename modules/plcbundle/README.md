# PLC Bundle NixOS Service Module

This directory contains NixOS service modules for deploying and managing the plcbundle service on NixOS systems.

## Overview

The plcbundle service is a PLC (Placeholder) Directory operation archiving and distribution system for the AT Protocol ecosystem. It:

- Fetches operations from the PLC Directory
- Groups them into immutable, cryptographically-chained bundles
- Compresses bundles using Zstandard (zstd) for efficient storage
- Verifies integrity using SHA-256 hashing
- Serves bundles via HTTP with optional WebSocket streaming
- Detects spam in operations
- Indexes DIDs for efficient searching

## Available Modules

### plcbundle-archive

The main plcbundle service that archives PLC Directory operations.

**Service name**: `plcbundle-archive`

## Quick Start

Enable the plcbundle service in your NixOS configuration:

```nix
{ config, lib, pkgs, ... }:

{
  services.plcbundle-archive = {
    enable = true;
    openFirewall = true;
  };
}
```

Then rebuild your system:

```bash
sudo nixos-rebuild switch
```

## Configuration

### Basic Example

```nix
services.plcbundle-archive = {
  enable = true;

  # PLC Directory to archive from
  plcDirectoryUrl = "https://plc.directory";

  # Network binding
  bindAddress = "127.0.0.1:8080";

  # Logging level
  logLevel = "info";

  # Open firewall ports
  openFirewall = true;
};
```

### Advanced Example

```nix
services.plcbundle-archive = {
  enable = true;

  # Source directory
  plcDirectoryUrl = "https://plc.directory";

  # Data storage
  dataDir = "/var/lib/plcbundle-archive";
  bundleDir = "/var/lib/plcbundle-archive/bundles";

  # Service user/group
  user = "plcbundle";
  group = "plcbundle";

  # Network configuration
  bindAddress = "0.0.0.0:8080";

  # Bundle settings
  maxBundleSize = 10000;           # Operations per bundle
  compressionLevel = 19;            # Zstandard level (1-22)

  # Features
  enableWebSocket = true;           # Real-time streaming
  enableSpamDetection = true;       # Spam filtering
  enableDidIndexing = true;         # DID search index

  # Logging
  logLevel = "info";

  # Firewall
  openFirewall = true;
};
```

## Configuration Options

### General Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | Enable the plcbundle service |
| `user` | `string` | `plcbundle-archive` | UNIX user account |
| `group` | `string` | `plcbundle-archive` | UNIX group |
| `dataDir` | `path` | `/var/lib/plcbundle-archive` | Service data directory |
| `logLevel` | `enum` | `info` | Log level: `trace`, `debug`, `info`, `warn`, `error` |
| `openFirewall` | `bool` | `false` | Automatically open firewall ports |

### PLC Bundle Specific Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `plcDirectoryUrl` | `string` | `https://plc.directory` | PLC Directory URL to archive from |
| `bundleDir` | `path` | `/var/lib/plcbundle-archive/bundles` | Bundle storage directory |
| `bindAddress` | `string` | `127.0.0.1:8080` | HTTP server bind address (HOST:PORT) |
| `maxBundleSize` | `int` | `10000` | Operations per bundle |
| `compressionLevel` | `int` | `19` | Zstandard compression (1-22) |
| `enableWebSocket` | `bool` | `true` | Enable WebSocket streaming |
| `enableSpamDetection` | `bool` | `true` | Enable spam detection |
| `enableDidIndexing` | `bool` | `true` | Enable DID indexing |

## Service Management

### Status

Check service status:

```bash
sudo systemctl status plcbundle-archive
```

### Logs

View service logs:

```bash
sudo journalctl -u plcbundle-archive -f
```

View recent logs:

```bash
sudo journalctl -u plcbundle-archive -n 50
```

### Start/Stop

Start the service:

```bash
sudo systemctl start plcbundle-archive
```

Stop the service:

```bash
sudo systemctl stop plcbundle-archive
```

Restart the service:

```bash
sudo systemctl restart plcbundle-archive
```

## Bundle Storage

Bundles are stored in the `bundleDir` with the following structure:

```
/var/lib/plcbundle-archive/bundles/
├── bundle-00000000-00000001.zstd    # First bundle (1-10,000 operations)
├── bundle-00000001-00000002.zstd    # Second bundle
├── bundle-00000002-00000003.zstd    # Third bundle
└── ...
```

Each bundle file contains:

- **Header**: Metadata (bundle number, operation range)
- **Compressed operations**: zstd-compressed JSON operation records
- **Chain hash**: SHA-256 hash linking to previous bundle
- **Integrity verification**: Checksums for each operation

### Bundle Inspection

Check bundle information:

```bash
ls -lh /var/lib/plcbundle-archive/bundles/
```

Verify bundle integrity:

```bash
curl http://localhost:8080/api/v1/bundle/verify
```

## HTTP API

The plcbundle service exposes an HTTP API for accessing bundles:

### Get Bundle Info

```bash
curl http://localhost:8080/api/v1/bundle/info
```

### Get Bundle by Number

```bash
curl http://localhost:8080/api/v1/bundle/0
```

### Get Operation by Range

```bash
curl http://localhost:8080/api/v1/operations/1000/2000
```

### WebSocket Streaming

Connect to real-time operation stream:

```bash
wscat -c ws://localhost:8080/stream
```

## Monitoring

### systemd Integration

The service integrates with systemd for:

- **Restart policy**: Automatically restarts on failure
- **Logging**: All output goes to journalctl
- **Resource limits**: Configurable via service settings
- **Security hardening**: Applied automatically

### Resource Usage

Monitor memory and CPU:

```bash
systemctl status plcbundle-archive
```

Get detailed metrics:

```bash
ps aux | grep plcbundle
```

## Troubleshooting

### Service Won't Start

Check logs for errors:

```bash
sudo journalctl -u plcbundle-archive -n 100
```

Common issues:

- **Port already in use**: Change `bindAddress` to a different port
- **Permission denied**: Check `dataDir` and `bundleDir` permissions
- **Network unreachable**: Verify `plcDirectoryUrl` is accessible

### Bundle Creation Fails

Check disk space:

```bash
df -h /var/lib/plcbundle-archive/
```

Verify write permissions:

```bash
sudo ls -la /var/lib/plcbundle-archive/
```

### Memory Issues

Monitor memory usage:

```bash
watch -n 1 'systemctl status plcbundle-archive | grep Memory'
```

Adjust compression level (lower = less memory):

```nix
compressionLevel = 10;  # Instead of 19
```

## Security Hardening

The module automatically applies standard security hardening:

- **User isolation**: Runs as non-root `plcbundle` user
- **Permission restrictions**: Strict file permissions
- **Namespace isolation**: Private tmpfs, mounts, devices
- **Kernel protections**: Kernel log, module, and tunable protection
- **Process restrictions**: No realtime, SUID, namespaces
- **Syscall filtering**: Architecture-native syscalls only

## Advanced Configuration

### Custom User/Group

```nix
services.plcbundle-archive = {
  enable = true;
  user = "myplcuser";
  group = "myplcgroup";
};
```

### Multiple Instances

Run multiple plcbundle instances with different configurations by creating additional module copies (not supported by default).

### Custom Environment Variables

Environment variables are automatically set from configuration:

```
PLC_DIRECTORY_URL=https://plc.directory
BUNDLE_DIR=/var/lib/plcbundle-archive/bundles
HTTP_HOST=127.0.0.1
HTTP_PORT=8080
LOG_LEVEL=info
```

## Integration with Other Services

### Reverse Proxy (Nginx)

```nix
services.nginx = {
  enable = true;
  virtualHosts."bundles.example.com" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
    };
  };
};
```

### Monitoring (Prometheus)

The plcbundle service exposes metrics on `/metrics`:

```bash
curl http://localhost:8080/metrics
```

## File Locations

| Path | Purpose |
|------|---------|
| `/var/lib/plcbundle-archive/` | Service data directory |
| `/var/lib/plcbundle-archive/bundles/` | Bundle storage |
| `/var/log/plcbundle-archive/` | Service logs (via journalctl) |
| `/run/plcbundle-archive/` | Runtime state (tmpfiles) |

## Development Notes

The module is designed to be:

- **Declarative**: All configuration through Nix options
- **Composable**: Works with other NixOS modules
- **Secure by default**: Hardening enabled automatically
- **Observable**: Logs available through journalctl
- **Maintainable**: Clear separation of concerns

## Further Reading

- [PLC Bundle GitHub](https://github.com/atscan-net/plcbundle)
- [AT Protocol Documentation](https://atproto.com)
- [NixOS Module System](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- [systemd Service Documentation](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

## Support

For issues or questions:

1. Check logs: `journalctl -u plcbundle-archive`
2. Verify configuration: Review your NixOS configuration
3. Test connectivity: `curl` the PLC Directory URL
4. Open an issue: [GitHub Issues](https://github.com/atscan-net/plcbundle/issues)
