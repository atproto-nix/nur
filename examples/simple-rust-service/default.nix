# Example: Simple Rust ATProto Service
# This demonstrates packaging a basic Rust ATProto service

{ lib
, fetchFromGitHub
, craneLib
, atprotoLib
, pkg-config
, openssl
, sqlite
}:

atprotoLib.mkRustAtprotoService {
  pname = "simple-atproto-service";
  version = "0.1.0";
  
  # In a real package, this would fetch from the actual repository
  src = lib.cleanSource ./.;
  
  # ATProto metadata - this is what makes it discoverable and manageable
  type = "application";
  services = [ "simple-service" ];
  protocols = [ "com.atproto" ];
  
  # Additional build dependencies specific to this service
  buildInputs = [ sqlite ];
  
  # Service-specific build configuration
  cargoExtraArgs = "--bin simple-service";
  
  # Comprehensive metadata following nixpkgs standards
  meta = with lib; {
    description = "A simple ATProto service demonstrating best practices";
    longDescription = ''
      This is an example ATProto service that demonstrates:
      - Proper Nix packaging patterns
      - ATProto metadata integration
      - Security best practices
      - Testing and documentation standards
    '';
    homepage = "https://github.com/atproto-nix/nur";
    license = licenses.mit;
    maintainers = with maintainers; [ ]; # Add actual maintainers
    platforms = platforms.linux;
    
    # Additional metadata for ATProto ecosystem
    atproto = {
      # Detailed service information
      endpoints = [
        "/xrpc/com.atproto.repo.createRecord"
        "/xrpc/com.atproto.repo.getRecord"
        "/health"
      ];
      
      # Configuration requirements
      configuration = {
        required = [ "port" ];
        optional = [ "database_url" "log_level" ];
      };
      
      # Runtime requirements
      databases = [ "sqlite" ];
      storage = [ "disk" ];
    };
  };
  
  # Development and testing support
  passthru = {
    # Expose test utilities
    tests = {
      unit = craneLib.cargoNextest (atprotoLib.defaultRustEnv // {
        src = lib.cleanSource ./.;
        cargoArtifacts = craneLib.buildDepsOnly {
          src = lib.cleanSource ./.;
          env = atprotoLib.defaultRustEnv;
          nativeBuildInputs = atprotoLib.defaultRustNativeInputs;
          buildInputs = atprotoLib.defaultRustBuildInputs;
        };
      });
    };
    
    # Development shell
    devShell = craneLib.devShell {
      packages = with lib; [
        # Development tools
        pkg-config
        openssl
        sqlite
        
        # ATProto development utilities
        curl
        jq
      ];
      
      env = atprotoLib.defaultRustEnv // {
        RUST_LOG = "debug";
        DATABASE_URL = "sqlite:./dev.db";
      };
    };
  };
}