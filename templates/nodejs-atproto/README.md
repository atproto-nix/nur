# ATProto Node.js Service Template

This template provides a starting point for building ATProto services in Node.js/TypeScript using Nix for packaging and deployment.

## Features

- **Nix Flake**: Complete Nix flake setup with development shell and CI checks
- **TypeScript**: Full TypeScript support with strict configuration
- **ATProto Integration**: XRPC server setup with ATProto lexicons
- **Express.js**: Production-ready HTTP server with security middleware
- **Logging**: Structured logging with Winston
- **Testing**: Jest test framework setup
- **Development**: Hot reloading with nodemon and ts-node

## Quick Start

1. **Initialize your project**:
   ```bash
   nix flake init -t github:atproto-nix/nur#nodejs-atproto
   ```

2. **Customize the template**:
   - Replace `my-atproto-node-service` with your service name in:
     - `package.json`
     - `flake.nix`
     - `src/index.ts`
   - Update the ATProto metadata in `flake.nix`:
     - `services`: List of services your package provides
     - `protocols`: ATProto protocols supported
   - Implement your ATProto logic in `src/index.ts`

3. **Enter development environment**:
   ```bash
   nix develop
   ```

4. **Install dependencies**:
   ```bash
   npm install
   ```

5. **Start development server**:
   ```bash
   npm run dev
   ```

6. **Test the service**:
   ```bash
   # Health check
   curl http://localhost:3000/health
   
   # ATProto endpoint
   curl -X POST http://localhost:3000/xrpc/com.atproto.repo.createRecord \
     -H "Content-Type: application/json" \
     -d '{"did": "did:plc:example123", "collection": "app.bsky.feed.post", "record": {"text": "Hello ATProto!"}}'
   ```

## Development

### Available Commands

```bash
# Enter development shell
nix develop

# Install dependencies
npm install

# Start development server with hot reload
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Run tests
npm test

# Lint code
npm run lint

# Fix linting issues
npm run lint:fix

# Type check
npm run type-check

# Build Nix package
nix build

# Run all checks (CI)
nix flake check
```

### Project Structure

```
.
├── flake.nix          # Nix flake configuration
├── package.json       # Node.js package configuration
├── tsconfig.json      # TypeScript configuration
├── src/
│   └── index.ts       # Main service implementation
└── README.md          # This file
```

## ATProto Implementation

This template provides a basic ATProto service structure with XRPC server setup. You'll need to implement:

1. **Authentication**: Verify ATProto tokens and DIDs
2. **Authorization**: Check permissions for operations
3. **Data Storage**: Implement your data model and storage
4. **XRPC Methods**: Add your specific ATProto methods
5. **Lexicon Validation**: Validate requests against ATProto lexicons

### Common ATProto Patterns

```typescript
// DID validation
function validateDid(did: string): boolean {
  return did.startsWith('did:') && did.includes(':');
}

// JWT token verification
async function verifyToken(token: string): Promise<any> {
  // Implement JWT verification logic
}

// Lexicon validation
function validateRecord(collection: string, record: any): boolean {
  // Implement lexicon validation
}

// XRPC method handler
xrpc.method('com.example.myMethod', async (ctx) => {
  const { input } = ctx;
  
  // Validate input
  // Process request
  // Return response
  
  return { success: true };
});
```

## Configuration

The service uses environment variables for configuration:

```bash
# Server configuration
PORT=3000
HOST=localhost
LOG_LEVEL=info

# Database configuration (add as needed)
DATABASE_URL=sqlite:./data.db

# ATProto configuration (add as needed)
ATPROTO_SERVICE_DID=did:web:example.com
ATPROTO_SIGNING_KEY=...
```

## Deployment

### NixOS Module

This package can be deployed using NixOS modules:

```nix
# In your NixOS configuration
{
  services.my-atproto-node-service = {
    enable = true;
    settings = {
      port = 3000;
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
node ./result/lib/node_modules/my-atproto-node-service/index.js
```

## Testing

The template includes Jest for testing:

```typescript
// Example test
import request from 'supertest';
import { AtprotoService } from '../src/index';

describe('ATProto Service', () => {
  let service: AtprotoService;

  beforeAll(async () => {
    service = new AtprotoService();
    await service.start();
  });

  test('health endpoint', async () => {
    const response = await request(service.app)
      .get('/health')
      .expect(200);
      
    expect(response.body.status).toBe('healthy');
  });

  test('XRPC endpoint', async () => {
    const response = await request(service.app)
      .post('/xrpc/com.atproto.repo.createRecord')
      .send({
        did: 'did:plc:example123',
        collection: 'app.bsky.feed.post',
        record: { text: 'Hello ATProto!' }
      })
      .expect(200);
      
    expect(response.body.success).toBe(true);
  });
});
```

## Contributing

1. Follow the [ATProto Nix Packaging Guidelines](../docs/PACKAGING.md)
2. Ensure all tests pass: `npm test`
3. Ensure all checks pass: `nix flake check`
4. Update documentation as needed
5. Submit a pull request

## Resources

- [ATProto Specification](https://atproto.com/)
- [ATProto TypeScript SDK](https://github.com/bluesky-social/atproto/tree/main/packages)
- [ATProto Nix Ecosystem Documentation](../docs/)
- [Express.js Documentation](https://expressjs.com/)
- [Nix Flakes Documentation](https://nixos.wiki/wiki/Flakes)