{
  description = "ATProto Go application template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Package configuration
        pname = "my-atproto-go-service";
        version = "0.1.0";

        # Build the Go package
        my-atproto-go-service = pkgs.buildGoModule {
          inherit pname version;
          
          src = ./.;
          
          # Generate the vendor hash
          # Run `nix build` and update this hash when dependencies change
          vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          
          # Build configuration
          ldflags = [
            "-s" "-w"
            "-X main.version=${version}"
            "-X main.buildTime=${builtins.toString self.lastModified}"
          ];

          # ATProto-specific metadata
          passthru = {
            atproto = {
              type = "application";
              services = [ "my-go-service" ]; # Replace with your service name
              protocols = [ "com.atproto" ];
              schemaVersion = "1.0";
            };
          };

          meta = with nixpkgs.lib; {
            description = "My ATProto Go service";
            homepage = "https://github.com/your-org/your-repo";
            license = licenses.mit;
            maintainers = [ ]; # Add your maintainer info
            platforms = platforms.linux ++ platforms.darwin;
          };
        };
      in
      {
        packages = {
          default = my-atproto-go-service;
          inherit my-atproto-go-service;
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gopls
            gotools
            go-tools
            delve
            
            # ATProto development tools
            curl
            jq
            
            # Database tools (if needed)
            sqlite
            postgresql
          ];

          shellHook = ''
            echo "ATProto Go Development Environment"
            echo "Go version: $(go version)"
            echo ""
            echo "Available commands:"
            echo "  go mod tidy     - Clean up dependencies"
            echo "  go run .        - Run the service"
            echo "  go build        - Build binary"
            echo "  go test ./...   - Run tests"
            echo "  nix build       - Build Nix package"
          '';
        };

        # Checks for CI/CD
        checks = {
          inherit my-atproto-go-service;
          
          # Go format check
          go-fmt-check = pkgs.runCommand "go-fmt-check" {
            buildInputs = [ pkgs.go ];
          } ''
            cd ${./.}
            if [ -n "$(gofmt -l .)" ]; then
              echo "Go files are not formatted. Run 'gofmt -w .'"
              exit 1
            fi
            touch $out
          '';

          # Go vet check
          go-vet-check = pkgs.runCommand "go-vet-check" {
            buildInputs = [ pkgs.go ];
          } ''
            cd ${./.}
            go vet ./...
            touch $out
          '';

          # Run tests
          go-test-check = pkgs.runCommand "go-test-check" {
            buildInputs = [ pkgs.go ];
          } ''
            cd ${./.}
            go test ./...
            touch $out
          '';
        };
      });
}