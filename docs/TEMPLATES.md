# ATProto Nix Templates Guide

This guide covers how to use, customize, and create templates for ATProto applications in the Nix ecosystem.

## Table of Contents

- [Overview](#overview)
- [Available Templates](#available-templates)
- [Using Templates](#using-templates)
- [Customizing Templates](#customizing-templates)
- [Template Structure](#template-structure)
- [Creating New Templates](#creating-new-templates)
- [Best Practices](#best-practices)

## Overview

ATProto Nix templates provide standardized starting points for creating new ATProto applications. Each template includes:

- **Complete Nix flake** with development environment
- **Language-specific tooling** and dependencies
- **ATProto integration** patterns and examples
- **Testing framework** setup
- **Documentation** and usage examples
- **CI/CD configuration** for automated testing

## Available Templates

### Rust ATProto Service (`rust-atproto`)

**Best for**: High-performance services, system components, memory-critical applications

**Features**:
- Axum web server with async/await support
- Comprehensive error handling with anyhow
- Structured logging with tracing
- SQLx database integration
- Comprehensive testing with cargo-nextest
- Security hardening by default

**Use cases**:
- Personal Data Servers (PDS)
- ATProto relays
- Feed generators
- Content labelers
- System utilities

### Node.js ATProto Service (`nodejs-atproto`)

**Best for**: Rapid prototyping, web applications, TypeScript development

**Features**:
- Express.js server with TypeScript
- ATProto SDK integration
- XRPC server setup
- Winston structured logging
- Jest testing framework
- Hot reloading with nodemon

**Use cases**:
- Web applications
- API services
- Development tools
- Prototypes and demos
- Frontend services

### Go ATProto Service (`go-atproto`)

**Best for**: CLI tools, system services, simple deployment

**Features**:
- Gorilla Mux HTTP router
- Cobra CLI framework
- Viper configuration management
- Logrus structured logging
- Standard library focus
- Minimal dependencies

**Use cases**:
- Command-line tools
- System services
- Infrastructure utilities
- Simple web services
- Deployment tools

## Using Templates

### Quick Start

1. **Initialize from template**:
   ```bash
   # Create new directory and initialize
   mkdir my-atproto-service
   cd my-atproto-service
   nix flake init -t github:atproto-nix/nur#rust-atproto
   ```

2. **Enter development environment**:
   ```bash
   nix develop
   ```

3. **Customize the template** (see [Customizing Templates](#customizing-templates))

4. **Start development**:
   ```bash
   # Rust
   cargo run
   
   # Node.js
   npm install && npm run dev
   
   # Go
   go mod tidy && go run .
   ```

### Template Selection Guide

Choose your template based on:

**Performance Requirements**:
- **High performance**: Rust (compiled, zero-cost abstractions)
- **Moderate performance**: Go (compiled, garbage collected)
- **Development speed**: Node.js (interpreted, rapid iteration)

**Ecosystem Preferences**:
- **Systems programming**: Rust (memory safety, concurrency)
- **Web development**: Node.js (rich ecosystem, TypeScript)
- **Simple deployment**: Go (single binary, minimal dependencies)

**Team Expertise**:
- **Rust experience**: rust-atproto template
- **JavaScript/TypeScript**: nodejs-atproto template
- **Go experience**: go-atproto template

## Customizing Templates

### Basic Customization

All templates require these basic customizations:

1. **Update package names**:
   ```bash
   # Find and replace placeholder names
   find . -type f -name "*.nix" -o -name "*.toml" -o -name "*.json" -o -name "*.go" -o -name "*.rs" -o -name "*.ts" | \
     xargs sed -i 's/my-atproto-service/your-service-name/g'
   ```

2. **Update ATProto metadata**:
   ```nix
   # In flake.nix
   passthru.atproto = {
     type = "application";
     services = [ "your-service-name" ];
     protocols = [ "com.atproto" "app.bsky" ]; # Add your protocols
   };
   ```

3. **Update package metadata**:
   ```nix
   meta = with lib; {
     description = "Your service description";
     homepage = "https://github.com/your-org/your-repo";
     license = licenses.mit; # or your preferred license
     maintainers = with maintainers; [ your-github-handle ];
   };
   ```

### Rust Template Customization

1. **Update Cargo.toml**:
   ```toml
   [package]
   name = "your-service-name"
   version = "0.1.0"
   description = "Your service description"
   
   [[bin]]
   name = "your-service-name"
   path = "src/main.rs"
   ```

2. **Add dependencies**:
   ```toml
   [dependencies]
   # ATProto-specific dependencies
   atproto-lexicon = "0.4"
   atproto-crypto = "0.3"
   
   # Your additional dependencies
   uuid = { version = "1.0", features = ["v4"] }
   chrono = { version = "0.4", features = ["serde"] }
   ```

3. **Customize service logic**:
   ```rust
   // In src/main.rs
   #[derive(Deserialize)]
   struct YourRequest {
       // Define your request structure
   }
   
   async fn handle_your_method(
       State(state): State<AppState>,
       Json(request): Json<YourRequest>,
   ) -> Result<Json<YourResponse>, StatusCode> {
       // Implement your ATProto method
   }
   ```

### Node.js Template Customization

1. **Update package.json**:
   ```json
   {
     "name": "your-service-name",
     "description": "Your service description",
     "dependencies": {
       "@atproto/api": "^0.12.0",
       "@atproto/lexicon": "^0.4.0"
     }
   }
   ```

2. **Add XRPC methods**:
   ```typescript
   // In src/index.ts
   this.xrpc.method('com.yourorg.yourMethod', async (ctx) => {
     const { input } = ctx;
     // Implement your method logic
     return { success: true };
   });
   ```

3. **Configure TypeScript**:
   ```json
   // tsconfig.json
   {
     "compilerOptions": {
       "target": "ES2022",
       "module": "ESNext",
       "strict": true
     }
   }
   ```

### Go Template Customization

1. **Update go.mod**:
   ```go
   module your-service-name
   
   go 1.21
   
   require (
       github.com/gorilla/mux v1.8.1
       // Your additional dependencies
   )
   ```

2. **Add HTTP handlers**:
   ```go
   // In main.go
   func (s *Server) handleYourMethod(w http.ResponseWriter, r *http.Request) {
       // Implement your ATProto method
   }
   
   // Register in setupRoutes
   xrpc.HandleFunc("/com.yourorg.yourMethod", s.handleYourMethod).Methods("POST")
   ```

3. **Configure CLI**:
   ```go
   var rootCmd = &cobra.Command{
       Use:   "your-service-name",
       Short: "Your service description",
       RunE: func(cmd *cobra.Command, args []string) error {
           // Your service logic
       },
   }
   ```

## Template Structure

### Common Structure

All templates follow this structure:

```
template-name/
├── flake.nix          # Nix flake configuration
├── README.md          # Template documentation
├── .gitignore         # Version control ignores
└── src/               # Source code (language-specific)
```

### Language-Specific Files

**Rust Template**:
```
rust-atproto/
├── flake.nix
├── Cargo.toml         # Rust package configuration
├── src/
│   └── main.rs        # Main service implementation
└── README.md
```

**Node.js Template**:
```
nodejs-atproto/
├── flake.nix
├── package.json       # Node.js package configuration
├── tsconfig.json      # TypeScript configuration
├── src/
│   └── index.ts       # Main service implementation
└── README.md
```

**Go Template**:
```
go-atproto/
├── flake.nix
├── go.mod             # Go module configuration
├── main.go            # Main service implementation
└── README.md
```

### Flake Structure

All templates include a comprehensive flake.nix:

```nix
{
  description = "Template description";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Language-specific inputs (crane, rust-overlay, etc.)
  };
  
  outputs = { self, nixpkgs, ... }: {
    packages = {
      # Package definitions
    };
    
    devShells.default = {
      # Development environment
    };
    
    checks = {
      # CI/CD checks
    };
  };
}
```

## Creating New Templates

### Template Requirements

New templates must include:

1. **Complete flake.nix** with all necessary inputs and outputs
2. **Development shell** with appropriate tools
3. **Package definition** following ATProto conventions
4. **Testing setup** with example tests
5. **Documentation** with usage instructions
6. **ATProto metadata** properly configured

### Template Creation Process

1. **Create template directory**:
   ```bash
   mkdir templates/your-template
   cd templates/your-template
   ```

2. **Implement template files**:
   - `flake.nix` - Main flake configuration
   - Language-specific configuration files
   - Source code with ATProto integration
   - `README.md` with instructions

3. **Add to main flake**:
   ```nix
   # In main flake.nix
   templates.your-template = {
     path = ./templates/your-template;
     description = "Your template description";
     welcomeText = ''
       Welcome text for users
     '';
   };
   ```

4. **Test the template**:
   ```bash
   # Test template initialization
   nix flake init -t .#your-template
   
   # Test development environment
   nix develop
   
   # Test package building
   nix build
   ```

### Template Guidelines

**Naming Conventions**:
- Template names: `language-atproto` (e.g., `python-atproto`)
- Package names: `my-atproto-service` (placeholder for user customization)
- Service names: Match package names

**Code Quality**:
- Follow language-specific best practices
- Include comprehensive error handling
- Provide clear examples and comments
- Use structured logging

**Documentation**:
- Clear README with step-by-step instructions
- Code comments explaining ATProto patterns
- Configuration examples
- Troubleshooting section

## Best Practices

### Template Design

1. **Keep it simple**: Templates should be minimal but complete
2. **Follow conventions**: Use established patterns from the ecosystem
3. **Include examples**: Provide working examples of common patterns
4. **Document everything**: Clear documentation is essential

### ATProto Integration

1. **Use standard metadata**: Follow the ATProto metadata schema
2. **Implement common endpoints**: Include health checks and basic XRPC methods
3. **Handle authentication**: Provide patterns for ATProto authentication
4. **Validate inputs**: Include input validation examples

### Development Experience

1. **Fast iteration**: Development shells should start quickly
2. **Hot reloading**: Include development servers with hot reloading
3. **Good defaults**: Sensible defaults for development
4. **Clear errors**: Helpful error messages and debugging

### Security

1. **Secure defaults**: All templates should be secure by default
2. **Input validation**: Validate all inputs
3. **Error handling**: Don't expose sensitive information in errors
4. **Dependencies**: Use well-maintained, secure dependencies

## Troubleshooting

### Common Issues

**Template initialization fails**:
- Check Nix flake syntax with `nix flake check`
- Ensure all inputs are available
- Verify template path is correct

**Development shell issues**:
- Check if all dependencies are available
- Verify system compatibility
- Look for missing build tools

**Build failures**:
- Update dependency hashes when needed
- Check for missing system dependencies
- Verify source code compiles

### Getting Help

1. **Check existing templates** for similar patterns
2. **Review documentation** for detailed guides
3. **Ask in discussions** for community help
4. **Report issues** for bugs or missing features

## Examples

See the `examples/` directory for complete examples of:
- Simple Rust service with NixOS module
- Node.js web application
- Go CLI tool
- Multi-service workspace

These examples demonstrate real-world usage patterns and best practices for ATProto development with Nix.