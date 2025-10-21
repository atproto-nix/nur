{
  description = "ATProto Nix templates for creating new ATProto applications";

  outputs = { self }: {
    templates = {
      rust-atproto = {
        path = ./rust-atproto;
        description = "ATProto Rust service template with Nix flake";
        welcomeText = ''
          # ATProto Rust Service Template

          You have created a new ATProto Rust service template.

          ## Next steps:
          1. Replace 'my-atproto-service' with your service name in:
             - Cargo.toml
             - flake.nix
             - src/main.rs
          2. Update ATProto metadata in flake.nix
          3. Enter development environment: `nix develop`
          4. Run the service: `cargo run`

          See README.md for detailed instructions.
        '';
      };

      nodejs-atproto = {
        path = ./nodejs-atproto;
        description = "ATProto Node.js/TypeScript service template with Nix flake";
        welcomeText = ''
          # ATProto Node.js Service Template

          You have created a new ATProto Node.js/TypeScript service template.

          ## Next steps:
          1. Replace 'my-atproto-node-service' with your service name in:
             - package.json
             - flake.nix
             - src/index.ts
          2. Update ATProto metadata in flake.nix
          3. Enter development environment: `nix develop`
          4. Install dependencies: `npm install`
          5. Run the service: `npm run dev`

          See README.md for detailed instructions.
        '';
      };

      go-atproto = {
        path = ./go-atproto;
        description = "ATProto Go service template with Nix flake";
        welcomeText = ''
          # ATProto Go Service Template

          You have created a new ATProto Go service template.

          ## Next steps:
          1. Replace 'my-atproto-go-service' with your service name in:
             - go.mod
             - flake.nix
             - main.go
          2. Update ATProto metadata in flake.nix
          3. Enter development environment: `nix develop`
          4. Initialize modules: `go mod tidy`
          5. Run the service: `go run .`

          See README.md for detailed instructions.
        '';
      };
    };
  };
}