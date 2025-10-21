{
  description = "ATProto Node.js application template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Package configuration
        pname = "my-atproto-node-service";
        version = "0.1.0";

        # Build the Node.js package
        my-atproto-node-service = pkgs.buildNpmPackage {
          inherit pname version;
          
          src = ./.;
          
          # Generate the npm dependencies hash
          # Run `nix build` and update this hash when dependencies change
          npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          
          # Build configuration
          buildPhase = ''
            runHook preBuild
            npm run build
            runHook postBuild
          '';

          # Install configuration
          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin $out/lib/node_modules/${pname}
            
            # Copy built application
            cp -r dist/* $out/lib/node_modules/${pname}/
            cp package.json $out/lib/node_modules/${pname}/
            
            # Create executable wrapper
            cat > $out/bin/${pname} << 'EOF'
            #!${pkgs.bash}/bin/bash
            exec ${pkgs.nodejs}/bin/node $out/lib/node_modules/${pname}/index.js "$@"
            EOF
            chmod +x $out/bin/${pname}
            
            runHook postInstall
          '';

          # ATProto-specific metadata
          passthru = {
            atproto = {
              type = "application";
              services = [ "my-node-service" ]; # Replace with your service name
              protocols = [ "com.atproto" ];
              schemaVersion = "1.0";
            };
          };

          meta = with nixpkgs.lib; {
            description = "My ATProto Node.js service";
            homepage = "https://github.com/your-org/your-repo";
            license = licenses.mit;
            maintainers = [ ]; # Add your maintainer info
            platforms = platforms.linux ++ platforms.darwin;
          };
        };
      in
      {
        packages = {
          default = my-atproto-node-service;
          inherit my-atproto-node-service;
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs
            npm
            nodePackages.typescript
            nodePackages.ts-node
            nodePackages.nodemon
            
            # ATProto development tools
            curl
            jq
            
            # Database tools (if needed)
            sqlite
            postgresql
          ];

          shellHook = ''
            echo "ATProto Node.js Development Environment"
            echo "Node.js version: $(node --version)"
            echo "npm version: $(npm --version)"
            echo ""
            echo "Available commands:"
            echo "  npm install     - Install dependencies"
            echo "  npm run dev     - Start development server"
            echo "  npm run build   - Build for production"
            echo "  npm test        - Run tests"
            echo "  nix build       - Build Nix package"
          '';
        };

        # Checks for CI/CD
        checks = {
          inherit my-atproto-node-service;
          
          # TypeScript type checking
          typescript-check = pkgs.runCommand "typescript-check" {
            buildInputs = [ pkgs.nodejs pkgs.nodePackages.typescript ];
          } ''
            cd ${./.}
            npm ci
            npx tsc --noEmit
            touch $out
          '';

          # ESLint check
          eslint-check = pkgs.runCommand "eslint-check" {
            buildInputs = [ pkgs.nodejs ];
          } ''
            cd ${./.}
            npm ci
            npm run lint
            touch $out
          '';

          # Run tests
          test-check = pkgs.runCommand "test-check" {
            buildInputs = [ pkgs.nodejs ];
          } ''
            cd ${./.}
            npm ci
            npm test
            touch $out
          '';
        };
      });
}