# ATProto Go Service Template

This template provides a starting point for building ATProto services in Go using Nix for packaging and deployment.

## Features

- **Nix Flake**: Complete Nix flake setup with development shell and CI checks
- **HTTP Server**: Production-ready HTTP server with Gorilla Mux
- **ATProto Integration**: Basic XRPC endpoint structure for ATProto methods
- **Configuration**: Flexible configuration with Viper (environment variables, config files, CLI flags)
- **Logging**: Structured logging with Logrus
- **Testing**: Go testing framework setup
- **CLI**: Command-line interface with Cobra

## Quick Start

1. **Initialize your project**:
   ```bash
   nix flake init -t github:atproto-nix/nur#go-atproto
   ```

2. **Customize the template**:
   - Replace `my-atproto-go-service` with your service name in:
     - `go.mod`
     - `flake.nix`
     - `main.go`
   - Update the ATProto metadata in `flake.nix`:
     - `services`: List of services your package provides
     - `protocols`: ATProto protocols supported
   - Implement your ATProto logic in `main.go`

3. **Enter development environment**:
   ```bash
   nix develop
   ```

4. **Initialize Go modules**:
   ```bash
   go mod tidy
   ```

5. **Run the service**:
   ```bash
   go run .
   ```

6. **Test the service**:
   ```bash
   # Health check
   curl http://localhost:8080/health
   
   # ATProto endpoint
   curl -X POST http://localhost:8080/xrpc/com.atproto.repo.createRecord \
     -H "Content-Type: application/json" \
     -d '{"did": "did:plc:example123", "collection": "app.bsky.feed.post", "record": {"text": "Hello ATProto!"}}'
   ```

## Development

### Available Commands

```bash
# Enter development shell
nix develop

# Install/update dependencies
go mod tidy

# Run the service
go run .

# Build binary
go build

# Run tests
go test ./...

# Format code
gofmt -w .

# Vet code
go vet ./...

# Build Nix package
nix build

# Run all checks (CI)
nix flake check
```

### Project Structure

```
.
├── flake.nix          # Nix flake configuration
├── go.mod             # Go module configuration
├── main.go            # Main service implementation
└── README.md          # This file
```

## Configuration

The service supports multiple configuration methods:

### Environment Variables

```bash
export ATPROTO_PORT=8080
export ATPROTO_HOST=localhost
export ATPROTO_LOG_LEVEL=info
```

### Configuration File

Create a `config.yaml` file:

```yaml
port: 8080
host: localhost
log_level: info
```

### Command Line Flags

```bash
./my-atproto-go-service --port 8080 --host localhost --log-level info
```

## ATProto Implementation

This template provides a basic ATProto service structure with HTTP server setup. You'll need to implement:

1. **Authentication**: Verify ATProto tokens and DIDs
2. **Authorization**: Check permissions for operations
3. **Data Storage**: Implement your data model and storage
4. **XRPC Methods**: Add your specific ATProto methods
5. **Lexicon Validation**: Validate requests against ATProto lexicons

### Common ATProto Patterns

```go
// DID validation
func validateDID(did string) error {
    if !strings.HasPrefix(did, "did:") {
        return fmt.Errorf("invalid DID format")
    }
    return nil
}

// JWT token verification
func verifyToken(token string) (*Claims, error) {
    // Implement JWT verification logic
    return nil, nil
}

// Lexicon validation
func validateRecord(collection string, record interface{}) error {
    // Implement lexicon validation
    return nil
}

// XRPC method handler
func (s *Server) handleMyMethod(w http.ResponseWriter, r *http.Request) {
    // Parse request
    // Validate input
    // Process request
    // Return response
}
```

## Testing

The template includes Go's built-in testing framework:

```go
// Example test
func TestHealthEndpoint(t *testing.T) {
    config := &Config{Port: 8080, Host: "localhost", LogLevel: "info"}
    server := NewServer(config)
    
    req, err := http.NewRequest("GET", "/health", nil)
    if err != nil {
        t.Fatal(err)
    }
    
    rr := httptest.NewRecorder()
    server.router.ServeHTTP(rr, req)
    
    if status := rr.Code; status != http.StatusOK {
        t.Errorf("handler returned wrong status code: got %v want %v",
            status, http.StatusOK)
    }
    
    var response HealthResponse
    if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
        t.Fatal(err)
    }
    
    if response.Status != "healthy" {
        t.Errorf("expected status 'healthy', got '%s'", response.Status)
    }
}
```

## Deployment

### NixOS Module

This package can be deployed using NixOS modules:

```nix
# In your NixOS configuration
{
  services.my-atproto-go-service = {
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

Build and run the service:

```bash
nix build
./result/bin/my-atproto-go-service --help
```

## Performance Considerations

- **Goroutines**: Use goroutines for concurrent request handling
- **Connection Pooling**: Implement database connection pooling
- **Caching**: Add caching layers for frequently accessed data
- **Rate Limiting**: Implement rate limiting for API endpoints
- **Monitoring**: Add metrics and health checks

## Security Best Practices

- **Input Validation**: Validate all input data
- **Authentication**: Implement proper ATProto authentication
- **Authorization**: Check permissions for all operations
- **HTTPS**: Use HTTPS in production
- **Secrets Management**: Use secure secret management
- **Logging**: Avoid logging sensitive information

## Contributing

1. Follow the [ATProto Nix Packaging Guidelines](../docs/PACKAGING.md)
2. Ensure all tests pass: `go test ./...`
3. Ensure all checks pass: `nix flake check`
4. Format code: `gofmt -w .`
5. Update documentation as needed
6. Submit a pull request

## Resources

- [ATProto Specification](https://atproto.com/)
- [ATProto Go Libraries](https://pkg.go.dev/search?q=atproto)
- [ATProto Nix Ecosystem Documentation](../docs/)
- [Go Documentation](https://golang.org/doc/)
- [Gorilla Mux Documentation](https://github.com/gorilla/mux)
- [Nix Flakes Documentation](https://nixos.wiki/wiki/Flakes)