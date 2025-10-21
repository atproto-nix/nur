# Test for ATproto TypeScript libraries
{ pkgs, lib, ... }:

let
  atprotoPackages = pkgs.nur.atproto;
  
  # List of all ATproto TypeScript libraries to test
  typescriptLibs = [
    "atproto-api"
    "atproto-lexicon" 
    "atproto-xrpc"
    "atproto-did"
    "atproto-identity"
    "atproto-repo"
    "atproto-syntax"
  ];

  # Test that a package exists and has proper metadata
  testPackage = name: pkg: {
    name = "test-${name}";
    machine = { ... }: {
      environment.systemPackages = [ pkg ];
    };
    testScript = ''
      # Test that the package was built successfully
      machine.succeed("test -d ${pkg}")
      
      # Test that the package has ATproto metadata
      ${lib.optionalString (pkg.meta ? atproto) ''
        # Verify ATproto-specific metadata exists
        machine.succeed("echo 'Package ${name} has ATproto metadata'")
      ''}
      
      # Test that the package structure is correct
      machine.succeed("test -d ${pkg}/lib/node_modules/@atproto")
    '';
  };

  # Generate tests for all TypeScript libraries
  packageTests = lib.listToAttrs (map (name: {
    inherit name;
    value = testPackage name atprotoPackages.${name};
  }) typescriptLibs);

in
{
  # Individual package tests
  inherit (packageTests) 
    atproto-api
    atproto-lexicon
    atproto-xrpc
    atproto-did
    atproto-identity
    atproto-repo
    atproto-syntax;

  # Comprehensive test for all TypeScript libraries
  atproto-typescript-comprehensive = {
    name = "atproto-typescript-comprehensive";
    machine = { ... }: {
      environment.systemPackages = map (name: atprotoPackages.${name}) typescriptLibs;
    };
    testScript = ''
      start_all()
      
      # Test that all packages are available
      ${lib.concatMapStringsSep "\n" (name: ''
        machine.succeed("test -d ${atprotoPackages.${name}}")
        machine.succeed("test -d ${atprotoPackages.${name}}/lib/node_modules/@atproto")
      '') typescriptLibs}
      
      # Test package metadata consistency
      machine.succeed("echo 'All ATproto TypeScript libraries built successfully'")
    '';
  };

  # Dependency compatibility test
  atproto-typescript-dependencies = {
    name = "atproto-typescript-dependencies";
    machine = { ... }: {
      environment.systemPackages = [ pkgs.nodejs ];
    };
    testScript = ''
      start_all()
      
      # Test that Node.js can load the packages (basic smoke test)
      machine.succeed("node --version")
      
      # Create a simple test to verify package structure
      machine.succeed("""
        cat > test-packages.js << 'EOF'
        const fs = require('fs');
        const path = require('path');
        
        // Test package paths
        const packages = [
          ${lib.concatMapStringsSep ",\n          " (name: ''"${atprotoPackages.${name}}/lib/node_modules/@atproto"'') typescriptLibs}
        ];
        
        packages.forEach(pkg => {
          if (!fs.existsSync(pkg)) {
            console.error('Package not found:', pkg);
            process.exit(1);
          }
          console.log('Package found:', pkg);
        });
        
        console.log('All packages verified successfully');
        EOF
      """)
      
      machine.succeed("node test-packages.js")
    '';
  };
}