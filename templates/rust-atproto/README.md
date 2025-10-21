# ATProto Rust Service Template

This template provides a starting point for building ATProto services in Rust using Nix for packaging and deployment.

## Features

- **Nix Flake**: Complete Nix flake setup with development shell and CI checks
- **ATProto Integration**: Basic ATProto service structure with XRPC endpoints
- **Security**: Follows ATProto security best practices
- **Testing**: Comprehensive test setup with axum-test
- **Observability**: Structured logging with tracing
- **Development**: Hot reloading and development tools

## Quick Start

1. **Initialize your project**:
   ```bash
   nix flake init -t github:atproto-nix/nur#rust-atproto
   ```

2. **Customize the template**:
   - Replace `my-atproto-service` with your service name in:
     - `Cargo.toml`
     - `flake.nix`
     - `src/main.rs`
   - Update the ATProto metadata in `flake.nix`:
     - `services`: List of services your package provides
     - `protocols`: ATProto protocols supported
   - Implement your ATProto logic in `src/main.rs`

3. **Enter development environment**:
   ```bash
   nix develop
   ```

4. **Run the service**:
   ```bash
   cargo run
   ```

5. **Test the service**:
   ```bash
   # Health check
   curl http://localhost:8080/health
   
   # ATProto endpoint
   curl -X POST http://localhost:8080/xrpc/com.atproto.repo.createRecord \
     -H "Content-Type: application/json" \
     -d '{"did": "did:plc:example123", "collection": "app.bsky.feed.post"}'
   ```

## Development

### Available Commands

```bash
# Enter development shell
nix develop

# Build the package
nix build

# Run tests
cargo test

# Run with hot reloading
cargo watch -x run

# Format code
cargo fmt

# Lint code
cargo clippy

# Run all checks (CI)
nix flake check
```

### Project Structure

```
.
├── flake.nix          # Nix flake configuration
├── Cargo.toml         # Rust package configuration
├── src/
│   └── main.rs        # Main service implementation
└── README.md          # This file
```

## ATProto Implementation

This template provides a basic ATProto service structure. You'll need to implement:

1. **Authentication**: Verify ATProto tokens and DIDs
2. **Authorization**: Check permissions for operations
3. **Data Storage**: Implement your data model and storage
4. **XRPC Endpoints**: Add your specific ATProto methods
5. **Lexicon Validation**: Validate requests against ATProto lexicons

### Common ATProto Patterns

```rust
// DID validation
fn validate_did(did: &str) -> Result<(), Error> {
    // Implement DID validation logic
}

// JWT token verification
fn verify_token(token: &str) -> Result<Claims, Error> {
    // Implement JWT verification
}

// Lexicon validation
fn validate_record(collection: &str, record: &Value) -> Result<(), Error> {
    // Implement lexicon validation
}
```

## Deployment

### NixOS Module

This package can be deployed using NixOS modules:

```nix
# In your NixOS configuration
{
  services.my-atproto-service = {
    enable = true;
    settings = {
      port = 8080;
      host = "0.0.0.0";
      logLevel = "info";
    };
  };
}
```

### Docker

Build a Docker image:

```bash
nix build .#dockerImage
docker load < result
```

### Binary

Build a static binary:

```bash
nix build
./result/bin/my-atproto-service --help
```

## Contributing

1. Follow the [ATProto Nix Packaging Guidelines](../docs/PACKAGING.md)
2. Ensure all tests pass: `nix flake check`
3. Update documentation as needed
4. Submit a pull request

## Resources

- [ATProto Specification](https://atproto.com/)
- [ATProto Nix Ecosystem Documentation](../docs/)
- [Rust ATProto Libraries](https://crates.io/search?q=atproto)
- [Nix Flakes Documentation](https://nixos.wiki/wiki/Flakes)