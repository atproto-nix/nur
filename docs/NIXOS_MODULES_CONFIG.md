# NixOS Modules Configuration Guide

This document covers best practices and common configuration patterns for NixOS modules in the ATProto NUR.

## Common Configuration Patterns

### Environment Variables for Application Settings

Many web applications (especially those using frameworks like Sinatra, Rails, or Django) rely on environment variables for configuration rather than config files. When creating NixOS modules for these services, the `Environment` list in `systemd.services` is the standard way to pass configuration.

```nix
systemd.services.my-service = {
  serviceConfig = {
    Environment = [
      "DATABASE_URL=postgresql://user:pass@localhost/db"
      "PORT=3000"
      "DEBUG=false"
    ];
  };
};
```

## Web Framework Integration

### Sinatra: Host Validation via Rack::Protection

**Issue**: HTTP requests to Sinatra applications fail with "Host not permitted" errors.

**Root Cause**: Sinatra includes `rack-protection` middleware by default, which validates the `Host` HTTP header against an allowed hosts list using `Rack::Protection::HostAuthorization`.

**Symptoms**:
```
Rack::Protection::HostAuthorization: Host not permitted
```

**Fix**: Configure the `allowedHosts` NixOS module option to set the `RACK_PROTECTION_ALLOWED_HOSTS` environment variable.

**Implementation Pattern** (see `modules/mackuba/mackuba-lycan.nix`):

1. **Define the NixOS option**:
```nix
allowedHosts = mkOption {
  type = types.listOf types.str;
  default = [];
  description = "Allowed hosts for the Sinatra server";
  example = [ "example.com" "localhost" ];
};
```

2. **Set the environment variable in systemd service**:
```nix
Environment = [
  "SERVER_HOSTNAME=${cfg.hostname}"
  # ... other vars ...
] ++ optional (cfg.allowedHosts != [])
  "RACK_PROTECTION_ALLOWED_HOSTS=${concatStringsSep "," cfg.allowedHosts}";
```

3. **Usage in NixOS configuration**:
```nix
services.mackuba-lycan = {
  enable = true;
  hostname = "lycan.example.com";
  allowedHosts = [
    "lycan.example.com"
    "localhost"
    "127.0.0.1"  # for IP-based access during development
  ];
};
```

**Technical Details**:
- **Gem**: `rack-protection` (included by Sinatra)
- **Environment Variable**: `RACK_PROTECTION_ALLOWED_HOSTS`
- **Format**: Comma-separated list of hostnames (no spaces)
- **Default Behavior**: If unset, Rack::Protection may reject requests from unexpected hosts
- **Disabled**: Empty list may disable the check (not recommended for production)

**Why This Matters**:
When accessing a web service through a reverse proxy or multiple hostnames, the `Host` header might not match the hardcoded list. This is common in:
- Load-balanced deployments
- Multiple domain names pointing to the same service
- Development environments with `localhost` / IP access
- Reverse proxy configurations

### Rails: Similar Pattern with Different Variable

While Rails uses a different mechanism (`ALLOWED_HOSTS` in some versions), the pattern is identical:
1. Identify the environment variable the framework expects
2. Add a NixOS module option
3. Set the variable via `Environment` in systemd service

## Best Practices for Web Service Modules

### 1. Always Allow localhost for Development/Testing
```nix
allowedHosts = [
  cfg.hostname
  "localhost"
  "127.0.0.1"
];
```

### 2. Document Network Access Requirements
```nix
description = ''
  Allowed hosts for the Sinatra server. Must include the hostname
  and any domains/IPs used to access the service. Use "localhost"
  for local development.
'';
```

### 3. Consider Reverse Proxy Scenarios
If the service is commonly deployed behind nginx/Caddy:
```nix
allowedHosts = [
  cfg.hostname
  "localhost"
  "127.0.0.1"
  # Add a way for users to configure additional hosts for reverse proxy setups
];
```

### 4. Validate Host Configuration
```nix
assertions = [
  {
    assertion = cfg.allowedHosts != [];
    message = "allowedHosts must not be empty when using Rack::Protection";
  }
];
```

## Troubleshooting

### Request Blocked with Host Validation Error

**Symptom**: HTTP 400 or similar when accessing the service

**Diagnosis**:
1. Check the service logs: `journalctl -u my-service -e`
2. Look for "Host not permitted" or similar messages
3. Verify the `Host` header in the request matches an allowed host

**Solution**:
1. Identify the hostname/IP used to access the service
2. Add it to `allowedHosts`
3. Restart the service: `systemctl restart my-service`

### Testing Host Configuration

Use `curl` with custom Host header:
```bash
# Test with specific host header
curl -H "Host: example.com" http://localhost:3000/health

# Test current hostname
curl http://example.com:3000/health
```

## References

- [Sinatra Security Features](https://github.com/sinatra/sinatra/blob/main/lib/sinatra/protection.rb)
- [Rack::Protection Documentation](https://rubydoc.info/gems/rack-protection)
- [nixos/modules/services](https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/services)

## Related Modules

- `modules/mackuba/mackuba-lycan.nix` - Lycan custom feed generator (Sinatra-based)
